extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(12)
    await _go("HomeFront")
    var boss: Gugalanna = get_nodes_in_group("enemies")[0]
    _check(boss.hp==2000 and boss.body_size==Vector2(380,420) and boss._turn_seconds()==.8,"Boss spec")
    _check(not boss.battle_started and manager.current_level.doors["home_gate"].locked,"Idle before dialogue, exit locked")
    await dialogue_node.play_interaction("gugalanna_intro",{"gugalanna":boss,"player":hero})
    boss._physics_process(.016)
    _check(boss.battle_started,"Dialogue begins battle")
    for id in ["uppercut","rake","charge"]:
        boss.position = Vector2(1600,880)
        boss.facing = -1
        boss.start_pattern(id)
        boss._set_state(EnemyBase.State.ACTIVE)
        hero.action = "normal"
        hero.transition_locked = false
        hero.damage_grace = 0
        hero.hp = 180
        hero.position = Vector2(1420,880)
        boss._update_active(.016)
        _check(hero.hp==180-int(boss.stats["patterns"][id]["damage"]),"Actual damage "+id)
    boss.start_pattern("rake")
    boss._set_state(EnemyBase.State.ACTIVE)
    hero.position = boss.position+Vector2(120,0) # boss faces left: behind is safe
    _check(not boss.attack_hits(hero),"Rake behind safe")
    hero.position = boss.position-Vector2(650,0)
    _check(not boss.attack_hits(hero),"Rake outside semicircle safe")
    hero.position = boss.position-Vector2(120,0)
    hero.action = "roll"
    hero.roll_clock = .1
    hero.hp = 180
    boss._update_active(.016)
    _check(hero.hp==180,"Roll iframe avoids rake")
    hero.action = "normal"
    hero.position = Vector2(1200,880)
    hero.set_physics_process(true)
    await physics_frame
    await physics_frame
    hero.set_physics_process(false)
    var quake: Node2D = load("res://scripts/gugalanna_quake.gd").new()
    quake.spec = boss.stats["patterns"]["stomp"]
    quake.position = Vector2(1200,880)
    manager.current_level.add_child(quake)
    _check(quake.eligible(hero),"Ground hero quake eligible")
    hero.damage_grace = 0
    hero.hp = 180
    quake._physics_process(.016)
    _check(hero.hp==162 and hero.hurt_duration==.5,"Ground quake18 and stun0.5")
    hero.global_position.y = 750
    _check(not quake.eligible(hero),"130px raised platform safe")
    hero.global_position.y = 700
    _check(not quake.eligible(hero),"Airborne safe")
    quake.queue_free()
    var before: int = boss.hp
    boss.take_hit(20,hero.position,1)
    _check(boss.hp==before-20 and boss.state!=EnemyBase.State.STUN,"Superarmor normal hit")
    boss.position = Vector2(2400,880)
    boss.facing = 1
    boss.start_pattern("charge")
    boss._set_state(EnemyBase.State.ACTIVE)
    boss._update_active(.1)
    _check(boss.crashed and boss.state==EnemyBase.State.STUN and is_equal_approx(boss.stun_left,1.2),"Wall/bound crash stun")
    boss.hp = 1000
    boss.start_pattern("rake")
    _check(boss.cooldowns["rake"]==12,"Half HP finisher cooldown12")
    boss._die()
    boss._update_dead(2.41)
    _check(story_state.is_flag("gugalanna_defeated") and manager.current_level.has_node("Helm"),"Death clip then helmet drop")
    await root.get_node("Chapter").event("helm")
    _check(hero.modifiers.modifiers.has("gugalanna_helm") and hero.get_max_hp()==215,"Helmet flat HP15")
    await _finish("STAGE10_GUGALANNA")
