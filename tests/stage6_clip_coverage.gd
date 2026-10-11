extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    await manager.go_to("CastleF2", "Spawn_FromBelow")
    manager.current_level.safe_zones.clear()
    var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
    var enemies: Dictionary = registry["world"]["enemy_scripts"]
    for id in enemies:
        var enemy: EnemyBase = load(str(enemies[id])).new()
        enemy.position = Vector2(900,620)
        manager.current_level.add_child(enemy)
        enemy.set_physics_process(false)
        for state in EnemyBase.State.values():
            enemy.state = state
            enemy.state_clock = .05
            enemy._update_visual(.01)
            _check(enemy.visual.visible and not enemy.missing_visual.visible, "%s state %s has actual PNG" % [id,state])
        for clip in ["idle","walk","windup","attack","recovery","turn","hurt","death"]:
            enemy._show_clip(clip, .02)
            _check(enemy.visual.texture != null and not enemy.missing_visual.visible, "%s resolves %s" % [id,clip])
        if enemy is CedarEnemy:
            for phase in ["shield","shield_break_stun","thrust","slash","slam","sweep","rear_poke","hop","shoot","tell","fall","land_stab","claws","fuse"]:
                # Request only phases belonging to the selected enemy.
                if not enemy.clip_data.has(phase) and phase not in ["shield","hop"]:
                    continue
                enemy.phase = phase
                enemy.state = EnemyBase.State.ACTIVE
                enemy._update_visual(0)
                _check(not enemy.missing_visual.visible,"Special phase resolves image")
        enemy.queue_free()
        await process_frame
    await _finish("STAGE6_CLIP_COVERAGE")
