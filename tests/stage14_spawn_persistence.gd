extends "res://tests/helpers/stage9_support.gd"
func enemy_children(parent: Node) -> Array[EnemyBase]:
    var actors: Array[EnemyBase]=[]
    for child in parent.get_children():
        if child is EnemyBase:actors.append(child)
    return actors
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    world.invulnerable=true
    await world.enter()
    hero.set_physics_process(false)
    var holder:=Node2D.new()
    manager.current_level.add_child(holder)
    var spec: Dictionary={"uid":"qa_normal_uid","id":"cedar_sentinel","type":"enemy","region":"landing","position":[12000,608],"patrol":96}
    world.spawn_entity(spec,holder)
    _check(enemy_children(holder).size()==1,"Normal enemy instantiated from world data")
    var enemy: EnemyBase=enemy_children(holder)[0]
    enemy.no_drop=true
    world.update_sleep(hero)
    _check(not enemy.is_physics_processing(),"Distant enemy physics sleeps")
    enemy.global_position=hero.global_position+Vector2(400,0)
    world.update_sleep(hero)
    _check(enemy.is_physics_processing(),"Enemy wakes inside activation radius")
    enemy.take_fixed_damage(99999,enemy.global_position+Vector2(100,0))
    _check(enemy.hp<=0 and world.defeated.has("qa_normal_uid"),"Actual enemy death commits attempt UID")
    manager.current_level.remove_child(holder)
    holder.queue_free()
    await process_frame
    await process_frame
    var next_holder:=Node2D.new()
    manager.current_level.add_child(next_holder)
    world.spawn_entity(spec,next_holder)
    _check(enemy_children(next_holder).is_empty(),"Retired chunk cannot respawn a defeated enemy")
    var boss_spec: Dictionary={"uid":"qa_boss_uid","id":"humbaba","type":"boss","region":"landing","position":[500,608],"patrol":256,"display_name":"검증 수호자","placeholder":true}
    world.spawn_entity(boss_spec,next_holder)
    _check(enemy_children(next_holder).size()==1,"Existing boss sheet reused")
    var boss: EnemyBase=enemy_children(next_holder)[0]
    hero.position+=Vector2(700,0)
    boss.global_position=hero.global_position+Vector2(400,0)
    boss._physics_process(0)
    _check(boss.battle_started,"Boss activates near player")
    boss.take_fixed_damage(99999,boss.global_position+Vector2(100,0))
    _check(world.bosses.has("qa_boss_uid"),"Boss death commits permanent UID")
    var before: Dictionary=world.persistent_data()
    _check(before.defeated_bosses.has("qa_boss_uid") and not before.has("qa_normal_uid"),"Save retains bosses and excludes normal attempt kills")
    await _go("HwaniraPlaza")
    await world.enter()
    var returned:=Node2D.new()
    manager.current_level.add_child(returned)
    world.spawn_entity(spec,returned)
    world.spawn_entity(boss_spec,returned)
    _check(enemy_children(returned).size()==1 and enemy_children(returned)[0].enemy_id=="cedar_sentinel","New descent resets normal enemies and retains defeated bosses")
    await _go("HwaniraPlaza")
    hero.set_physics_process(true)
    _finish("stage14_spawn_persistence")
