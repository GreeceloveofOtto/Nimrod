extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    var save: Node=root.get_node("Save")
    save.save_path="user://stage14_f5.json"
    save.save_checkpoint("character")
    var flags_before: Dictionary=root.get_node("GameState").run_flags.duplicate(true)
    await world.enter("crystal_59","left",false)
    var room: WorldRoom=manager.current_level
    _check(room.room_data.boss_room and room.enemies.size()==1 and room.enemies[0].get_meta("world_boss",false),"Isolated placeholder boss room")
    _check(not world.can_exit(),"Boss locks exits")
    var boss: EnemyBase=room.enemies[0]
    boss.set_physics_process(false)
    boss.attack_stats=boss.stats.attacks[0]
    boss._set_state(EnemyBase.State.ACTIVE)
    _check(boss.get_attack_rect().size.x>0,"Placeholder boss hitbox")
    boss.hp=1
    boss.take_fixed_damage(100,hero.position)
    _check(world.can_exit() and world.collected.has("crystal_guardian"),"Victory unlock and session boss flag")
    _check(root.get_node("GameState").run_flags==flags_before,"No Nimrod story flags changed")
    await world.enter("landing_00","left",false)
    world.fragments=8
    world.abilities.dash=true
    manager.player_locked=false
    hero.set_transition_locked(false)
    await manager.full_reset_run()
    _check(not FileAccess.file_exists(save.save_path) and not world.active and world.fragments==0 and world.abilities.is_empty(),"F5 deletes save and complete world memory")
    _check(root.get_node("GameState").active_character=="nimrod" and hero.weapon=="none" and manager.current_level.level_id=="NimrodHome","F5 begins Nimrod from start")
    _finish("stage14_boss_save_policy")
