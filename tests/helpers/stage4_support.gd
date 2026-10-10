extends SceneTree

var checks: int = 0
var failures: int = 0
var manager: Node
var main: Node2D
var hero: NimrodPlayer

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    pass

func _check(value: bool, description: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("FAIL: " + description)

func _wait(seconds: float) -> void:
    await create_timer(seconds).timeout

func _freeze(_level: String) -> void:
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)

func _start() -> void:
    manager = root.get_node("SceneManager")
    manager.level_changed.connect(_freeze)
    main = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main
    await manager.transition_finished
    hero = manager.player
    hero.set_physics_process(false)

func _finish(label: String) -> void:
    manager.set_player_locked(true)
    manager.level_changed.disconnect(_freeze)
    root.get_node("Audio").stop_bgm(0.0)
    main.queue_free()
    current_scene = null
    await _wait(0.2)
    print("%s: %d checks, %d failures" % [label, checks, failures])
    quit(1 if failures else 0)
