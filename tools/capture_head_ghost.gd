extends "res://tests/helpers/stage9_support.gd"

func _run() -> void:
    await _start9()
    story_state.debug_stage(15)
    await _go("CastleF1")
    hero.global_position = Vector2(760,620)
    hero.camera.position_smoothing_enabled = false
    hero.camera.zoom = Vector2.ONE
    hero.camera.global_position = Vector2(760,400)
    hero.camera.force_update_scroll()
    var phase: String = "after" if "after" in OS.get_cmdline_user_args() else "before"
    var folder: String = "res://tests/artifacts/head_ghost/"+phase
    DirAccess.make_dir_recursive_absolute(folder)
    root.get_node("Rampage").death_suspended = true
    for row in [[0,"idle"],[0,"walk"],[0,"attack_1"],[0,"attack_2"],[0,"attack_3"],[0,"attack_4"],[41,"r40_idle"],[51,"r50_idle"],[95,"r90_idle"]]:
        root.get_node("Rampage").set_value(row[0])
        hero.sync_story_state()
        hero.rampage_flash_left = 0
        hero.flash_time = 0
        hero.visual.modulate = Color.WHITE
        var clip: String = "idle" if "_idle" in str(row[1]) else str(row[1])
        hero._show_clip(clip,0)
        await process_frame
        await RenderingServer.frame_post_draw
        var capture: Image = root.get_viewport().get_texture().get_image()
        capture.save_png(folder+"/"+str(row[1])+".png")
        var alpha: Image = hero.visual.texture.get_image().get_region(Rect2i(hero.visual.region_rect))
        alpha.save_png(folder+"/"+str(row[1])+"_cell.png")
    await _finish("HEAD_GHOST_CAPTURE_"+phase.to_upper())
