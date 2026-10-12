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
    im.save_png("res://docs/screenshots/stage12_"+label+".png")
func _run() -> void:
    await _start9()
    story_state.debug_stage(18)
    await _go("TiamatZone")
    hero.position=Vector2(1460,880)
    await capture("tiamat",1520)
    await _finish("STAGE12_SCREENSHOTS")
