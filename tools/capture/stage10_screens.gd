extends "res://tests/helpers/stage9_support.gd"
func _save(label: String) -> void:
    hero.camera.position_smoothing_enabled = false
    hero.camera.reset_smoothing()
    hero.camera.force_update_scroll()
    await create_timer(.15,true,false,true).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_jpg("res://docs/screenshots/stage10_"+label+".jpg",.88)
func _run() -> void:
    root.size = Vector2i(1280,720)
    await _start9()
    main.get_node("HUD").story.hide()
    story_state.debug_stage(8)
    await _go("CedarBossRoom")
    hero.position = Vector2(760,620)
    await _save("onearm_melammu")
    story_state.debug_stage(9)
    await _go("NimrodHome","Spawn_FromMelammu")
    await _save("bed_awake")
    story_state.debug_stage(10)
    await _go("NimrodHome","Spawn_FromMelammu")
    await _save("inanna_bed_asleep")
    story_state.debug_stage(12)
    await _go("NimrodHome","Spawn_FromMelammu")
    root.get_node("Chapter").event("bed_blood")
    hero.cinematic_set = "cutscene"
    hero.sync_story_state()
    hero._show_clip("cry_loop",.6)
    root.get_node("Audio").play_bgm("home_sorrow")
    await _save("grieving")
    hero.cinematic_set = ""
    story_state.debug_stage(12)
    await _go("HomeFront")
    hero.position = Vector2(1460,880)
    hero.camera.position = Vector2(120,-200)
    var boss: Gugalanna = get_nodes_in_group("enemies")[0]
    boss.battle_started = true
    boss._show_clip("idle",0)
    await _save("gugalanna")
    boss.facing = -1
    boss.start_pattern("rake")
    boss._show_clip("rake_windup",.8)
    await _save("rake_warning")
    story_state.debug_stage(14)
    await _go("VillaF3","Spawn_FromSkip")
    hero.camera.position = Vector2.ZERO
    hero._show_clip("idle",0)
    await _save("prosthetic")
    await _go("VillaF4")
    await create_timer(.02,true,false,true).timeout
    cutscene_node.cancel()
    hero.position = Vector2(1400,620)
    await _save("rooftop")
    await _go("Dilmun","Spawn_Landing")
    await _save("dilmun")
    await _finish("STAGE10_SCREENS")
