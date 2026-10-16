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
    var directory: String="res://docs/stage15_map_review_revision"
    DirAccess.make_dir_recursive_absolute(directory)
    var measurements: Array=[]
    for point: Dictionary in world.settings.review_points:
        hero.position=Vector2(float(point.at[0]),float(point.at[1]))*32
        world.schedule_stream(hero.position)
        while not world.streaming_idle():await process_frame
        for i in range(5):await process_frame
        hero._show_clip("jump_rise" if point.id=="shaft" else "idle",0.)
        hero.camera.position_smoothing_enabled=false
        hero.camera.reset_smoothing()
        hero.camera.force_update_scroll()
        await process_frame
        # Exclude the 0.08px physics contact skin, so standing on a floor is not penetration.
        _check(not hero._solid_overlaps(hero._hero_box().grow(-.1)),"Capture starts outside solid terrain: "+str(point.id))
        var solid:=0
        var total:=0
        var camera_center: Vector2=hero.camera.get_screen_center_position()
        for y in range(floori((camera_center.y-360)/32.),ceili((camera_center.y+360)/32.)):
            for x in range(floori((camera_center.x-640)/32.),ceili((camera_center.x+640)/32.)):
                if world.solid_at(Vector2i(x,y)):solid+=1
                total+=1
        measurements.append({"id":point.id,"hero":[hero.position.x,hero.position.y],"camera":[camera_center.x,camera_center.y],"zoom":[hero.camera.zoom.x,hero.camera.zoom.y],"solid_percent":100.*solid/maxi(1,total)})
        if DisplayServer.get_name()!="headless":
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(directory+"/landing_"+str(point.id)+".png")
        _check(world.loaded.size()<=9,"Nine chunks: "+str(point.id))
        for chunk: Node in world.loaded.values():
            _check(_nodes(chunk)<=250,"Chunk node cap "+str(chunk.data.id))
    DirAccess.make_dir_recursive_absolute("res://tests/artifacts")
    var file:=FileAccess.open("res://tests/artifacts/stage15_capture.json",FileAccess.WRITE)
    if file!=null:file.store_string(JSON.stringify(measurements,"  "))
    await _go("HwaniraPlaza")
    hero.set_physics_process(true)
    _finish("stage15_landing_capture")

func _nodes(node: Node) -> int:
    var count:=1
    for child: Node in node.get_children():count+=_nodes(child)
    return count
