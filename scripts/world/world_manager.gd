extends Node
# The shared CedarEnemy behavior is unchanged; only world-local JSON reads use
# a defensive copy of preloaded data instead of reparsing files for every spawn.
class CachedCedarEnemy extends CedarEnemy:
    func _read_json(path: String) -> Dictionary:
        return get_node("/root/World").enemy_json(path)

signal ability_acquired(id: String)
signal region_changed(id: String)
var settings: Dictionary = {}
var density: Dictionary = {}
var abilities_data: Dictionary = {}
var regions: Dictionary = {}
var art: Dictionary = {}
var carved_art: Dictionary = {}
var loaded: Dictionary = {}
var active:=false
var transitioning:=false
var abilities: Dictionary = {}
var collected: Dictionary = {}
var switches: Dictionary = {}
var bosses: Dictionary = {}
var defeated: Dictionary = {}
var explored:=PackedByteArray()
var cord_ids: Dictionary = {}
var embers:=0
var embers_offered_total:=0
var embers_offered_best:=0
var returns_alive:=0
var discovered_sites: Dictionary = {}
var collectible_data: Dictionary = {}
var deaths_zabulistan:=0
var deaths_total:=0
var death_latched:=false
var hero_motion: Node
var map_ui: CanvasLayer
var invulnerable:=false
var tokens: Dictionary = {}
var reveal_all:=false
var timing_scale:=1.0
var nearest_interactable: Node2D
var active_enemies:=0
var sleeping_enemies:=0
var last_load_ms:=0.
var slowest_stream_step: Dictionary = {}
var saved_camera_smoothing:=true
var level: ContinuousWorld
var worker: Thread
var pending: Array = []
var desired: Dictionary = {}
var stream_center:=Vector2i(-100,-100)
var stream_times: Array[float] = []
var texture_cache: Array[Resource] = []
var enemy_json_cache: Dictionary = {}
var terrain_sets: Dictionary = {}
var surface_shapes: Dictionary = {}
var light_material: CanvasItemMaterial
var building: Node2D
var reveal_cursor:=Vector2i(-100,-100)

func _ready() -> void:
    process_mode=PROCESS_MODE_ALWAYS
    settings=read_json("res://data/world/zabulistan/world_v2.json")
    if not settings.has("navigation"):
        var navigation: Array[String] = []
        for y in range(int(settings.height)):navigation.append("#".repeat(int(settings.width)))
        for path: String in settings.chunks.values():
            var chunk: Dictionary=read_json(path)
            var cx: int=int(chunk.coord[0])*64
            var cy: int=int(chunk.coord[1])*36
            for y in range(chunk.rle.size()):
                var line: String=navigation[cy+y]
                navigation[cy+y]=line.substr(0,cx)+decode_row(chunk.rle[y])+line.substr(cx+64)
        settings["navigation"]=navigation
    density=read_json("res://data/world/enemy_density.json")
    collectible_data=read_json("res://data/world/collectibles.json")
    abilities_data=read_json("res://data/world/abilities.json")
    art=read_json("res://data/world/zabulistan/art_v2.json")
    carved_art=read_json("res://data/world/zabulistan/carved_art.json")
    light_material=CanvasItemMaterial.new()
    light_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    for row: Dictionary in settings.regions:regions[str(row.id)]=row
    explored.resize(int(settings.width/8)*int(settings.height/8))
    get_node("/root/GameState").run_reset.connect(clear_session)
    hero_motion=load("res://scripts/world/world_abilities.gd").new()
    add_child(hero_motion)
    map_ui=load("res://scripts/world/world_map.gd").new()
    add_child(map_ui)

func read_json(path: String) -> Dictionary:
    return JSON.parse_string(FileAccess.get_file_as_string(path))

func enemy_json(path: String) -> Dictionary:
    if not enemy_json_cache.has(path):
        var file:=FileAccess.open(path,FileAccess.READ)
        if file==null:
            push_warning("Missing data: "+path)
            return {}
        var value: Variant=JSON.parse_string(file.get_as_text())
        if not value is Dictionary:
            push_warning("Invalid data: "+path)
            return {}
        enemy_json_cache[path]=value
    return enemy_json_cache[path].duplicate(true)

