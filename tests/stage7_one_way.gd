extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
    for entry in registry["levels"]:
        for platform in entry.get("platforms", []):
            _check(bool(platform.get("one_way", false)), "Every platform is one-way: " + str(entry["id"]))
        await manager.go_to(str(entry["id"]), str(entry["spawns"].keys()[0]), {"instant": true})
        var platforms: int = 0
        for body: StaticBody2D in get_nodes_in_group("surfaces"):
            var shape: CollisionShape2D = body.get_child(0)
            if bool(body.get_meta("one_way", false)):
                platforms += 1
                _check(shape.one_way_collision and body.collision_layer == 2, "Platform collision uses one-way layer 2")
            else:
                _check(not shape.one_way_collision, "Solid floor/wall/ceiling remains solid")
        _check(platforms >= entry.get("platforms", []).size(), "Runtime builds all one-way platforms")
    await manager.go_to("CastleF2", "Spawn_FromBelow", {"instant": true})
    manager.current_level._make_surface(800, 500, 240, 16, true, 48)
    manager.current_level._make_surface(800, 524, 240, 16, true, 48)
    await physics_frame
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero.global_position = Vector2(900, 620)
    hero._physics_process(.02)
    Input.action_press("jump")
    hero._physics_process(1.0 / 60.0)
    var peak: float = hero.global_position.y
    for tick in range(100):
        await physics_frame
        hero._physics_process(1.0 / 60.0)
        peak = minf(peak, hero.global_position.y)
    Input.action_release("jump")
    await physics_frame
    _check(peak < 500 and absf(hero.global_position.y - 500) < 4, "Actual jump passes through both platforms and lands on their top")
    Input.action_press("crouch")
    Input.action_press("jump")
    hero.set_physics_process(true)
    await physics_frame
    await physics_frame
    hero.set_physics_process(false)
    Input.action_release("jump")
    Input.action_release("crouch")
    _check(hero.drop_mask_left > 0 and not hero.get_collision_mask_value(2), "S+Space disables the supporting platform layer")
    for tick in range(60):
        await physics_frame
        hero._physics_process(1.0 / 60.0)
    _check(absf(hero.global_position.y - 620) < 4 and hero.get_collision_mask_value(2), "Drop skips the thin stacked platform and restores collision on the floor")
    await _finish("STAGE7_ONE_WAY")
