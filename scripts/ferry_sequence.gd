extends Node

signal paper_delivered
signal phase_changed(phase: String)
var boarding_requested := false
var settings: Dictionary = {}
var notice_left := 0.0

func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/ferry.json"))

func _process(delta: float) -> void:
    var manager: Node = get_node("/root/SceneManager")
    if get_tree().paused or manager.player_locked or not is_instance_valid(manager.current_level) or manager.current_level.level_id != "TiamatZone":
        return
    notice_left = maxf(0.,notice_left-delta)
    if manager.player.global_position.x < float(settings["left_notice_distance"]) and Input.get_axis("move_left","move_right")<0 and notice_left<=0:
        manager.show_toast(str(settings["rear_locked_message"]))
        notice_left = float(settings["notice_seconds"])

func start_boarding() -> void:
    if not boarding_requested or get_node("/root/Dialogue").active or get_node("/root/Cutscene").active:
        return
    boarding_requested = false
    var manager: Node = get_node("/root/SceneManager")
    if manager.current_level.level_id != "DeathSea" or not get_node("/root/Story").is_flag("paper_handed") or get_node("/root/Story").is_flag("ferry_boarded"):
        return
    var prior_volume: float = get_node("/root/Audio")._bgm.volume_db
    var succeeded: bool = await get_node("/root/Cutscene").play("ferry_boarding")
    if not succeeded:
        get_node("/root/Audio").fade_bgm_volume(prior_volume,float(settings["cancel_audio_seconds"]),false)
    if succeeded and is_instance_valid(manager.current_level) and manager.current_level.level_id == "TiamatZone" and get_node("/root/Story").is_flag("tiamat_arrived"):
        get_node("/root/Save").save_game(true)

func event(event_id: String) -> void:
    var story: Node = get_node("/root/Story")
    var manager: Node = get_node("/root/SceneManager")
    var runner: Node = get_node("/root/Cutscene")
    var hero: NimrodPlayer = manager.player
    var token: int = runner.generation
    match event_id:
        "paper":
            if not story.is_flag("death_sea_paper") or story.is_flag("paper_handed"):
                return
            var npc: NPC = manager.current_level.npcs.get("urshanabi")
            if not is_instance_valid(npc):
                return
            # The paper icon is existing generated art. Its movement is UI support.
            var icon: Node2D = AssetVisual.add_image(manager.current_level,"res://assets/props/paper_note.webp",Vector2.ZERO,Vector2(48,36),70)
            runner._control(icon)
            icon.global_position = hero.global_position+Vector2(hero.facing*20,-65)
            var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
            runner.motion = tween
            tween.tween_property(icon,"global_position",npc.global_position+Vector2(-20,-40),float(settings["paper_seconds"])*runner.timing_scale)
            await tween.finished
            if token != runner.generation:
                if is_instance_valid(icon):
                    icon.queue_free()
                return
            icon.queue_free()
            story.set_flag("death_sea_paper",false)
            story.set_flag("paper_handed")
            paper_delivered.emit()
        "board":
            phase_changed.emit("boarding")
            runner._control(hero)
            hero.cinematic_clip = "walk"
            hero.cinematic_clock = 0
            hero.facing = 1
            var at: Array = settings["boarding_position"]
            var walk := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
            runner.motion = walk
            walk.tween_property(hero,"global_position",Vector2(float(at[0]),float(at[1])),float(settings["boarding_seconds"])*runner.timing_scale)
            await walk.finished
            if token != runner.generation:
                return
            hero.cinematic_clip = "idle"
            phase_changed.emit("fade_out")
            await get_node("/root/Audio").fade_bgm_volume(-42.,float(settings["fade_out_seconds"])*runner.timing_scale,false)
            await manager._fade_to(1.,float(settings["fade_out_seconds"])*runner.timing_scale)
            if token != runner.generation:
                return
            phase_changed.emit("black")
            story.set_flag("ferry_boarded")
            # Keep the coroutine on this autoload; the old level/NPC is freed here.
            await manager.go_to("TiamatZone","Spawn_FromFerry",{"instant":true,"preserve_fade":true})
            manager.set_player_locked(true)
            phase_changed.emit("arrival")
            await get_node("/root/Audio").fade_bgm_volume(float(settings["arrival_bgm_db"]),float(settings["fade_in_seconds"])*runner.timing_scale,false)
            await manager._fade_to(0.,float(settings["fade_in_seconds"])*runner.timing_scale)
            if token != runner.generation:
                return
            hero.cinematic_clip = "walk"
            var ashore: Array = settings["ashore_position"]
            var leaving := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
            runner.motion = leaving
            leaving.tween_property(hero,"global_position",Vector2(float(ashore[0]),float(ashore[1])),float(settings["disembark_seconds"])*runner.timing_scale)
            await leaving.finished
            if token != runner.generation:
                return
            story.set_flag("tiamat_arrived")
            phase_changed.emit("ashore")

func decorate(level: LevelBase) -> void:
    if level.level_id != "TiamatZone":
        return
    get_node("/root/Audio").fade_bgm_volume(float(settings["arrival_bgm_db"]),0.01,false)
    for ground: Node in level.get_children():
        if ground is CanvasItem and str(ground.get_meta("art_path","")) in ["res://assets/tiles/deathsea/ground_tile.png",str(level.world_settings.get("underground_art",""))]:
            ground.modulate = Color(.18,.20,.29)
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    var glow: String = "res://assets/fx/npc_light_pool.webp"
    var light: Node2D = AssetVisual.add_image(level,glow,Vector2(1500,740),Vector2(250,140),-1)
    light.modulate = Color(1.,.72,.4,.18)
    var material_add := CanvasItemMaterial.new()
    material_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    light.material = material_add
    var sight: Node2D = AssetVisual.add_image(hero,glow,Vector2(-180,-170),Vector2(360,200),-1)
    sight.name = "TiamatSight"
    sight.material = material_add
    sight.modulate = Color(.52,.6,.9,.12)
