extends "res://tests/helpers/stage4_support.gd"

var actors: Dictionary = {}

func _add(id: String, x: float = 900) -> Stage5Enemy:
    var actor := load("res://scripts/enemy_"+id+".gd").new() as Stage5Enemy
    actor.position = Vector2(x,620)
    actor.patrol_center = x
    actor.patrol_range = 350
    manager.current_level.add_child(actor)
    actor.set_physics_process(false)
    actors[id] = actor
    return actor

func _reset_hero(at: Vector2) -> void:
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero.global_position = at
    hero.set_physics_process(false)

func _run() -> void:
    await _start()
    await manager.go_to("CastleF2","Spawn_FromBelow")
    # Indoor fixture itself is safe, replace its zones for controlled battle checks.
    manager.current_level.safe_zones.clear()
    var expected: Dictionary = {"explosive_spitter":[76,7,.3],"wall_diver":[36,8,.25],"root_spewer":[55,1,.25],"boar_charger":[110,15,.45],"gas_sac":[40,6,.3],"wraith_ray":[18,5,.25],"shell_scorpion":[75,12,.5],"corpse_bomber":[30,18,.3],"chain_beastman":[160,10,.8]}
    var expected_bodies: Dictionary = {"explosive_spitter":Vector2(165,129),"wall_diver":Vector2(135,90),"root_spewer":Vector2(111,120),"boar_charger":Vector2(232.5,141),"gas_sac":Vector2(132,135),"wraith_ray":Vector2(147,72),"shell_scorpion":Vector2(201,120),"corpse_bomber":Vector2(93,132),"chain_beastman":Vector2(270,267)}
    for id in expected:
        var e: Stage5Enemy = _add(id)
        _check(e.hp == expected[id][0] and e.stats["contact_damage"] == expected[id][1] and is_equal_approx(e.stats["turn_delay"],expected[id][2]), id+" numerical stats")
        _check(e.collision_layer == 4 and e.clip_data.has("turn") and e.clip_data["turn"]["frames"] >= 3,id+" shares EnemyBase collision and turn animation")
        _check(e.stats["size_multiplier"] == 1.5 and is_equal_approx(e.stats["visual_scale"],.45), id+" Stage6 revised scale1.5 without stat changes")
        _check((e.collider.shape as RectangleShape2D).size.is_equal_approx(expected_bodies[id]) and e.get_hurt_rect().size.is_equal_approx(expected_bodies[id]), id+" body collider and hurtbox halved with the sprite")
        e.global_position.x = 1400
    var spitter: Stage5Enemy = actors["explosive_spitter"]
    spitter.global_position = Vector2(900,620)
    spitter._set_state(EnemyBase.State.CHASE)
    _reset_hero(Vector2(1200,620))
    spitter._update_chase(1.0/60)
    _check(spitter.velocity.x < 0.0 and spitter.state == EnemyBase.State.CHASE,"Spitter retreats below preferred427.5")
    _reset_hero(Vector2(1600,620))
    spitter._update_chase(1.0/60)
    _check(spitter.velocity.x > 0.0 and spitter.state == EnemyBase.State.CHASE,"Spitter approaches above preferred585")
    _reset_hero(Vector2(1400,620))
    spitter._update_chase(1.0/60)
    _check(spitter.velocity.x == 0.0 and spitter.state == EnemyBase.State.WINDUP,"Spitter attacks within427.5to585")
    var shell: Stage5Enemy = actors["shell_scorpion"]
    shell.global_position = Vector2(900,620)
    shell.facing = 1
    var blocked: Dictionary = shell.take_hit(20,Vector2(1000,620),1)
    _check(blocked["blocked"] and blocked["damage_dealt"] == 0 and shell.hp == 75 and shell.hitstop_left == 0 and shell.state == EnemyBase.State.IDLE,"Front guard causes no damage, stun or hitstop")
    _check(shell.take_shockwave_hit(22,Vector2(1100,620),4)["blocked"],"Shockwave also blocked from front")
    var hit: Dictionary = shell.take_hit(20,Vector2(800,620),1)
    _check(not hit["blocked"] and hit["damage_dealt"] == 20 and shell.hp == 55 and shell.hitstop_left == .05,"Rear hit applies normal damage and hitstop")
    _reset_hero(Vector2(800,620))
    shell._set_state(EnemyBase.State.CHASE)
    shell._request_turn(-1)
    _check(shell._turn_seconds() == .6,"Close rear target makes turn .60sec")
    shell.state_clock = .6*2/6-.001
    shell._update_turn(0)
    _check(shell.facing == 1,"Six-frame turn not flipped before third frame")
    shell.state_clock = .6*2/6
    shell._update_turn(0)
    _check(shell.facing == -1,"Six-frame turn flips precisely at third frame")
    var root_beast: Stage5Enemy = actors["root_spewer"]
    root_beast.global_position = Vector2(900,620)
    _reset_hero(Vector2(900,500))
    root_beast._begin_active()
    for i in range(10):
        hero.damage_tick_clock = i*.1
        root_beast.state_clock = i*.1
        root_beast._update_active(0)
    _check(hero.hp == 170 and root_beast.tick_count == 10 and hero.hurt_duration == .18 and hero.damage_grace == 0,"Root flame ten single ticks with only first .18sec stagger")
    root_beast.take_hit(20,Vector2(800,620),1)
    _check(root_beast.state == EnemyBase.State.STUN and root_beast.stun_left == .4 and root_beast.attack_cooldown_left == 1.8 and root_beast.flame_effect == null and root_beast.loop_sound == null,"Axe interrupts flame immediately and stops loop")
    var boar: Stage5Enemy = actors["boar_charger"]
    boar._set_state(EnemyBase.State.WINDUP)
    boar.take_hit(20,Vector2(1300,620),1)
    _check(boar.hp == 90 and boar.state == EnemyBase.State.WINDUP and boar.hitstop_left == .05,"Boar telegraph has stun immunity but hitstop")
    boar._set_state(EnemyBase.State.ACTIVE)
    boar.take_hit(20,Vector2(1300,620),3)
    _check(boar.hp == 70 and boar.state == EnemyBase.State.ACTIVE,"Boar charge retains superarmor")
    boar.hitstop_left = 0
    boar.global_position = Vector2(1600,620)
    boar.velocity = Vector2(640,0)
    for i in range(20):
        await physics_frame
        boar._integrate_motion(1.0/60)
        if boar.state == EnemyBase.State.STUN:
            break
    _check(boar.state == EnemyBase.State.STUN and boar.stun_left == .8,"Actual wall collision stuns boar .8sec")
    var wraith: Stage5Enemy = actors["wraith_ray"]
    _check(wraith.collision_mask == 0,"Wraith ignores solid and platform collision")
    wraith.take_hit(20,Vector2(1300,620),1)
    _check(wraith.state == EnemyBase.State.DEAD,"Wraith dies from one axe strike")
    _reset_hero(Vector2(900,620))
    var projectile := Stage5Projectile.new()
    _reset_hero(Vector2(980,620))
    projectile.configure(actors["explosive_spitter"].stats["projectile"],Vector2(1080,558))
    projectile.position = Vector2(870,558)
    manager.current_level.add_child(projectile)
    projectile.set_physics_process(false)
    projectile._physics_process(130.0/480)
    _check(projectile.struck_player and not projectile.armed and projectile.global_position.x == 1000 and hero.hp == 173, "Real projectile direct7 and continues past player")
    projectile._physics_process(100.0/480)
    _check(projectile.armed and projectile.global_position.x == 1080, "Projectile stops at fixed destination")
    var armed: Stage5Hazard = get_nodes_in_group("stage5_hazards").back()
    armed.set_physics_process(false)
    _check(not armed.detonated and armed.spec["fuse"] == .3, "Destination starts .3sec fuse")
    armed._physics_process(.3)
    _check(hero.hp == 159, "Actual projectile destination explosion adds14")
    armed.queue_free()
    _reset_hero(Vector2(900,620))
    var hazard := Stage5Hazard.new()
    hazard.configure("explosion",{"fuse":.3,"radius":90,"damage":14,"knockback":220})
    hazard.position = Vector2(900,560)
    manager.current_level.add_child(hazard)
    hazard.set_physics_process(false)
    hero.receive_damage(7,{"stagger_seconds":.3})
    hazard._physics_process(.299)
    _check(not hazard.detonated and hero.hp == 173,"Projectile explosion waits .3sec after direct7")
    hazard._physics_process(.001)
    _check(hazard.detonated and hero.hp == 159,"Explosion14 follows direct7 even inside direct grace")
    hazard.queue_free()
    _reset_hero(Vector2(900,620))
    hero._begin_roll()
    hero.roll_clock = .10
    hazard = Stage5Hazard.new()
    hazard.configure("explosion",{"radius":110,"damage":18})
    hazard.position = Vector2(900,560)
    manager.current_level.add_child(hazard)
    hazard.set_physics_process(false)
    _check(hero.hp == 180,"Roll invulnerability avoids corpse explosion")
    hazard.queue_free()
    _reset_hero(Vector2(900,620))
    var gas := Stage5Hazard.new()
    gas.configure("gas",{"seconds":2,"radius":110,"height":160,"tick_interval":.2,"damage":1})
    gas.position = Vector2(900,560)
    manager.current_level.add_child(gas)
    gas.set_physics_process(false)
    for i in range(10):
        hero.damage_tick_clock = i*.2
        gas._physics_process(.2)
    _check(hero.hp == 170 and hero.action == "normal" and hero.damage_grace == 0,"Two seconds gas inflicts10 without stagger/grace")
    gas.queue_free()
    _reset_hero(Vector2(900,620))
    _check(hero.receive_damage(1,{"stagger":false,"grant_grace":false,"tick_group":"gas","tick_source":1}),"First gas source tick accepted")
    _check(not hero.receive_damage(1,{"stagger":false,"grant_grace":false,"tick_group":"gas","tick_source":2}),"Overlapping second gas source cannot double tick")
    hero.damage_tick_clock = .2
    _check(hero.receive_damage(1,{"stagger":false,"grant_grace":false,"tick_group":"gas","tick_source":2}),"Next source accepted after .2sec")
    var sac: Stage5Enemy = actors["gas_sac"]
    sac.take_hit(100,Vector2(1300,620),1)
    _check(sac.state == EnemyBase.State.DEAD and sac.collision_layer == 0 and not sac.gas_released,"Gas body immediately noncolliding but cloud delayed")
    sac._update_dead(.999)
    _check(not sac.gas_released,"Gas sac has1sec swell")
    sac._update_dead(.001)
    _check(sac.gas_released,"Cloud starts after full1sec swell")
    var corpse: Stage5Enemy = actors["corpse_bomber"]
    corpse._ignite_fuse()
    corpse._physics_process(1.499)
    _check(corpse.state != EnemyBase.State.DEAD,"Corpse fuse has not expired at1.499")
    corpse._physics_process(.001)
    _check(corpse.state == EnemyBase.State.DEAD,"Corpse explodes exactly1.5sec after detection")
    var wall: Stage5Enemy = actors["wall_diver"]
    wall.global_position = Vector2(900,180)
    _reset_hero(Vector2(950,500))
    wall._update_idle(0)
    _check(wall.phase == "perch_tell" and wall.state == EnemyBase.State.WINDUP,"Ceiling sensor starts .2sec tell")
    wall.state_clock = .2
    wall._update_windup(0)
    _check(not wall.perched and wall.phase == "perch_dive" and is_equal_approx(wall.velocity.length(),720),"Perch dives at720px/s")
    wall._land_claw()
    _check(wall.phase == "landing_claw" and wall.get_attack_rect().size == Vector2(150,120),"Landing produces claw and permanent ground mode")
    await physics_frame
    await process_frame
    var chain: Stage5Enemy = actors["chain_beastman"]
    chain.phase = "tail"
    chain._set_state(EnemyBase.State.RECOVERY)
    chain.take_hit(20,Vector2(1300,620),3)
    _check(chain.hp == 140 and chain.state == EnemyBase.State.RECOVERY,"Tail pattern superarmor includes recovery")
    chain.phase = "chain"
    chain.attack_stats = chain.stats["attacks"][1]
    chain.global_position = Vector2(900,620)
    _reset_hero(Vector2(1300,620))
    chain._begin_active()
    chain.state_clock = .3
    chain._update_chain(0)
    _check(chain.phase == "pull_pending" and hero.pull_left == 0, "Chain callback defers player effects to next physics frame")
    await physics_frame
    await process_frame
    _check(chain.phase == "pull" and is_equal_approx(hero.pull_left, .35) and hero.hp == 180,"Chain hit starts damage-free .35sec pull")
    hero._physics_process(.1)
    _check(hero.pull_left > 0 and hero.global_position.x < 1300,"Pull moves toward enemy front")
    Input.action_press("roll")
    hero._physics_process(.02)
    _check(hero.action != "roll","K before .15sec cannot escape pull")
    Input.action_release("roll")
    await physics_frame
    await process_frame
    Input.action_press("roll")
    hero._physics_process(.04)
    _check(hero.action == "roll" and hero.pull_left == 0 and hero.pull_escaped,"K after .15sec escapes pull")
    Input.action_release("roll")
    _reset_hero(Vector2(1000,620))
    chain.phase = "smash"
    chain.attack_has_hit = false
    chain._set_state(EnemyBase.State.ACTIVE)
    chain._update_chain(0)
    _check(hero.hp == 164,"Smash inflicts16 once")
    chain._update_chain(0)
    _check(hero.hp == 164,"Smash does not repeat damage")
    await _finish("STAGE5_ENEMIES")
