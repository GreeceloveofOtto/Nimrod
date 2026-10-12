extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    _check(not hero.cast_anur_light(),"R before acquisition does nothing")
    story_state.set_flag("skill_anur_light")
    _check(hero.cast_anur_light() and is_equal_approx(hero.skill_cooldown_left,5),"Unlock casts and starts five-second cooldown")
    _check(not hero.cast_anur_light(),"Cooldown blocks recast")
    for action in ["roll","hurt","attack"]:
        hero.action=action
        hero.skill_cooldown_left=0
        _check(not hero.cast_anur_light(),"Disallowed action "+action)
    hero.action="normal"
    await _go("CastleF1")
    hero.global_position=Vector2(500,620)
    hero.facing=1
    hero.modifiers.add_modifier("test",{"attack":.5})
    for x in [650,730,810]:
        var enemy: EnemyBase=load("res://scripts/enemy_melee_beast.gd").new()
        manager.current_level.add_child(enemy)
        enemy.global_position=Vector2(x,620)
        enemy.set_physics_process(false)
    hero.skill_cooldown_left=0
    _check(hero.cast_anur_light(),"Buffed light casts")
    await _wait(.5)
    var total:=0
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        total += 95-enemy.hp
    _check(total==108,"Projectile damages exactly two enemies for 54 each")
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        if enemy.hp<95:
            _check(is_equal_approx(enemy.stun_left,.2),"Light applies its own .2-second stun")
    hero.skill_cooldown_left=0
    hero.crouching=true
    _check(not hero.cast_anur_light(),"Crouch blocks light")
    hero.crouching=false
    manager.set_player_locked(true)
    _check(not hero.cast_anur_light(),"Dialogue/cutscene input lock blocks light")
    manager.set_player_locked(false)
    var wall:=StaticBody2D.new()
    var collider:=CollisionShape2D.new()
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(20,15)
    collider.shape=shape
    wall.add_child(collider)
    manager.current_level.add_child(wall)
    wall.global_position=Vector2(580,hero.global_position.y-84)
    await physics_frame
    var projectile:=AnurLightProjectile.new()
    projectile.hero=hero
    projectile.global_position=Vector2(550,hero.global_position.y-74)
    manager.current_level.add_child(projectile)
    await _wait(.15)
    _check(not is_instance_valid(projectile),"Projectile box edge hits a solid that its center ray would miss")
    var guard: EnemyBase=load("res://scripts/enemy_shell_scorpion.gd").new()
    manager.current_level.add_child(guard)
    guard.global_position=Vector2(950,620)
    guard.set_physics_process(false)
    guard.facing=1
    _check(guard.take_light_hit(36,guard.global_position+Vector2(100,0),.2)["blocked"] and guard.hp==75,"Light preserves shell's front guard")
    _check(guard.take_light_hit(36,guard.global_position-Vector2(100,0),.2)["damage_dealt"]==36,"Light damages shell from behind")
    var restart: InputEventKey=InputMap.action_get_events("restart")[0]
    var light: InputEventKey=InputMap.action_get_events("skill_light")[0]
    _check(restart.physical_keycode==KEY_F5 and light.physical_keycode==KEY_R,"Restart F5 and skill R bindings")
    hero.hp=60
    Input.action_press("restart")
    hero._physics_process(1.0/60.0)
    Input.action_release("restart")
    await manager.transition_finished
    _check(manager.current_level.level_id=="NimrodHome" and hero.hp==180,"F5 action returns home and restores HP")
    _check(not story_state.is_flag("skill_anur_light") and story_state.stage()==0 and hero.weapon=="none","F5 clears skill, story and weapon")
    await _finish("STAGE9_ANUR_LIGHT")
