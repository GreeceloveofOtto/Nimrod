extends "res://tests/helpers/stage9_support.gd"

func _run() -> void:
    await _start9()
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    hero.position = Vector2(2000,880)
    hero.set_process(false)
    hero.set_physics_process(false)
    hero.camera.position_smoothing_enabled = false
    hero.camera.reset_smoothing()
    var gpu: bool = DisplayServer.get_name() != "headless"
    if gpu:
        DirAccess.make_dir_recursive_absolute("res://docs/siyavash_review")
    for clip_name: String in ["idle","run","hurt","death"]:
        var clip: Dictionary = hero.clip_data[clip_name]
        var clock: float = 0.0
        if clip_name == "death":
            clock = float(clip["duration_seconds"])
        hero._show_clip(clip_name,clock)
        _check(hero.visual.texture != null and hero.visual.region_filter_clip_enabled,"Generated atlas configured for " + clip_name)
        _check(hero.collider.shape.size == NimrodPlayer.STAND_BOX,"Gameplay collider unchanged")
        if gpu:
            for zoom: float in [1.0,1.35]:
                hero.camera.zoom=Vector2.ONE*zoom
                hero.camera.force_update_scroll()
                await RenderingServer.frame_post_draw
                root.get_viewport().get_texture().get_image().save_png("res://docs/siyavash_review/runtime_%s_%.2f.png" % [clip_name,zoom])
    hero.camera.zoom=Vector2.ONE
    await _finish("STAGE13_SIYAVASH_LOOK_CAPTURE")
