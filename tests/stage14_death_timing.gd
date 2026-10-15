extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    var save: Node=root.get_node("Save")
    save.save_path="user://stage14_death_timing.json"
    world.timing_scale=1
    await world.enter()
    hero.position+=Vector2(700,0)
    world.invulnerable=false
    hero.damage_grace=0
    hero.debug_hp_floor=false
    hero.set_physics_process(true)
    var began:=Time.get_ticks_usec()
    _check(hero.receive_damage(99999),"Real fatal hit accepted")
    while Time.get_ticks_usec()-began<4000000:
        if not world.active and manager.current_level!=null and manager.current_level.level_id=="HwaniraPlaza" and not manager.player_locked and not world.transitioning:break
        await process_frame
    var elapsed: float=(Time.get_ticks_usec()-began)/1000000.
    print("DEATH_RETURN_SECONDS: ",elapsed)
    _check(not world.active and manager.current_level.level_id=="HwaniraPlaza" and not manager.player_locked,"Automatic death path restores plaza control")
    _check(elapsed<3.,"Real death animation and plaza return within three seconds")
    _check(world.deaths_zabulistan==1 and hero.hp==hero.get_max_hp(),"Death count and full heal")
    _check(save.read_save().get("zabulistan",{}).get("deaths_zabulistan",0)==1,"Arrival checkpoint contains confirmed death")
    _finish("stage14_death_timing")
