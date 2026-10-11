extends "res://tests/helpers/stage4_support.gd"

func _add(id: String) -> CedarEnemy:
    var actor: CedarEnemy = load("res://scripts/enemy_"+id+".gd").new()
    actor.position = Vector2(900,620)
    actor.patrol_center = 900
    actor.patrol_range = 1000
    manager.current_level.add_child(actor)
    actor.set_physics_process(false)
    return actor

func _run() -> void:
    await _start()
    await manager.go_to("CastleF2","Spawn_FromBelow")
    manager.current_level.safe_zones.clear()
    hero.set_transition_locked(false)
    var sentinel: CedarEnemy = _add("cedar_sentinel")
    sentinel.forced_roll = .49
    var hit: Dictionary = sentinel.take_hit(20,Vector2(1000,620),1)
    _check(hit["damage_dealt"] == 8 and sentinel.guard_left == .6 and sentinel.velocity.x == 0,"50percent front guard reduces60percent")
    var hp: int = sentinel.hp
    sentinel.take_shockwave_hit(22,Vector2(1000,620),4)
    _check(sentinel.hp == hp-22 and sentinel.stun_left == 1 and sentinel.guard_broken_left == 3,"Shockwave breaks guard for1second and bans3seconds")
    sentinel.take_hit(20,Vector2(1000,620),1)
    _check(sentinel.guard_left == 0,"No re-guard during broken interval")
    var giant: CedarEnemy = _add("cedar_colossus")
    hero.global_position = Vector2(800,620)
    hero.action = "roll"
    giant.forced_roll = .39
    giant._request_turn(-1)
    _check(giant.phase == "rear_poke" and giant.facing == 1 and giant.state == EnemyBase.State.WINDUP,"40percent rear poke retains direction")
    giant._set_state(EnemyBase.State.CHASE)
    giant.forced_roll = .41
    giant._request_turn(-1)
    _check(giant.state == EnemyBase.State.TURN,"Other60percent uses animated turn")
    var archer: CedarEnemy = _add("cedar_archer")
    archer._begin_hop()
    _check(archer.phase == "hop" and archer.hop_cooldown == 3,"Archer hops within260 with3second cooldown")
    archer.state_clock = .4
    archer._integrate_motion(0)
    _check(archer.global_position.x <= 681,"Archer moves backwards220 through physics")
    var wisp: CedarEnemy = _add("cedar_wisp")
    _check(wisp.collision_mask == 0,"Wisp ignores terrain")
    wisp.take_hit(40,Vector2(800,620),1)
    _check(wisp.phase == "fuse" and wisp.state == EnemyBase.State.WINDUP and wisp.marker_blinks(),"Wisp death starts delayed fuse")
    wisp.state_clock = .499
    wisp._update_windup(0)
    _check(wisp.state != EnemyBase.State.DEAD,"Wisp fuse does not explode early")
    wisp.state_clock = .5
    wisp._update_windup(0)
    _check(wisp.state == EnemyBase.State.DEAD,"Wisp explodes at0.5")
    var demon: CedarEnemy = _add("cedar_demon")
    demon.global_position = Vector2(900,240)
    hero.global_position = Vector2(900,620)
    hero.action = "normal"
    demon._update_idle(0)
    _check(demon.phase == "tell","Demon detects player below perch")
    demon.state_clock = .2
    demon._update_windup(0)
    _check(demon.phase == "fall" and not demon.perched,"Demon drops once")
    demon.global_position = Vector2(900,620)
    demon.phase = "claws"
    demon.attack_stats = demon.stats["attacks"][0]
    demon._set_state(EnemyBase.State.ACTIVE)
    demon.facing = 1
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero.global_position = Vector2(950,620)
    for i in range(4):
        demon.state_clock = i*.15
        hero.damage_tick_clock = i*.15
        demon._update_active(0)
    _check(hero.hp == 170 and demon.tick_index == 4,"Demon four hits total3+3+2+2")
    hero.global_position.x = 800
    demon._request_turn(-1)
    _check(demon.facing == 1,"Four-hit active phase cannot turn")
    for e in [sentinel,giant,archer,wisp,demon]:
        _check(e.get_drop_chance() == .05,"Cedar enemy drop5percent")
    await _finish("STAGE6_CEDAR_ENEMIES")