func clear_session() -> void:
    leave()
    abilities.clear()
    collected.clear()
    switches.clear()
    bosses.clear()
    defeated.clear()
    cord_ids.clear()
    embers=0
    embers_offered_total=0
    embers_offered_best=0
    returns_alive=0
    discovered_sites.clear()
    deaths_total=0
    deaths_zabulistan=0
    death_latched=false
    explored.fill(0)
    if hero_motion!=null:hero_motion.reset_motion()

func leave() -> void:
    if is_instance_valid(map_ui) and map_ui.opened:map_ui.close()
    active=false
    transitioning=false
    nearest_interactable=null
    tokens.clear()
    if worker!=null:
        worker.wait_to_finish()
        worker=null
    pending.clear()
    building=null
    loaded.clear()
    desired.clear()
    stream_center=Vector2i(-100,-100)
    if is_instance_valid(level):
        level.get_parent().remove_child(level)
        level.queue_free()
    var manager: Node = get_node("/root/SceneManager")
    if manager.current_level==level:manager.current_level=null
    level=null
    if is_instance_valid(manager.player):manager.player.camera.position_smoothing_enabled=saved_camera_smoothing

func saving_allowed() -> bool:return not active or bool(settings.save_enabled)
func has_ability(id: String) -> bool:return bool(abilities.get(id,false))
func meets(required: Array) -> bool:
    for id in required:
        if not has_ability(str(id)):return false
    return true
func max_hp() -> int:
    var base: int=int(get_node("/root/GameState").siyavash_settings["max_hp"])
    var effect: Dictionary=collectible_data.cord.effect
    return mini(int(effect.cap),base+floori(float(cord_ids.size())/float(effect.per))*int(effect.add))

func story_counts() -> Dictionary:
    return {"zab_cord_count":cord_ids.size(),"zab_cord_ids":cord_ids.keys(),"zab_embers_offered_total":embers_offered_total,"zab_embers_offered_best":embers_offered_best,"zab_returns_alive":returns_alive,"zab_embers_carried":embers,"deaths_zabulistan":deaths_zabulistan}

func clear_attempt() -> void:
    abilities.clear()
    collected.clear()
    embers=0
    if hero_motion!=null:hero_motion.reset_motion()

func persistent_data() -> Dictionary:
    var result: Dictionary=story_counts()
    result["zab_embers_carried"]=0
    result.merge({"opened_doors":switches.duplicate(),"defeated_bosses":bosses.duplicate(),"map_bitmap":Marshalls.raw_to_base64(explored.compress(FileAccess.COMPRESSION_DEFLATE)),"discovered_sites":discovered_sites.duplicate(true)})
    return result

func restore_persistent(data: Dictionary,total: int = 0) -> void:
    clear_attempt()
    cord_ids.clear()
    for uid: String in data.get("zab_cord_ids",[]):cord_ids[uid]=true
    discovered_sites=data.get("discovered_sites",{}).duplicate(true)
    embers_offered_total=maxi(0,int(data.get("zab_embers_offered_total",0)))
    embers_offered_best=maxi(0,int(data.get("zab_embers_offered_best",0)))
    returns_alive=maxi(0,int(data.get("zab_returns_alive",0)))
    switches=data.get("opened_doors",{}).duplicate()
    bosses=data.get("defeated_bosses",{}).duplicate()
    deaths_zabulistan=maxi(0,int(data.get("deaths_zabulistan",0)))
    deaths_total=maxi(deaths_zabulistan,total)
    explored.fill(0)
    var packed: PackedByteArray=Marshalls.base64_to_raw(str(data.get("map_bitmap","")))
    if not packed.is_empty():
        var decoded: PackedByteArray=packed.decompress(explored.size(),FileAccess.COMPRESSION_DEFLATE)
        if decoded.size()==explored.size():explored=decoded
    death_latched=false

func confirm_death(hero: NimrodPlayer) -> bool:
    if death_latched or hero.hp>0:return false
    if get_node("/root/Rampage").death_suspended and get_node("/root/HumbabaForm").engaged():return false
    death_latched=true
    deaths_total+=1
    if active:
        deaths_zabulistan+=1
        clear_attempt()
    return true

