extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    world.invulnerable=true
    for id in ["landing_00","forest_12","village_12","crystal_18","deep_02"]:
        await world.enter(id,"left",false)
        hero.position=Vector2(1500,1320)
        hero.camera.reset_smoothing()
        hero.camera.force_update_scroll()
        for i in range(4):await process_frame
        if DisplayServer.get_name()!="headless":
            await RenderingServer.frame_post_draw
            var path: String="res://docs/world_review/"+id+".png"
            DirAccess.make_dir_recursive_absolute("res://docs/world_review")
            root.get_texture().get_image().save_png(path)
        _check(manager.current_level is WorldRoom,"Capture loaded "+id)
    world.map_ui.opened=true
    world.map_ui.panel.visible=true
    world.map_ui.canvas.queue_redraw()
    for i in range(4):await process_frame
    if DisplayServer.get_name()!="headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/world_review/map.png")
    world.map_ui.close()
    await _go("HwaniraPlaza")
    _finish("stage14_world_capture")
