extends "res://tests/helpers/stage9_support.gd"

func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    world.invulnerable=true
    await world.enter()
    world.abilities.clear()
    hero.set_physics_process(true)
    for i in range(10):await physics_frame
    _check(hero.is_on_floor(),"Spawn settles on the solid inset floor")
    var began: Vector2=hero.position
    Input.action_press("move_right")
    Input.action_press("jump")
    for i in range(55):await physics_frame
    Input.action_release("jump")
    Input.action_release("move_right")
    _check(hero.position.x>began.x+150,"Real held jump exits the inset floor under the ceiling")
    _check(hero.hp>0 and hero.action!="dead","No falling or spike death on the initial route")
    _check(hero._can_stand(),"Standing collider remains clear after head contact")
    print("CARVED_ENGINE_ROUTE: ",began," -> ",hero.position)
    hero.set_physics_process(false)
    await _go("HwaniraPlaza")
    _finish("stage15_carved_motion")
