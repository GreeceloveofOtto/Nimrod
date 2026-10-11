extends SceneTree

var failures: int = 0
var manager: Node
var main: Node2D
var hero: NimrodPlayer
var samples: Array[Dictionary] = []

func _initialize() -> void:
    _run.call_deferred()

func _freeze(_id: String) -> void:
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
        enemy._update_visual(0)

func _shot(name: String, at: Vector2) -> void:
    hero.global_position = at
    hero.camera.reset_smoothing()
    hero.camera.force_update_scroll()
    await create_timer(.15).timeout
    await process_frame
    await RenderingServer.frame_post_draw
    var path: String = "res://docs/screenshots/stage5_"+name+".png"
    var result: Error = root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
    if result != OK:
        failures += 1
    print("SCREENSHOT ",path)

func _run() -> void:
    if DisplayServer.get_name() == "headless":
        quit(1)
        return
    root.size = Vector2i(1280,720)
    manager = root.get_node("SceneManager")
    manager.level_changed.connect(_freeze)
    main = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main
    await manager.transition_finished
    hero = manager.player
    hero.set_physics_process(false)
    hero.camera.position_smoothing_enabled = false
    main.get_node("HUD").story.visible = false
    for n in range(1,9):
        await manager.go_to("DowntownPassage_F"+str(n),"Spawn_FromAbove")
        hero.set_physics_process(false)
        hero._show_clip("crouch_idle" if n == 7 else "idle",0.0)
        var x: float = 1900
        var y: float = manager.current_level.ground_y_at(x)
        await _shot("passage_f"+str(n),Vector2(x,y))
    await manager.go_to("HomeRoad","Spawn_FromPassage")
    hero.set_physics_process(false)
    for i in range(8):
        var x: float = [10350,9000,7500,6200,4800,3350,2050,450][i]
        var y: float = manager.current_level.ground_y_at(x)
        if i == 1:
            y = 690
        elif i == 5:
            y = 730
        await _shot("homeroad_region_"+str(i+1),Vector2(x,y))
    await manager.go_to("DowntownPassage_F1","Spawn_FromAbove")
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        enemy.queue_free()
    await process_frame
    hero.set_physics_process(false)
    for id in ["explosive_spitter","wall_diver","root_spewer","boar_charger","gas_sac","wraith_ray","shell_scorpion","corpse_bomber","chain_beastman"]:
        var actor := load("res://scripts/enemy_"+id+".gd").new() as Stage5Enemy
        actor.position = Vector2(2000,550 if id in ["gas_sac","wraith_ray","wall_diver"] else 620)
        manager.current_level.add_child(actor)
        actor.set_physics_process(false)
        actor._update_visual(0)
        await _shot("enemy_"+id,Vector2(1860,620))
        actor.queue_free()
        await process_frame
    for f in [1,3,5,7,12]:
        hero._show_clip("roll",(f-1)*.04)
        await _shot("roll_frame_"+str(f),Vector2(1860,620))
    root.get_node("Audio").stop_bgm(0)
    manager.set_player_locked(true)
    main.queue_free()
    current_scene = null
    await create_timer(.2).timeout
    print("STAGE5_CAPTURE: 30 screenshots; failures ",failures)
    quit(1 if failures else 0)