func debug_abilities(grant: bool) -> bool:
    if not OS.is_debug_build() or not active or transitioning:return false
    var hero: NimrodPlayer=get_node("/root/SceneManager").player
    if grant:
        for id: String in abilities_data.abilities:abilities[id]=true
    else:
        abilities.clear()
        var needs_compact: bool=hero_motion.crawling and not hero._can_stand()
        hero_motion.reset_motion()
        hero_motion.crawling=needs_compact
        if not needs_compact:
            hero.crouching=false
            hero._set_standing_collider()
    return true

func _unhandled_input(event: InputEvent) -> void:
    if not OS.is_debug_build() or not event is InputEventKey:return
    if not event.pressed or event.echo or not event.ctrl_pressed:return
    if event.physical_keycode==KEY_G and debug_abilities(true):get_viewport().set_input_as_handled()
    elif event.physical_keycode==KEY_B and debug_abilities(false):get_viewport().set_input_as_handled()

func region_at(point: Vector2) -> Dictionary:
    for region: Dictionary in regions.values():
        var b: Array = region.bounds
        if Rect2(float(b[0]),float(b[1]),float(b[2]),float(b[3])).has_point(point):return region
    return regions.values()[0]

func region_weights(point: Vector2) -> Dictionary:
    var result: Dictionary = {}
    var total:=0.
    for region: Dictionary in regions.values():
        var b: Array = region.bounds
        var rect:=Rect2(float(b[0]),float(b[1]),float(b[2]),float(b[3]))
        var dx: float = maxf(rect.position.x-point.x,point.x-rect.end.x)
        var dy: float = maxf(rect.position.y-point.y,point.y-rect.end.y)
        var weight: float = clampf((30.-maxf(dx,dy))/60.,0.,1.)
        if weight>0:result[region.id]=weight;total+=weight
    for id in result:result[id]/=maxf(total,.001)
    return result

func tile_at(at: Vector2i) -> String:
    if at.x<0 or at.y<0 or at.x>=int(settings.width) or at.y>=int(settings.height):return "#"
    var glyph: String=str(settings.navigation[at.y])[at.x]
    if glyph=="F":
        for wall: Array in settings.get("fake_walls",[]):
            if Rect2i(int(wall[1]),int(wall[2]),int(wall[3]),int(wall[4])).has_point(at) and switches.has(str(wall[0])):return "."
    return glyph

func solid_at(at: Vector2i) -> bool:
    return tile_at(at) in ["#","W","^","F"]

func surface_shape(size_px: Vector2) -> RectangleShape2D:
    var key:=Vector2i(roundi(size_px.x),roundi(size_px.y))
    if not surface_shapes.has(key):
        var shape:=RectangleShape2D.new()
        shape.size=size_px
        surface_shapes[key]=shape
    return surface_shapes[key]

func decode_row(runs: Variant) -> String:
    var row: String=""
    if runs is Array:
        for pair: Array in runs:row+=str(pair[0]).repeat(int(pair[1]))
        return row
    var count: int=0
    for char: String in str(runs):
        if char.is_valid_int():count=count*10+char.to_int()
        else:
            row+=char.repeat(count)
            count=0
    return row

func chunk_id(at: Vector2i) -> String:return "c%02d_%02d" % [at.x,at.y]
func chunk_at(point: Vector2) -> Vector2i:
    return Vector2i(floori(point.x/(32.*int(settings.chunk_size[0]))),floori(point.y/(32.*int(settings.chunk_size[1]))))

