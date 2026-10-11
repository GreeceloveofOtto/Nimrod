extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
    var random := RandomNumberGenerator.new()
    random.seed = 70742
    var trials: int = 0
    for config: Dictionary in registry["levels"]:
        await manager.go_to(str(config["id"]), str(config["spawns"].keys()[0]), {"instant": true})
        await physics_frame
        var solids: Array[StaticBody2D] = []
        for candidate: Node in get_nodes_in_group("surfaces"):
            if candidate is StaticBody2D and candidate.collision_layer == 1 and candidate.has_meta("surface_rect"):
                solids.append(candidate)
        for sample in range(40):
            var body: StaticBody2D = solids[random.randi_range(0, solids.size()-1)]
            if not body.has_meta("surface_rect"): continue
            var surface: Rect2 = body.get_meta("surface_rect")
            if body.collision_layer != 1 or surface.size.x < 50: continue
            hero.reset_run_state()
            hero.set_transition_locked(false)
            var at_right: bool = random.randf() < .5
            var edge_x: float = surface.end.x-2.0 if at_right else surface.position.x+2.0
            hero.global_position = Vector2(edge_x, surface.position.y+random.randf_range(1.0,8.0))
            trials += 1
            hero._recover_solid_overlap()
            var solid: bool = hero._hero_box().grow(-.2).intersects(hero._solid_box(body))
            _check(not solid, "Least-axis recovery beside " + str(config["id"]) + "/" + str(body.name))
    # In addition to overlap probes, exercise 600 real physics frames per level.
    # Enemies stay frozen so damage/knockback cannot disguise terrain stalls.
    Engine.physics_ticks_per_second = 120
    var incidents: Array[String] = []
    var simulated: int = 0
    for config: Dictionary in registry["levels"]:
        await manager.go_to(str(config["id"]), str(config["spawns"].keys()[0]), {"instant": true})
        hero.reset_run_state()
        hero.set_transition_locked(false)
        hero.stuck_recoveries.clear()
        hero.set_physics_process(true)
        root.get_node("GameState").set_weapon("axe")
        for tick in range(600):
            for input_name: String in ["move_left", "move_right", "jump", "crouch", "attack", "roll"]:
                Input.action_release(input_name)
            Input.action_press("move_left" if random.randf() < .5 else "move_right")
            if random.randf() < .12: Input.action_press("jump")
            if random.randf() < .12: Input.action_press("crouch")
            if random.randf() < .18: Input.action_press("attack")
            if random.randf() < .08: Input.action_press("roll")
            await physics_frame
            simulated += 1
        for incident in hero.stuck_recoveries:
            incidents.append(str(config["id"]) + ": " + str(incident))
        hero.set_physics_process(false)
        for input_name: String in ["move_left", "move_right", "jump", "crouch", "attack", "roll"]:
            Input.action_release(input_name)
    Engine.physics_ticks_per_second = 60
    var report := FileAccess.open("res://docs/STAGE7_STUCK_REPORT.txt", FileAccess.WRITE)
    report.store_string("\n".join(incidents))
    report.close()
    _check(incidents.is_empty(), "600 random physics frames per level have no terrain stall recoveries")
    print("STUCK_FUZZ: ", simulated, " random frames, ", incidents.size(), " stalls")
    await manager.go_to("CastleF2", "Spawn_FromBelow", {"instant":true})
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero.global_position = Vector2(900, 620)
    hero.last_safe_position = Vector2(850, 620)
    hero.stuck_origin = hero.global_position
    Input.action_press("move_right")
    for tick in range(41): hero._track_stuck(.02)
    Input.action_release("move_right")
    _check(hero.global_position.is_equal_approx(Vector2(850,620)) and not hero.stuck_recoveries.is_empty(), "0.8-second movement stall returns to the last safe position")
    print("STUCK_FUZZ: %d seeded corner probes across 25 levels" % trials)
    await _finish("STAGE7_STUCK_FUZZ")
