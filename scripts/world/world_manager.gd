extends Node

signal room_changed(id: String)
signal ability_acquired(id: String)
var settings: Dictionary = {}
var density: Dictionary = {}
var autotile: Dictionary = {}
var abilities_data: Dictionary = {}
var index: Dictionary = {}
var regions: Dictionary = {}
var loaded: Dictionary = {}
var current_id := ""
var active := false
var transitioning := false
var abilities: Dictionary = {}
var collected: Dictionary = {}
var visited: Dictionary = {}
var switches: Dictionary = {}
var fragments := 0
var crystals := 0
var last_entry := "left"
var last_load_ms := 0.0
var active_enemies := 0
var sleeping_enemies := 0
var map_ui: CanvasLayer
var hero_motion: Node
var invulnerable := false
var tokens: Dictionary = {}
var reveal_all := false
var timing_scale := 1.0
var nearest_interactable: Node2D
var saved_camera_smoothing := true

func _ready() -> void:
    settings = read_json("res://data/world/zabulistan/world.json")
    autotile=read_json("res://data/world/autotile.json")
    density = read_json("res://data/world/enemy_density.json")
    abilities_data = read_json("res://data/world/abilities.json")
    index = read_json("res://data/world/zabulistan/index.json").rooms
    for row: Dictionary in read_json("res://data/world/zabulistan/regions.json").regions:regions[str(row.id)]=row
    get_node("/root/GameState").run_reset.connect(clear_session)
    hero_motion = load("res://scripts/world/world_abilities.gd").new()
    add_child(hero_motion)
    map_ui = load("res://scripts/world/world_map.gd").new()
    add_child(map_ui)

func read_json(path: String) -> Dictionary:
    return JSON.parse_string(FileAccess.get_file_as_string(path))

func clear_session() -> void:
    leave()
    abilities.clear()
    collected.clear()
    visited.clear()
    switches.clear()
    fragments=0
    crystals=0
    reveal_all=false
    hero_motion.reset_motion()

func leave() -> void:
    active=false
    current_id=""
    nearest_interactable=null
    tokens.clear()
    for room: Node in loaded.values():
        if is_instance_valid(room):
            if room.loaded_current:room.deactivate()
            if room.get_parent()!=null:room.get_parent().remove_child(room)
            room.queue_free()
    loaded.clear()
    var manager: Node = get_node("/root/SceneManager")
    if manager.current_level is WorldRoom:manager.current_level=null
    if is_instance_valid(manager.player):manager.player.camera.position_smoothing_enabled=saved_camera_smoothing
    if is_instance_valid(manager.main):manager.main.get_node("HUD").story.modulate.a=1

func saving_allowed() -> bool:return not active or bool(settings.save_enabled)
func has_ability(id: String) -> bool:return bool(abilities.get(id,false))
func meets(required: Array) -> bool:
    for id in required:
        if not has_ability(str(id)):return false
    return true
func max_hp() -> int:return mini(int(settings.life_hp_cap),100+(fragments/int(settings.life_fragments_per_upgrade))*int(settings.life_hp_increment))

func enter(room_id: String = "",entry: String = "left",fade: bool = true) -> bool:
    if transitioning:return false
    if room_id.is_empty():room_id=str(settings.start_room)
    if not index.has(room_id):return false
    var manager: Node = get_node("/root/SceneManager")
    if not is_instance_valid(manager.player):return false
    transitioning=true
    manager.set_player_locked(true)
    if fade:await manager._fade_to(1,float(settings.transition_seconds)*timing_scale)
    var start := Time.get_ticks_usec()
    if not active:saved_camera_smoothing=manager.player.camera.position_smoothing_enabled
    if not active and is_instance_valid(manager.current_level):
        manager.level_root.remove_child(manager.current_level)
        manager.current_level.queue_free()
    elif loaded.has(current_id):loaded[current_id].deactivate()
    active=true
    current_id=room_id
    last_entry=entry
    var room: WorldRoom = preload_room(room_id)
    room.activate(entry)
    manager.current_level=room
    manager.player.global_position=room.get_spawn(entry).global_position
    manager.player.velocity=Vector2.ZERO
    manager.player.last_safe_position=manager.player.global_position
    manager.player.camera.position_smoothing_enabled=false
    manager._update_camera(room.camera_limits)
    manager.main.get_node("HUD").set_level_name(room.display_name)
    get_node("/root/Audio").play_bgm(room.bgm_name)
    visited[room_id]=true
    hero_motion.reset_motion()
    tokens.clear()
    var keep: Dictionary = {room_id:true}
    for exit: Dictionary in room.room_data.exits:
        if exit.side in ["left","right","top","bottom"]:
            keep[str(exit.target_room)]=true
    for id in loaded.keys():
        if not keep.has(id):
            var old: Node = loaded[id]
            old.get_parent().remove_child(old)
            old.queue_free()
            loaded.erase(id)
    for id in keep:
        if id!=room_id:preload_room(str(id))
    last_load_ms=(Time.get_ticks_usec()-start)/1000.0
    if fade:await manager._fade_to(0,float(settings.transition_seconds)*timing_scale)
    manager.set_player_locked(get_node("/root/Cutscene").active)
    transitioning=false
    manager.show_toast("자불리스탄 · "+str(regions[room.room_data.region].name))
    room_changed.emit(room_id)
    return true

