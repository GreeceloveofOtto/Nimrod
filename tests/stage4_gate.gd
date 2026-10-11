extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    await manager.go_to("CastleF1", "Spawn_FromRearGate")
    hero.hp = 123
    var front: DoorPortal = manager.current_level.doors["castle_front_gate"]
    hero.global_position = front.global_position
    front.interact(hero)
    await manager.transition_finished
    var level: LevelBase = manager.current_level
    _check(level.level_id == "CastleFront" and hero.global_position.x == 2100 and hero.hp == 123, "F1 portal reaches split courtyard preserving HP")
    _check(level.camera_limits.end.x == 2600 and hero.camera.limit_right == 2600, "Courtyard camera is 2600px")
    _check(get_nodes_in_group("enemies").is_empty() and level.is_point_safe(Vector2(1300,880)), "Entire courtyard is safe without beasts")
    _check(not level.npcs.has("castle_gatekeeper_outer") and not level.doors.has("downtown_passage_entrance"), "Outskirts actors removed from courtyard")
    var gate: GateController = level.doors["castle_great_gate"]
    var keeper: VillaGatekeeper = level.npcs["castle_gatekeeper_inner"]
    _check(gate.target_level == "CastleOutskirts" and gate.target_spawn == "Spawn_FromGate", "Inner great gate is an automatic map portal")
    _check(keeper.global_position.x == 880 and keeper.facing == -1, "Inner keeper remains to right facing gate")
    gate.set_process(false)
    keeper.set_process(false)
    hero.global_position = Vector2(550,880)
    for step in range(20):
        await physics_frame
        hero.velocity = Vector2(600,0)
        hero.move_and_slide()
    _check(hero.global_position.x <= 552.1, "Closed gate physically blocks movement")
    hero.velocity = Vector2.ZERO
    hero.global_position.x = 880
    gate._process(0.0)
    _check(gate.gate_state == GateController.GateState.REQUESTED, "Approach requests keeper gesture")
    keeper.clip_clock = 0.31
    keeper._refresh_visual()
    _check(gate.gate_state == GateController.GateState.REQUESTED, "Second keeper frame keeps gate closed")
    keeper.clip_clock = 0.321
    keeper._refresh_visual()
    _check(gate.gate_state == GateController.GateState.OPENING, "Third keeper frame starts opening")
    await _wait(0.6)
    _check(not gate.blocker.disabled, "Barrier remains during partial opening")
    await _wait(0.65)
    _check(gate.blocker.disabled and keeper.current_clip == "idle", "Complete opening releases barrier and keeper")
    hero.global_position.x = 600
    gate._process(0.0)
    await manager.transition_finished
    level = manager.current_level
    _check(level.level_id == "CastleOutskirts" and hero.global_position == Vector2(9440,760) and hero.hp == 123, "Automatic great gate reaches exterior x9440")
    gate = level.doors["castle_great_gate"]
    await physics_frame
    _check(is_zero_approx(gate.open_progress) and not gate.blocker.disabled, "Arrival great gate closes after player exits")
    _check(gate.opens_without_keeper and gate.inner_gatekeeper == null, "Exterior gate opens without local inner keeper")
    _check(level.camera_limits.end.x == 10000 and level.doors["downtown_passage_entrance"].global_position.x == 520, "Long route retains 9080px gate-to-passage distance")
    _check(get_nodes_in_group("enemies").size() == 15, "Exterior reuses ten melee and five ranged beasts")
    var outer: NPC = level.npcs["castle_gatekeeper_outer"]
    _check(outer.global_position.x == 9140 and outer.interactable and not outer.three_way, "Outer keeper keeps two-way noninteractive role")
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        enemy.global_position.x = 8900
        enemy._enforce_bounds()
        _check(enemy.get_hurt_rect().end.x <= 8850.01 and not enemy._can_detect(hero), "Enemy cannot invade safe gate plaza")
    root.get_node("GameState").run_flags["castle_gate_authorized"] = true
    gate.set_process(false)
    hero.global_position.x = 9100
    gate._process(0.0) # Leave approach radius before rearming arrival.
    hero.global_position.x = 9350
    gate._process(0.0)
    _check(gate.gate_state == GateController.GateState.OPENING, "Exterior proximity opens directly")
    await _wait(1.25)
    hero.global_position.x = 8950
    gate._process(0.0)
    await _wait(1.05)
    _check(gate.gate_state == GateController.GateState.CLOSED and not gate.blocker.disabled, "600px departure closes exterior gate")
    hero.global_position.x = 9350
    gate._process(0.0)
    await _wait(1.25)
    hero.global_position.x = 9600
    gate._process(0.0)
    await manager.transition_finished
    _check(manager.current_level.level_id == "CastleFront" and hero.global_position == Vector2(760,880) and hero.hp == 123, "Great gate returns to courtyard x760 preserving HP")
    await manager.go_to("CastleOutskirts", "Spawn_Debug")
    var locked: DoorPortal = manager.current_level.doors["downtown_passage_entrance"]
    _check(not locked.locked and locked.target_level == "DowntownPassage_F8", "Exterior entrance is unlocked for top-floor descent")
    await manager.go_to("RearGate", "Spawn_Start")
    gate = manager.current_level.doors["villa_gate"]
    _check(gate.target_level == "VillaF1" and gate.target_spawn == "Spawn_FromGate", "Villa automatic destination unchanged")
    await _finish("STAGE4_GATE")
