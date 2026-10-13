extends "res://tests/helpers/stage9_support.gd"
const OLD_MAN: Array[String] = [
"그대가 우트나피쉬팀이요? 단도직입적으로 말하겠어, 난 영생을 찾아 오랫동안 여행했지. 그대는 영생을 아는가?",
"자네의 눈을 보아하니 숨쉬는 존재의 영원한 생명이 아니라, 흙으로 돌아간 자의 부활을 꿈꾸는군.",
"그래, 난 죽은 자를 되살리고자 해. 당신이 영원한 생명을 갖고 있다고 해서, 죽음의 바다를 건너 찾아왔어.",
"나의 영원한 생명은 죽는 것에 실패하는 것과 같지.",
"나는 지금도 끊임없이 죽기를 반복해. 그러나 사망에 실패할 뿐이야.",
"미안하지만, 영생에 대해서는 해줄 말이 없네, 부활을 꿈꾼다면 더더욱."]
const TIAMAT: Array[String] = ["재밌구나, 재밌어. 나에게 오라. 나를 죽여다오.","니므롯, 이 짧은 시대에 내가 너를 주인공으로 삼았다. 앞으로 더욱 재밌어질 거야. 고통에 신음하지말고, 내가 너에게 준 운명을 즐겨라!"]
func _run() -> void:
    await _start9()
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
    for pair in [["utnapishtim_talk",OLD_MAN],["tiamat_talk",TIAMAT]]:
        var lines: Array=data["interactions"][pair[0]]["variants"][0]["first"]
        _check(lines.size()==pair[1].size(),"Exact dialogue length")
        for i in range(lines.size()):_check(str(lines[i]["text"])==str(pair[1][i]),"Exact literal line %s %d"%[pair[0],i])
    _check(data["interactions"]["utnapishtim_talk"]["variants"][0]["on_finish"][0]["cutscene"]=="utnapishtim_rampage","Cutscene linked after dialogue")
    _check(not dialogue_node.interaction_available("utnapishtim_talk"),"Old man requires ferry arrival")
    story_state.debug_stage(18)
    _check(dialogue_node.interaction_available("utnapishtim_talk"),"Old man available before completion")
    await _finish("STAGE13_LITERAL_DIALOGUE")
