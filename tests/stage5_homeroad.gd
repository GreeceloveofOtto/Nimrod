extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    await manager.go_to("HomeRoad","Spawn_FromPassage")
    var level: LevelBase = manager.current_level
    var home: DoorPortal = level.doors["nimrod_home_gate"]
    var exit: DoorPortal = level.doors["passage_exit"]
    _check(level.camera_limits.end.x == 10800 and exit.global_position.x-home.global_position.x == 10000,"Home gate10000px from passage in10800px map")
    _check(not home.locked and home.target_level == "NimrodHome","Stage6 house now opens to interior")
    _check(level.config["regions"].size() == 8,"Eight distinct home-road regions")
    _check(get_nodes_in_group("enemies").size() == 22,"Home road fourteen melee and eight ranged")
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        _check(enemy.enemy_id in ["melee_beast","ranged_beast"] and enemy.global_position.x < 10000,"Only existing beasts away from exit")
        enemy.global_position.x = 800
        enemy._enforce_bounds()
        _check(enemy.get_hurt_rect().position.x >= 900,"House safe boundary rejects beast")
    hero.global_position = home.global_position
    home.interact(hero)
    await manager.transition_finished
    _check(manager.current_level.level_id == "NimrodHome", "Home portal enters interior")
    await manager.go_to("HomeRoad", "Spawn_FromHome")
    exit = manager.current_level.doors["passage_exit"]
    hero.global_position = exit.global_position
    exit.interact(hero)
    await manager.transition_finished
    _check(manager.current_level.level_id == "DowntownPassage_F1" and hero.global_position.x == 300,"Passage can be reentered from road")
    await _finish("STAGE5_HOMEROAD")
