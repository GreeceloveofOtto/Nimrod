extends "res://tests/helpers/stage4_support.gd"
func _run() -> void:
    root.size = Vector2i(1280,720)
    await _start(false)
    main.get_node("HUD").story.hide()
    await manager.go_to("CedarForest_F1","Spawn_FromVilla",{"instant":true})
    hero.global_position = Vector2(1160,300)
    hero.camera.position_smoothing_enabled = false
    hero.camera.reset_smoothing()
    hero.camera.force_update_scroll()
    await create_timer(.2,true,false,true).timeout
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_jpg("res://docs/screenshots/stage8_trunk_before.jpg",.8)
    await _finish("STAGE8_BEFORE_CAPTURE")
