extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(15)
    await _go("CastleF1")
    hero.position = Vector2(600,620)
    hero.facing = 1
    _check(not hero.try_devour() and hero.devour_cooldown_left==0,"No target means no skill or cooldown")
    var enemy: EnemyBase = load("res://scripts/enemy_shell_scorpion.gd").new()
    manager.current_level.add_child(enemy)
    enemy.position = Vector2(740,620)
    enemy.facing = -1
    enemy.hp = 400
    enemy.set_physics_process(false)
    hero.modifiers.add_modifier("test",{"attack":4,"attack_speed":1})
    _check(hero.try_devour(),"Valid nearest forward target starts devour")
    _check(hero.devour_cooldown_left==15 and root.get_node("Rampage").value()==12,"Fixed cooldown and gain")
    hero._update_devour(.36)
    _check(enemy.hp==250,"Fixed 150 bypasses frontal guard and all modifiers")
    hero._update_devour(.4)
    _check(hero.action=="normal" and not hero.try_devour(),"Recovery ends and cooldown rejects repeated use")
    var body: EnemyBase = load("res://scripts/enemy_gugalanna.gd").new()
    manager.current_level.add_child(body)
    body.position = Vector2(800,880)
    body.set_physics_process(false)
    var result: Dictionary = body.take_fixed_damage(150,hero.position)
    _check(result["damage_dealt"]==0,"Cinematic boss invulnerability is respected")
    body.battle_started = true
    result = body.take_fixed_damage(150,hero.position)
    _check(body.hp==1850 and result["damage_dealt"]==150,"Boss receives unmodified fixed damage")
    for action in ["roll","hurt","attack"]:
        hero.action = action
        hero.devour_cooldown_left = 0
        _check(not hero.try_devour(),"Cannot devour in "+action)
    hero.action = "normal"
    root.get_node("Rampage").set_value(50)
    enemy.hp = 50
    enemy.take_fixed_damage(150,hero.position)
    _check(root.get_node("Rampage").value()==50,"Devour death never counts as a basic kill")
    await _finish("STAGE11_DEVOUR")
