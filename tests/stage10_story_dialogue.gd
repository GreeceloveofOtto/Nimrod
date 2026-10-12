extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage10_dialogue_original.json"))
    var counts: Dictionary = {"home_critical":5,"inanna_home":14,"enkidua_last":6,"gugalanna_intro":3,"villa_prosthetic":6,"rooftop":2}
    for id in expected:
        _check(expected[id].size()==counts[id],"Independent requested line count "+id)
        var spec: Dictionary = dialogue_node.settings["interactions"][id]
        var actual: Array = spec["first"].filter(func(line: Dictionary) -> bool: return line.has("text"))
        _check(actual==expected[id],"Exact original speaker/text/order/line count for "+id)
        _check(spec["repeat"].is_empty(),"New conversation one per run "+id)
    story_state.debug_stage(9)
    await _go("NimrodHome","Spawn_FromMelammu")
    var speakers: Array[String] = []
    var observed: Array[String] = []
    dialogue_node.line_changed.connect(func(id: String, text: String) -> void:
        speakers.append(id)
        observed.append(text)
        _check(dialogue_node.name_label.text==("니므롯" if id=="player" else "엔키두아"),"Name chip during actual home conversation"))
    await dialogue_node.play_interaction("home_critical")
    await _wait(.3)
    if cutscene_node.active:
        await cutscene_node.completed
    _check(speakers.size()==5 and observed[0]==expected["home_critical"][0]["text"],"Five exact home lines replayed")
    _check(story_state.is_flag("home_critical_done"),"Conversation flag")
    await _finish("STAGE10_STORY_DIALOGUE")
