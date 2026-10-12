extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(7)
    story_state.set_flag("arm_lost")
    await _go("CedarBossRoom")
    var boss: Humbaba = get_nodes_in_group("enemies")[0]
    boss._die()
    _check(manager.current_level.doors["boss_arrival"].locked,"Death keeps exit locked until absorption")
    boss._update_dead(1.59)
    _check(not manager.current_level.has_node("Melammu"),"Drop waits for death clip")
    boss._update_dead(.02)
    _check(manager.current_level.has_node("Melammu"),"Exactly one Melammu after death")
    hero.hp = 40
    manager.current_level.get_node("Melammu").interact()
    await cutscene_node.completed
    await process_frame
    _check(story_state.is_flag("melammu_absorbed") and story_state.is_flag("melammu"),"Absorption flags")
    _check(hero.get_max_hp()==200 and is_equal_approx(hero.modifiers.multiplier("attack"),1.1),"Permanent flat HP20 and attack10 percent")
    _check(manager.current_level.level_id=="NimrodHome" and is_equal_approx(hero.position.x,470),"Automatic home arrival")
    _check(manager.current_level.doors["home_exit"].locked,"Critical home scene cannot be skipped by exit")
    await _finish("STAGE10_MELAMMU")
