extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var save: Node = root.get_node("Save")
    save.save_path = "user://stage12_reset.json"
    await _go("CastleF2")
    story_state.debug_stage(17)
    root.get_node("Rampage").set_value(50)
    _check(save.save_game() and save.save_game(),"Create primary and backup")
    hero.debug_hp_floor = true
    # Use the actual F5 route: the player schedules SceneManager.full_reset_run.
    hero._request_run_restart()
    await manager.transition_finished
    _check(manager.current_level.level_id=="NimrodHome","F5 starts at home")
    _check(not FileAccess.file_exists(save.save_path) and not FileAccess.file_exists(save.save_path+".bak"),"F5 deletes both primary and backup")
    _check(root.get_node("GameState").get_weapon()=="none" and story_state.stage()==0 and not root.get_node("Rampage").unlocked(),"Story/weapon/rampage reset")
    _check(not hero.debug_hp_floor and hero.hp==180 and hero.skill_cooldown_left==0 and hero.devour_cooldown_left==0,"HP/skills/debug reset")
    _check(not await save.resume(),"Deleted save cannot be resurrected")
    _check(InputMap.action_has_event("restart",_key(KEY_F5)),"F5 binding retained")
    await _finish("STAGE12_FULL_RESET")
func _key(code: int) -> InputEventKey:
    var key:=InputEventKey.new()
    key.physical_keycode=code
    return key
