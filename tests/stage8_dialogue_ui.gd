extends "res://tests/helpers/stage4_support.gd"
var seen: Array[String] = []
func _line(_id: String, _text: String) -> void:
    var dialogue: Node = root.get_node("Dialogue")
    seen.append(dialogue.name_label.text)
func _run() -> void:
    root.size = Vector2i(1280,720)
    await _start()
    await manager.go_to("CastleF1", "Spawn_Debug", {"instant": true})
    var d: Node = root.get_node("Dialogue")
    d.line_changed.connect(_line)
    var father: NPC = manager.current_level.npcs["lugalbanda"]
    d.play([{"speaker":"lugalbanda","text":"아들아."},{"speaker":"player","text":"고마워요."}], father, {"participants":{"lugalbanda":father,"player":hero},"character_seconds":.001,"hold_seconds":.3})
    await create_timer(.45,true,false,true).timeout
    _check(paused and d.active,"Dialogue unconditionally pauses world")
    _check(absf(d.balloon.position.x + d.balloon.size.x - 1248) < 1,"Right margin32")
    _check(absf(d.balloon.position.y + d.balloon.size.y*.5 - 360) < 1,"Fixed vertical center")
    _check(father.name_tag.visible,"World name remains visible")
    await d.finished
    _check(seen == ["루갈반다","니므롯"],"Name chip follows every speaker")
    _check(d.input_blocked(),"E is suppressed for .2 seconds after close")
    await create_timer(.21,true,false,true).timeout
    _check(not d.input_blocked(),"E suppression expires")
    d.play(["취소 검사"],hero,{"character_seconds":.001,"hold_seconds":5})
    await create_timer(.5,true,false,true).timeout
    _check(not await root.get_node("DebugTeleport").teleport("VillaF1","Spawn_FromGate"),"Debug teleport is blocked throughout dialogue")
    d.cancel()
    _check(not paused and not d.active and d.live_timer == null,"Cancellation resumes time and releases pending auto-progress timer")
    await _finish("STAGE8_DIALOGUE_UI")
