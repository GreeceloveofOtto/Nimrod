extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    await _go("CastleF1")
    var saved_weapon: String = hero.weapon
    cutscene_node.settings["cutscenes"]["cancel_test"]=[{"type":"lock_player"},{"type":"set_weapon_visibility","hidden":true},{"type":"wait","seconds":20.0}]
    cutscene_node.play("cancel_test")
    await create_timer(.05,true,false,true).timeout
    _check(paused and manager.player_locked and hero.visual_weapon_hidden,"Cutscene locks input, hides art and pauses world")
    cutscene_node.cancel()
    await process_frame
    _check(not paused and not cutscene_node.active and not manager.player_locked,"Cancel restores pause/input state")
    _check(hero.weapon==saved_weapon and not hero.visual_weapon_hidden,"Cancel preserves actual weapon and restores visibility")
    cutscene_node.settings["cutscenes"]["cancel_fade"]=[{"type":"fade","alpha":1.0,"seconds":20.0},{"type":"set_flag","flag":"should_not_run"}]
    cutscene_node.play("cancel_fade")
    await create_timer(.05,true,false,true).timeout
    cutscene_node.cancel()
    await process_frame
    _check(not story_state.is_flag("should_not_run") and manager._fade_rect.modulate.a==0,"Cancel releases pending fade without running later steps")
    cutscene_node.settings["cutscenes"]["travel_test"]=[{"type":"teleport_player","level":"VillaF1","spawn":"Spawn_FromGate"},{"type":"wait","seconds":.2}]
    await cutscene_node.play("travel_test")
    _check(manager.current_level.level_id=="VillaF1" and not manager.player_locked,"Cross-level cutscene safely completes")
    await _finish("STAGE9_CUTSCENE_RUNNER")
