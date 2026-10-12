extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(14)
    await _go("VillaF4")
    await _wait(.02)
    if cutscene_node.active:
        await cutscene_node.completed
    _check(story_state.is_flag("rooftop_done") and story_state.is_flag("dilmun_arrived"),"Automatic rooftop to Dilmun story")
    _check(manager.current_level.level_id=="Dilmun" and is_equal_approx(hero.position.x,600),"Landing")
    _check(manager.current_level.npcs.is_empty() and manager.current_level.doors.is_empty() and get_nodes_in_group("enemies").is_empty(),"Desolate planet no actors or doors")
    _check(manager.current_level.config["width"]==9000 and manager.current_level.config["pickups"].is_empty(),"World length and no pickups")
    _check(not manager.player_locked and not paused and hero.cinematic_clip.is_empty(),"Free movement after landing")
    hero.global_position = Vector2(8900,880)
    root.get_node("Chapter")._process(.01)
    _check(float(root.get_node("Chapter").vignette.material.get_shader_parameter("strength"))>0,"Near-edge vignette")
    await _finish("STAGE10_DILMUN")
