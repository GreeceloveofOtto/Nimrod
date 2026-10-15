extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    world.timing_scale=.001
    _check(await world.enter(),"Continuous world entry")
    _check(manager.current_level is ContinuousWorld and world.loaded.size()<=9,"One level, at most nine chunks")
    _check(hero.camera.limit_right==20480 and hero.camera.limit_bottom==11520,"Camera limits are the whole world")
    var save_node: Node=root.get_node("Save")
    var before_save: String=FileAccess.get_file_as_string(save_node.save_path) if FileAccess.file_exists(save_node.save_path) else ""
    _check(not save_node.can_save() and not save_node.save_game() and not save_node.save_checkpoint("character") and not save_node._write_snapshot(true),"Every world save route is blocked")
    var after_save: String=FileAccess.get_file_as_string(save_node.save_path) if FileAccess.file_exists(save_node.save_path) else ""
    _check(before_save==after_save,"World does not overwrite plaza save")
    for i in range(10):await process_frame
    var hud: Node=manager.main.get_node("HUD")
    _check(not hud.hp_text.visible and not hud.title.visible and not hud.controls.visible,"Combat information hidden")
    world.map_ui.open_map()
    _check(paused and world.map_ui.opened,"Map pauses simulation")
    _check(world.map_ui.footer.text.contains("죽음 0회"),"Map death counter")
    world.map_ui.close()
    _check(not paused,"Map releases pause")
    world.abilities["dash"]=true
    for i in range(4):world.collected["life_test_"+str(i)]=true
    world.fragments=4
    world.switches["door_test"]=true
    world.crystals=7
    world.reveal_near(hero.position)
    var bits: PackedByteArray=world.explored.duplicate()
    world.invulnerable=false
    hero.position+=Vector2(700,0)
    hero.damage_grace=0
    hero.debug_hp_floor=false
    hero.hp=1
    _check(hero.receive_damage(999),"Lethal hit")
    _check(world.deaths_zabulistan==1 and world.deaths_total==1,"Death counted at confirmed HP zero")
    _check(not world.confirm_death(hero),"Duplicate fall/hit confirmation ignored")
    _check(not hero.receive_damage(999,{"source":"world_fall","grant_grace":false}),"Same-frame second fatal source ignored")
    hero.set_physics_process(false)
    await world.return_to_plaza()
    _check(not world.active and manager.current_level.level_id=="HwaniraPlaza","Death returns to plaza")
    _check(world.has_ability("dash") and world.switches.has("door_test") and world.fragments==4,"Permanent progression retained")
    _check(world.crystals==0 and world.explored==bits,"Consumables lost, fog retained")
    _check(hero.hp==110 and hero.get_max_hp()==110,"Permanent life upgrades are fully healed in plaza before fade in")
    var save: Node=root.get_node("Save")
    var snapshot: Dictionary=save.read_save()
    _check(int(snapshot.get("version",0))==2 and snapshot.has("zabulistan"),"Plaza checkpoint contains schema v2")
    _check(await save.resume(),"Resume new checkpoint")
    _check(world.deaths_zabulistan==1 and world.has_ability("dash"),"Persistent block restored")
    snapshot.erase("zabulistan")
    snapshot.erase("deaths_total")
    snapshot.version=1
    var migrated: Dictionary=save.migrate_save(snapshot)
    _check(migrated.version==2 and migrated.zabulistan.is_empty(),"Schema v1 migration")
    await world.enter()
    world.invulnerable=false
    hero.set_physics_process(false)
    hero.position=Vector2(500,float(world.settings.height)*32+100)
    hero.action="normal"
    hero.damage_grace=0
    world._process(0)
    _check(hero.hp==0 and world.deaths_zabulistan==2,"Out-of-world fall uses the same confirmed death path")
    await world.return_to_plaza()
    _check(manager.current_level.level_id=="HwaniraPlaza","Fall returns to plaza")
    hero.set_physics_process(true)
    _finish("stage14_continuous_runtime")
