extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    print("DEATHSEA starting")
    await _start9()
    print("DEATHSEA initial main ready")
    story_state.debug_stage(15)
    await _go("Dilmun")
    print("DEATHSEA Dilmun ready")
    var zone: Node = manager.current_level.get_node("TravelZone")
    _check(not await zone.interact() and manager.current_level.level_id=="Dilmun","Cannot cross without paper")
    story_state.set_flag("death_sea_paper")
    story_state.set_flag("shimati_done")
    print("DEATHSEA crossing")
    _check(await zone.interact(),"Paper enables crossing")
    await manager.transition_finished
    await process_frame
    await process_frame
    print("DEATHSEA arrived")
    _check(manager.current_level.level_id=="DeathSea" and story_state.stage()==17,"Arrival advances story")
    _check(manager.current_level.config["width"]==1800 and get_nodes_in_group("enemies").is_empty(),"Quiet island and no enemies")
    var npc: NPC = manager.current_level.npcs["urshanabi"]
    _check(npc.npc_id=="urshanabi" and npc._interaction_complete(),"Ferryman does not interact")
    _check(npc.clip_data["dice_loop"]["frames"]==8,"Dice loop has eight poses")
    _check(int(manager.current_level.config["walk_bounds"][0])==0 and int(manager.current_level.config["walk_bounds"][1])==1400,"Invisible walls enclose painted island")
    hero.global_position = Vector2(1380,880)
    hero.velocity = Vector2(360,0)
    for i in range(10):
        hero.move_and_slide()
        await physics_frame
    _check(hero.global_position.x<=1400,"Cannot walk into sea")
    await _finish("STAGE11_DEATHSEA")
