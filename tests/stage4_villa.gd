extends "res://tests/helpers/stage4_support.gd"

func _use(id: String, expected: String, x: float) -> void:
    var door: DoorPortal = manager.current_level.doors[id]
    hero.global_position = door.global_position
    door.interact(hero)
    await manager.transition_finished
    _check(manager.current_level.level_id == expected and hero.global_position.x == x and hero.hp == 111, "Villa portal arrives at correct door preserving HP")
    _check(root.get_node("Audio")._bgm_name == "villa_calm", "Villa floors share continuous calm BGM")

func _run() -> void:
    await _start()
    await manager.go_to("VillaF1","Spawn_FromGate")
    hero.hp = 111
    var level: LevelBase = manager.current_level
    _check(level.doors["door_up"].global_position.x == 1000, "Central upstairs portal at x1000")
    _check(level.doors["villa_back_door"].locked and level.doors["villa_back_door"].locked_message == "후문은 아직 열 수 없다", "Right door is locked villa rear door")
    for npc: NPC in level.npcs.values():
        _check(npc.global_position.x < 860 or npc.global_position.x > 1140, "Servants leave central door clear")
    var bgm_stream: AudioStream = root.get_node("Audio")._bgm.stream
    await _use("door_up","VillaF2",240)
    level = manager.current_level
    _check(level.config["width"] == 2200 and level.npcs.size() == 4, "Dining floor has four reused cooks")
    _check(level.npcs["cook_c_left"].npc_id == "cook_c" and level.npcs["cook_c_right"].npc_id == "cook_c", "Two arranging cooks independently reuse same sheet")
    _check(level.npcs["cook_c_right"].visual.flip_h and not level.npcs["cook_c_left"].visual.flip_h, "Arranging cooks face inward from opposite sides")
    _check(root.get_node("Audio")._bgm.stream == bgm_stream, "Same BGM retains its playing stream")
    await _use("door_up","VillaF3",240)
    level = manager.current_level
    _check(level.npcs["shamash"].display_name == "샤마쉬" and level.npcs["aya"].display_name == "아야", "Couple displays Korean names")
    _check(level.doors["villa_up_locked"].locked, "Future upper floor remains locked")
    _check(get_nodes_in_group("enemies").is_empty(), "All villa floors are safe without beasts")
    await _use("door_down","VillaF2",2000)
    await _use("door_down","VillaF1",1040)
    await _finish("STAGE4_VILLA")
