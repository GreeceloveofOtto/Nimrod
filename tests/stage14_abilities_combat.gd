extends "res://tests/helpers/stage9_support.gd"
func release_keys() -> void:
    for action in ["dash","jump","move_right","move_left","crouch","ability_vision","skill_light"]:Input.action_release(action)
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    await world.enter()
    world.set_process(false)
    hero.set_physics_process(false)
    # Controlled physics fixture independent of the hand-designed maze layout.
    for chunk: Node in world.loaded.values():
        chunk.get_parent().remove_child(chunk)
        chunk.queue_free()
    world.loaded.clear()
    await process_frame
    manager.current_level._make_surface(400,2000,1800,40,false,0)
    var wall: StaticBody2D=manager.current_level._make_surface(720,1400,40,600,false,0)
    wall.set_meta("wall_climbable",true)
    manager.current_level._make_surface(1600,1910,240,40,false,0)
    hero.position=Vector2(1100,2000)
    hero.velocity=Vector2(0,100)
    for i in range(5):
        await physics_frame
        hero.move_and_slide()
    Input.action_press("dash")
    _check(not world.hero_motion.tick(hero,.016),"Dash requires altar")
    release_keys()
    for id in world.abilities_data.abilities:_check(world.acquire(str(id)),"Acquire "+str(id))
    await process_frame
    Input.action_press("dash")
    _check(world.hero_motion.tick(hero,.016) and hero.velocity.x==900 and hero.displayed_clip=="dash","Dash uses data and existing generated clip")
    release_keys()
    world.hero_motion.reset_motion()
    hero.position=Vector2(1100,1700)
    hero.velocity=Vector2.ZERO
    hero.move_and_slide()
    await process_frame
    Input.action_press("jump")
    world.hero_motion.tick(hero,.016)
    _check(hero.velocity.y==-640 and world.hero_motion.second_jump_used,"Double jump")
    release_keys()
    world.hero_motion.reset_motion()
    await physics_frame
    hero.position=Vector2(700,1600)
    hero.velocity=Vector2(500,80)
    hero.move_and_slide()
    await process_frame
    Input.action_press("move_right")
    _check(world.hero_motion.tick(hero,.016) and hero.displayed_clip=="wall_cling","Climbable-wall slide")
    Input.action_press("jump")
    _check(world.hero_motion.tick(hero,.016) and hero.velocity.x<0,"Wall jump")
    release_keys()
    world.hero_motion.reset_motion()
    hero.position=Vector2(1700,2000)
    hero._set_short_collider()
    hero.crouching=true
    hero.velocity=Vector2(0,100)
    hero.move_and_slide()
    await process_frame
    Input.action_press("crouch")
    _check(world.hero_motion.tick(hero,.016) and hero.collider.shape.size.y==48,"Crawl height")
    release_keys()
    world.hero_motion.tick(hero,.016)
    _check(hero.collider.shape.size.y==48,"Low ceiling prevents standing")
    hero.position=Vector2(1500,2000)
    world.hero_motion.tick(hero,.016)
    _check(hero.collider.shape.size.y==124,"Collider restored after tunnel")
    Input.action_press("ability_vision")
    world.hero_motion.tick(hero,.016)
    _check(world.hero_motion.vision,"Hold vision")
    release_keys()
    world.hero_motion.tick(hero,.016)
    _check(not world.hero_motion.vision,"Release vision")
    _check(world.hero_motion.throw_light(hero),"Siyavash light throw")
    _check(not world.hero_motion.throw_light(hero),"Throw cooldown")
    var pool: Array[EnemyBase]=[]
    world.tokens.clear()
    for i in range(4):
        var enemy: EnemyBase=load("res://scripts/enemy_cedar_sentinel.gd").new()
        manager.current_level.add_child(enemy)
        enemy.state=EnemyBase.State.WINDUP
        pool.append(enemy)
        _check(world.request_attack(enemy)==(i<3),"Melee token bound "+str(i))
    for enemy in pool:enemy.queue_free()
    var offset_parent:=Node2D.new()
    offset_parent.position=Vector2(10000,0)
    manager.current_level.add_child(offset_parent)
    var boss: EnemyBase=load("res://scripts/world/world_boss.gd").new()
    boss.enemy_id="humbaba"
    boss.position=Vector2(200,1900)
    offset_parent.add_child(boss)
    boss.set_physics_process(false)
    hero.position=Vector2(10100,1900)
    boss.facing=-1
    boss.attack_cooldown_left=10
    boss._update_chase(.016)
    _check(boss.velocity.x<0,"Boss chases in global coordinates across chunk origins")
    offset_parent.queue_free()
    await process_frame
    release_keys()
    world.set_process(true)
    await _go("HwaniraPlaza")
    hero.set_physics_process(true)
    _finish("stage14_abilities_combat")
