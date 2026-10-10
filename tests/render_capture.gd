extends SceneTree

# Rendered smoke capture; needs a display (for example Xvfb), not --headless.
const OUTPUT: String = "res://artifacts/"

func _initialize() -> void:
    _run.call_deferred()

func _stop_audio(node: Node) -> void:
    if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
        node.stop()
    for child: Node in node.get_children():
        _stop_audio(child)

func _run() -> void:
    root.size = Vector2i(1280, 720)
    var main: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main
    await process_frame
    var hero: NimrodPlayer = get_first_node_in_group("player") as NimrodPlayer
    hero.set_physics_process(false)
    hero.camera.position_smoothing_enabled = false
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
        if enemy.global_position.x == 400.0:
            enemy.facing = -1
            enemy._show_clip("idle", 0.0)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    for sample: Dictionary in [
        {"name": "rear_gate_start", "x": 260.0},
        {"name": "rear_gate_middle", "x": 1500.0},
        {"name": "rear_gate_exit", "x": 3500.0}
    ]:
        hero.global_position = Vector2(float(sample["x"]), 880.0)
        hero.camera.force_update_scroll()
        hero._show_clip("idle", 0.0)
        if str(sample["name"]) == "rear_gate_middle":
            for enemy: EnemyBase in get_nodes_in_group("enemies"):
                if enemy.enemy_id == "ranged_beast" and enemy.global_position.x == 1300.0:
                    enemy.facing = 1
                    enemy._begin_active()
                    enemy._show_clip("flame_loop", 0.0)
        await process_frame
        await RenderingServer.frame_post_draw
        var image: Image = root.get_texture().get_image()
        var path: String = OUTPUT + str(sample["name"]) + ".png"
        var result: Error = image.save_png(path)
        if result != OK or image.get_size() != Vector2i(1280, 720):
            push_error("Rendered capture failed: " + path)
            quit(1)
            return
        print("RENDER PASS: ", path, " ", image.get_size())
    _stop_audio(root)
    main.queue_free()
    current_scene = null
    await process_frame
    await create_timer(0.15).timeout
    quit(0)
