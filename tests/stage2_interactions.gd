extends SceneTree

var checks: int = 0
var failures: int = 0
var main: Node2D
var manager: Node
var player: NimrodPlayer
var interaction_signals: int = 0

func _initialize() -> void:
    _run.call_deferred()

func _check(condition: bool, description: String) -> void:
    checks += 1
    if condition:
        print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)

func _wait(seconds: float) -> void:
    await create_timer(seconds).timeout

func _run() -> void:
    main = load("res://scenes/Main.tscn").instantiate() as Node2D
    root.add_child(main)
    current_scene = main
    manager = root.get_node("SceneManager")
    await manager.transition_finished
    player = manager.player as NimrodPlayer
    player.set_physics_process(false)
    await _test_npcs()
    await _test_locked_and_nearest()
    await _test_villa_gate()
    for child in root.get_node("Audio").get_children():
        if child.has_method("stop"):
            child.call("stop")
    main.queue_free()
    await _wait(0.15)
    print("STAGE2_INTERACTIONS: %d checks, %d failures" % [checks, failures])
    quit(1 if failures > 0 else 0)

func _test_npcs() -> void:
    await manager.go_to("CastleF1", "Spawn_FromRearGate")
    var level: Node = manager.current_level
    _check(level.npcs.size() == 2, "CastleF1 has Lugalbanda and Ninsun")
    var npc: NPC = level.npcs["lugalbanda"] as NPC
    _check(npc.current_clip == "idle" and bool(npc.clip_data["idle"]["loop"]), "Royal NPC repeats breathing idle")
    _check(is_equal_approx(npc.visual.scale.x, player.visual.scale.x), "NPC and player use the same sprite scale")
    npc.set_process(false)
    npc.facing = 1
    npc.visual.flip_h = false
    npc.face_cooldown_left = 0.0
    npc.face_toward(npc.global_position.x - 219.0)
    _check(npc.facing == 1, "NPC ignores crossing hysteresis below 220 px")
    npc.face_toward(npc.global_position.x - 220.0)
    _check(npc.facing == -1 and npc.visual.flip_h, "NPC faces player at 220 px crossing")
    npc.face_toward(npc.global_position.x + 220.0)
    _check(npc.facing == -1, "NPC flip is blocked during 0.5 s cooldown")
    npc.face_cooldown_left = 0.0
    npc.face_toward(npc.global_position.x + 220.0)
    _check(npc.facing == 1, "NPC can flip after cooldown")
    npc.interacted.connect(func() -> void: interaction_signals += 1)
    var old_interaction: String = str(npc.stats.get("interaction", ""))
    npc.stats["interaction"] = ""
    npc.interact(player)
    _check(interaction_signals == 0, "Unconfigured NPC interact hook is intentionally inert")
    npc.stats["interaction"] = old_interaction
    _check(not npc.is_class("CollisionObject2D"), "NPC does not block the player")
    await manager.go_to("CastleF3", "Spawn_FromBelow")
    level = manager.current_level
    var clips: Array[String] = []
    for cook in level.npcs.values():
        clips.append(str(cook.current_clip))
        _check(float(cook.stats["height_ratio"]) <= 0.963 and is_equal_approx(float(cook.stats["visual_scale_multiplier"]), 1.30), "Cook uses the requested 1.30 Toin display multiplier")
        _check(bool(cook.stats["random_start"]), "Cook has an independent randomized clip phase")
    _check(clips.has("chop") and clips.has("stir") and clips.has("arrange"), "Kitchen cooks use three distinct generated actions")
    await manager.go_to("VillaF1", "Spawn_FromGate")
    level = manager.current_level
    _check(level.npcs.size() == 2, "Villa has two cleaning servants")
    _check(level.npcs["servant_a"].facing == 1 and level.npcs["servant_b"].facing == -1, "Servants clean in opposite fixed directions")
    _check(level.npcs["servant_a"].current_clip == "sweep" and level.npcs["servant_b"].current_clip == "sweep", "Both servants play sweeping clips")

