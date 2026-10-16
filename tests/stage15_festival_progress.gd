extends "res://tests/helpers/stage9_support.gd"

func object(kind: String,uid: String,ability: String = "") -> Node2D:
    var actor: Node2D=load("res://scripts/world/world_object.gd").new()
    actor.spec={"type":kind,"uid":uid,"id":uid,"region":"landing","position":[hero.position.x+40,hero.position.y]}
    if not ability.is_empty():actor.spec["ability"]=ability
    actor.position=hero.position+Vector2(40,0)
    manager.current_level.add_child(actor)
    return actor

func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    var save: Node=root.get_node("Save")
    save.save_path="user://stage15_festival.json"
    world.timing_scale=.001
    world.invulnerable=true
    await world.enter()
    hero.set_physics_process(false)
    hero.hp=41
    for i in range(4):_check(object("cord","cord_test_"+str(i)).interact(),"Cord collection "+str(i))
    _check(world.cord_ids.size()==4 and hero.get_max_hp()==110,"Four permanent cords increase maximum HP by ten")
    _check(hero.hp==41,"Cords never heal on pickup")
    for i in range(3):_check(object("ember","ember_test_"+str(i)).interact(),"Ember collection "+str(i))
    _check(world.embers==3 and hero.hp==41,"Embers have no healing effect")
    var site: Node=object("site","site_test_0","light_throw")
    _check(site.interact() and world.has_ability("light_throw"),"Festival site grants skill without the old chain")
    _check(not site.interact(),"Repeated E cannot consume a site twice")
    _check(world.collected.has("site_test_0") and world.discovered_sites.has("site_test_0"),"Attempt-use and permanent discovery are separate")
    for id: String in world.abilities_data.abilities:_check(world.abilities_data.abilities[id].requires.is_empty(),"No acquisition prerequisite: "+id)
    var grant_key:=InputEventKey.new()
    grant_key.physical_keycode=KEY_G
    grant_key.ctrl_pressed=true
    grant_key.pressed=true
    Input.parse_input_event(grant_key)
    await process_frame
    _check(world.abilities.size()==7,"Ctrl+G grants all seven attempt abilities")
    grant_key.pressed=false
    Input.parse_input_event(grant_key)
    var clear_key:=InputEventKey.new()
    clear_key.physical_keycode=KEY_B
    clear_key.ctrl_pressed=true
    clear_key.pressed=true
    Input.parse_input_event(clear_key)
    await process_frame
    _check(world.abilities.is_empty() and world.embers==3 and world.cord_ids.size()==4,"Ctrl+B removes abilities without changing collectibles")
    clear_key.pressed=false
    Input.parse_input_event(clear_key)
    world.switches["door_test"]=true
    world.bosses["boss_test"]=true
    world.reveal_near(hero.position)
    var fog: PackedByteArray=world.explored.duplicate()
    hero.hp=0
    _check(world.confirm_death(hero),"Confirmed death is accepted")
    _check(not world.confirm_death(hero),"Same-frame duplicate death is rejected")
    _check(world.abilities.is_empty() and world.embers==0,"Confirmed death immediately removes abilities and embers")
    _check(world.cord_ids.size()==4 and world.switches.has("door_test") and world.bosses.has("boss_test") and world.explored==fog,"Permanent progress survives death")
    _check(world.discovered_sites.has("site_test_0") and not world.collected.has("site_test_0"),"Site knowledge survives while the site relights")
    await world.return_to_plaza()
    _check(hero.hp==110 and manager.current_level.level_id=="HwaniraPlaza","Death arrives healed at plaza")
    var snapshot: Dictionary=save.read_save()
    _check(snapshot.version==3 and not snapshot.zabulistan.has("abilities") and not snapshot.zabulistan.has("life_fragments"),"Schema 3 never persists attempt abilities or old fragments")
    _check(snapshot.zabulistan.zab_cord_count==4 and snapshot.zabulistan.zab_embers_carried==0,"Permanent count and empty carried amount are saved")
    var old: Dictionary=snapshot.duplicate(true)
    old.version=2
    old.zabulistan["abilities"]={"dash":true}
    old.zabulistan["life_fragments"]={"life_legacy":true}
    var migrated: Dictionary=save.migrate_save(old)
    _check(migrated.version==3 and migrated.zabulistan.zab_cord_ids.is_empty() and not migrated.zabulistan.has("abilities") and not migrated.zabulistan.has("life_fragments"),"Schema 2 discards old abilities and fragment records")
    _check(migrated.zabulistan.opened_doors==old.zabulistan.opened_doors and migrated.zabulistan.defeated_bosses==old.zabulistan.defeated_bosses and migrated.zabulistan.map_bitmap==old.zabulistan.map_bitmap and migrated.deaths_total==old.deaths_total,"Migration preserves doors, bosses, fog and deaths")
    await world.enter()
    _check(world.abilities.is_empty() and not world.collected.has("site_test_0"),"Fresh descent starts with no resonance and unused sites")
    world.abilities["wall_jump"]=true
    _check(not world.hero_motion.can_wall_jump(),"Wall jump acquisition alone cannot activate wall jumping")
    world.abilities["wall_cling"]=true
    _check(world.hero_motion.can_wall_jump(),"Wall cling enables an independently acquired wall jump")
    var boss_spec: Dictionary={"uid":"boss_reward_test","type":"boss"}
    world.enemy_died(null,boss_spec)
    world.enemy_died(null,boss_spec)
    _check(world.embers==5,"Boss contributes exactly five embers once")
    world.enemy_died(null,{"uid":"enemy_reward_test","type":"enemy"})
    _check(world.embers==5,"Normal enemies never drop embers")
    hero.crouching=true
    hero.collider.shape.size=Vector2(36,48)
    hero.collider.position.y=-24
    world.embers=12
    world.abilities["dash"]=true
    _check(await world.return_alive(),"Alive return completes")
    _check(world.embers_offered_total==12 and world.embers_offered_best==12 and world.returns_alive==1,"Offering total, best and alive-return count")
    _check(world.abilities.is_empty() and world.embers==0 and hero.hp==110,"Alive return clears attempt state and fully heals")
    _check(hero.collider.shape.size==Vector2(36,124) and not hero.crouching,"Alive return restores the standing collision body")
    _check(hero.position==Vector2(1840,880) and not manager.player_locked,"Return arrives at the plaza brazier with control")
    _check(not await world.return_alive(),"Repeated return outside the world is ignored")
    _check(await save.resume(),"Schema 3 checkpoint resumes")
    _check(world.embers_offered_total==12 and world.cord_ids.size()==4 and world.discovered_sites.has("site_test_0") and world.abilities.is_empty(),"Schema 3 restores permanent data only")
    await world.enter()
    _check(await world.return_alive(),"Returning with zero embers is allowed")
    _check(world.returns_alive==2 and world.embers_offered_total==12 and world.embers_offered_best==12,"Zero offering does not alter total/best")
    var counters: Dictionary=world.story_counts()
    _check(counters.zab_cord_count==4 and counters.zab_cord_ids.size()==4 and counters.zab_embers_offered_total==12 and counters.zab_embers_offered_best==12 and counters.zab_returns_alive==2 and counters.zab_embers_carried==0 and counters.deaths_zabulistan==1,"All seven story-facing counters are exposed")
    root.get_node("GameState").reset_run(false)
    _check(world.cord_ids.is_empty() and world.discovered_sites.is_empty() and world.embers_offered_total==0 and world.returns_alive==0,"Full reset removes every new progress field")
    _finish("stage15_festival_progress")
