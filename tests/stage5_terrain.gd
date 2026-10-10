extends "res://tests/helpers/stage4_support.gd"

func _top(level: LevelBase,x: float) -> float:
    var y: float = level.ground_y_at(x)
    for obstacle: Dictionary in level.config.get("obstacles",[]):
        var r: Array = obstacle["rect"]
        if x >= r[0] and x <= r[0]+r[2]:
            y = minf(y,r[1])
    return y

func _walk(level: LevelBase,direction: int,goal: float) -> void:
    Input.action_press("move_left" if direction<0 else "move_right")
    var stalled: int = 0
    for i in range(6500):
        if (goal-hero.global_position.x)*direction <= 0:
            break
        var before: float = hero.global_position.x
        var crouch: bool = false
        for ceiling: Dictionary in level.config.get("ceilings",[]):
            var r: Array = ceiling["rect"]
            crouch = crouch or (before >= r[0]-50 and before <= r[0]+r[2]+50)
        if crouch:
            Input.action_press("crouch")
        else:
            Input.action_release("crouch")
        if not crouch and hero.is_on_floor() and (_top(level,before+direction*55)<hero.global_position.y-10 or stalled>5):
            var event := InputEventKey.new()
            event.physical_keycode = KEY_SPACE
            event.pressed = true
            Input.parse_input_event(event)
        hero._physics_process(1.0/60)
        if hero.velocity.y >= 0:
            var event := InputEventKey.new()
            event.physical_keycode = KEY_SPACE
            event.pressed = false
            Input.parse_input_event(event)
        stalled = stalled+1 if absf(before-hero.global_position.x)<.1 else 0
        if stalled > 180:
            break
        await physics_frame
    for action in ["move_left","move_right","jump","crouch"]:
        Input.action_release(action)
    _check((goal-hero.global_position.x)*direction<=0,"%s direction%d complete at x%.1f" % [level.level_id,direction,hero.global_position.x])

func _run() -> void:
    await _start()
    Engine.physics_ticks_per_second = 240
    Engine.time_scale = 4
    for id in ["DowntownPassage_F1","DowntownPassage_F2","DowntownPassage_F3","DowntownPassage_F4","DowntownPassage_F5","DowntownPassage_F6","DowntownPassage_F7","DowntownPassage_F8","HomeRoad"]:
        await manager.go_to(id,"Spawn_FromPassage" if id=="HomeRoad" else "Spawn_FromAbove")
        var level: LevelBase = manager.current_level
        for door in level.doors.values():
            door.set_process(false)
        hero.reset_run_state()
        hero.set_transition_locked(false)
        hero.global_position = Vector2(10340 if id=="HomeRoad" else 3330,level.ground_y_at(10340 if id=="HomeRoad" else 3330))
        hero.set_physics_process(false)
        for i in range(3):
            hero._physics_process(1.0/60)
            await physics_frame
        await _walk(level,-1,400 if id=="HomeRoad" else 300)
        hero.velocity = Vector2.ZERO
        await _walk(level,1,10340 if id=="HomeRoad" else 3330)
    await _finish("STAGE5_TERRAIN")
