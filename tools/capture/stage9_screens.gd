extends "res://tests/helpers/stage9_support.gd"
func _save(label: String) -> void:
    hero.camera.position_smoothing_enabled=false
    hero.camera.reset_smoothing()
    hero.camera.force_update_scroll()
    await create_timer(.15,true,false,true).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_jpg("res://docs/screenshots/stage9_"+label+".jpg",.86)
func _run() -> void:
    root.size=Vector2i(1280,720)
    await _start9()
    main.get_node("HUD").story.hide()
    story_state.debug_stage(1)
    await _go("VillaF2")
    hero.global_position=Vector2(1360,620)
    await _save("dining_full")
    cutscene_node.timing_scale=.5
    dialogue_node.test_timing_scale=.08
    var saved: bool=false
    cutscene_node.step_started.connect(func(kind: String) -> void:
        if kind=="dialogue" and not saved:
            saved=true
            _dinner_capture())
    await cutscene_node.play("villa_dinner")
    story_state.debug_stage(3)
    await _go("VillaF1")
    hero.global_position=Vector2(950,620)
    await _save("night_empty")
    await _go("VillaF2")
    hero.global_position=Vector2(1360,620)
    await _save("night_preparation")
    story_state.debug_stage(4)
    await _go("CastleF1")
    hero.global_position=Vector2(850,620)
    await _save("castle_return")
    story_state.debug_stage(7)
    await _go("CedarBossRoom")
    hero.global_position=Vector2(900,620)
    var boss: Humbaba=get_nodes_in_group("enemies")[0]
    boss.battle_started=true
    boss._lock_arrival(true)
    boss.set_physics_process(false)
    boss._show_clip("idle",0)
    await _save("humbaba")
    boss.phase_two=true
    boss._update_visual(0)
    boss._effect("humbaba_ember_aura",Vector2(0,-155),true)
    await _save("humbaba_phase2")
    await _go("CastleF1")
    hero.global_position=Vector2(800,620)
    hero.skill_cooldown_left=0
    hero.cast_anur_light()
    await _save("anur_light")
    await _finish("STAGE9_SCREENS")
func _dinner_capture() -> void:
    await create_timer(.8,true,false,true).timeout
    await _save("dinner_dialogue")
