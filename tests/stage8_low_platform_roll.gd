extends "res://tests/helpers/stage4_support.gd"

func _surface(at: Vector2, size_px: Vector2, one_way: bool) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.collision_layer = 2 if one_way else 1
    body.set_meta("one_way", one_way)
    body.position = at
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = size_px
    shape.shape = rect
    shape.one_way_collision = one_way
    body.add_child(shape)
    main.add_child(body)
    return body

func _run() -> void:
    await _start()
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        enemy.queue_free()
    hero.global_position = Vector2(500, -500)
    var ground := _surface(Vector2(500, -450), Vector2(1200, 100), false)
    var platform := _surface(Vector2(500, -558), Vector2(200, 12), true)
    await physics_frame
    await physics_frame
    _check(hero._can_stand(), "52px gap: one-way platform is not a headroom obstacle")
    var beast: EnemyBase = load("res://scripts/enemy_melee_beast.gd").new()
    beast.position = Vector2(500,-501)
    main.add_child(beast)
    beast.set_physics_process(false)
    _check(hero._can_stand(),"Monster hurtbox does not change one-way clearance")
    for direction in [-1, 1]:
        hero.global_position = Vector2(500 - direction * 180, -501)
        hero.action = "normal"
        hero.crouching = false
        hero.facing = direction
        hero._begin_roll()
        hero.set_physics_process(true)
        await _wait(.6)
        _check(hero.action == "normal" and not hero.crouching, "Roll from either side restores standing")
        hero.set_physics_process(false)
        hero.global_position = Vector2(500, -501)
        hero._restore_safe_collider()
        hero.velocity = Vector2(0, NimrodPlayer.JUMP_IMPULSE)
        Input.action_press("jump")
        hero.set_physics_process(true)
        await _wait(.25)
        _check(hero.global_position.y < -565, "Jump passes upward through the one-way platform")
        Input.action_release("jump")
        await _wait(.6)
        _check(hero.global_position.y < -550 and hero.is_on_floor(), "Jump lands on the platform")
        hero.set_physics_process(false)
    platform.queue_free()
    var ceiling := _surface(Vector2(500, -610), Vector2(200, 20), false)
    hero.global_position = Vector2(500, -501)
    await physics_frame
    _check(not hero._can_stand(), "Solid 100px tunnel still prevents standing")
    hero._restore_safe_collider()
    _check(hero.crouching and not hero.compact_escape and hero.collider.shape.size.y == 90, "Solid tunnel supports crouch walking")
    ceiling.queue_free()
    ground.queue_free()
    beast.queue_free()
    await _finish("STAGE8_LOW_PLATFORM_ROLL")
