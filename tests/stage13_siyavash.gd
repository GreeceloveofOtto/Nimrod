extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var state: Node=root.get_node("GameState")
    story_state.debug_stage(18)
    var original: Dictionary=state.run_flags.duplicate(true)
    state.switch_character("siyavash")
    await _go("HwaniraPlaza")
    _check(hero.get_max_hp()==100 and hero.weapon=="none" and hero.max_step==0,"Character-specific HP and empty weapon")
    _check(hero.sprite_set=="siyavash" and hero.clip_data.size()==17 and not hero.clip_data.has("attack_1"),"Seventeen movement clips; no attack")
    _check(not hero.cast_anur_light() and not hero.try_devour() and not root.get_node("Rampage").unlocked(),"Nimrod powers inactive")
    for key in original:_check(state.run_flags.get(key)==original[key],"Nimrod flag retained: "+str(key))
    for node in manager.current_level.find_children("Image","Sprite2D",true,false):_check(node.texture!=null,"Plaza texture loads")
    _check(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("npcs").size()==6,"Exploration plaza with six noncombat heroes")
    var save: Node=root.get_node("Save")
    save.save_path="user://stage13_siya.json"
    hero.position=Vector2(2100,880)
    hero.hp=37
    state.siyavash_progress["visited"]=true
    _check(save.save_checkpoint("character"),"Quiet character checkpoint")
    _check(await save.resume(),"Character save loads")
    _check(hero.hp==37 and hero.position==Vector2(2100,880) and state.active_character=="siyavash" and state.siyavash_progress["visited"],"Restores character, HP, position and separate progress")
    var old: Dictionary=save.snapshot_data()
    old.erase("active_character")
    old.erase("siyavash_progress")
    old.erase("nimrod_status")
    old.erase("choice_pending")
    old.erase("selected_system")
    _check(save.migrate_save(old)["active_character"]=="nimrod","Stage12 save defaults compatible")
    hero._request_run_restart()
    await manager.transition_finished
    _check(state.active_character=="nimrod" and state.siyavash_progress.is_empty() and story_state.stage()==0 and hero.hp==180 and not FileAccess.file_exists(save.save_path),"F5 completely resets both characters and disk save")
    await _finish("STAGE13_SIYAVASH")
