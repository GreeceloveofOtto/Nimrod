extends "res://tests/helpers/stage4_support.gd"

func _surface_y(level: LevelBase, x: float) -> float:
    var y: float = level.ground_y_at(x)
    for obstacle: Dictionary in level.config["obstacles"]:
        var rect: Array = obstacle["rect"]
        if x >= float(rect[0]) and x <= float(rect[0]) + float(rect[2]):
            y = minf(y,float(rect[1]))
    return y

func _traverse(level: LevelBase, direction: int, goal: float) -> void:
    Input.action_press("move_right" if direction > 0 else "move_left")
    var stalled: int = 0
    var jumps: int = 0
    var elapsed_steps: int = 0
    for step in range(6000):
        elapsed_steps = step
        if (goal-hero.global_position.x)*direction <= 0:
            break
        var before: float = hero.global_position.x
        var target_y: float = _surface_y(level,before+direction*55)
        if hero.is_on_floor() and (target_y < hero.global_position.y-10 or stalled > 5):
            var event := InputEventKey.new()
            event.physical_keycode = KEY_SPACE
            event.pressed = true
            Input.parse_input_event(event)
            jumps += 1
        hero._physics_process(1.0/60.0)
        if hero.velocity.y >= 0.0:
            var event := InputEventKey.new()
            event.physical_keycode = KEY_SPACE
            event.pressed = false
            Input.parse_input_event(event)
        stalled = stalled+1 if absf(hero.global_position.x-before)<.1 else 0
        if stalled > 160:
            break
        await physics_frame
    Input.action_release("jump")
    Input.action_release("move_right")
    Input.action_release("move_left")
    _check((goal-hero.global_position.x)*direction <= 0, "Actual player walks/jumps entire route in direction %d (ended x%.1f)" % [direction,hero.global_position.x])
    _check(jumps >= 5 and stalled <= 160, "Terrain requires jumps and causes no impassable wall")
    print("TERRAIN PHYSICS: direction ",direction," jumps ",jumps," steps ",elapsed_steps," end ",hero.global_position)

func _run() -> void:
    await _start()
    await manager.go_to("CastleOutskirts","Spawn_FromGate")
    Engine.physics_ticks_per_second = 240
    Engine.time_scale = 4.0
    var level: LevelBase = manager.current_level
    for door: DoorPortal in level.doors.values():
        door.set_process(false)
    for step in range(3):
        hero._physics_process(1.0/60.0)
        await physics_frame
    await _traverse(level,-1,520)
    hero.velocity = Vector2.ZERO
    await _traverse(level,1,9440)
    _check(hero.hp == 180, "Frozen enemy fixture leaves route verification at full HP")
    await _finish("STAGE4_TERRAIN")