func enter() -> bool:
    if transitioning:return false
    var manager: Node = get_node("/root/SceneManager")
    if not is_instance_valid(manager.player):return false
    transitioning=true
    manager.set_player_locked(true)
    saved_camera_smoothing=manager.player.camera.position_smoothing_enabled
    if is_instance_valid(manager.current_level):
        manager.current_level.get_parent().remove_child(manager.current_level)
        manager.current_level.queue_free()
        manager.current_level=null
    await prewarm_art()
    clear_attempt()
    active=true
    death_latched=false
    reveal_cursor=Vector2i(-100,-100)
    defeated.clear()
    level=load("res://scenes/ZabulistanWorld.tscn").instantiate()
    manager.level_root.add_child(level)
    manager.current_level=level
    manager.player.position=Vector2(float(settings.spawn[0]),float(settings.spawn[1]))*32
    manager.player.velocity=Vector2.ZERO
    manager.player.last_safe_position=manager.player.position
    manager.player.camera.position_smoothing_enabled=true
    manager._update_camera(level.camera_limits)
    manager.main.get_node("HUD").set_level_name("자불리스탄")
    hero_motion.reset_motion()
    schedule_stream(manager.player.position)
    while not streaming_idle():
        await get_tree().process_frame
    transitioning=false
    manager.set_player_locked(get_node("/root/Cutscene").active)
    manager.show_toast("자불리스탄")
    return true

func schedule_stream(point: Vector2) -> void:
    var center:=chunk_at(point)
    if center==stream_center:return
    stream_center=center
    desired.clear()
    var tasks: Array = []
    for dy in range(-1,2):
        for dx in range(-1,2):
            var coord:=center+Vector2i(dx,dy)
            var id:=chunk_id(coord)
            if settings.chunks.has(id):desired[id]=true
    for id in loaded.keys():
        if not desired.has(id):
            var old: Node = loaded[id]
            old.get_parent().remove_child(old)
            if building==old:building=null
            old.queue_free()
            loaded.erase(id)
    if worker!=null:return
    for id in desired:
        if not loaded.has(id):tasks.append({"id":id,"path":settings.chunks[id]})
    if tasks.is_empty():return
    worker=Thread.new()
    worker.start(_read_chunks.bind(tasks))

func _read_chunks(tasks: Array) -> Array:
    var output: Array = []
    for task: Dictionary in tasks:
        var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(task.path)))
        var rows: Array = []
        for runs: Variant in data.rle:rows.append(decode_row(runs))
        data["rows"]=rows
        data.erase("rle")
        data["id"]=task.id
        output.append(data)
    return output

func streaming_idle() -> bool:
    return worker==null and pending.is_empty() and not is_instance_valid(building)

func pump_stream() -> void:
    if worker!=null and not worker.is_alive():
        pending.append_array(worker.wait_to_finish())
        worker=null
    if not is_instance_valid(building):
        building=null
        while not pending.is_empty():
            var data: Dictionary=pending.pop_front()
            if not desired.has(data.id) or loaded.has(data.id):continue
            building=load("res://scripts/world/world_chunk.gd").new()
            building.data=data
            building.position=Vector2(float(data.coord[0])*float(settings.chunk_size[0])*32,float(data.coord[1])*float(settings.chunk_size[1])*32)
            level.add_child(building)
            loaded[data.id]=building
            break
    if not is_instance_valid(building):return
    var profile_phase: int=building.phase
    var profile_id: String=str(building.data.id)
    var profile_row: int=building.row_cursor
    var profile_entity: String=""
    if (profile_phase==3 or profile_phase==4 and building.extra_cursor>=building.extras.size()) and building.entity_cursor<building.data.get("entities",[]).size():profile_entity=str(building.data.entities[building.entity_cursor].get("uid",""))
    var profile_extra: String=""
    if profile_phase==4 and building.extra_cursor<building.extras.size():profile_extra=str(building.extras[building.extra_cursor].get("kind",""))
    var started:=Time.get_ticks_usec()
    var complete: bool=building.build_step()
    last_load_ms=(Time.get_ticks_usec()-started)/1000.
    stream_times.append(last_load_ms)
    if last_load_ms>float(slowest_stream_step.get("ms",0)):
        slowest_stream_step={"ms":last_load_ms,"chunk":profile_id,"phase":profile_phase,"row":profile_row,"entity":profile_entity,"extra":profile_extra}
    if last_load_ms>20 and OS.is_debug_build() and (bool(settings.get("developer_overlay",false)) or OS.get_environment("NIMROD_STREAM_TRACE")=="1"):print("STREAM_STEP ",building.data.id," phase=",building.phase," row=",building.row_cursor," ms=",last_load_ms)
    if complete:building=null

