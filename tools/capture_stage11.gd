extends "res://tests/helpers/stage9_support.gd"
func capture(label: String,position_x: float) -> void:
    hero.rampage_flash_left=0
    hero.flash_time=0
    hero.visual.modulate=Color.WHITE
    hero.camera.position_smoothing_enabled=false
    hero.camera.limit_smoothed=false
    hero.camera.global_position=Vector2(position_x,hero.global_position.y-220)
    hero.camera.force_update_scroll()
    await process_frame
    await RenderingServer.frame_post_draw
    var im: Image=root.get_viewport().get_texture().get_image()
    im.save_png("res://docs/screenshots/stage11_"+label+".png")
func _run() -> void:
    await _start9()
    story_state.debug_stage(15)
    await _go("Dilmun")
    hero.position=Vector2(4440,880)
    await capture("dilmun",4500)
    await _go("CastleF2")
    hero.position=Vector2(840,620)
    await dialogue_node.play_interaction("shamhat")
    root.get_node("Choice").open(manager.current_level.npcs["shamhat"])
    await capture("choice_menu",900)
    root.get_node("Choice").close()
    await _go("CastleF1")
    for row in [[0,"helm"],[41,"r40"],[51,"r50"],[95,"r90"]]:
        root.get_node("Rampage").death_suspended=true
        root.get_node("Rampage").set_value(row[0])
        hero.sync_story_state()
        hero.position=Vector2(760,620)
        hero.rampage_flash_left=0
        hero.visual.modulate=Color.WHITE
        hero._show_clip("idle",0)
        await capture(row[1],760)
    root.get_node("Rampage").set_value(0)
    story_state.debug_stage(10)
    await _go("NimrodHome")
    hero.position=Vector2(700,620)
    await capture("bed_contact",450)
    story_state.debug_stage(16)
    await _go("DeathSea")
    hero.position=Vector2(720,880)
    await capture("deathsea",1050)
    await _finish("STAGE11_SCREENSHOTS")
