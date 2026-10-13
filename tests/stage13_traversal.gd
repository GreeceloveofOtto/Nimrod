extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(18)
    story_state.set_flag("utnapishtim_done")
    root.get_node("Rampage").set_death_suspended(true)
    root.get_node("Rampage").set_value(100)
    await _go("TiamatZone")
    await cutscene_node.play("huluppu_climb")
    _check(manager.current_level.level_id=="HuluppuCrown" and not manager.player_locked and not paused,"Climb fades to branch arena and restores control")
    _check(hero.selected_sprite_set()=="axe_prosthetic_helm_r90" and root.get_node("Rampage").death_suspended,"Rage100 r90 persists in combat")
    var layout: Dictionary=manager.current_level.config
    _check(layout["width"]==3200 and layout["platforms"].size()>=8,"Multi-tier branch arena")
    _check(not root.get_node("Save").can_save() and not root.get_node("Save").save_checkpoint("rampage"),"No save during boss fight")
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        _check(enemy.textures.size()>=9,"Generated boss clips loaded")
        enemy.take_fixed_damage(enemy.hp,hero.global_position)
    await cutscene_node.completed
    _check(story_state.is_flag("huluppu_boss_done") and manager.current_level.level_id=="TiamatCollapsed","All three bosses defeated transitions without dialogue")
    _check(not manager.current_level.has_node("HermitHouse") and not manager.current_level.npcs.has("utnapishtim"),"Collapsed world contains no house or old man")
    _check(is_equal_approx(manager.current_level.get_node("CollapsedHuluppu").rotation,PI*.5),"Reuse trunk rotated90 degrees")
    _check(not root.get_node("Rampage").death_suspended and root.get_node("Rampage").value()==90,"Rage safe at end of combat")
    await _finish("STAGE13_TRAVERSAL")