func _process(_delta: float) -> void:
    if not active:return
    pump_stream()
    if transitioning or get_tree().paused:return
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    if not is_instance_valid(hero) or hero.action=="dead":return
    if hero.position.y>float(settings.height)*32+64:
        hero.receive_damage(hero.get_max_hp()*10,{"source":"world_fall","grant_grace":false,"stagger":false})
        return
    var center:=chunk_at(hero.position)
    if streaming_idle() and (center!=stream_center or loaded.size()<desired.size()):
        stream_center=Vector2i(-100,-100)
        schedule_stream(hero.position)
    reveal_near(hero.position)
    nearest_interactable=null
    var closest:=10000.
    for object: Node2D in get_tree().get_nodes_in_group("world_interactables"):
        var distance: float = object.global_position.distance_squared_to(hero.position)
        if distance<closest and meets(object.spec.get("requires",[])):
            closest=distance
            nearest_interactable=object
    update_sleep(hero)

func reveal_near(point: Vector2) -> void:
    var at:=Vector2i(point/256.)
    if at==reveal_cursor:return
    reveal_cursor=at
    var width: int = int(settings.width)/8
    var eye:=point/32.-Vector2(0,2)
    for y in range(maxi(0,at.y-1),mini(int(settings.height)/8,at.y+2)):
        for x in range(maxi(0,at.x-2),mini(width,at.x+3)):
            var target:=Vector2(x*8+4,y*8+4)
            var steps:=maxi(1,ceili(eye.distance_to(target)))
            var clear:=true
            for step in range(1,steps+1):
                if solid_at(Vector2i(eye.lerp(target,float(step)/steps))):clear=false;break
            if clear or Vector2i(x,y)==at:explored[y*width+x]=1

func update_sleep(hero: NimrodPlayer) -> void:
    active_enemies=0
    sleeping_enemies=0
    for enemy: Variant in level.enemies:
        if not is_instance_valid(enemy):continue
        var awake: bool = enemy.state==EnemyBase.State.DEAD or (active_enemies<int(density.active_limit) and enemy.global_position.distance_to(hero.position)<=float(density.sleep_radius))
        enemy.set_physics_process(awake)
        if is_instance_valid(enemy.threat_marker):
            enemy.threat_marker.set_process(awake)
            if not awake:enemy.threat_marker.visible=false
        enemy.visible=enemy.global_position.distance_to(hero.position)<1800
        if awake and enemy.state!=EnemyBase.State.DEAD:active_enemies+=1
        elif not awake:sleeping_enemies+=1
    for key in tokens.keys():
        var e: Variant = instance_from_id(int(key))
        if not is_instance_valid(e) or e.state not in [EnemyBase.State.WINDUP,EnemyBase.State.ACTIVE]:tokens.erase(key)

func spawn_entity(spec: Dictionary,parent: Node2D) -> void:
    var id: String = str(spec.uid)
    if defeated.has(id) or collected.has(id) or cord_ids.has(id) or (spec.type=="boss" and bosses.has(id)):return
    if spec.type in ["enemy","boss"]:
        var enemy: EnemyBase = load("res://scripts/world/world_boss.gd").new() if spec.type=="boss" else CachedCedarEnemy.new()
        enemy.enemy_id=str(spec.id)
        enemy.position=Vector2(float(spec.position[0]),float(spec.position[1]))-parent.global_position
        enemy.room_bounds=level.camera_limits
        enemy.safe_min_x=maxf(32,float(spec.position[0])-float(spec.get("patrol",160)))
        enemy.safe_max_x=minf(level.camera_limits.end.x-32,float(spec.position[0])+float(spec.get("patrol",160)))
        enemy.patrol_range=float(spec.get("patrol",160))
        enemy.no_drop=spec.type=="boss"
        parent.add_child(enemy)
        scale_enemy(enemy,spec,regions[str(spec.region)])
        enemy.died.connect(enemy_died.bind(spec))
        enemy.tree_exiting.connect(level.forget_enemy.bind(enemy))
        level.enemies.append(enemy)
    else:
        var actor: Node2D = load("res://scripts/world/world_object.gd").new()
        actor.spec=spec.duplicate(true)
        actor.spec["id"]=id
        actor.position=Vector2(float(spec.position[0]),float(spec.position[1]))-parent.global_position
        parent.add_child(actor)

