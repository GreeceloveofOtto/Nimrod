extends Node

signal run_reset

var run_flags: Dictionary = {}

func first_time(key: String) -> bool:
    if run_flags.has(key):
        return false
    run_flags[key] = true
    return true

func reset_run() -> void:
    run_flags.clear()
    run_reset.emit()
