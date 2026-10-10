extends "res://tests/helpers/stage4_support.gd"

func _ground() -> void:
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero.global_position = Vector2(600,620)
    for i in range(3):
        hero._physics_process(1.0/60)
        await physics_frame
    await process_frame

func _press(action: String) -> void:
    Input.action_press(action)

func _release() -> void:
    Input.action_release("attack")
    Input.action_release("move_left")
    Input.action_release("move_right")
    Input.action_release("roll")

func _run() -> void:
    await _start()
    await manager.go_to("CastleF2","Spawn_FromBelow")
    for clock in [0.02,0.12,0.24]:
        await _ground()
        hero.facing = 1
        hero._begin_attack(1)
        hero.attack_clock = clock
        hero.buffered_attack = true
        hero.attack_already_hit[42] = true
        hero.debug_rect = Rect2(1,1,20,20)
        hero.shockwave_rect = Rect2(1,1,20,20)
        _press("move_left")
        _press("attack")
        hero._physics_process(1.0/60)
        _check(hero.facing == -1 and hero.visual.flip_h and hero.attack_step == 2 and hero.displayed_clip == "attack_2", "Opposite+J cancels phase %.2f within one frame" % clock)
        _check(hero.velocity.x <= 0 and not hero.buffered_attack and hero.attack_already_hit.is_empty() and hero.shockwave_rect == Rect2(), "Old impulse and hit/wave/buffer cleared")
        _release()
        await physics_frame
    await _ground()
    hero.facing = 1
    hero._begin_attack(4)
    _press("move_left")
    _press("attack")
    hero._physics_process(1.0/60)
    _check(hero.attack_step == 1 and hero.displayed_clip == "attack_1", "Fourth attack wraps to first on direction cancel")
    _release()
    await physics_frame
    await _ground()
    hero.facing = 1
    hero._begin_attack(1)
    _press("move_right")
    _press("attack")
    hero._physics_process(1.0/60)
    _check(hero.attack_step == 1 and hero.buffered_attack and hero.facing == 1, "Same-direction J preserves existing combo buffer")
    _release()
    await physics_frame
    await _ground()
    hero.facing = 1
    hero._begin_attack(1)
    hero.hitstop_left = .05
    _press("move_left")
    _press("attack")
    hero._physics_process(.01)
    _check(hero.attack_step == 1 and hero.pending_cancel_direction == -1, "Opposite J buffers during hitstop")
    _release()
    await physics_frame
    hero._physics_process(.04)
    _check(hero.attack_step == 2 and hero.facing == -1 and hero.pending_cancel_direction == 0, "Buffered cancel fires as hitstop ends")
    await _ground()
    hero.global_position.y = 300
    hero.velocity = Vector2.ZERO
    hero.move_and_slide()
    hero.facing = 1
    hero._begin_attack(4)
    hero._direction_cancel_attack(-1)
    _check(hero.attack_step == 4 and hero.air_direction_cancels == 1 and hero.facing == -1, "Air cancel keeps slam and consumes one")
    hero._direction_cancel_attack(1)
    _check(hero.air_direction_cancels == 2 and hero.facing == 1, "Second air cancel succeeds")
    hero._direction_cancel_attack(-1)
    _check(hero.air_direction_cancels == 2 and hero.facing == 1, "Third air cancel is ignored")
    await _ground()
    hero.facing = 1
    hero._begin_attack(1)
    _press("move_left")
    _press("roll")
    hero._physics_process(.01)
    _check(hero.action == "roll" and hero.roll_direction == -1, "Existing K opposite roll direction remains")
    _release()
    await _finish("STAGE5_DIRECTION_CANCEL")