func enemy_died(_enemy: EnemyBase,spec: Dictionary) -> void:
    if spec.type=="boss" and bosses.has(str(spec.uid)):return
    defeated[str(spec.uid)]=true
    if spec.type=="boss":
        bosses[str(spec.uid)]=true
        embers+=int(collectible_data.ember.effect.boss_amount)

func return_to_plaza() -> void:
    if transitioning:return
    transitioning=true
    var manager: Node = get_node("/root/SceneManager")
    manager.set_player_locked(true)
    await manager._fade_to(1,.3*timing_scale)
    var caption:=Label.new()
    caption.text="흐와니라 광장\n죽음 %d회\n%s" % [deaths_zabulistan,str(collectible_data.death_caption)]
    caption.position=Vector2(400,310)
    caption.size=Vector2(480,100)
    caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    caption.add_theme_font_size_override("font_size",28)
    manager._overlay.add_child(caption)
    clear_attempt()
    defeated.clear()
    manager.player.reset_run_state()
    await manager.go_to("HwaniraPlaza","Spawn_Start",{"instant":true,"preserve_fade":true})
    manager.player.hp=manager.player.get_max_hp()
    manager.set_player_locked(true)
    death_latched=false
    await get_tree().create_timer(.35*timing_scale,true).timeout
    caption.queue_free()
    await manager._fade_to(0,.3*timing_scale)
    transitioning=false
    manager.set_player_locked(false)
    get_node("/root/Save").save_checkpoint("character")

func return_alive() -> bool:
    if not active or transitioning:return false
    transitioning=true
    var manager: Node=get_node("/root/SceneManager")
    manager.set_player_locked(true)
    var offered: int=embers
    await manager._fade_to(1,.3*timing_scale)
    var travel_glow: Node2D=AssetVisual.add_image(manager._overlay,"res://assets/fx/npc_light_pool.webp",Vector2(240,230),Vector2(800,260))
    travel_glow.modulate=Color(.9,.65,.35,.7)
    await get_tree().create_timer(.2*timing_scale,true).timeout
    travel_glow.queue_free()
    var caption:=Label.new()
    caption.text="흐와니라 광장"
    caption.position=Vector2(400,310)
    caption.size=Vector2(480,100)
    caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    caption.add_theme_font_size_override("font_size",28)
    manager._overlay.add_child(caption)
    clear_attempt()
    manager.player.reset_run_state()
    embers_offered_total+=offered
    embers_offered_best=maxi(embers_offered_best,offered)
    returns_alive+=1
    await manager.go_to("HwaniraPlaza","Spawn_Start",{"instant":true,"preserve_fade":true})
    manager.player.global_position=Vector2(float(collectible_data.return_pier.arrival_position[0]),float(collectible_data.return_pier.arrival_position[1]))
    manager.player.velocity=Vector2.ZERO
    manager.player.hp=manager.player.get_max_hp()
    manager.player.camera.reset_smoothing()
    manager.player.camera.force_update_scroll()
    manager.set_player_locked(true)
    var fire: Node2D=AssetVisual.add_image(manager.current_level,"res://assets/fx/npc_light_pool.webp",Vector2(1900,600),Vector2(150,280),-1)
    fire.modulate=Color(1.,.44,.12,.8)
    fire.material=light_material
    var flash: Tween=create_tween()
    flash.tween_property(fire,"modulate:a",0.,.6*timing_scale)
    flash.tween_callback(fire.queue_free)
    await manager._fade_to(0,.3*timing_scale)
    caption.queue_free()
    manager.show_toast(str(collectible_data.return_pier.offering_caption) % offered,float(collectible_data.return_pier.caption_seconds))
    transitioning=false
    manager.set_player_locked(false)
    get_node("/root/Save").save_checkpoint("character")
    return true

