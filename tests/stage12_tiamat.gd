extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var debug: Node = root.get_node("DebugTeleport")
    _check(await debug.ferry_debug(true),"Debug Tiamat warp succeeds")
    _check(hero.position.distance_to(manager.current_level.get_spawn("Spawn_FromFerry").position)<1 and not manager.player_locked,"Debug uses dock spawn and returns control")
    _check(story_state.stage()==18 and manager.current_level.config["enemies"].is_empty(),"Stage18 has no combat")
    var old: NPC = manager.current_level.npcs["utnapishtim"]
    _check(old.interactable and not old.three_way and not old.face_player and dialogue_node.interaction_available("utnapishtim_talk"),"Stage13 adds gated dialogue to the existing front-facing set")
    _check(old.current_clip=="idle" and old.clip_data["idle"]["frames"]==6,"Six-frame front breathing loop")
    var cell: Image=old.visual.texture.get_image().get_region(Rect2i(old.visual.region_rect))
    var npc_foot_y: float=old.visual.to_global(old.visual.get_rect().position+Vector2(0,cell.get_used_rect().end.y)).y
    _check(absf(npc_foot_y-880)<=4,"Old man alpha footprint is grounded within4px")
    for prop_name in ["Huluppu","HermitHouse","FerryBoat"]:
        var prop: Node = manager.current_level.get_node(prop_name)
        var image: Sprite2D = prop.get_node("Image")
        _check(image.texture!=null,"Loaded "+prop_name)
        if prop_name!="FerryBoat":
            var foot: Rect2i = image.texture.get_image().get_used_rect()
            var bottom: float = image.global_position.y+(foot.end.y)*image.scale.y
            _check(absf(bottom-880)<=4,"Prop alpha footprint at floor: "+prop_name)
    _check(hero.get_node("TiamatSight")!=null,"Player reuses generated glow for visibility")
    _check(await debug.ferry_debug(false),"Debug ferryman warp succeeds")
    _check(story_state.stage()==17 and story_state.is_flag("death_sea_paper"),"Debug supplies paper to test whole dialogue")
    _check(not manager.current_level.npcs["urshanabi"]._interaction_complete(),"Ferryman E is available before boarding")
    await _finish("STAGE12_TIAMAT")
