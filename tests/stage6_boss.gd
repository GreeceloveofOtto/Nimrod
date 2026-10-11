extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    await manager.go_to("CedarBossRoom","Spawn_FromForest")
    var boss: KalaUshumgal = get_first_node_in_group("enemies") as KalaUshumgal
    boss.set_physics_process(false)
    hero.set_transition_locked(false)
    hero.global_position.x = 450
    boss._physics_process(0)
    _check(boss.battle_started and manager.current_level.doors["boss_arrival"].locked,"Crossing450 starts battle and locks arrival")
    boss._set_state(EnemyBase.State.IDLE)
    boss.facing = 1
    var hit: Dictionary = boss.take_hit(20,Vector2(1100,400),1)
    _check(hit["damage_dealt"]==14 and boss.hp == 1186,"Upper front armor scales0.7")
    hit = boss.take_hit(20,Vector2(700,400),1)
    _check(hit["damage_dealt"]==20,"Rear full damage")
    hit = boss.take_hit(20,Vector2(1100,780),1)
    _check(hit["damage_dealt"]==20 and boss.state != EnemyBase.State.STUN,"Lower front full damage, boss superarmor")
    _check(boss.hitstop_left == .05 and boss.stats["knockback_multiplier"]==.2,"Boss hitstop and knockback20percent")
    boss.set_hit_contact(Vector2(1100,400))
    _check(boss.take_hit(20,Vector2(1100,780),1)["damage_dealt"]==14,"Actual upper contact applies armor regardless of attacker feet")
    boss.set_hit_contact(Vector2(1100,780))
    _check(boss.take_hit(20,Vector2(1100,400),1)["damage_dealt"]==20,"Actual lower contact bypasses upper armor")
    boss.hp = 600
    boss._set_state(EnemyBase.State.CHASE)
    boss._update_chase(0)
    _check(boss.phase == "phase_transition","HP600 begins phase transition")
    var before: int = boss.hp
    boss.take_hit(100,Vector2(700,500),1)
    _check(boss.hp == before,"Phase transition invulnerable")
    boss.state_clock = 2
    boss._update_windup(0)
    _check(boss.phase_two and boss._turn_seconds()==.5 and is_equal_approx(boss._time_factor(),1.0/1.2),"Phase2 speed and turn")
    boss.facing=1
    boss._request_turn(-1)
    boss.state_clock=.5*2.0/6.0-.001
    boss._update_turn(0)
    _check(boss.facing==1,"Boss six-frame turn holds facing until frame3")
    boss.state_clock=.5*2.0/6.0
    boss._update_turn(0)
    _check(boss.facing==-1,"Boss turn flips at frame3")
    boss.facing=1
    boss._start_pattern("roar")
    boss._begin_active()
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero.global_position = Vector2(1500,800)
    for i in range(14):
        boss.state_clock = i*float(boss.stats["roar"]["interval"])*boss._time_factor()
        hero.damage_tick_clock = i*.11
        boss._roar_damage(hero)
    _check(boss.roar_ticks == 14 and hero.hp == 152 and hero.damage_grace == 0 and hero.action == "normal","Roar total28 with no repeated stagger/grace")
    boss.roar_ticks = 0
    hero.action = "roll"
    hero.roll_clock = .1
    boss.state_clock = 0
    boss._roar_damage(hero)
    _check(hero.hp == 152,"Roar respects roll immunity")
    hero.action = "normal"
    boss._stop_roar()
    boss._set_state(EnemyBase.State.CHASE)
    boss.rear_hits.clear()
    boss.take_hit(20,Vector2(800,600),1)
    boss.take_hit(20,Vector2(800,600),1)
    boss._request_turn(-1)
    _check(boss.phase == "spines" and boss.rear_cooldown == 6 and boss.facing == 1,"Two rear hits trigger delayed spines without instant turn")
    boss._summon_archers()
    _check(boss.summons.size()==2,"Boss summons max2")
    for archer in boss.summons:
        archer.set_physics_process(false)
        _check(archer.get_drop_chance()==0,"Summoned archer has no drop")
    boss._summon_archers()
    _check(boss.summons.size()==2,"Repeated summon cannot exceed2")
    hero.global_position = Vector2(1200,800)
    boss.facing=1
    boss.hp = 0
    root.get_node("GameState").run_flags["kala_death_lines"] = true
    boss._die()
    boss.state_clock = 1
    boss._update_dead(0)
    _check(boss.phase=="final_windup" and not boss.battle_finished,"HP0 collapse still reserves final attack")
    boss.state_clock=.8
    boss._update_dead(0)
    _check(boss.phase=="final_active" and boss.marker_is_dangerous(),"Final attack active after0.8 warning")
    hero.hp = 180
    hero.action="roll"
    hero.roll_clock=.1
    boss._update_dead(0)
    _check(hero.hp==180,"Final swing roll dodge")
    hero.action="normal"
    boss._update_dead(0)
    _check(hero.hp==150,"Final swing damage30 even after boss HP0")
    boss.state_clock=.2
    boss._update_dead(0)
    _check(boss.battle_finished and boss.death_attack_done and not manager.current_level.doors["boss_arrival"].locked,"Final attack finishes, unlocks arrival")
    await _finish("STAGE6_BOSS")
