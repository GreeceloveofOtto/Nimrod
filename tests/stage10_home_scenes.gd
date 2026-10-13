extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(9)
    await _go("NimrodHome")
    _check(manager.current_level.npcs["enkidua_bed"].current_clip=="bed_awake","Critical awake bed")
    story_state.set_flag("home_critical_done")
    _check(manager.current_level.npcs["enkidua_bed"].current_clip=="bed_asleep" and not manager.current_level.npcs["enkidua_bed"].interactable,"Day5 asleep not interactable")
    await cutscene_node.play("inanna_home_exit")
    _check(not manager.current_level.npcs.has("inanna") and manager.current_level.npcs["enkidua_bed"].current_clip=="bed_awake","Day11 Inanna gone, Enkidua awake")
    var phases: Array[String] = []
    cutscene_node.step_started.connect(func(kind: String) -> void: phases.append(kind))
    await cutscene_node.play("enkidua_end")
    _check(story_state.is_flag("enkidua_gone") and story_state.is_flag("enkidua_last_talk_done"),"Final loss flags")
    _check(not manager.current_level.npcs.has("enkidua_bed") and manager.current_level.has_node("BedBlood"),"Stage13: empty bed retains blood after loss")
    _check(hero.cinematic_set.is_empty() and hero.sprite_set=="axe_onearm" and not manager.player_locked,"Normal unbloodied set and input restored")
    _check(phases.has("zoom") and phases.has("sound") and phases.has("time_skip"),"Grieving camera, sob and caption stages executed")
    await _finish("STAGE10_HOME_SCENES")
