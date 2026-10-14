extends "res://tests/helpers/stage9_support.gd"

func _run() -> void:
    await _start9()
    var state: Node = root.get_node("GameState")
    story_state.debug_stage(20)
    state.switch_character("siyavash")
    await _go("HwaniraPlaza")
    hero.position = Vector2(1875, 880)
    hero.set_physics_process(false)
    hero.camera.position_smoothing_enabled = false
    hero.camera.zoom = Vector2.ONE
    hero.camera.position = Vector2(145, -110)
    hero.camera.reset_smoothing()
    hero._show_clip("idle", 0)
    await process_frame
    await process_frame
    var native: bool = DisplayServer.get_name() != "headless"
    if native:
        DirAccess.make_dir_recursive_absolute("res://docs/plaza_dagger_review")
        hero.camera.force_update_scroll()
        await RenderingServer.frame_post_draw
        root.get_viewport().get_texture().get_image().save_png("res://docs/plaza_dagger_review/plaza_heroes.png")
    _check(manager.current_level.npcs.size() == 6, "Six hero overview")
    state.set_weapon("dagger")
    for step in range(1,6):
        hero._show_clip("attack_"+str(step), float(hero.attack_data[step]["active_start"]))
        _check(hero.visual.region_filter_clip_enabled and hero.visual.texture != null, "Dagger attack renders " + str(step))
        if native:
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_viewport().get_texture().get_image().save_png("res://docs/plaza_dagger_review/dagger_attack_%d.png" % step)
    await _finish("STAGE13_PLAZA_CAPTURE")
