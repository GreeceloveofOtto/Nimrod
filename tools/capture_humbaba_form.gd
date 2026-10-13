extends "res://tests/helpers/stage9_support.gd"
func capture(label: String) -> void:
    hero.camera.position_smoothing_enabled=false
    hero.camera.limit_smoothed=false
    hero.camera.force_update_scroll()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_viewport().get_texture().get_image().save_png("res://docs/screenshots/stage13_form_"+label+".png")
func _run() -> void:
    await _start9()
    story_state.debug_stage(18)
    var rage: Node=root.get_node("Rampage")
    var form: Node=root.get_node("HumbabaForm")
    await _go("HuluppuCrown")
    hero.position=Vector2(1650,880)
    rage.set_value(100)
    await form.transformed
    form.render("idle",0)
    await capture("idle")
    form.request_breath()
    form.attack_phase=1
    form.attack_clock=.3
    form.render("breath_loop",.3)
    form.flame=form._fx("humbaba_flame_cone",Vector2(300,-155),Vector2(600,300),true)
    await capture("breath")
    form.exit(true)
    manager.set_player_locked(false)
    await _go("TiamatZone")
    form.cooldown_left=0
    await cutscene_node.play("utnapishtim_rampage")
    hero.position=Vector2(1530,880)
    await capture("cutscene_after")
    _check(not form.engaged() and rage.value()==60 and not manager.player_locked,"Capture ends on restored Nimrod60")
    await _finish("FORM_SCREENSHOTS")
