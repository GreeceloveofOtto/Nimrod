extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    await manager.go_to("CastleF2", "Spawn_FromBelow", {"instant": true})
    manager.current_level.safe_zones.clear()
    hero.set_transition_locked(false)
    hero.global_position = Vector2(900, 620)
    var corpse: Stage5Enemy = load("res://scripts/enemy_corpse_bomber.gd").new()
    corpse.position = Vector2(960, 620)
    manager.current_level.add_child(corpse)
    corpse.set_physics_process(false)
    corpse.hp = 1
    var wisp: CedarEnemy = load("res://scripts/enemy_cedar_wisp.gd").new()
    wisp.position = Vector2(960, 570)
    manager.current_level.add_child(wisp)
    wisp.set_physics_process(false)
    wisp.hp = 1
    hero.facing = 1
    await physics_frame
    await physics_frame
    hero._begin_attack(2)
    var generation: int = hero.attack_generation
    hero._resolve_axe_hit()
    _check(corpse.hp <= 0 and wisp.hp <= 0, "One actual shape query kills overlapping corpse and wisp")
    _check(hero.action == "attack" and hero.attack_generation == generation and hero.hp == 180, "Lethal take_hit cannot modify player in its callback")
    await physics_frame
    await process_frame
    _check(hero.hp == 162 and hero.action == "hurt" and hero.attack_step == 0, "Death explosion applies on next physics frame and preserves hurt")
    hero._update_attack(.3)
    _check(hero.action == "hurt" and hero.attack_step == 0, "Stale attack update never reads attack_data[0]")
    hero.reset_run_state()
    hero.set_transition_locked(false)
    var blast_corpse: Stage5Enemy = load("res://scripts/enemy_corpse_bomber.gd").new()
    blast_corpse.position = Vector2(960, 620)
    manager.current_level.add_child(blast_corpse)
    blast_corpse.set_physics_process(false)
    blast_corpse.hp = 1
    await physics_frame
    await physics_frame
    hero.facing = 1
    hero._begin_attack(4)
    hero._resolve_shockwave()
    _check(blast_corpse.hp <= 0 and hero.action == "attack", "Fourth shockwave queues lethal corpse explosion")
    await physics_frame
    await process_frame
    _check(hero.action == "hurt", "Shockwave callback preserves deferred hurt state")
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero._begin_attack(1)
    hero._direction_cancel_attack(-1.0)
    hero.receive_damage(1)
    hero._update_attack(.2)
    _check(hero.action == "hurt" and hero.attack_step == 0, "Damage after direction cancel cannot revive the cancelled attack")
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero._begin_attack(1)
    hero._begin_roll()
    hero.roll_clock = .4
    hero.receive_damage(1)
    hero._update_attack(.2)
    _check(hero.action == "hurt" and hero.attack_step == 0, "Damage in roll recovery cannot revive an attack")
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero.hp = 1
    hero._begin_attack(4)
    hero.receive_damage(9)
    hero._update_attack(.5)
    _check(hero.action == "dead" and hero.attack_step == 0, "Dead remains dead after a stale combo update")
    await _finish("STAGE7_ATTACK_SAFETY")
