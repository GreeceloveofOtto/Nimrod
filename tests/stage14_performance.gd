extends "res://tests/helpers/stage9_support.gd"
func count_nodes(node: Node) -> int:
    var total := 1
    for child in node.get_children():total+=count_nodes(child)
    return total
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    world.timing_scale=.001
    world.invulnerable=true
    await world.enter("deep_02","left",false)
    hero.position=Vector2(1900,1320)
    hero.set_physics_process(false)
    _check(manager.current_level.enemies.size()==30,"Maximum30 enemy fixture")
    world.update_sleep(manager.current_level,hero)
    _check(world.active_enemies==24 and world.sleeping_enemies==6,"Exactly24 active and6 asleep")
    _check(count_nodes(manager.current_level)<=400,"Recursive node budget")
    # Performance monitors publish once per second; exclude the cold loading
    # interval so cached load time is not misreported as ongoing frame time.
    for warmup in range(120):await physics_frame
    var frames: Array[float]=[]
    for i in range(180):
        await physics_frame
        frames.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))*1000)
    frames.sort()
    var p95: float = frames[int(frames.size()*.95)]
    _check(p95<16.667,"Headless physics95th percentile below16.667ms")
    var baseline_nodes := 0
    var final_nodes := 0
    var load_times: Array[float]=[]
    for i in range(12):
        await world.enter("deep_03","left",false)
        await process_frame
        await world.enter("deep_02","left",false)
        await process_frame
        await process_frame
        load_times.append(world.last_load_ms)
        if i==2:baseline_nodes=count_nodes(manager.level_root)
        if i==11:final_nodes=count_nodes(manager.level_root)
    _check(final_nodes==baseline_nodes,"Owned level subtree remains exactly stable across warm streaming cycles")
    load_times.sort()
    _check(load_times.back()<150,"Room streaming under150ms including neighbor terrain")
    var metrics: Dictionary={"room":"deep_02","enemies":30,"active":24,"physics_p95_ms":p95,"load_max_ms":load_times.back(),"load_median_ms":load_times[load_times.size()/2],"node_baseline":baseline_nodes,"node_final":final_nodes,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"recursive_room_nodes":count_nodes(manager.current_level)}
    var file:=FileAccess.open("user://world_performance.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(metrics));file.close()
    print("WORLD_BENCHMARK: ",JSON.stringify(metrics))
    await _go("HwaniraPlaza")
    _finish("stage14_performance")
