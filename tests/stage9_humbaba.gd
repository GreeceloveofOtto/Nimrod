extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(7)
    await _go("CedarBossRoom")
    var boss: Humbaba=get_nodes_in_group("enemies")[0]
    boss.set_physics_process(false)
    _check(boss.hp==1350 and is_equal_approx(boss._turn_seconds(),.6),"HP1350 and phase-one turn delay")
    boss.facing=1
    _check(boss.take_hit(20,boss.global_position+Vector2(100,0),1)["damage_dealt"]==16,"Front basic attack reduced twenty percent")
    _check(boss.hurt_flash_left>0 and boss.visual.modulate.r>1.0,"A damaging hit flashes the painted boss without a stun clip")
    _check(boss.take_hit(20,boss.global_position-Vector2(100,0),1)["damage_dealt"]==20,"Rear attack full damage")
    _check(boss.take_light_hit(36,boss.global_position+Vector2(100,0),.2)["damage_dealt"]==36,"Light bypasses armor")
    _check(boss.state!=EnemyBase.State.STUN,"Superarmor suppresses hit stun")
    _check(is_equal_approx(float(boss.stats["tail_chance"]),.5),"Rear tail probability fifty percent")
    _check(boss.stats["patterns"]["bite"]["damage"]==24 and boss.stats["patterns"]["claw"]["damage"]==14,"Bite and claw damage")
    for phase in [false,true]:
        boss.phase_two=phase
        for attack in ["bite","claw","tail","breath"]:
            hero.hp=180
            hero.action="normal"
            hero.damage_grace=0
            boss._start_pattern(attack)
            boss._set_state(EnemyBase.State.ACTIVE)
            hero.global_position=boss.global_position+Vector2(-100 if attack=="tail" else 550 if attack=="breath" else 100,0)
            var factor: float=boss._time_factor()
            var count: int=18 if phase else 16
            var seconds: float=count*.1 if attack=="breath" else (4 if phase else 3)*.25 if attack=="claw" else .15 if attack=="tail" else .2
            for frame in range(121):
                boss.state_clock=seconds*factor*frame/120.0
                if attack=="breath" and phase:
                    var origin: Vector2=boss.global_position+Vector2(boss.body_size.x*.35,-boss.body_size.y*.7)
                    var angle: float=sin(boss.state_clock/(seconds*factor)*TAU)*deg_to_rad(30)
                    hero.global_position=origin+Vector2.from_angle(angle)*400+Vector2(0,62)
                boss._update_active(seconds*factor/120.0)
            var expected: int=(36 if phase else 32) if attack=="breath" else (56 if phase else 42) if attack=="claw" else 12 if attack=="tail" else 24
            _check(180-hero.hp==expected,"Actual %s phase %d total damage %d" % [attack,2 if phase else 1,expected])
    boss.phase_two=false
    boss._start_pattern("breath")
    boss._set_state(EnemyBase.State.ACTIVE)
    hero.hp=180
    hero.action="roll"
    hero.roll_clock=.05
    hero.global_position=boss.global_position+Vector2(550,0)
    boss._update_active(.01)
    _check(hero.hp==180,"Roll invulnerability prevents breath ticks")
    hero.action="normal"
    boss.facing=1
    boss._set_state(EnemyBase.State.CHASE)
    boss._request_turn(-1)
    boss.state_clock=.6*2.0/6.0-.001
    boss._update_turn(0)
    _check(boss.facing==1,"Turn preserves original direction before third frame")
    boss.state_clock=.6*2.0/6.0
    boss._update_turn(0)
    _check(boss.facing==-1,"Third turn frame changes facing")
    boss.facing=1
    boss.pending_facing=-1
    boss.pattern="tail"
    boss._begin_recovery(.6)
    boss.state_clock=.6
    boss._update_recovery(0)
    _check(boss.state==EnemyBase.State.TURN,"Rear tail completes recovery before entering turn")
    boss.facing=1
    boss._set_state(EnemyBase.State.CHASE)
    boss.hp=675
    hero.global_position=Vector2(600,620)
    boss.battle_started=true
    boss._update_chase(.01)
    _check(boss.phase_roaring,"Half HP enters invulnerable roar")
    _check(boss.take_light_hit(36,boss.global_position,.2)["damage_dealt"]==0,"Roar invulnerable")
    boss.state_clock=1.8
    boss._update_windup(.01)
    _check(boss.phase_two and is_equal_approx(boss._turn_seconds(),.45) and is_equal_approx(boss._time_factor(),.87),"Phase two timing and turn speed")
    boss.facing=1
    boss._set_state(EnemyBase.State.CHASE)
    boss._request_turn(-1)
    boss.state_clock=.45*2.0/6.0-.0001
    boss._update_turn(0)
    boss._update_visual(0)
    _check(boss.facing==1 and boss.current_frame==1,"Phase-two turn holds old facing before frame three")
    boss.state_clock=.45*2.0/6.0
    boss._update_turn(0)
    boss._update_visual(0)
    _check(boss.facing==-1 and boss.current_frame==2,"Phase-two facing changes exactly when frame three starts")
    boss.hp=1
    boss.take_light_hit(36,boss.global_position,.2)
    _check(story_state.is_flag("humbaba_defeated") and not manager.current_level.doors["boss_arrival"].locked,"Defeat sets flag and unlocks arrival")
    await _finish("STAGE9_HUMBABA")
