extends "res://tests/render_stage6.gd"

func _run() -> void:
    if DisplayServer.get_name() == "headless":
        quit(1)
        return
    root.size = Vector2i(1280, 720)
    await _start()
    hero.camera.position_smoothing_enabled = false
    main.get_node("HUD").story.hide()
    await manager.go_to("DowntownPassage_F1", "Spawn_FromAbove")
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        enemy.queue_free()
    await process_frame
    for id in ["explosive_spitter", "wall_diver", "root_spewer", "boar_charger", "gas_sac", "wraith_ray", "shell_scorpion", "corpse_bomber", "chain_beastman"]:
        var actor: EnemyBase = load("res://scripts/enemy_" + id + ".gd").new()
        actor.position = Vector2(1850, 620 if id not in ["gas_sac", "wraith_ray", "wall_diver"] else 470)
        manager.current_level.add_child(actor)
        actor.set_physics_process(false)
        actor._show_clip("idle", 0)
        await _shot("size_" + id, Vector2(1510, 620))
        actor.queue_free()
        await process_frame
    for sample in [
        ["DowntownPassage_F1", "Spawn_FromAbove", "surface_accents", Vector2(2740, 620)],
        ["DowntownPassage_F4", "Spawn_FromAbove", "fix_bridge", Vector2(1600, 760)],
        ["DowntownPassage_F7", "Spawn_FromAbove", "fix_ceiling", Vector2(2000, 620)],
        ["CedarBossRoom", "Spawn_FromForest", "fix_boss_platform", Vector2(500, 800)],
        ["CastleOutskirts", "Spawn_Debug", "fix_outskirts_bridge", Vector2(7280, 1000)],
        ["HomeRoad", "Spawn_FromPassage", "fix_overpass", Vector2(3420, 880)],
        ["CastleOutskirts", "Spawn_Debug", "fix_rubble", Vector2(4590, 940)]
    ]:
        await manager.go_to(sample[0], sample[1])
        await _shot(sample[2], sample[3])
    await _finish("STAGE6_FIX_CAPTURE")
