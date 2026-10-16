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
    var maximum_nodes:=0
    var initial_level: int=manager.current_level.get_instance_id()
    var positions: Array[Vector2] = [Vector2(3000,1700),Vector2(4900,1700),Vector2(7000,2900),Vector2(9000,4100),Vector2(7000,2900),Vector2(4900,1700),Vector2(3000,1700)]
    var times: Array[float] = []
    var warm_return_nodes:=0
    var final_return_nodes:=0
    var static_before: float=Performance.get_monitor(Performance.MEMORY_STATIC)
    positions.append_array(positions.duplicate())
    var step_index:=0
    for at in positions:
        hero.position=at
        world.schedule_stream(at)
        while not world.streaming_idle():
            var began:=Time.get_ticks_usec()
            await process_frame
            times.append((Time.get_ticks_usec()-began)/1000.)
        _check(world.loaded.size()<=9,"Nine-chunk memory bound")
        _check(manager.current_level.get_instance_id()==initial_level and manager._fade_rect.modulate.a==0,"Streaming preserves the level and never fades")
        maximum_nodes=maxi(maximum_nodes,_count_nodes(manager.current_level))
        step_index+=1
        if step_index==7:warm_return_nodes=_count_nodes(manager.current_level)
        if step_index==14:final_return_nodes=_count_nodes(manager.current_level)
    _check(maximum_nodes<=1655,"Total level nodes stay within the review baseline")
    var sorted_times: Array[float]=times.duplicate()
    sorted_times.sort()
    var p95: float=sorted_times[int(sorted_times.size()*.95)]
    _check(final_return_nodes<=warm_return_nodes+16,"Repeated streaming returns to a bounded node count")
    var memory_delta: float=Performance.get_monitor(Performance.MEMORY_STATIC)-static_before
    print("STATIC_MEMORY_DELTA_BYTES: ",memory_delta," return_nodes=",warm_return_nodes,"->",final_return_nodes)
    _check(memory_delta<=7488612,"Static memory growth stays within the Stage14 baseline")
    print("SLOWEST_STREAM_STEP: ",JSON.stringify(world.slowest_stream_step))
    print("CONTINUOUS_PERFORMANCE: frame_p95_ms=",p95," chunk_step_max_ms=",world.stream_times.max()," nodes_max=",maximum_nodes," chunks=",world.loaded.size())
    _check(p95<=8.2,"Streaming frame P95 at or below the 8.2ms review baseline")
    _check(float(world.stream_times.max())<=13.5,"One main-thread streaming step at or below the 13.5ms review baseline")
    await _go("HwaniraPlaza")
    hero.set_physics_process(true)
    _finish("stage14_performance")

func _count_nodes(node: Node) -> int:
    var count:=1
    for child in node.get_children():count+=_count_nodes(child)
    return count
