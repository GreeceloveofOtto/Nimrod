extends Node

var skips: Dictionary = {}
var overlay: CanvasLayer
var caption: Label
var flash: ColorRect
var vignette: ColorRect
var sounds: Array[Node] = []
var saved_camera_zoom := Vector2.ONE
var current_skip := ""

func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    skips = JSON.parse_string(FileAccess.get_file_as_string("res://data/time_skips.json"))
    overlay = CanvasLayer.new()
    overlay.layer = 110
    add_child(overlay)
    caption = Label.new()
    caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    caption.add_theme_font_override("font", load(str(skips["caption_font"])) as Font)
    caption.add_theme_font_size_override("font_size", int(skips["caption_size"]))
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(caption)
    caption.hide()
    flash = ColorRect.new()
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flash.color = Color.TRANSPARENT
    overlay.add_child(flash)
    vignette = ColorRect.new()
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var shader := Shader.new()
    shader.code = "shader_type canvas_item; uniform float strength=0.0; uniform vec3 tint=vec3(0.35,0.01,0.01); void fragment(){ float edge=smoothstep(0.18,0.68,length(UV-vec2(0.5))); COLOR=vec4(tint,edge*strength); }"
    var effect := ShaderMaterial.new()
    effect.shader = shader
    vignette.material = effect
    overlay.add_child(vignette)

func _process(_delta: float) -> void:
    var manager: Node = get_node("/root/SceneManager")
    if is_instance_valid(manager.current_level) and manager.current_level.level_id == "Dilmun" and not get_node("/root/Cutscene").active:
        var distance: float = minf(manager.player.global_position.x, 9000-manager.player.global_position.x)
        vignette.material.set_shader_parameter("strength", .75*clampf(1-distance/float(get_node("/root/Story").settings["edge_vignette_distance"]),0,1))
        vignette.material.set_shader_parameter("tint",Vector3.ZERO)

func on_arrival(level_id: String) -> void:
    if level_id == "Dilmun":
        get_node("/root/Rampage").unlock()
        get_node("/root/Story").set_flag("dilmun_arrived")
    elif level_id == "DeathSea":
        get_node("/root/Story").set_flag("deathsea_arrived")
    if level_id == "VillaF4" and get_node("/root/Story").is_flag("prosthetic_equipped") and not get_node("/root/Story").is_flag("rooftop_done"):
        get_node("/root/Cutscene").play("rooftop")

func refresh_level(level: LevelBase) -> void:
    var story: Node = get_node("/root/Story")
    level.reconcile_presence()
    if story.is_flag("enkidua_gone"):
        get_node("/root/GameState").run_flags["bed_blood"] = true
    if level.level_id == "NimrodHome":
        var bed: NPC = level.npcs.get("enkidua_bed")
        if is_instance_valid(bed):
            bed.three_way = false
            bed.face_player = false
            bed.story_pose_locked = true
            bed.idle_clip = "bed_asleep" if story.is_flag("home_critical_done") and not story.is_flag("inanna_home_done") else "bed_awake"
            if bed.current_clip != bed.idle_clip:
                bed.play_clip(bed.idle_clip)
            bed.interactable = bed.idle_clip == "bed_awake"
        var blood: Node2D = level.get_node_or_null("BedBlood")
        if story.is_flag("bed_blood") and not is_instance_valid(blood):
            var contact: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/prop_contacts.json"))
            blood = AssetVisual.add_image(level,"res://assets/props/home_bed_blood.webp",Vector2(float(contact["blood_position"][0]),float(contact["blood_position"][1])),Vector2(float(contact["blood_size"][0]),float(contact["blood_size"][1])),1)
            blood.name = "BedBlood"
        elif not story.is_flag("bed_blood") and is_instance_valid(blood):
            blood.queue_free()
        if story.is_flag("enkidua_gone"):
            level.bgm_name = "home_sorrow"
    if level.level_id == "CedarBossRoom" and story.is_flag("humbaba_defeated"):
        level.doors["boss_arrival"].locked = not story.is_flag("melammu_absorbed")
        level.doors["boss_arrival"].locked_message = "멜람무를 먼저 삼켜야 한다"
        if not story.is_flag("melammu_absorbed") and not level.has_node("Melammu") and get_tree().get_nodes_in_group("enemies").is_empty():
            drop(level,"melammu",Vector2(800,620))
    if level.level_id == "HomeFront" and story.is_flag("gugalanna_defeated") and not story.is_flag("gugalanna_helm") and get_tree().get_nodes_in_group("enemies").is_empty() and not level.has_node("Helm"):
        drop(level,"helm",Vector2(1700,880))

func drop(level: LevelBase, kind: String, at: Vector2) -> void:
    var item: Node2D = load("res://scripts/story_pickup.gd").new()
    item.kind = kind
    item.name = "Melammu" if kind == "melammu" else "Helm"
    item.position = at
    level.add_child(item)