func preload_room(id: String) -> WorldRoom:
    if loaded.has(id):return loaded[id]
    var data: Dictionary = read_json(str(index[id]))
    var room: WorldRoom = load("res://scenes/WorldRoom.tscn").instantiate()
    room.room_data=data
    room.region_data=regions[str(data.region)]
    get_node("/root/SceneManager").level_root.add_child(room)
    loaded[id]=room
    return room

func _process(_delta: float) -> void:
    if not active or transitioning or get_tree().paused:return
    var manager: Node = get_node("/root/SceneManager")
    var hero: NimrodPlayer = manager.player
    var room: WorldRoom = loaded.get(current_id)
    if not is_instance_valid(room) or hero.action=="dead":return
    nearest_interactable=null
    var closest := 10000.
    for object: Node2D in get_tree().get_nodes_in_group("world_interactables"):
        var distance: float = object.position.distance_squared_to(hero.position)
        if distance<closest and meets(object.spec.get("requires",[])):
            if object.spec.type=="portal" and object.spec.get("one_way",false) and hero.position.x<object.position.x:continue
            closest=distance
            nearest_interactable=object
    update_sleep(room,hero)
    if manager.player_locked:return
    for exit: Dictionary in room.room_data.exits:
        var at: Vector2 = hero.position
        var crossed := false
        match str(exit.side):
            "left":crossed=at.x<20 and at.y>=float(exit.from) and at.y<=float(exit.to)
            "right":crossed=at.x>room.camera_limits.end.x-20 and at.y>=float(exit.from) and at.y<=float(exit.to)
            "top":crossed=at.y<50 and at.x>=float(exit.from) and at.x<=float(exit.to)
            "bottom":crossed=at.y>=room.floor_y-4 and at.x>=float(exit.from) and at.x<=float(exit.to) and Input.is_action_pressed("crouch") and Input.is_action_just_pressed("interact")
        if crossed:
            if room.room_data.boss_room and room.enemies.any(func(e: Variant)->bool:return is_instance_valid(e) and e.hp>0):
                hero.position.x=clampf(hero.position.x,80,room.camera_limits.end.x-80)
                manager.show_toast("수호자를 쓰러뜨려야 한다",1)
                return
            if not meets(exit.requires) or (exit.get("concealed",false) and not hero_motion.vision):
                hero.position.x=clampf(hero.position.x,80,room.camera_limits.end.x-80)
                if exit.side=="top":hero.position.y=120;hero.velocity.y=0
                manager.show_toast("F로 숨은 통로를 살핀다" if meets(exit.requires) else "광질 시야가 필요하다",1)
                return
            enter.call_deferred(str(exit.target_room),str(exit.target_entry))
            return

func update_sleep(room: WorldRoom,hero: NimrodPlayer) -> void:
    var candidates: Array[EnemyBase] = []
    for item: Variant in room.enemies:
        if is_instance_valid(item):candidates.append(item as EnemyBase)
    candidates.sort_custom(func(a: EnemyBase,b: EnemyBase)->bool:return a.position.distance_squared_to(hero.position)<b.position.distance_squared_to(hero.position))
    active_enemies=0
    sleeping_enemies=0
    for enemy in candidates:
        var awake: bool = enemy.state==EnemyBase.State.DEAD or (active_enemies<int(density.active_limit) and enemy.position.distance_to(hero.position)<=float(density.sleep_radius))
        enemy.set_physics_process(awake)
        if is_instance_valid(enemy.threat_marker):
            enemy.threat_marker.set_process(awake)
            if not awake:enemy.threat_marker.visible=false
        if awake and enemy.state!=EnemyBase.State.DEAD:active_enemies+=1
        elif not awake:sleeping_enemies+=1
    for key in tokens.keys():
        var e: Variant = instance_from_id(int(key))
        if not is_instance_valid(e) or e.state not in [EnemyBase.State.WINDUP,EnemyBase.State.ACTIVE]:tokens.erase(key)

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

func enemy_died(_enemy: EnemyBase,spec: Dictionary) -> void:
    if spec.type=="boss":collected[str(spec.boss_id)]=true

func acquire(id: String) -> bool:
    if has_ability(id) or not abilities_data.abilities.has(id):return false
    if not meets(abilities_data.abilities[id].requires):return false
    abilities[id]=true
    ability_acquired.emit(id)
    var manager: Node = get_node("/root/SceneManager")
    AnurLightProjectile.spawn_fx(manager.current_level,manager.player.position-Vector2(0,55),"anur_light_cast")
    manager.show_toast(str(abilities_data.abilities[id].name)+" · "+str(abilities_data.abilities[id].key))
    return true

func respawn() -> void:
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    hero.reset_run_state()
    await enter(current_id,last_entry)
    hero.hp=hero.get_max_hp()

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
    await enter(str(settings.start_room),"left",false)
    await manager._fade_to(0,float(travel_data.fade_in)*timing_scale)

func can_exit() -> bool:
    if not active:return true
    var room: WorldRoom = loaded[current_id]
    return not room.room_data.boss_room or not room.enemies.any(func(e: Variant)->bool:return is_instance_valid(e) and e.hp>0)

func altar_animation() -> void:
    var manager: Node = get_node("/root/SceneManager")
    manager.set_player_locked(true)
    await get_tree().create_timer(.3,false).timeout
    if active and not transitioning and not get_node("/root/Cutscene").active:manager.set_player_locked(false)
