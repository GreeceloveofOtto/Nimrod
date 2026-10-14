extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    world.timing_scale=.001
    var event:=InputEventKey.new()
    event.pressed=true
    event.ctrl_pressed=true
    event.physical_keycode=KEY_1
    world.map_ui._unhandled_input(event)
    await world.room_changed
    _check(world.active and world.current_id=="landing_00" and root.get_node("GameState").active_character=="siyavash","World debug entry from plaza")
    event.physical_keycode=KEY_8
    world.map_ui._unhandled_input(event)
    await world.room_changed
    _check(world.current_id=="crystal_00" and not manager.player_locked,"Region shortcut keeps control")
    event.physical_keycode=KEY_M
    world.map_ui._unhandled_input(event)
    _check(not world.map_ui.minimap_enabled and not paused and not world.map_ui.opened,"CtrlM toggles only minimap")
    event.ctrl_pressed=false
    world.map_ui._unhandled_input(event)
    _check(world.map_ui.opened and paused,"Map pauses gameplay")
    world.map_ui._unhandled_input(event)
    _check(not world.map_ui.opened and not paused,"Map closes and restores gameplay")
    await _go("HwaniraPlaza")
    _check(hero.camera.position_smoothing_enabled,"Camera smoothing restored after world")
    _finish("stage14_map_debug")