func can_exit() -> bool:return true
func request_attack(enemy: EnemyBase) -> bool:
    if not active:return true
    var category := "melee"
    if enemy.enemy_id=="cedar_archer":category="ranged"
    elif enemy.enemy_id=="cedar_demon":category="dive"
    elif enemy.enemy_id=="cedar_wisp":category="explosion"
    if tokens.has(enemy.get_instance_id()):return true
    var count := 0
    for value in tokens.values():
        if value==category:count+=1
    if count>=int(density[category+"_tokens"]):return false
    tokens[enemy.get_instance_id()]=category
    return true

func scale_enemy(enemy: EnemyBase,spec: Dictionary,region: Dictionary) -> void:
    var number: int = int(region.number)-1
    var hp_mult: float = float(density.region_hp[number])*(float(density.elite_hp) if spec.get("elite",false) else 1.)
    enemy.stats.hp=roundi(float(enemy.stats.hp)*hp_mult)
    enemy.hp=int(enemy.stats.hp)
    scale_damage(enemy.stats,float(density.region_damage[number]))
    if spec.get("elite",false):
        for attack: Dictionary in enemy.stats.get("attacks",[]):
            for key in ["windup","active","recovery"]:
                if attack.has(key):attack[key]=float(attack[key])/float(density.elite_speed)
    if spec.type=="boss":enemy.stats["display_name"]=str(spec.display_name)
    enemy.modulate=Color.WHITE.lerp(Color(str(region.palette)),.15 if spec.get("elite",false) else .35)

func scale_damage(data: Variant,multiplier: float) -> void:
    if data is Dictionary:
        for key in data:
            if key in ["damage","contact_damage"] and (data[key] is float or data[key] is int):data[key]=roundi(float(data[key])*multiplier)
            elif key=="claw_damage" and data[key] is Array:
                for i in range(data[key].size()):data[key][i]=roundi(float(data[key][i])*multiplier)
            else:scale_damage(data[key],multiplier)
    elif data is Array:
        for item in data:scale_damage(item,multiplier)

func acquire(id: String) -> bool:
    if has_ability(id) or not abilities_data.abilities.has(id):return false
    abilities[id]=true
    ability_acquired.emit(id)
    var manager: Node = get_node("/root/SceneManager")
    AnurLightProjectile.spawn_fx(manager.current_level,manager.player.position-Vector2(0,55),"anur_light_cast")
    manager.show_toast(str(collectible_data.site.acquire_caption)+"\n"+str(abilities_data.abilities[id].name)+" · "+str(abilities_data.abilities[id].key),float(collectible_data.site.caption_seconds))
    return true

func travel() -> void:
    var manager: Node = get_node("/root/SceneManager")
    var travel_data: Dictionary = settings.travel
    await manager._fade_to(1,float(travel_data.fade_out)*timing_scale)
    var glow_root := Node2D.new()
    manager._overlay.add_child(glow_root)
    for i in range(travel_data.palette.size()):
        var size := Vector2(850-i*80,300-i*20)
        var glow: Node2D = AssetVisual.add_image(glow_root,"res://assets/fx/npc_light_pool.webp",Vector2(640,360)-size*.5,size)
        glow.modulate=Color(str(travel_data.palette[i]))
        glow.modulate.a=.6
    var glow_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    glow_tween.tween_property(glow_root,"modulate:a",0.,float(travel_data.glow_seconds)*timing_scale)
    await glow_tween.finished
    glow_root.queue_free()
    var caption := Label.new()
    caption.text="자불리스탄"
    caption.position=Vector2(480,330)
    caption.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    caption.add_theme_font_size_override("font_size",38)
    manager._overlay.add_child(caption)
    await get_tree().create_timer(float(travel_data.caption_seconds)*timing_scale,true).timeout
    caption.queue_free()
    await enter()
    await manager._fade_to(0,float(travel_data.fade_in)*timing_scale)

func altar_animation() -> void:
    var manager: Node = get_node("/root/SceneManager")
    manager.set_player_locked(true)
    await get_tree().create_timer(.3,false).timeout
    if active and not transitioning and not get_node("/root/Cutscene").active:manager.set_player_locked(false)

