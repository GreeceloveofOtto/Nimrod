extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    hero.hp = 140
    await manager.go_to("HomeRoad","Spawn_FromPassage")
    var gate: DoorPortal = manager.current_level.doors["nimrod_home_gate"]
    _check(not gate.locked and gate.target_level=="NimrodHome","Home exterior gate unlocked")
    await manager.go_to(gate.target_level,gate.target_spawn)
    _check(manager.current_level.level_id=="NimrodHome" and hero.hp==140,"Home transition preserves HP")
    _check(manager.current_level.npcs.has("enkidua") and get_nodes_in_group("enemies").is_empty(),"Home NPC and no monsters")
    var npc: NPC = manager.current_level.npcs["enkidua"]
    _check(npc.three_way and npc.interactable and npc.display_name=="엔키두아","Enkidua three-way, name and no interaction")
    await manager.go_to("VillaF1","Spawn_FromGate")
    var back: DoorPortal = manager.current_level.doors["villa_back_door"]
    _check(not back.locked and back.target_level=="VillaBackyard","Villa backdoor unlocked")
    await manager.go_to(back.target_level,back.target_spawn)
    var yard: LevelBase = manager.current_level
    _check(yard.config["width"]==1500,"Backyard width1500")
    _check(absf(yard.doors["cedar_entrance"].global_position.x-yard.doors["villa_back_exterior"].global_position.x)==400,"Backdoor to forest portal400px")
    _check(get_nodes_in_group("enemies").is_empty() and yard.is_point_safe(Vector2(900,880)),"Backyard entirely safe")
    await manager.go_to("CedarForest_F1","Spawn_FromVilla")
    _check(manager.current_level.camera_limits.size==Vector2(4800,3400),"Approved20-room maze dimensions")
    _check(get_nodes_in_group("enemies").size()==16,"Forest1 twelve sentinels and four colossi")
    var exit: DoorPortal = manager.current_level.doors["forest_exit"]
    await manager.go_to(exit.target_level,exit.target_spawn)
    _check(manager.current_level.level_id=="CedarForest_F2" and get_nodes_in_group("enemies").size()==23,"Forest2 eight archers, eight wisps, seven demons")
    exit = manager.current_level.doors["forest_exit"]
    await manager.go_to(exit.target_level,exit.target_spawn)
    _check(manager.current_level.level_id=="CedarBossRoom","Top forest portal reaches boss")
    await manager.restart_run()
    _check(manager.current_level.level_id=="NimrodHome" and hero.hp==180 and hero.global_position.x==330,"Death returns to original start")
    await _finish("STAGE6_LEVELS")
