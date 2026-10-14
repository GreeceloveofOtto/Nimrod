extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var save: Node = root.get_node("Save")
    save.save_path="user://stage14_test.json"
    _check(save.save_checkpoint("character"),"Plaza checkpoint")
    var original: String = FileAccess.get_file_as_string(save.save_path)
    var world: Node = root.get_node("World")
    world.timing_scale=.01
    _check(await world.enter("landing_00","left",false),"Generic room entry")
    _check(world.loaded.size()<=5 and manager.current_level is WorldRoom,"Current plus cardinal neighbors")
    _check(hero.weapon=="dagger" and hero.get_max_hp()==100,"Dagger preserved and HP100")
    _check(not save.can_save() and not save.save_checkpoint("character") and not save.save_game(true) and not save._write_snapshot(true),"Every save path denied")
    _check(FileAccess.get_file_as_string(save.save_path)==original,"Disk checkpoint unchanged")
    _check(manager.current_level.enemies.size()>=15,"Dense existing cedar enemies")
    _check(manager.current_level.collision_count<160,"Merged collider budget")
    for id in world.abilities_data.abilities:_check(world.acquire(str(id)),"Ability altar "+str(id))
    world.fragments=20
    world.crystals=5
    _check(hero.get_max_hp()==150,"Four life fragments grant10HP")
    hero.position=Vector2(1200,1320)
    hero.hp=1
    hero.set_physics_process(true)
    _check(hero.receive_damage(999),"Actual player death accepted outside entry sanctuary")
    await world.room_changed
    _check(hero.action=="normal" and hero.hp==150 and world.fragments==20,"Death animation automatically respawns with session state")
    hero.set_physics_process(false)
    var old_id: String = world.current_id
    await world.respawn()
    _check(world.current_id==old_id and world.fragments==20 and world.crystals==5 and world.abilities.size()==7,"Session respawn retains exploration")
    _check(hero.hp==150 and hero.action=="normal","Respawn heals and unlocks")
    var maximum_loaded := 0
    var start_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
    for id in ["forest_00","fortress_12","ridge_25","mine_19","village_00","marsh_20","crystal_29","skywalk_21","deep_28","landing_00"]:
        _check(await world.enter(id,"left",false),"Region loading "+id)
        await process_frame
        await process_frame
        maximum_loaded=maxi(maximum_loaded,world.loaded.size())
        world.update_sleep(manager.current_level,hero)
        _check(world.active_enemies<=24,"At most24 active")
        _check(manager.current_level.get_child_count()<400,"Room node bound")
    _check(maximum_loaded<=5,"Repeated streaming bound")
    print("WORLD_PERFORMANCE: nodes_start=",start_nodes," nodes_final=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," loaded=",world.loaded.size()," load_ms=",world.last_load_ms)
    _check(await save.resume(),"Resume plaza checkpoint")
    _check(not world.active and world.abilities.is_empty() and manager.current_level.level_id=="HwaniraPlaza" and hero.weapon=="dagger","Disk resume discards world session")
    save.erase_save()
    _finish("stage14_world_runtime")
