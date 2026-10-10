extends SceneTree

# Render the seven stage-two levels plus the exterior villa gate.
# DISPLAY=:99 godot43 --path . --audio-driver Dummy --script tests/render_capture.gd
# A display is required; headless rendering cannot capture the actual artwork.
const OUTPUT: String = "res://docs/screenshots/"
const VIEWPORT_SIZE: Vector2i = Vector2i(1280, 720)
const SAMPLES: Array[Dictionary] = [
    {"name": "rear_gate_start", "level": "RearGate", "spawn": "Spawn_Start", "x": 230.0, "settle": 0.3},
    {"name": "rear_gate_villa_gate", "level": "RearGate", "spawn": "Spawn_Start", "x": 4930.0, "settle": 1.6},
    {"name": "castle_f1", "level": "CastleF1", "spawn": "Spawn_FromRearGate", "x": 780.0, "settle": 0.3},
    {"name": "castle_f2", "level": "CastleF2", "spawn": "Spawn_FromBelow", "x": 740.0, "settle": 0.3},
    {"name": "castle_f3", "level": "CastleF3", "spawn": "Spawn_FromBelow", "x": 900.0, "settle": 0.3},
    {"name": "castle_f4", "level": "CastleF4", "spawn": "Spawn_FromBelow", "x": 740.0, "settle": 0.3},
    {"name": "castle_f5", "level": "CastleF5", "spawn": "Spawn_FromBelow", "x": 1100.0, "settle": 0.3},
    {"name": "villa_f1", "level": "VillaF1", "spawn": "Spawn_FromGate", "x": 910.0, "settle": 0.3},
]

func _initialize() -> void:
    _run.call_deferred()

func _stop_audio(node: Node) -> void:
    if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
        node.stop()
        node.stream = null
    for child: Node in node.get_children():
        _stop_audio(child)

func _freeze_enemies(_level_id: String) -> void:
    var actor := get_first_node_in_group("player") as Node2D
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        # Freeze before the arrival animation so a rooftop beast stays in view.
        enemy.set_physics_process(false)
        if actor != null:
            enemy.facing = -1 if actor.global_position.x < enemy.global_position.x else 1
        enemy._show_clip("fly_idle" if enemy.enemy_id == "sky_beast" else "idle", 0.0)

func _run() -> void:
    if DisplayServer.get_name() == "headless":
        push_error("Capture requires a rendered display; use DISPLAY=:99 without --headless.")
        quit(1)
        return
    root.size = VIEWPORT_SIZE
    var manager: Node = root.get_node("SceneManager")
    manager.level_changed.connect(_freeze_enemies)
    var main: Node2D = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main
    # Main binds its persistent player and performs the initial level transition.
    await manager.transition_finished
    var hero: NimrodPlayer = main.get_node("Player") as NimrodPlayer
    hero.set_physics_process(false)
    hero.camera.position_smoothing_enabled = false
    var output_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    if output_error != OK:
        push_error("Cannot create screenshot directory: " + OUTPUT)
        await _finish(main, 1)
        return
    for sample: Dictionary in SAMPLES:
        if str(manager.current_level.level_id) != str(sample["level"]):
            var changed: bool = await manager.go_to(str(sample["level"]), str(sample["spawn"]))
            if not changed:
                push_error("Capture could not load level: " + str(sample["level"]))
                await _finish(main, 1)
                return
        var level: Node2D = manager.current_level
        hero.set_physics_process(false)
        hero.global_position = Vector2(float(sample["x"]), float(level.get("floor_y")))
        hero.facing = 1
        hero.visual.flip_h = false
        hero._show_clip("idle", 0.0)
        hero.camera.reset_smoothing()
        hero.camera.force_update_scroll()
        if str(sample["name"]) != "rear_gate_start":
            # Keep the opening narration out of later map composition captures.
            main.get_node("HUD").story.visible = false
        await create_timer(float(sample["settle"])).timeout
        await process_frame
        await RenderingServer.frame_post_draw
        var image: Image = root.get_texture().get_image()
        var path: String = OUTPUT + "stage2_" + str(sample["name"]) + ".png"
        var result: Error = image.save_png(path)
        if result != OK or image.get_size() != VIEWPORT_SIZE:
            push_error("Rendered capture failed: " + path)
            await _finish(main, 1)
            return
        print("RENDER PASS: ", path, " ", image.get_size())
    await _finish(main, 0)

func _finish(main: Node, exit_code: int) -> void:
    var manager: Node = root.get_node("SceneManager")
    if manager.level_changed.is_connected(_freeze_enemies):
        manager.level_changed.disconnect(_freeze_enemies)
    var audio: Node = root.get_node("Audio")
    audio.stop_bgm(0.0)
    _stop_audio(root)
    if is_instance_valid(main):
        main.queue_free()
    current_scene = null
    await process_frame
    await process_frame
    await create_timer(0.2).timeout
    await RenderingServer.frame_post_draw
    quit(exit_code)
