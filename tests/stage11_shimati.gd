extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(15)
    await _go("Dilmun")
    var npc: NPC = manager.current_level.npcs["shimati"]
    _check(npc.npc_id=="shimati" and not npc._interaction_complete(),"Traveller interaction before paper")
    await dialogue_node.play_interaction("shimati_intro")
    await _wait(.12)
    _check(story_state.is_flag("death_sea_paper") and story_state.is_flag("shimati_done"),"Paper transfer and disappearance complete flags")
    _check(not is_instance_valid(npc),"Shimati fades and despawns")
    _check(not manager.player_locked and not paused and not cutscene_node.active,"End restores movement")
    await _go("CastleF1")
    await _go("Dilmun")
    _check(manager.current_level.npcs.is_empty(),"Traveller never reappears in same run")
    var stall: bool=false
    for prop: Dictionary in manager.current_level.config["decorations"]:
        stall = stall or "shimati_stall" in prop["path"]
    _check(stall,"Stall remains after traveller departure")
    await _finish("STAGE11_SHIMATI")
