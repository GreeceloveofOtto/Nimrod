extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    hero.hp = 135
    await manager.go_to("CastleOutskirts","Spawn_FromPassage")
    var entrance: DoorPortal = manager.current_level.doors["downtown_passage_entrance"]
    _check(not entrance.locked and entrance.target_level == "DowntownPassage_F8", "Outskirts entrance opens to floor8")
    hero.global_position = entrance.global_position
    entrance.interact(hero)
    await manager.transition_finished
    _check(manager.current_level.level_id == "DowntownPassage_F8" and hero.global_position.x == 3330 and hero.hp == 135, "E animation arrives right side of top floor")
    var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/passage_floors.json"))
    for n in range(8,0,-1):
        var level: LevelBase = manager.current_level
        var ids: Array = []
        for enemy: EnemyBase in get_nodes_in_group("enemies"):
            if not ids.has(enemy.enemy_id):
                ids.append(enemy.enemy_id)
            var expected: float = .07 if n <= 3 and enemy.enemy_id == "explosive_spitter" else 0.0 if n <= 3 else .05
            _check(is_equal_approx(enemy.get_drop_chance(),expected), "Floor%d %s drop rule" % [n,enemy.enemy_id])
            _check(absf(enemy.global_position.x - 220) >= 200 and absf(enemy.global_position.x - 3450) >= 200, "No spawn within200px of door")
        for id in roster["floors"][n-1]["enemy_ids"]:
            _check(ids.has(id), "Floor%d roster includes%s" % [n,id])
        _check(ids.size() == 4 and level.camera_limits.end.x == 3600, "Four-type window and3600px floor")
        _check(root.get_node("Audio")._bgm_name == "passage_descent", "All passage floors preserve one BGM")
        var door: DoorPortal = level.doors["door_down"]
        hero.global_position = door.global_position
        door.interact(hero)
        await manager.transition_finished
        _check(manager.current_level.level_id == ("HomeRoad" if n==1 else "DowntownPassage_F"+str(n-1)) and hero.hp == 135, "Descent floor%d preserves player" % n)
        if n > 1:
            _check(hero.global_position.x == 3330, "Descending arrives next floor right")
    _check(hero.global_position.x == 10360, "Home road arrival takes left exit step")
    await manager.go_to("DowntownPassage_F1","Spawn_FromBelow")
    for n in range(1,9):
        var up: DoorPortal = manager.current_level.doors["door_up"]
        hero.global_position = up.global_position
        up.interact(hero)
        await manager.transition_finished
        _check(manager.current_level.level_id == ("CastleOutskirts" if n==8 else "DowntownPassage_F"+str(n+1)), "Return upward floor%d works" % n)
    _check(hero.global_position.x == 640 and hero.hp == 135, "Top exit returns to Outskirts x640")
    await _finish("STAGE5_PASSAGE")
