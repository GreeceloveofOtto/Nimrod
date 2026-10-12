extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    await manager.go_to("CastleF2", "Spawn_FromBelow")
    var npc: NPC = manager.current_level.npcs["shamhat"]
    _check(npc.interactable and npc.stats["interact_range"] == 120, "Shamhat range and hook")
    hero.reset_run_state()
    hero.set_transition_locked(false)
    hero.hp = 100
    hero.global_position = npc.global_position - Vector2(80,0)
    Input.action_press("interact")
    npc._process(0)
    await process_frame
    await process_frame
    Input.action_release("interact")
    _check(paused and root.get_node("Dialogue").active and npc.pose==NPC.Pose.FRONT,"Real E input pauses world and faces Shamhat front")
    await create_timer(.4,true,false,true).timeout
    _check(hero.camera.zoom.x > 1.3 and hero.camera.zoom.x <= 1.3501 and hero.camera.process_mode==Node.PROCESS_MODE_ALWAYS,"Dialogue camera actually processes while paused")
    await root.get_node("Dialogue").finished
    await process_frame
    _check(hero.get_max_hp()==180 and hero.hp==100,"First dialogue gives no blessing")
    await create_timer(.21,true,false,true).timeout
    npc.interact(hero)
    await process_frame
    _check(root.get_node("Choice").active,"Repeated E opens choice menu")
    await root.get_node("Choice").choose(0)
    await process_frame
    _check(hero.get_max_hp()==270 and hero.hp==190,"Second dialogue grants blessing")
    _check(root.get_node("Dialogue").interaction_available("shamhat"),"Blessed NPC retains repeat conversation menu")
    root.get_node("GameState").reset_run(false)
    hero.reset_run_state()
    hero.hp = 100
    _check(hero.apply_shamhat_blessing(),"First blessing applies")
    _check(hero.get_max_hp() == 270 and hero.hp == 190,"Maximum270 grants exactly90 current HP")
    _check(not hero.apply_shamhat_blessing() and hero.hp == 190,"Blessing cannot stack in same run")
    _check(roundi(20*hero.modifiers.multiplier("attack")) == 30 and roundi(22*hero.modifiers.multiplier("attack")) == 33,"All axe damage scales50percent")
    hero.modifiers.add_modifier("future", {"attack_speed":2.0})
    _check(hero.modifiers.multiplier("attack_speed") == 2.0,"Speed capped2")
    hero.modifiers.modifiers.erase("future")
    root.get_node("GameState").set_weapon("axe")
    hero._begin_attack(1)
    hero._update_attack(.02)
    _check(is_equal_approx(hero.attack_clock,.03),"Only attack clock speeds up")
    _check(is_equal_approx(NimrodPlayer.ROLL_DURATION,.48) and is_equal_approx(NimrodPlayer.RUN_SPEED,360),"Roll and movement unchanged")
    var zoom: Vector2 = hero.camera.zoom
    var offset: Vector2 = hero.camera.offset
    root.get_node("Dialogue").play(["네가 자꾸 신경쓰여."], npc, {"character_seconds":.001,"hold_seconds":.01})
    await process_frame
    _check(paused and root.get_node("Dialogue").active and npc.name_tag.visible,"Dialogue freezes world and retains speaker name")
    await root.get_node("Dialogue").finished
    _check(not paused and not root.get_node("Dialogue").active and hero.camera.zoom.is_equal_approx(zoom) and hero.camera.offset.is_equal_approx(offset),"Dialogue restores pause and camera")
    root.get_node("GameState").reset_run(false)
    hero.reset_run_state()
    _check(hero.hp == 180 and hero.get_max_hp() == 180 and not root.get_node("GameState").run_flags.has("shamhat_blessing"),"Death resets run modifier and flags")
    root.get_node("Dialogue").play(["취소 검증"],npc,{"character_seconds":.01})
    await process_frame
    root.get_node("Dialogue").cancel()
    _check(not paused and not root.get_node("Dialogue").active and hero.camera.zoom.is_equal_approx(zoom),"Cancel restores frozen world and camera immediately")
    await _finish("STAGE6_SHAMHAT_BUFF")
