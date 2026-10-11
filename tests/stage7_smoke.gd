extends "res://tests/helpers/stage4_support.gd"

func _freeze(_level: String) -> void:
    pass

func _run() -> void:
    await _start(false)
    Engine.physics_ticks_per_second = 120
    var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
    var random := RandomNumberGenerator.new()
    random.seed = 7072026
    for config: Dictionary in registry["levels"]:
        var spawn: String = str(config["spawns"].keys()[0])
        await manager.go_to(str(config["id"]), spawn, {"instant": true})
        hero.set_physics_process(true)
        root.get_node("GameState").set_weapon("axe")
        var ticks: int = 0
        while ticks < 600:
            for action_name: String in ["move_left", "move_right", "attack", "roll", "jump", "crouch"]:
                Input.action_release(action_name)
            if ticks % 30 == 0:
                hero.hp = 180
                if hero.action == "dead":
                    hero.reset_run_state()
                    hero.set_transition_locked(false)
            var direction: String = "move_left" if random.randf() < .5 else "move_right"
            Input.action_press(direction)
            if random.randf() < .25: Input.action_press("attack")
            if random.randf() < .10: Input.action_press("roll")
            if random.randf() < .10: Input.action_press("jump")
            if random.randf() < .08: Input.action_press("crouch")
            await physics_frame
            ticks += 1
            _check(is_finite(hero.global_position.x) and is_finite(hero.global_position.y), "Finite position in " + str(config["id"]))
        hero.set_physics_process(false)
        for action_name: String in ["move_left", "move_right", "attack", "roll", "jump", "crouch"]:
            Input.action_release(action_name)
        print("SMOKE: ", config["id"], " 600 random physics ticks")
    Engine.physics_ticks_per_second = 60
    await _finish("STAGE7_SMOKE")
