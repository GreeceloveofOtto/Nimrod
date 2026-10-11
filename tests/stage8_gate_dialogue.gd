extends "res://tests/helpers/stage4_support.gd"
func _run() -> void:
    await _start()
    var state: Node = root.get_node("GameState")
    for level_id in ["CastleOutskirts", "RearGate"]:
        await manager.go_to(level_id, "Spawn_Debug" if level_id == "CastleOutskirts" else "Spawn_Start", {"instant": true})
        var gate: GateController = manager.current_level.doors["castle_great_gate" if level_id == "CastleOutskirts" else "villa_gate"]
        hero.global_position = gate.global_position + Vector2(-200,0)
        gate._process(0)
        _check(gate.gate_state == GateController.GateState.CLOSED and gate._dialogue_locked(), "First visit waits for keeper dialogue")
        gate.authorize_open()
        await _wait(2.2)
        _check(gate.gate_state == GateController.GateState.OPEN and gate.wall_shape.disabled, "Dialogue authorization opens gate")
        hero.global_position.x -= 700
        await _wait(1.3)
        hero.global_position = gate.global_position - Vector2(200,0)
        await _wait(2.2)
        _check(gate.gate_state == GateController.GateState.OPEN, "Subsequent approach opens without dialogue")
        state.reset_run(false)
        _check(gate._dialogue_locked(), "Run reset requires keeper dialogue again")
    await manager.go_to("CastleFront", "Spawn_FromCastle", {"instant": true})
    var inner: GateController = manager.current_level.doors["castle_great_gate"]
    _check(not inner._dialogue_locked(), "Castle courtyard gate always allows opening")
    await _finish("STAGE8_GATE_DIALOGUE")
