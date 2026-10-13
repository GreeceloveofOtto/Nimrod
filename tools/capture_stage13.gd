extends "res://tests/helpers/stage9_support.gd"
func capture(label: String,at: Vector2) -> void:
    hero.global_position=at
    hero.rampage_flash_left=0
    hero.flash_time=0
    hero.visual.modulate=Color.WHITE
    hero.camera.position_smoothing_enabled=false
    hero.camera.limit_smoothed=false
    hero.camera.force_update_scroll()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_viewport().get_texture().get_image().save_png("res://docs/screenshots/stage13_"+label+".png")
func _run() -> void:
    await _start9()
    story_state.debug_stage(12)
    await _go("NimrodHome")
    await capture("enkidua_gone",Vector2(340,620))
    story_state.debug_stage(18)
    await _go("TiamatZone")
    await cutscene_node.play("utnapishtim_rampage")
    await capture("utnapishtim_rampage",Vector2(1530,880))
    await _go("HuluppuCrown")
    await capture("crown",Vector2(1650,880))
    for pair in [["ninazu_mother",Vector2(1970,880)],["lilith",Vector2(1220,880)],["zu",Vector2(2350,610)]]:
        await capture(str(pair[0]),pair[1])
    story_state.set_flag("huluppu_boss_done")
    story_state.set_flag("tiamat_talk_done")
    root.get_node("Rampage").set_value(90)
    await _go("TiamatCollapsed")
    await capture("tiamat",Vector2(2450,880))
    manager._fade_rect.modulate.a=1
    root.get_node("Choice").open_systems()
    await capture("choice",Vector2(2450,880))
    root.get_node("Choice").close()
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    await capture("hwanira_start",Vector2(650,880))
    await capture("hwanira_center",Vector2(2000,880))
    await _finish("STAGE13_SCREENSHOTS")