func time_skip(id: String) -> void:
    var runner: Node = get_node("/root/Cutscene")
    var manager: Node = get_node("/root/SceneManager")
    var spec: Dictionary = skips["skips"][id]
    current_skip = id
    await manager._fade_to(1.,float(spec["fade_out"])*runner.timing_scale)
    if not runner.active:
        return
    caption.text = str(spec["caption"])
    if caption.text.is_empty():
        await runner._wait(float(spec["hold"]))
    else:
        caption.modulate.a = 0
        caption.show()
        var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        tween.tween_property(caption,"modulate:a",1.,float(skips["caption_fade"])*runner.timing_scale)
        tween.tween_interval(float(spec["hold"])*runner.timing_scale)
        tween.tween_property(caption,"modulate:a",0.,float(skips["caption_fade"])*runner.timing_scale)
        await tween.finished
    if not runner.active:
        return
    caption.hide()
    for flag in spec.get("set_flags",[]):
        get_node("/root/Story").set_flag(str(flag))
    if id == "home_after_loss":
        get_node("/root/Story").set_flag("bed_blood",true)
        manager.player.cinematic_set = ""
        manager.player.sync_story_state()
    var destination: Dictionary = spec["spawn"]
    await manager.go_to(str(destination["level"]),str(destination["spawn"]),{"instant":true,"preserve_fade":true})
    manager.set_player_locked(true)
    manager.player.cinematic_clip = "crouch_exit"
    manager.player.cinematic_clock = 0
    if not str(spec.get("bgm","")).is_empty():
        get_node("/root/Audio").play_bgm(str(spec["bgm"]))
    var healing: Variant = spec.get("heal")
    if healing != null:
        manager.player.hp = manager.player.get_max_hp() if str(healing) == "full" else mini(manager.player.get_max_hp(),manager.player.hp+int(healing))
        manager.player.damage_received.emit(0,manager.player.hp)
    await manager._fade_to(0.,float(spec["fade_in"])*runner.timing_scale)
    if not runner.active:
        return
    current_skip = ""

func pulse(color: Color, seconds: float) -> void:
    flash.color = color
    var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(flash,"color:a",0.,seconds*get_node("/root/Cutscene").timing_scale)
    await tween.finished

func cutscene_sound(id: String) -> void:
    var sound: Node = get_node("/root/Audio").play_sfx(id)
    if is_instance_valid(sound):
        sounds.append(sound)

func event(id: String) -> void:
    var manager: Node = get_node("/root/SceneManager")
    var hero: NimrodPlayer = manager.player
    var story: Node = get_node("/root/Story")
    match id:
        "arm_loss":
            if story.is_flag("arm_lost"):
                return
            var data: Dictionary = story.settings["arm_loss"]
            var boss: EnemyBase = get_node("/root/Cutscene").actor("humbaba") as EnemyBase
            if is_instance_valid(boss):
                boss.global_position = Vector2(clampf(hero.global_position.x+boss.body_size.x*.5, boss.body_size.x*.5, manager.current_level.camera_limits.end.x-boss.body_size.x*.5),hero.global_position.y)
                boss.velocity = Vector2.ZERO
            hero.hp = maxi(1,hero.hp-int(data["damage"]))
            hero.damage_received.emit(int(data["damage"]),hero.hp)
            hero._restore_safe_collider()
            hero.roll_clock = 0
            hero.action = "normal"
            hero.attack_generation += 1
            hero._cancel_attack()
            hero.velocity = Vector2.ZERO
            story.set_flag("arm_lost")
            get_node("/root/GameState").set_weapon("axe")
            var arm: Node2D = spawn_fx(manager.current_level,hero.global_position+Vector2(0,-80),"severed_arm")
            get_node("/root/Cutscene")._control(arm)
            var falling := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
            falling.tween_property(arm,"position:x",arm.position.x-110,.9*get_node("/root/Cutscene").timing_scale)
            falling.tween_property(arm,"position:y",hero.global_position.y-8,.9*get_node("/root/Cutscene").timing_scale)
            falling.tween_property(arm,"rotation",-PI,.9*get_node("/root/Cutscene").timing_scale)
            cutscene_sound("arm_cut")
            pulse(Color(.8,.02,.02,.6),float(data["flash"]))
            var boss_processing: bool = is_instance_valid(boss) and boss.is_physics_processing()
            if is_instance_valid(boss):
                boss.set_physics_process(false)
            var original: Vector2 = hero.camera.offset
            for i in range(6):
                hero.camera.offset = original+Vector2(8 if i%2==0 else -8,3)
                await get_node("/root/Cutscene")._wait(float(data["hitstop"])/6)
            hero.camera.offset = original
            if is_instance_valid(boss):
                boss.set_physics_process(boss_processing)
        "melammu":
            story.set_flag("melammu_absorbed")
            story.set_flag("melammu")
            hero.sync_story_state()
            cutscene_sound("melammu_heartbeat")
            vignette.material.set_shader_parameter("tint",Vector3(.4,.01,.01))
            var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
            for i in range(4):
                tween.tween_method(func(v: float) -> void: vignette.material.set_shader_parameter("strength",v),0.,.7,.25*get_node("/root/Cutscene").timing_scale)
                tween.tween_method(func(v: float) -> void: vignette.material.set_shader_parameter("strength",v),.7,0.,.25*get_node("/root/Cutscene").timing_scale)
            get_node("/root/Cutscene")._control(manager.main.get_node("HUD"))
            manager.show_toast(str(story.settings["melammu_toast"]),float(story.settings["melammu_toast_seconds"]))
            await tween.finished
        "bed_blood":
            saved_camera_zoom = hero.camera.zoom
            var bed: NPC = manager.current_level.npcs.get("enkidua_bed")
            if is_instance_valid(bed):
                manager.current_level.npcs.erase("enkidua_bed")
                bed.get_parent().remove_child(bed)
                bed.queue_free()
            story.set_flag("bed_blood")
            hero.global_position = manager.current_level.get_spawn("Spawn_FromMelammu").global_position
            hero.facing = -1
            hero.cinematic_set = "cutscene"
            hero.sync_story_state()
        "paper_transfer":
            var npc: NPC = manager.current_level.npcs.get("shimati")
            if is_instance_valid(npc):
                var paper: Node2D = AssetVisual.add_image(manager.current_level,"res://assets/props/paper_note.webp",Vector2.ZERO,Vector2(48,36),70)
                get_node("/root/Cutscene")._control(paper)
                paper.global_position = npc.global_position+Vector2(npc.facing*20,-65)
                npc.play_clip("idle")
                var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
                tween.tween_property(paper,"global_position",hero.global_position+Vector2(10,-65),.6*get_node("/root/Cutscene").timing_scale)
                await tween.finished
                paper.queue_free()
                story.set_flag("death_sea_paper")
                manager.show_toast("종이를 받았다")
                var mote: Node2D = load("res://scripts/image_effect.gd").new()
                mote.configure("res://assets/sprites/fx/mote.webp",Vector2i(64,64),4,2.,false,Vector2(32,32))
                manager.current_level.add_child(mote)
                mote.global_position = npc.global_position-Vector2(0,60)
                get_node("/root/Cutscene")._control(mote)
        "helm":
            if not story.is_flag("gugalanna_helm"):
                story.set_flag("gugalanna_helm")
                manager.show_toast(str(story.settings["helm_toast"]))
            if not story.is_flag("helmet_equipped"):
                var was_locked: bool = manager.player_locked
                manager.set_player_locked(true)
                story.set_flag("helmet_equipped")
                hero.cinematic_set = "axe_onearm_helm"
                hero.sync_story_state()
                hero.cinematic_clip = "helm_equip"
                hero.cinematic_clock = 0
                await get_tree().create_timer(.6*get_node("/root/Cutscene").timing_scale,true,false,true).timeout
                hero.cinematic_clip = ""
                hero.cinematic_set = ""
                hero.sync_story_state()
                hero._show_clip("idle",0)
                manager.set_player_locked(was_locked or not get_node("/root/Cutscene").active)

