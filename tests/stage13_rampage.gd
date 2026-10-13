extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var rage: Node=root.get_node("Rampage")
    story_state.debug_stage(18)
    await _go("TiamatZone")
    _check(dialogue_node.interaction_available("utnapishtim_talk"),"E enabled after arrival")
    var hp_before: int=hero.hp
    rage.set_death_suspended(true)
    rage.set_value(100)
    _check(hero.hp>=hp_before and hero.action!="dead" and not rage.death_queued,"100 suspension prevents only rage death")
    _check(hero.selected_sprite_set()=="axe_prosthetic_helm_r90","Highest rage sprite selected")
    await cutscene_node.play("utnapishtim_rampage")
    _check(story_state.is_flag("utnapishtim_done") and rage.value()==100 and rage.death_suspended,"Rage maintained until combat ends")
    var elder: NPC=manager.current_level.npcs["utnapishtim"]
    _check(elder.current_clip=="idle" and elder.position==Vector2(1650,880),"Old man remains standing, shake restored")
    _check(manager.current_level.has_node("UtnapishtimBlood"),"Blood pool persists")
    var pool_sprite: Sprite2D=manager.current_level.get_node("UtnapishtimBlood/Image")
    var blood_bbox: Rect2i=pool_sprite.texture.get_image().get_used_rect()
    var blood_foot: float=pool_sprite.global_position.y+float(blood_bbox.end.y)*pool_sprite.scale.y
    _check(absf(blood_foot-880)<=4,"Blood alpha bottom touches floor within4px")
    _check(not manager.player_locked and not paused,"Cutscene restores gameplay")
    _check(not dialogue_node.interaction_available("utnapishtim_talk"),"One-shot old man conversation")
    var climb: Node=manager.current_level.find_child("*",false,false)
    for child in manager.current_level.get_children():
        if child.get_script()==load("res://scripts/huluppu_interaction.gd"):climb=child
    _check(climb.available(),"Tree E activated only after rampage")
    story_state.set_flag("utnapishtim_done",false)
    _check(not climb.available(),"Tree E gated before rampage")
    await _finish("STAGE13_RAMPAGE")
