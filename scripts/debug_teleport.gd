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
    if key.ctrl_pressed:return # Reserved for isolated room-world debug shortcuts.
    if key.physical_keycode == KEY_F9 and key.shift_pressed:
        await odyssey_debug("plaza")
        get_node("/root/SceneManager").player.global_position = Vector2(1890, 880)
        get_viewport().set_input_as_handled()
    elif key.physical_keycode == KEY_F4:
        if get_node("/root/GameState").active_character != "nimrod":return
        if not key.shift_pressed and not get_node("/root/Rampage").unlocked():get_node("/root/Rampage").unlock()
        var form: Node=get_node("/root/HumbabaForm")
        if key.shift_pressed:form.exit(false)
        else:
            get_node("/root/Rampage").set_death_suspended(true)
            get_node("/root/Rampage").set_value(100)
        get_viewport().set_input_as_handled()
    elif key.physical_keycode == KEY_Y:
        get_node("/root/SceneManager").player.debug_hp_floor = not get_node("/root/SceneManager").player.debug_hp_floor
        get_viewport().set_input_as_handled()
    elif key.physical_keycode == KEY_F8:
        await ferry_debug(false)
        get_viewport().set_input_as_handled()
    elif key.physical_keycode == KEY_F9:
        await ferry_debug(true)
        get_viewport().set_input_as_handled()
    elif key.physical_keycode in [KEY_F10,KEY_F11,KEY_F12]:
        await odyssey_debug("choice" if key.physical_keycode==KEY_F12 and key.shift_pressed else "plaza" if key.physical_keycode==KEY_F11 and key.shift_pressed else "utnapishtim" if key.physical_keycode==KEY_F10 and key.shift_pressed else "crown" if key.physical_keycode==KEY_F10 else "tiamat" if key.physical_keycode==KEY_F11 else "choice")
        get_viewport().set_input_as_handled()
    elif key.physical_keycode in [KEY_F6, KEY_F7]:
        var next: int = get_node("/root/Story").stage() + (1 if key.physical_keycode == KEY_F6 else -1)
        get_node("/root/Story").debug_stage(next)
        if next>=19:
            await odyssey_debug("plaza" if next>=20 else "choice")
            if next >= 20:
                get_node("/root/Story").debug_stage(next)
                get_node("/root/GameState").set_weapon("dagger" if next >= 21 else "none")
            get_viewport().set_input_as_handled()
            return
        get_node("/root/GameState").switch_character("nimrod")
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
    if level_id!="HwaniraPlaza":get_node("/root/GameState").switch_character("nimrod")
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

func odyssey_debug(destination: String) -> bool:
    var manager: Node=get_node("/root/SceneManager")
    if get_tree().paused or manager.player_locked or manager.is_transitioning:return false
    var story: Node=get_node("/root/Story")
    get_node("/root/GameState").switch_character("nimrod")
    story.debug_stage(18 if destination=="utnapishtim" else 19)
    var level_id: String="TiamatZone" if destination=="utnapishtim" else "HuluppuCrown" if destination=="crown" else "TiamatCollapsed"
    var spawn: String="Spawn_FromFerry" if destination=="utnapishtim" else "Spawn_Entrance" if destination=="crown" else "Spawn_Start"
    if destination=="plaza":
        story.debug_stage(20)
        get_node("/root/GameState").switch_character("siyavash")
        level_id="HwaniraPlaza"
        spawn="Spawn_Start"
    if destination in ["crown","utnapishtim"]:
        story.set_flag("utnapishtim_done",destination=="crown")
        story.set_flag("huluppu_boss_done",false)
        story.set_flag("tiamat_talk_done",false)
        get_node("/root/Rampage").set_death_suspended(true)
        get_node("/root/Rampage").set_value(60 if destination=="crown" else 50)
    if destination=="tiamat":story.set_flag("tiamat_talk_done",false)
    var succeeded: bool=await manager.go_to(level_id,spawn,{"instant":true,"debug_reload":true})
    if destination=="utnapishtim":manager.player.global_position=Vector2(1560,880)
    if destination=="choice":
        story.set_flag("choice_pending")
        manager._fade_rect.modulate.a=1
        get_node("/root/Choice").open_systems()
    manager.set_player_locked(false)
    return succeeded