func _test_locked_and_nearest() -> void:
    await manager.go_to("VillaF1", "Spawn_FromGate")
    var level: Node = manager.current_level
    var front: DoorPortal = level.doors.get("villa_back_door") as DoorPortal
    _check(not front.locked and front.target_level == "VillaBackyard", "Stage6 backdoor connects backyard")
    # Use the connected door as a controlled locked-door fixture.
    front.locked = true
    front.locked_message = "후문은 아직 열 수 없다"
    player.global_position = front.global_position
    var origin: Vector2 = front.visual.position
    front.interact(player)
    await _wait(0.03)
    _check(front.busy and not front.visual.position.is_equal_approx(origin), "Locked door shakes when interacted with")
    _check(str(main.get_node("HUD").toast.text) == "후문은 아직 열 수 없다", "Locked door displays its Korean toast")
    _check(not manager.player_locked and front.open_progress == 0.0, "Locked door leaves input available and stays closed")
    await _wait(0.30)
    _check(not front.busy and front.visual.position.is_equal_approx(origin), "Locked door shake restores its exact position")
    var near_door := DoorPortal.new()
    near_door.locked = true
    near_door.locked_message = "NEAREST"
    near_door.position = Vector2(600.0, 620.0)
    level.add_child(near_door)
    var far_door := DoorPortal.new()
    far_door.locked = true
    far_door.locked_message = "FAR"
    far_door.position = Vector2(650.0, 620.0)
    level.add_child(far_door)
    player.global_position = Vector2(610.0, 620.0)
    var input := InputEventAction.new()
    input.action = "interact"
    input.pressed = true
    far_door._unhandled_input(input)
    _check(not far_door.busy, "Farther door ignores one E input when a nearer door exists")
    near_door._unhandled_input(input)
    _check(near_door.busy and not far_door.busy, "Only the nearest door handles the E input")
    await _wait(0.30)
    near_door.queue_free()
    far_door.queue_free()

func _test_villa_gate() -> void:
    await manager.go_to("RearGate", "Spawn_Start")
    var level: Node = manager.current_level
    for enemy in get_nodes_in_group("enemies"):
        enemy.queue_free()
    var gate: VillaGate = level.doors["villa_gate"] as VillaGate
    var keeper: VillaGatekeeper = level.npcs["gatekeeper"] as VillaGatekeeper
    gate.gate_requires_dialogue = true
    player.global_position = Vector2(5050.0, level.floor_y)
    await _wait(0.1)
    _check(gate.gate_state == VillaGate.GateState.CLOSED and not gate.wall_shape.disabled, "Future dialogue hook blocks automatic opening with collision intact")
    gate.gate_requires_dialogue = false
    keeper.set_process(false)
    gate._process(0.0)
    _check(gate.gate_state == VillaGate.GateState.REQUESTED and keeper.current_clip == "open_gate", "Approaching within 300 px begins the keeper gesture")
    _check(not gate.can_interact(player), "A closed/requested villa gate cannot trigger a portal")
    keeper.clip_clock = 0.31
    keeper._refresh_visual()
    _check(keeper.current_frame == 1 and gate.gate_state == VillaGate.GateState.REQUESTED, "Gate remains closed during gesture frame 2")
    keeper.clip_clock = 0.321
    keeper._refresh_visual()
    _check(keeper.current_frame == 2 and gate.gate_state == VillaGate.GateState.OPENING, "Gate starts opening at the beginning of gesture frame 3")
    await _wait(0.5)
    _check(gate.gate_state == VillaGate.GateState.OPENING and not gate.wall_shape.disabled, "Gate barrier remains until opening finishes")
    await _wait(0.6)
    _check(gate.gate_state == VillaGate.GateState.OPEN and gate.wall_shape.disabled, "Fully open villa gate releases its collision wall")
    _check(keeper.current_clip == "idle", "Keeper returns to idle only after the gate is fully open")
    player.global_position.x = 4500.0
    await _wait(0.1)
    _check(gate.gate_state == VillaGate.GateState.CLOSING, "Leaving beyond 600 px closes the villa gate")
    await _wait(0.8)
    _check(gate.gate_state == VillaGate.GateState.CLOSED and not gate.wall_shape.disabled, "Closing restores the barrier")
    player.global_position.x = 5050.0
    await _wait(0.05)
    _check(gate.gate_state == VillaGate.GateState.REQUESTED, "Returning within 300 px repeats the gatekeeper gesture")
    keeper.clip_clock = 0.321
    keeper._refresh_visual()
    await _wait(1.1)
    var old_hp: int = player.hp
    player.global_position.x = gate.global_position.x
    gate._process(0.0)
    _check(gate.busy and manager.player_locked, "Fully open gate auto-enters without E and locks input")
    await manager.transition_finished
    _check(str(manager.current_level.level_id) == "VillaF1" and player.hp == old_hp, "Automatic villa entry preserves HP and reaches VillaF1")
    await manager.go_to("RearGate", "Spawn_FromVilla")
    gate = manager.current_level.doors["villa_gate"] as VillaGate
    gate.set_process(false)
    _check(not gate.entry_armed, "Returning through the villa gate disarms automatic re-entry")
    gate.gate_state = VillaGate.GateState.OPEN
    player.global_position.x = gate.global_position.x
    _check(not gate.can_interact(player), "Arrival cannot immediately retrigger inside the entrance strip")
    player.global_position.x = 5050.0
    gate._process(0.0)
    _check(gate.entry_armed, "Leaving the entrance strip rearms future villa entry")
