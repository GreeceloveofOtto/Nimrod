extends Node

# Remove this file and its one autoload line to remove the debug shortcuts.
func _unhandled_input(event: InputEvent) -> void:
    if get_node("/root/Dialogue").input_blocked():
        return
    if not GameConstants.ENABLE_DEBUG_TELEPORT or not event is InputEventKey:
        return
    var key := event as InputEventKey
    if not key.pressed or key.echo or get_tree().paused or get_node("/root/Dialogue").active or get_node("/root/SceneManager").is_transitioning or get_node("/root/SceneManager").player_locked:
        return
    if key.physical_keycode == KEY_Y:
        get_node("/root/SceneManager").player.debug_hp_floor = not get_node("/root/SceneManager").player.debug_hp_floor
        get_viewport().set_input_as_handled()
    elif key.physical_keycode == KEY_F8:
        await ferry_debug(false)
        get_viewport().set_input_as_handled()
    elif key.physical_keycode == KEY_F9:
        await ferry_debug(true)
        get_viewport().set_input_as_handled()
    elif key.physical_keycode in [KEY_F6, KEY_F7]:
        var next: int = get_node("/root/Story").stage() + (1 if key.physical_keycode == KEY_F6 else -1)
        get_node("/root/Story").debug_stage(next)
        var level: LevelBase = get_node("/root/SceneManager").current_level
        var at: Vector2 = get_node("/root/SceneManager").player.global_position
        await get_node("/root/SceneManager").go_to(level.level_id, str(level.config["spawns"].keys()[0]), {"instant":true,"debug_reload":true})
        get_node("/root/SceneManager").player.global_position = at
        get_node("/root/SceneManager").show_toast("스토리 단계 %d" % get_node("/root/Story").stage())
        get_viewport().set_input_as_handled()
    elif key.physical_keycode == KEY_1:
        teleport("CastleF1", "Spawn_Debug")
        get_viewport().set_input_as_handled()
    elif key.physical_keycode == KEY_2:
        teleport("VillaF1", "Spawn_FromGate")
        get_viewport().set_input_as_handled()

func teleport(level_id: String, spawn_name: String) -> bool:
    if get_tree().paused or get_node("/root/Dialogue").active or get_node("/root/SceneManager").is_transitioning or get_node("/root/SceneManager").player_locked:
        return false
    return await get_node("/root/SceneManager").go_to(level_id, spawn_name, {"instant": true})

func ferry_debug(arrived: bool) -> bool:
    if get_tree().paused or get_node("/root/SceneManager").player_locked or get_node("/root/SceneManager").is_transitioning:
        return false
    var story: Node = get_node("/root/Story")
    story.debug_stage(18 if arrived else 17)
    var manager: Node = get_node("/root/SceneManager")
    var succeeded: bool = await manager.go_to("TiamatZone" if arrived else "DeathSea","Spawn_FromFerry" if arrived else "Spawn_DebugUrshanabi",{"instant":true,"debug_reload":true})
    manager.set_player_locked(false)
    return succeeded
