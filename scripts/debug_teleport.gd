extends Node

# Remove this file and its one autoload line to remove the debug shortcuts.
func _unhandled_input(event: InputEvent) -> void:
    if not GameConstants.ENABLE_DEBUG_TELEPORT or not event is InputEventKey:
        return
    var key := event as InputEventKey
    if not key.pressed or key.echo or get_tree().paused or get_node("/root/Dialogue").active or get_node("/root/SceneManager").is_transitioning or get_node("/root/SceneManager").player_locked:
        return
    if key.physical_keycode == KEY_1:
        teleport("CastleF1", "Spawn_Debug")
        get_viewport().set_input_as_handled()
    elif key.physical_keycode == KEY_2:
        teleport("VillaF1", "Spawn_FromGate")
        get_viewport().set_input_as_handled()

func teleport(level_id: String, spawn_name: String) -> bool:
    if get_tree().paused or get_node("/root/Dialogue").active or get_node("/root/SceneManager").is_transitioning or get_node("/root/SceneManager").player_locked:
        return false
    return await get_node("/root/SceneManager").go_to(level_id, spawn_name, {"instant": true})
