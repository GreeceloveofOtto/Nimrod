extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage9_dialogue_original.json"))
    var font: Font = load("res://assets/fonts/NimrodUIKorean-Regular.otf")
    for id in original:
        _check(dialogue_node.settings["interactions"][id]["first"] == original[id],id + " exact original Korean speaker/text")
        for line: Dictionary in original[id]:
            for character: String in str(line.get("text", "")):
                _check(font.has_char(character.unicode_at(0)),"Stage9 dialogue glyph exists")
    await _go("VillaF3")
    await dialogue_node.play_interaction("villa_hosts")
    _check(story_state.is_flag("villa_intro_done"),"First group intro sets its shared flag")
    _check(not dialogue_node.interaction_available("villa_hosts"),"Completed intro has no repeated lines")
    story_state.set_flag("kala_first_defeat")
    await dialogue_node.play_interaction("villa_hosts")
    _check(story_state.is_flag("report_done"),"Report variant sets report flag")
    await _finish("STAGE9_STORY_DIALOGUE")
