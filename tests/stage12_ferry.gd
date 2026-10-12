extends "res://tests/helpers/stage9_support.gd"
var spoken: Array[String] = []
var delivery_lines: Array[int] = []
var phases: Array[String] = []
func _run() -> void:
    await _start9()
    var ferry: Node = root.get_node("Ferry")
    var save: Node = root.get_node("Save")
    save.save_path = "user://stage12_ferry.json"
    save.erase_save()
    dialogue_node.line_changed.connect(func(_speaker: String,line: String) -> void: spoken.append(line))
    ferry.paper_delivered.connect(func() -> void: delivery_lines.append(spoken.size()))
    ferry.phase_changed.connect(func(phase: String) -> void:
        phases.append(phase)
        _check(manager.player_locked and paused,"Ferry input/world stay locked during "+phase)
        if phase == "black":
            _check(is_equal_approx(manager._fade_rect.modulate.a,1.),"Black precedes level switch")
            _check(not FileAccess.file_exists(save.save_path),"No save during boarding")
    )
    story_state.debug_stage(17)
    await _go("DeathSea")
    story_state.set_flag("death_sea_paper",false)
    await dialogue_node.play_interaction("urshanabi_ferry")
    _check(spoken==["…통행증이 없으면 곤란한데."] and delivery_lines.is_empty(),"No paper means only the exact 안내 line")
    _check(not ferry.boarding_requested and not story_state.is_flag("paper_handed"),"No-paper fallback cannot consume or board")
    spoken.clear()
    story_state.set_flag("death_sea_paper")
    dialogue_node.test_timing_scale = 1.
    var events_pending := true
    dialogue_node.play_interaction("urshanabi_ferry")
    for i in range(400):
        await create_timer(.02,true).timeout
        if dialogue_node.active:
            dialogue_node.skip_delay = 0
            dialogue_node.skip_line()
        if story_state.is_flag("tiamat_arrived") and not cutscene_node.active:
            events_pending = false
            break
    _check(not events_pending,"Rapid E skip still reaches Tiamat and returns control")
    var expected: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage12_urshanabi_lines.json"))
    _check(spoken==expected,"All ten lines match the independent original fixture")
    _check(delivery_lines==[9],"Paper event executes exactly once after line 9")
    _check(phases==["boarding","fade_out","black","arrival","ashore"],"Boarding/black/transition/disembark order")
    _check(manager.current_level.level_id=="TiamatZone" and not manager.player_locked and not paused,"Arrival returns all control")
    _check(not story_state.is_flag("death_sea_paper") and story_state.is_flag("paper_handed") and story_state.is_flag("ferry_boarded") and story_state.stage()==18,"Consumed paper and stage18 flags retained")
    for i in range(5):
        await process_frame
    _check(save.read_save().get("level")=="TiamatZone","Autosave runs only after completed arrival")
    _check(not save.can_save() and not save.save_game(),"No new manual save point in Tiamat")
    var position_saved: Vector2 = hero.position
    hero.hp = 1
    _check(await save.resume(false),"Tiamat checkpoint can be resumed")
    _check(hero.position.distance_to(position_saved)<1 and story_state.is_flag("tiamat_arrived"),"Resume restores coordinates and new flags")
    var old: Dictionary = save.migrate_save({"version":1,"level":"DeathSea","position":[800,880],"hp":100,"run_flags":{"deathsea_arrived":true,"death_sea_paper":true,"weapon":"axe"}})
    _check(not old.is_empty() and not old["run_flags"].get("tiamat_arrived",false),"Stage11 stage17 save remains compatible")
    _check(manager.current_level.npcs.has("utnapishtim"),"Utnapishtim restored")
    var missing_count := 0
    for placeholder: CanvasItem in manager.current_level.find_children("MISSING_TEXTURE","CanvasItem",true,false):
        if placeholder.is_visible_in_tree():
            missing_count += 1
    _check(missing_count==0,"New level has no visible missing textures")
    save.erase_save()
    await _finish("STAGE12_FERRY")
