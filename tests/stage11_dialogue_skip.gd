extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    dialogue_node.test_timing_scale = 1
    dialogue_node.settings["camera_seconds"] = .01
    var spoken: Array[String] = []
    dialogue_node.line_changed.connect(func(_id: String,line: String) -> void: spoken.append(line))
    dialogue_node.play.call_deferred([{"speaker":"player","text":"첫 줄"},{"speaker":"player","text":"두 번째"},{"speaker":"player","text":"마지막"}],hero)
    await _wait(.04)
    _check(not dialogue_node.skip_line(),"Opening E cannot skip first line")
    await _wait(.27)
    _check(dialogue_node.skip_line(),"Typing line skips immediately")
    _check(not dialogue_node.skip_line(),"One press cannot advance twice")
    await _wait(.14)
    var key := InputEventAction.new()
    key.action = "interact"
    key.pressed = true
    Input.parse_input_event(key)
    await _wait(.14)
    _check(spoken.size()==3,"Real E input advances exactly one line")
    dialogue_node.skip_line()
    await _wait(.04)
    _check(not dialogue_node.active and not paused,"Last E ends dialogue and restores world time")
    _check(dialogue_node.input_grace_left>0,"Post-dialogue grace prevents reinteraction")
    await _go("CastleF1")
    root.get_node("GameState").set_weapon("none")
    dialogue_node.play_interaction.call_deferred("parents_gift")
    for i in range(180):
        await _wait(.02)
        if dialogue_node.active:
            dialogue_node.skip_line()
        elif root.get_node("GameState").run_flags.get("dialogue_parents_gift",false):
            break
    _check(root.get_node("GameState").get_weapon()=="axe","Skipping still executes mid-dialogue axe gift")
    _check(root.get_node("GameState").visit_count("parents_gift")==1,"Skipped interaction completes once")
    await _finish("STAGE11_DIALOGUE_SKIP")
