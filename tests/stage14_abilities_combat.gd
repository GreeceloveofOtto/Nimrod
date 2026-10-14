extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node = root.get_node("World")
    await world.enter("deep_00","left",false)
    hero.set_physics_process(false)
    var room: WorldRoom = manager.current_level
    _check(not world.hero_motion.throw_light(hero),"No unacquired light throw")
    _check(not world.acquire("wall_jump"),"Prerequisite enforces progression")
    for id in world.abilities_data.abilities:world.acquire(str(id))
    _check(world.hero_motion.throw_light(hero) and not world.hero_motion.throw_light(hero),"Light projectile and cooldown")
    world.hero_motion.throw_cooldown=0
    _check(world.hero_motion.throw_light(hero),"Cooldown expiry permits throw")
    for action in ["dash","ability_vision","map_toggle"]:_check(InputMap.has_action(action),"Input "+action)
    for clip in ["dash","wall_cling","wall_jump","crawl"]:_check(hero.textures.has(clip),"Dagger reuses new movement "+clip)
    var enemies: Array[EnemyBase] = room.enemies
    for enemy in enemies:enemy.set_physics_process(false)
    world.tokens.clear()
    var melee: Array[EnemyBase] = []
    for enemy in enemies:
        if enemy.enemy_id in ["cedar_sentinel","cedar_colossus"]:melee.append(enemy)
    for i in range(mini(4,melee.size())):_check(world.request_attack(melee[i])==(i<3),"Melee token cap "+str(i))
    world.tokens.clear()
    var ranged: Array[EnemyBase]=[]
    for enemy in enemies:
        if enemy.enemy_id=="cedar_archer":ranged.append(enemy)
    for i in range(mini(3,ranged.size())):_check(world.request_attack(ranged[i])==(i<2),"Ranged token cap "+str(i))
    hero.position=Vector2(80,1320)
    world.update_sleep(room,hero)
    _check(world.sleeping_enemies>0 and world.active_enemies<=24,"Distance sleep and active ceiling")
    hero.position=Vector2(2000,1320)
    world.update_sleep(room,hero)
    _check(world.active_enemies>0,"Radius wakes enemies")
    var id_before: int = enemies[0].get_instance_id()
    await world.enter("deep_01","left",false)
    await process_frame
    await world.enter("deep_00","left",false)
    _check(manager.current_level.enemies[0].get_instance_id()!=id_before,"Respawn recreates enemy instances")
    _check(world.fragments==0 and world.abilities.size()==7,"Room transitions preserve session")
    var object: Node2D = load("res://scripts/world/world_object.gd").new()
    object.spec={"type":"crystal","id":"test_once","position":[0,0]}
    object.position=hero.position
    manager.current_level.gameplay.add_child(object)
    _check(object.interact() and world.crystals==1 and not object.interact(),"Item acquired once")
    _check(world.visited.has("deep_00") and not world.visited.has("forest_20"),"Visited map fog")
    for enemy: EnemyBase in manager.current_level.enemies:
        enemy.hp=0
        enemy.state=EnemyBase.State.DEAD
    world.update_sleep(manager.current_level,hero)
    _check(world.active_enemies<=24,"Dying animations do not exceed living active cap")
    await _go("HwaniraPlaza")
    _check(not world.active and hero.get_max_hp()==100,"Existing plaza behavior restored")
    _finish("stage14_abilities_combat")
