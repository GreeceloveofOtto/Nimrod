extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(18)
    await _go("HuluppuCrown")
    var arena: Node=manager.current_level.get_node("Arena")
    var victim: EnemyBase=get_nodes_in_group("enemies")[0]
    var name_before: String=arena.rows[0]["name"]
    victim.take_fixed_damage(victim.hp,hero.global_position)
    # Simulate completed death animation and actual queue_free while others live.
    victim.queue_free()
    await process_frame
    await process_frame
    _check(not is_instance_valid(victim),"Boss reference is genuinely freed")
    for i in range(120):arena.update_bars()
    _check(arena.rows[0]["fill"].size.x==0,"Freed boss HUD safely becomes zero")
    _check(arena.rows[0]["label"].text==name_before+"  0","Cached name survives boss deletion")
    _check(not arena.finished,"Other live bosses prevent premature victory")
    var survivor: EnemyBase=get_nodes_in_group("enemies")[0]
    survivor.take_fixed_damage(survivor.hp,hero.global_position)
    survivor.queue_free()
    await process_frame
    arena.update_bars()
    _check(not arena.finished,"Second death also leaves the final boss active")
    var last: EnemyBase=get_nodes_in_group("enemies")[0]
    last.take_fixed_damage(last.hp,hero.global_position)
    await cutscene_node.completed
    _check(manager.current_level.level_id=="TiamatCollapsed","Victory still starts after all three deaths")
    await _finish("HULUPPU_FREED_HUD")
