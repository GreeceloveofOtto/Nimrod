extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var all_text: String = FileAccess.get_file_as_string("res://data/dialogue.json")
    _check(not all_text.contains("너가"),"No incorrect subject particle in any dialogue")
    _check(all_text.contains("네가 나를 추천한 거 아니야? 내가 고맙지."),"Enkidua corrected subject")
    _check(all_text.contains("네가 못하겠다면, 내가 너의 운명을 기필코 바꿔놓겠어."),"Final conversation corrected subject")
    for preserved in ["너에게 거는 기대가 커","너는 많은 것을 할 수 있을 거야","너의 팔을 고쳐줄게","너 팔은 어떡해?","너 지금 심각해"]:
        _check(all_text.contains(preserved),"Other second-person forms preserved: "+preserved)
    var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage11_dialogue_original.json"))
    _check(dialogue_node.settings["interactions"]["shimati_intro"]["first"]==original["shimati_intro"],"All nine Shimati lines match independent original fixture")
    await _finish("STAGE11_STORY_DIALOGUE")
