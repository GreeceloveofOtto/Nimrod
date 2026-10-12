extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(4)
    await _go("CastleF1")
    var saved: String = hero.weapon
    _check(story_state.is_flag("night"),"Night before return dialogue")
    await dialogue_node.play_interaction("parents_gift")
    await process_frame
    while cutscene_node.active:
        await create_timer(.05,true,false,true).timeout
    _check(story_state.is_flag("time_skipped") and not story_state.is_flag("night"),"Return dialogue invokes time skip and ends night")
    _check(absf(hero.global_position.x-760)<1,"Wake at castle Spawn_Wake")
    _check(hero.weapon==saved and not manager.player_locked and manager._fade_rect.modulate.a==0,"Time skip preserves weapon and restores fade/input")
    _check(manager.current_level.doors["castle_rear_interior"].locked,"Rear exit remains locked pending talks")
    await dialogue_node.play_interaction("enkidua_intro")
    await dialogue_node.play_interaction("parents_gift")
    _check(story_state.is_flag("castle_talks_done") and not manager.current_level.doors["castle_rear_interior"].locked,"Enkidua then parents unlock exit")
    await _finish("STAGE9_TIME_SKIP")
