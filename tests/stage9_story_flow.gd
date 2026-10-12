extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    for stage in range(9):
        story_state.debug_stage(stage)
        _check(story_state.stage()==stage,"Cumulative story stage %d" % stage)
        _check(story_state.is_flag("night") == (stage in [3,4]),"Derived night phase %d" % stage)
        await _go("VillaF1")
        _check(manager.current_level.npcs.size() == (0 if stage in [3,4] else 2),"Servant night presence %d" % stage)
        await _go("VillaF3")
        _check(manager.current_level.npcs.size() == (0 if stage==2 else 2),"Host dinner/return presence %d" % stage)
        await _go("CastleF1")
        _check(manager.current_level.npcs.has("enkidua") == (stage>=4),"Castle Enkidua presence %d" % stage)
        _check(manager.current_level.doors["castle_rear_interior"].locked == (stage==5),"Rear door locks only after waking before talks %d" % stage)
        await _go("NimrodHome")
        _check(manager.current_level.npcs.has("enkidua") == (stage<4),"Home Enkidua presence %d" % stage)
    root.get_node("GameState").reset_run(false)
    _check(story_state.stage()==0 and not story_state.is_flag("skill_anur_light"),"Death reset clears story and skill")
    await _finish("STAGE9_STORY_FLOW")
