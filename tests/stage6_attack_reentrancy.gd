extends "res://tests/helpers/stage4_support.gd"

class ReactiveTarget extends CharacterBody2D:
    var hero: NimrodPlayer
    var mode: String = "hurt"
    var hits: int = 0

    func take_hit(amount: int, _from: Vector2, _step: int) -> Dictionary:
        hits += 1
        if mode == "replace":
            hero._cancel_attack()
            hero._begin_attack(1)
        else:
            hero.receive_damage(999 if mode == "dead" else 1)
        return {"blocked": false, "damage_dealt": amount}

func _run() -> void:
    await _start()
    await manager.go_to("CastleF2", "Spawn_FromBelow")
    var targets: Array[ReactiveTarget] = []
    for i in range(2):
        var target := ReactiveTarget.new()
        target.hero = hero
        target.collision_layer = 4
        target.collision_mask = 0
        var hit := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = Vector2(16, 100)
        hit.shape = shape
        target.add_child(hit)
        manager.current_level.add_child(target)
        targets.append(target)
    for mode in ["hurt", "dead", "replace"]:
        hero.reset_run_state()
        hero.set_transition_locked(false)
        hero.global_position = Vector2(900, 620)
        hero.facing = 1
        hero._begin_attack(1)
        var box: Rect2 = hero._attack_rect()
        for target in targets:
            target.mode = mode
            target.hits = 0
            target.global_position = hero.global_position + box.get_center()
        await physics_frame
        await physics_frame
        var generation: int = hero.attack_generation
        hero._update_attack(float(hero.attack_data[1]["active_start"]))
        _check(targets[0].hits + targets[1].hits == 1, "Hit callback %s stops the obsolete query" % mode)
        _check(hero.attack_generation != generation, "Hit callback changes attack generation")
        if mode == "replace":
            _check(hero.action == "attack" and hero.attack_step == 1 and hero.attack_clock == 0, "Replacement first strike retains its own clock")
        else:
            _check(hero.action == mode and hero.attack_step == 0 and not hero.shockwave_done, "Hurt/death state survives obsolete attack update")
            _check(hero.hitstop_left == 0, "Cancelled hit cannot add stale hitstop")
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero._begin_attack(4)
    var wave: Rect2 = hero._configured_hitbox(hero.shockwave_data)
    for target in targets:
        target.mode = "hurt"
        target.hits = 0
        target.global_position = hero.global_position + wave.get_center()
    await physics_frame
    await physics_frame
    hero._resolve_shockwave()
    _check(targets[0].hits + targets[1].hits == 1 and hero.action == "hurt", "Shockwave callbacks stop remaining hits after cancellation")
    hero._resolve_axe_hit()
    hero._update_attack(.1)
    _check(hero.attack_step == 0 and hero.action == "hurt", "No invalid dictionary access outside an attack")
    await _finish("STAGE6_ATTACK_REENTRANCY")
