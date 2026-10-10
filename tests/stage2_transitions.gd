extends SceneTree

var checks: int = 0
var failures: int = 0
var manager: Node
var state: Node
var audio: Node
var game: Node
var hero: NimrodPlayer
var player_id: int

func _initialize() -> void:
    _run.call_deferred()

func _check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("FAIL: " + label)

func _wait_arrival(level_id: String, timeout: float = 12.0) -> bool:
    var deadline: int = Time.get_ticks_msec() + roundi(timeout * 1000.0)
    while Time.get_ticks_msec() < deadline:
        if is_instance_valid(manager.current_level) and str(manager.current_level.level_id) == level_id and not manager.is_transitioning and not manager.player_locked:
            return true
        await process_frame
    _check(false, "transition timed out: " + level_id)
    return false

func _seed_state() -> void:
    hero.hp = 137
    hero.action = "roll"
    hero.roll_clock = 0.19
    hero.combo_left = 0.51
    hero.damage_grace = 0.33
    hero.velocity = Vector2(220.0, -65.0)
    hero.facing = -1
    hero._show_clip("roll", hero.roll_clock)

func _check_state(label: String) -> void:
    _check(hero.hp == 137, label + ": HP preserved")
    _check(hero.action == "roll" and is_equal_approx(hero.roll_clock, 0.19), label + ": roll preserved")
    _check(is_equal_approx(hero.combo_left, 0.51) and is_equal_approx(hero.damage_grace, 0.33), label + ": timers frozen")
    _check(hero.velocity == Vector2(220.0, -65.0) and hero.facing == -1, label + ": velocity and facing preserved")

func _travel(door_id: String, target: String, arrival: String) -> void:
    var door: Node2D = manager.current_level.doors.get(door_id)
    _check(door != null, "departure door exists: " + door_id)
    if door == null:
        return
    hero.global_position = door.global_position
    _seed_state()
    door.interact(hero)
    _check(manager.player_locked and not manager.is_transitioning, "door locks before scene fade: " + door_id)
    _check(not hero.receive_damage(50, {"stagger": false, "grant_grace": false}), "entry invulnerability: " + door_id)
    await create_timer(0.10).timeout
    _check_state("opening " + door_id)
    var arrived: String = await manager.transition_finished
    _check(arrived == target, "door reaches target: " + target)
    # Signal delivery lets us check the exact unlock frame before physics resumes.
    _check(hero.get_instance_id() == player_id and get_nodes_in_group("player").size() == 1, "single persistent player: " + target)
    _check_state("arrival " + target)
    var target_door: Node = manager.current_level.find_arrival_door(arrival)
    _check(target_door != null and is_zero_approx(target_door.open_progress), "arrival door closes: " + target)
    var marker: Marker2D = manager.current_level.get_spawn(arrival)
    var expected: Vector2 = marker.global_position
    if expected.is_equal_approx(target_door.global_position):
        expected.x += float(target_door.exit_direction) * float(target_door.config["arrival_step"])
    _check(hero.global_position.is_equal_approx(expected), "correct arrival spawn and outward step: " + target)
    _check(hero.camera.limit_right == roundi(manager.current_level.camera_limits.end.x), "camera limit: " + target)
    _check(not hero.transition_locked and is_equal_approx(hero.modulate.a, 1.0), "arrival restores input and visibility: " + target)

func _run() -> void:
    manager = root.get_node("SceneManager")
    state = root.get_node("GameState")
    audio = root.get_node("Audio")
    game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    if not await _wait_arrival("RearGate"):
        quit(1)
        return
    hero = manager.player
    player_id = hero.get_instance_id()
    _check(hero.global_position.x == 260.0 and hero.hp == 180, "initial RearGate Spawn_Start")
    _check(game.get_node("Player") == hero and game.get_node("LevelRoot").get_child_count() == 1, "Main owns one actor and one level")
    _check(state.first_time("transition_test_once"), "first_time first call")
    _check(not state.first_time("transition_test_once"), "first_time repeat call")
    await _travel("rear_gate_exterior", "CastleF1", "Spawn_FromRearGate")
    var bgm: AudioStreamPlayer = audio.get("_bgm")
    var castle_stream: AudioStream = bgm.stream
    var castle_position: float = bgm.get_playback_position()
    await _travel("door_up", "CastleF2", "Spawn_FromBelow")
    _check(bgm.stream == castle_stream and bgm.get_playback_position() > castle_position, "CastleF1 to F2 keeps the same BGM playback")
    await _travel("door_up", "CastleF3", "Spawn_FromBelow")
    await _travel("door_up", "CastleF4", "Spawn_FromBelow")
    _check(bgm.stream == castle_stream, "CastleF1 through F4 keeps castle_hall")
    await _travel("door_up", "CastleF5", "Spawn_FromBelow")
    _check(str(audio.get("_bgm_name")) == "uruk_sky", "rooftop changes BGM")
    await _travel("door_down", "CastleF4", "Spawn_FromAbove")
    await _travel("door_down", "CastleF3", "Spawn_FromAbove")
    await _travel("door_down", "CastleF2", "Spawn_FromAbove")
    await _travel("door_down", "CastleF1", "Spawn_FromAbove")
    await _travel("castle_rear_interior", "RearGate", "Spawn_FromCastle")
    _seed_state()
    _check(await manager.go_to("VillaF1", "Spawn_FromGate"), "VillaF1 direct arrival succeeds")
    _check_state("arrival VillaF1")
    _check(str(audio.get("_bgm_name")) == "villa_calm", "villa changes BGM")
    await _travel("villa_exit", "RearGate", "Spawn_FromVilla")
    _check(hero.global_position.x == 5050.0, "villa return spawn is near gatekeeper")
    await manager.go_to("VillaF1", "Spawn_FromGate")
    hero.reset_run_state()
    state.run_flags["must_clear_on_death"] = true
    _check(hero.receive_damage(180), "lethal damage accepted")
    await create_timer(1.2).timeout
    _check(hero.action == "dead" and str(manager.current_level.level_id) == "VillaF1", "death waits for original 1.6 second timer")
    var death_destination: String = await manager.transition_finished
    _check(death_destination == "RearGate", "death returns to RearGate")
    _check(hero.hp == 180 and is_equal_approx(hero.global_position.x, 260.0), "death restores HP180 at x260")
    _check(hero.get_instance_id() == player_id, "death keeps the persistent player")
    _check(not state.run_flags.has("must_clear_on_death"), "death clears run flags")
    _check(hero.combo_next == 1 and hero.action == "normal", "death clears combat action and combo")
    hero.hp = 50
    state.run_flags["must_clear_on_restart"] = true
    Input.action_press("restart")
    await create_timer(0.04).timeout
    Input.action_release("restart")
    var restart_destination: String = await manager.transition_finished
    _check(restart_destination == "RearGate", "R completes restart")
    _check(hero.hp == 180 and not state.run_flags.has("must_clear_on_restart"), "R restores HP and clears run flags")
    manager.set_player_locked(true)
    game.queue_free()
    for child in audio.get_children():
        if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
            child.stop()
    await create_timer(0.15).timeout
    print("Stage 2 transition regression: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
