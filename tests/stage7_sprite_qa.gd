extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
    for id: String in registry["world"]["enemy_scripts"]:
        var path: String = "res://assets/sprites/enemies/" + id + "/manifest.json"
        var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
        for clip: Dictionary in manifest["clips"]:
            var sheet: String = str(clip["sheet"])
            if not sheet.begins_with("res://"): sheet = "res://assets/" + sheet
            var texture := load(sheet) as Texture2D
            _check(texture != null, "Every enemy clip has a generated texture")
            var trim: Dictionary = clip.get("storage_trim", clip.get("trim", {"w":clip["frame_width"], "h":clip["frame_height"]}))
            _check(texture.get_width() == int(trim["w"]) * int(clip.get("stored_columns",clip["frames"])) and texture.get_height() == int(trim["h"]), "Declared dimensions: %s/%s actual %s expected %s" % [id,clip["name"],texture.get_size(),Vector2(int(trim["w"])*int(clip.get("stored_columns",clip["frames"])),int(trim["h"]))])
            _check(not bool(clip["loop"]) and int(clip.get("stored_columns",clip["frames"])) >= 3 if str(clip["name"]).begins_with("turn") else true, "Turn clips preserve staged turning")
    await manager.go_to("CastleF2", "Spawn_FromBelow", {"instant": true})
    var enemies: Dictionary = registry["world"]["enemy_scripts"]
    for id in enemies:
        var enemy: EnemyBase = load(str(enemies[id])).new()
        enemy.position = Vector2(900,620)
        manager.current_level.add_child(enemy)
        enemy.set_physics_process(false)
        var reachable: Array = EnemyBase.State.values()
        if id in ["gas_sac", "wraith_ray", "corpse_bomber"]:
            reachable = [EnemyBase.State.IDLE, EnemyBase.State.CHASE, EnemyBase.State.TURN, EnemyBase.State.STUN, EnemyBase.State.DEAD]
        if id == "shell_scorpion": enemy.phase = "claw"
        if id == "chain_beastman": enemy.phase = "tail"
        if enemy is Humbaba: enemy._start_pattern("bite")
        for state in reachable:
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
                if not enemy.clip_data.has(phase) and not (enemy.enemy_id == "cedar_sentinel" and phase == "shield") and not (enemy.enemy_id == "cedar_archer" and phase == "hop"):
                    continue
                enemy.phase = phase
                enemy.state = EnemyBase.State.ACTIVE
                enemy._update_visual(0)
                _check(not enemy.missing_visual.visible,"Special phase resolves image")
        enemy.queue_free()
        await process_frame
    await _finish("STAGE7_SPRITE_QA")
