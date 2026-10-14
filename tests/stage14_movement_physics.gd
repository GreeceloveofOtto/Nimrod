extends "res://tests/helpers/stage9_support.gd"
func release_inputs() -> void:
    for key in ["dash","jump","move_right","move_left","crouch","ability_vision","skill_light"]:Input.action_release(key)
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    world.invulnerable=true
    await world.enter("landing_00","left",false)
    hero.position=Vector2(1200,1320)
    hero.set_physics_process(true)
    for i in range(5):await physics_frame
    hero.set_physics_process(false)
    Input.action_press("dash")
    _check(not world.hero_motion.tick(hero,.016),"Dash unavailable before altar")
    release_inputs()
    for id in world.abilities_data.abilities:world.acquire(str(id))
    await process_frame
    Input.action_press("dash")
    _check(world.hero_motion.tick(hero,.016) and absf(hero.velocity.x)==900 and hero.displayed_clip=="dash","Dash speed and generated clip")
    release_inputs()
    world.hero_motion.dash_left=0
    hero.position=Vector2(1200,900)
    hero.velocity=Vector2.ZERO
    hero.move_and_slide()
    await process_frame
    Input.action_press("jump")
    world.hero_motion.tick(hero,.016)
    _check(world.hero_motion.second_jump_used and hero.velocity.y==-640,"Second jump impulse")
    release_inputs()
    await process_frame
    hero.velocity.y=10
    Input.action_press("jump")
    world.hero_motion.tick(hero,.016)
    _check(hero.velocity.y==10,"No third jump")
    release_inputs()
    world.hero_motion.reset_motion()
    await physics_frame
    await process_frame
    hero.position=Vector2(700,600)
    hero.velocity=Vector2(500,80)
    hero.move_and_slide()
    await process_frame
    Input.action_press("move_right")
    var cling_result: bool = world.hero_motion.tick(hero,.016)
    print("WALL_FIXTURE: collisions=",hero.get_slide_collision_count()," at=",hero.position," clip=",hero.displayed_clip," velocity=",hero.velocity," on_floor=",hero.is_on_floor())
    _check(cling_result and hero.displayed_clip=="wall_cling" and hero.velocity.y<=65,"Climbable wall slide")
    Input.action_press("jump")
    _check(world.hero_motion.tick(hero,.016) and hero.velocity.x<0 and hero.velocity.y< -600,"Wall jump pushes away")
    release_inputs()
    world.hero_motion.reset_motion()
    manager.current_level._make_surface(1600,1230,200,40,false,0)
    hero.position=Vector2(1700,1320)
    hero.velocity=Vector2.ZERO
    hero.move_and_slide()
    await process_frame
    Input.action_press("crouch")
    Input.action_press("move_right")
    _check(world.hero_motion.tick(hero,.016) and hero.collider.shape.size.y==48 and hero.displayed_clip=="crawl","Crawl fits50px tunnel")
    release_inputs()
    world.hero_motion.tick(hero,.016)
    _check(hero.collider.shape.size.y==48,"Ceiling prevents standing")
    hero.position=Vector2(1500,1320)
    world.hero_motion.tick(hero,.016)
    _check(hero.collider.shape.size.y==124,"Standing collider restored after tunnel")
    Input.action_press("ability_vision")
    world.hero_motion.tick(hero,.016)
    _check(world.hero_motion.vision,"Vision while held")
    release_inputs()
    world.hero_motion.tick(hero,.016)
    _check(not world.hero_motion.vision,"Vision released")
    release_inputs()
    hero.jump_buffer_left=0
    world.hero_motion.reset_motion()
    hero.position=Vector2(1100,1078)
    hero.velocity=Vector2(0,200)
    for i in range(5):
        await physics_frame
        hero.move_and_slide()
    Input.action_press("crouch")
    world.hero_motion.tick(hero,.016)
    await process_frame
    Input.action_press("jump")
    _check(not world.hero_motion.tick(hero,.016),"Crawl defers S+Space to existing platform drop")
    hero.platform_check.force_raycast_update()
    print("DROP_FIXTURE: at=",hero.position," floor=",hero.is_on_floor()," ray=",hero.platform_check.is_colliding()," action=",hero.action," mask=",hero.collision_mask)
    hero._try_drop_platform()
    _check(hero.drop_mask_left>0 and not hero.get_collision_mask_value(2),"One-way drop still works after crawl unlock")
    release_inputs()
    await _go("HwaniraPlaza")
    _finish("stage14_movement_physics")
