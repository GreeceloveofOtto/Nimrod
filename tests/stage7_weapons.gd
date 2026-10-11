extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start(false)
    var state: Node = root.get_node("GameState")
    _check(manager.current_level.level_id == "NimrodHome" and hero.global_position.x == 330, "New run begins at home x330")
    _check(hero.weapon == "none" and hero.max_step == 0, "New run is unarmed")
    hero._begin_attack(1)
    _check(hero.action == "normal" and hero.attack_step == 0, "Unarmed J cannot attack")
    var pickup: Node = get_first_node_in_group("weapon_pickups")
    hero.global_position = pickup.global_position
    pickup.interact(hero)
    _check(hero.weapon == "staff" and hero.max_step == 3 and state.run_flags["staff_taken"], "E equips the cedar staff and removes its pickup")
    _check(hero.attack_data[1]["damage"] == 18 and hero.attack_data[2]["damage"] == 18 and hero.attack_data[3]["damage"] == 24, "Staff has its independent 18/18/24 combo")
    _check(hero.shockwave_data.is_empty() and hero.weapon_hitstop == .03, "Staff has no shockwave and .03 hitstop")
    hero.velocity = Vector2.ZERO
    hero._physics_process(.02)
    hero._begin_attack(3)
    hero.facing = 1
    hero._direction_cancel_attack(-1)
    _check(hero.attack_step == 1 and hero.facing == -1, "Staff direction cancel wraps three strikes")
    hero._cancel_attack()
    hero.hp = 123
    state.run_flags["teleport_test"] = true
    await root.get_node("DebugTeleport").teleport("CastleF1", "Spawn_Debug")
    _check(hero.hp == 123 and hero.weapon == "staff" and state.run_flags["teleport_test"], "Debug teleport preserves HP, weapon and flags")
    _check(hero.global_position.x == 760 and not manager.player_locked, "Key 1 destination is x760, with input released")
    var parents: NPC = manager.current_level.npcs["lugalbanda"]
    hero.global_position = (parents.global_position + manager.current_level.npcs["ninsun"].global_position) * .5
    parents.interact(hero)
    await process_frame
    _check(root.get_node("Dialogue").active and paused, "Parents' first interaction pauses the world")
    await root.get_node("Dialogue").finished
    _check(hero.weapon == "axe" and hero.max_step == 4, "The gift equips the axe after its flight")
    _check(hero.attack_data[4]["damage"] == 22 and hero.weapon_hitstop == .05, "Original axe damage and hitstop remain unchanged")
    await create_timer(.25).timeout
    parents.interact(hero)
    _check(root.get_node("Dialogue").active, "Parents repeat the greeting without giving a second axe")
    await root.get_node("Dialogue").finished
    await state.reset_run()
    _check(manager.current_level.level_id == "NimrodHome" and hero.hp == 180 and hero.weapon == "none", "Restart restores home, HP180 and empty hands")
    _check(not state.run_flags.has("staff_taken") and not state.run_flags.has("teleport_test"), "Restart clears pickup and run flags")
    _check(get_nodes_in_group("weapon_pickups").size() == 1, "Staff pickup respawns after restart")
    await _finish("STAGE7_WEAPONS")
