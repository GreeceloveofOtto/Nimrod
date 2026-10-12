extends "res://tests/helpers/stage9_support.gd"

func _run() -> void:
    root.size=Vector2i(1280,720)
    await _start9()
    main.get_node("HUD").story.hide()
    await _go("CedarForest_F1", "Spawn_FromAbove")
    hero.global_position=Vector2(2200,768)
    hero.camera.position=Vector2(0,-280)
    hero.camera.position_smoothing_enabled=false
    hero.camera.reset_smoothing()
    hero.camera.force_update_scroll()
    await create_timer(.2,true,false,true).timeout
    await RenderingServer.frame_post_draw
    var before: bool="before" in OS.get_cmdline_user_args()
    var path: String="res://archive/stage9/trunk_before.jpg" if before else "res://docs/screenshots/stage9_cedar_trunks_removed.jpg"
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    root.get_texture().get_image().save_jpg(path,.88)
    await _finish("STAGE9_TRUNK_REMOVAL_CAPTURE")
