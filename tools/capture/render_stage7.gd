extends "res://tests/helpers/stage4_support.gd"

func _shot(label: String, at: Vector2) -> void:
    hero.global_position = at
    hero.camera.reset_smoothing()
    hero.camera.force_update_scroll()
    await create_timer(.2, true, false, true).timeout
    await process_frame
    await RenderingServer.frame_post_draw
    var path: String = "res://docs/screenshots/stage7_" + label + ".png"
    _check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK, "Screenshot writes")
    print("SCREENSHOT ",path)

func _run() -> void:
    if DisplayServer.get_name() == "headless":
        quit(1)
        return
    root.size = Vector2i(1280,720)
    await _start(false)
    hero.camera.position_smoothing_enabled = false
    main.get_node("HUD").story.hide()
    root.get_node("GameState").set_weapon("staff")
    hero._show_clip("idle",0)
    await _shot("home_staff",Vector2(620,620))
    await manager.go_to("CastleF1","Spawn_Debug",{"instant":true})
    root.get_node("GameState").set_weapon("axe")
    hero._show_clip("idle",0)
    await _shot("parents_axe",Vector2(860,620))
    await manager.go_to("DowntownPassage_F1","Spawn_FromAbove",{"instant":true})
    for enemy: EnemyBase in get_nodes_in_group("enemies"): enemy.queue_free()
    await process_frame
    for group in [["explosive_spitter","wall_diver","root_spewer","gas_sac","wraith_ray"],["boar_charger","shell_scorpion","corpse_bomber","chain_beastman"]]:
        var actors: Array[EnemyBase] = []
        for i in range(group.size()):
            var enemy: EnemyBase = load("res://scripts/enemy_"+group[i]+".gd").new()
            enemy.position = Vector2(1550+i*175,620 if group[i] not in ["wall_diver","gas_sac","wraith_ray"] else 530)
            manager.current_level.add_child(enemy)
            enemy.set_physics_process(false)
            enemy._show_clip("idle",0)
            actors.append(enemy)
        await _shot("passage_"+group[0],Vector2(1900,620))
        for enemy in actors: enemy.queue_free()
        await process_frame
    await manager.go_to("CedarForest_F1","Spawn_FromVilla",{"instant":true})
    var sentinel: EnemyBase = load("res://scripts/enemy_cedar_sentinel.gd").new()
    sentinel.position = Vector2(hero.global_position.x+140,hero.global_position.y)
    manager.current_level.add_child(sentinel)
    sentinel.set_physics_process(false)
    sentinel._show_clip("idle",0)
    await _shot("forest_human_scale",hero.global_position)
    await manager.go_to("CedarBossRoom","Spawn_FromForest",{"instant":true})
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
        enemy._show_clip("idle",0)
    await _shot("boss_scale",Vector2(600,manager.current_level.floor_y))
    await manager.go_to("DowntownPassage_F1","Spawn_FromAbove",{"instant":true})
    for enemy: EnemyBase in get_nodes_in_group("enemies"): enemy.queue_free()
    load("res://scripts/surface_debug.gd").enabled = true
    await _shot("surface_after_f4",Vector2(2740,620))
    await _finish("STAGE7_CAPTURE")
