extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    await _go("CastleF1")
    var level: LevelBase=manager.current_level
    level._make_surface(450,300,260,20,true,0)
    var demon: CedarEnemy=load("res://scripts/enemy_cedar_demon.gd").new()
    demon.position=Vector2(550,300)
    level.add_child(demon)
    demon.set_physics_process(false)
    demon.facing=1
    hero.position=Vector2(580,620)
    demon._update_idle(.01)
    _check(demon.phase=="tell","Player below inside sensor triggers tell")
    demon.state_clock=.15
    demon._update_windup(.01)
    _check(not demon.perched and demon.phase=="fall","Fast tell releases starting branch")
    _check(not demon.drop_supports.is_empty(),"Starting branch is temporarily excluded from drop collision")
    var start: float=demon.position.x
    for i in range(90):
        demon.state_clock+=1.0/60
        demon._update_active(1.0/60)
        demon._integrate_motion(1.0/60)
        await physics_frame
        if demon.phase=="land_stab":
            break
    _check(demon.phase=="land_stab" and demon.is_on_floor(),"Drops through own branch to real ground")
    _check(absf(demon.position.x-start)<=160 and demon.attack_stats["damage"]==18,"Bounded homing and landing stab damage")
    demon.perched=true
    demon.phase=""
    demon._set_state(EnemyBase.State.IDLE)
    demon.position=Vector2(550,300)
    hero.position=Vector2(620,280)
    demon._update_idle(.01)
    _check(demon.phase=="tell","Same height/above clear line of sight also detects")
    demon.phase=""
    demon._set_state(EnemyBase.State.IDLE)
    hero.position=Vector2(500,620)
    demon.facing=1
    demon._update_idle(.01)
    _check(demon.state==EnemyBase.State.TURN,"Rear target requires visible turn before tell")
    demon.state_clock=float(demon.stats["turn_delay"])
    demon._update_turn(.01)
    _check(demon.phase=="tell","Turn finishes into pending drop")
    _check(float(demon.stats["turn_delay"])+float(demon.stats["drop_tell"])<=.5,"Detection to drop begins within half a second")
    await _finish("STAGE11_DEMON_DROP")
