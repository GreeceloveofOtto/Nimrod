extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    world.invulnerable=true
    await world.enter()
    hero.set_physics_process(false)
    var dir: String="res://tests/artifacts/stage14_rework"
    DirAccess.make_dir_recursive_absolute(dir)
    for index in [0,1,4,5,7,9]:
        var region: Dictionary=world.settings.regions[index]
        hero.position=Vector2(float(region.bounds[0])+15,float(region.bounds[1])+25)*32
        world.schedule_stream(hero.position)
        while not world.streaming_idle():await process_frame
        for i in range(5):await process_frame
        hero.camera.position_smoothing_enabled=false
        hero.camera.reset_smoothing()
        hero.camera.force_update_scroll()
        await process_frame
        if DisplayServer.get_name()!="headless":
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(dir+"/"+str(region.id)+".png")
        _check(world.loaded.size()<=9,"Capture chunk bound "+str(region.id))
        _check(_top_left_labels(root).is_empty(),"No visible text in combat ROI "+str(region.id))
    world.map_ui.open_map()
    for i in range(3):await process_frame
    if DisplayServer.get_name()!="headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(dir+"/map.png")
    world.map_ui.close()
    await _go("HwaniraPlaza")
    hero.set_physics_process(true)
    _finish("stage14_stream_capture")

func _top_left_labels(node: Node) -> Array[String]:
    var found: Array[String]=[]
    if node is Label or node is RichTextLabel:
        var control: Control=node
        var opacity:=1.
        var parent: Node=node
        while parent!=null:
            if parent is CanvasItem:opacity*=parent.modulate.a*parent.self_modulate.a
            parent=parent.get_parent()
        if control.is_visible_in_tree() and opacity>.01 and not str(node.text).is_empty():
            var rect:=Rect2(control.get_global_transform_with_canvas()*Vector2.ZERO,control.size)
            if rect.intersects(Rect2(0,0,420,140)):found.append(str(node.text))
    for child in node.get_children():found.append_array(_top_left_labels(child))
    return found
