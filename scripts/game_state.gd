extends Node

signal run_reset
signal weapon_changed(weapon: String)

var run_flags: Dictionary = {"weapon": "none"}

func first_time(key: String) -> bool:
    if run_flags.has(key):
        return false
    run_flags[key] = true
    return true

func reset_run(restart_world: bool = true) -> void:
    run_flags.clear()
    set_weapon("none")
    run_reset.emit()
    if restart_world:
        var manager: Node = get_node_or_null("/root/SceneManager")
        if manager != null and is_instance_valid(manager.player):
            await manager.restart_run(false)

func get_weapon() -> String:
    return str(run_flags.get("weapon", "none"))

func set_weapon(value: String) -> void:
    if value not in ["none", "staff", "axe"]:
        return
    run_flags["weapon"] = value
    weapon_changed.emit(value)

func visit_count(key: String, increment: bool = false) -> int:
    var flag: String = "visits_" + key
    if increment:
        run_flags[flag] = int(run_flags.get(flag, 0)) + 1
    return int(run_flags.get(flag, 0))