func prewarm_art() -> void:
    if not texture_cache.is_empty():return
    for path in ["res://scripts/threat_marker.gd","res://scripts/enemy_cedar_sentinel.gd","res://scripts/enemy_cedar_archer.gd","res://scripts/enemy_cedar_colossus.gd","res://scripts/enemy_cedar_demon.gd","res://scripts/enemy_cedar_wisp.gd","res://scripts/world/world_boss.gd","res://scripts/world/world_object.gd"]:texture_cache.append(load(path))
    for path: String in ["res://data/enemies.json","res://data/player_attacks.json"]:enemy_json_cache[path]=read_json(path)
    var paths: Dictionary = {}
    for path: String in read_json("res://data/world/art.json").values():paths[path]=true
    for record: Variant in collectible_data.values():
        if record is Dictionary and record.has("icon"):paths[str(record.icon)]=true
    paths["res://assets/fx/npc_light_pool.webp"]=true
    for key: String in ["crust","fill","backwall","supports","foreground"]:paths[str(carved_art[key])]=true
    for spec: Dictionary in art.values():
        paths[str(spec.atlas)]=true
        if spec.has("terrain"):paths[str(spec.terrain)]=true
        for path in spec.backgrounds:paths[str(path)]=true
    for id in ["cedar_sentinel","cedar_archer","cedar_colossus","cedar_demon","cedar_wisp","kala_ushumgal","gugalanna","humbaba"]:
        var manifest_path: String="res://assets/sprites/enemies/"+id+"/manifest.json"
        var manifest: Dictionary=read_json(manifest_path)
        enemy_json_cache[manifest_path]=manifest
        for clip: Dictionary in manifest.clips:
            var sheet: String = str(clip.sheet)
            paths[sheet if sheet.begins_with("res://") else "res://assets/"+sheet if sheet.begins_with("sprites/") else "res://assets/sprites/enemies/"+id+"/"+sheet]=true
    var requested: Array[String]=[]
    for path in paths:
        if ResourceLoader.has_cached(path):
            texture_cache.append(load(path))
        elif ResourceLoader.load_threaded_request(path)==OK:
            requested.append(path)
        else:push_error("World art request failed: "+str(path))
    # A request must always be consumed, even if its completed resource entered
    # the cache before this loop. Leaving it pending leaks an Image/RID at exit.
    for path: String in requested:
        while ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            await get_tree().process_frame
        if ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_LOADED:texture_cache.append(ResourceLoader.load_threaded_get(path))
        else:push_error("World art load failed: "+path)
    for id in art:
        if art[id].has("terrain"):terrain_set(str(id))
    for kind: String in ["crust","fill","backwall","supports"]:carved_set(kind)

func carved_set(kind: String) -> TileSet:
    var key: String="carved_"+kind
    if terrain_sets.has(key):return terrain_sets[key]
    var dimensions: Vector2i={"crust":Vector2i(20,3),"fill":Vector2i(2,2),"backwall":Vector2i(16,3),"supports":Vector2i(4,2)}[kind]
    var cell: int=64 if kind=="supports" else 32
    var tiles:=TileSet.new()
    tiles.tile_size=Vector2i(cell,cell)
    var source:=TileSetAtlasSource.new()
    source.texture=load(str(carved_art[kind]))
    source.texture_region_size=Vector2i(cell,cell)
    source.margins=Vector2i(2,2)
    source.separation=Vector2i(4,4)
    for y in range(dimensions.y):
        for x in range(dimensions.x):source.create_tile(Vector2i(x,y))
    tiles.add_source(source,0)
    terrain_sets[key]=tiles
    return tiles

func terrain_set(id: String) -> TileSet:
    if terrain_sets.has(id):return terrain_sets[id]
    var spec: Dictionary=art[id]
    var tiles:=TileSet.new()
    tiles.tile_size=Vector2i(32,32)
    var source:=TileSetAtlasSource.new()
    source.texture=load(str(spec.terrain))
    source.texture_region_size=Vector2i(32,32)
    source.margins=Vector2i(2,2)
    source.separation=Vector2i(4,4)
    for y in range(4):
        for x in range(6):source.create_tile(Vector2i(x,y))
    tiles.add_source(source,0)
    terrain_sets[id]=tiles
    return tiles