func equip_prosthetic() -> void:
    get_node("/root/Story").set_flag("prosthetic_equipped")
    get_node("/root/SceneManager").show_toast(str(get_node("/root/Story").settings["prosthetic_toast"]))
    await pulse(Color(1,1,1,.8),.4)

func spawn_fx(parent: Node, at: Vector2, id: String) -> Node2D:
    var row: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage10_fx.json"))[id]
    var fx: Node2D = load("res://scripts/image_effect.gd").new()
    fx.configure("res://"+str(row["path"]),Vector2i(int(row["frame_size"][0]),int(row["frame_size"][1])),int(row["frames"]),float(row["duration"]),false,Vector2(float(row["frame_size"][0])*.5,float(row["frame_size"][1])*.5))
    parent.add_child(fx)
    fx.global_position = at
    fx.scale = Vector2.ONE*float(row.get("scale",1.))
    return fx

func finish_cutscene() -> void:
    caption.hide()
    current_skip = ""
    flash.color = Color.TRANSPARENT
    vignette.material.set_shader_parameter("strength",0.)
    for sound in sounds:
        if is_instance_valid(sound):
            get_node("/root/Audio").stop_sfx(sound)
    sounds.clear()
    var manager: Node = get_node("/root/SceneManager")
    if is_instance_valid(manager.player):
        manager.player.camera.zoom = saved_camera_zoom
        manager.player.cinematic_set = ""
        manager.player.sync_story_state()

func schedule_helm_departure() -> void:
    await get_tree().create_timer(float(get_node("/root/Story").settings["helm_delay"])*get_node("/root/Cutscene").timing_scale).timeout
    var manager: Node = get_node("/root/SceneManager")
    if is_instance_valid(manager.current_level) and manager.current_level.level_id=="HomeFront" and get_node("/root/Story").is_flag("gugalanna_helm") and not get_node("/root/Cutscene").active:
        get_node("/root/Cutscene").play("after_gugalanna")

func give_paper() -> void:
    var manager: Node = get_node("/root/SceneManager")
    var npc: NPC = manager.current_level.npcs.get("shimati")
    if not is_instance_valid(npc):
        return
    var runner: Node = get_node("/root/Cutscene")
    npc.facing = -1 if manager.player.global_position.x<npc.global_position.x else 1
    npc.pose = npc.facing
    # Use the runner to own paused actors and restore input even if a level is freed.
    await runner.play("shimati_paper")
