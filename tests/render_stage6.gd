extends "res://tests/helpers/stage4_support.gd"

var shots: int = 0

func _shot(name: String, at: Vector2, reposition: bool = true) -> void:
    if reposition:
        hero.global_position = at
        hero.camera.reset_smoothing()
        hero.camera.force_update_scroll()
    await create_timer(.15,true,false,true).timeout
    await process_frame
    await RenderingServer.frame_post_draw
    var path: String = "res://docs/screenshots/stage6_"+name+".png"
    _check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK,"Screenshot writes" )
    shots += 1
    print("SCREENSHOT ",path)

func _run() -> void:
    if DisplayServer.get_name() == "headless":
        quit(1)
        return
    root.size=Vector2i(1280,720)
    await _start()
    hero.camera.position_smoothing_enabled=false
    main.get_node("HUD").story.hide()
    await manager.go_to("HomeRoad","Spawn_FromHome")
    var exterior: Node2D = manager.current_level.get_node("HomeExterior")
    var corrected: Vector2 = exterior.position
    exterior.position.y -= 73
    await _shot("home_before",Vector2(480,880))
    exterior.position=corrected
    await _shot("home_after",Vector2(480,880))
    for sample in [["NimrodHome","Spawn_FromGate",Vector2(1030,620)],["VillaBackyard","Spawn_FromBackDoor",Vector2(600,880)],["CedarForest_F1","Spawn_FromVilla",Vector2(2100,3328)],["CedarForest_F2","Spawn_FromBelow",Vector2(2100,3328)],["CedarBossRoom","Spawn_FromForest",Vector2(1050,800)]]:
        await manager.go_to(sample[0],sample[1])
        for enemy: EnemyBase in get_nodes_in_group("enemies"):
            enemy._update_visual(0)
            if enemy is KalaUshumgal:
                enemy.battle_started=true
                enemy._lock_arrival(true)
        await _shot(sample[0],sample[2])
    await manager.go_to("DowntownPassage_F1","Spawn_FromAbove")
    for enemy: EnemyBase in get_nodes_in_group("enemies"):
        enemy.queue_free()
    await process_frame
    for id in ["explosive_spitter","wall_diver","root_spewer","boar_charger","gas_sac","wraith_ray","shell_scorpion","corpse_bomber","chain_beastman"]:
        var actor: EnemyBase = load("res://scripts/enemy_"+id+".gd").new()
        actor.position=Vector2(1850,620 if id not in ["gas_sac","wraith_ray","wall_diver"] else 470)
        manager.current_level.add_child(actor)
        actor.set_physics_process(false)
        actor._show_clip("idle",0)
        await _shot("size_"+id,Vector2(1510,620))
        if id=="explosive_spitter":
            actor.state=EnemyBase.State.WINDUP
            await _shot("threat_windup",Vector2(1510,620))
        actor.queue_free()
        await process_frame
    await _shot("surface_accents",Vector2(2740,620))
    await manager.go_to("CastleF2","Spawn_FromBelow")
    var shamhat: NPC = manager.current_level.npcs["shamhat"]
    hero.global_position=shamhat.global_position-Vector2(80,0)
    hero._show_clip("idle",0)
    shamhat.interact(hero)
    await create_timer(.8,true,false,true).timeout
    await _shot("shamhat_dialogue",hero.global_position,false)
    await root.get_node("Dialogue").finished
    await _shot("shamhat_blessing",hero.global_position)
    print("STAGE6_CAPTURE: ",shots," screenshots")
    await _finish("STAGE6_CAPTURE")
