extends "res://tests/helpers/stage4_support.gd"
func _run() -> void:
    await _start(false)
    var font: Font = load("res://assets/fonts/NimrodUIKorean-Regular.otf")
    var d: Node = root.get_node("Dialogue")
    for story: Dictionary in d.settings.interactions.values():
        var specs: Array = [story]
        specs.append_array(story.get("variants",[]))
        for spec: Dictionary in specs:
            for line: Dictionary in spec.get("first",[])+spec.get("repeat",[]):
                for character: String in str(line.get("text","")):
                    _check(font.has_char(character.unicode_at(0)),"Every original dialogue character has a glyph")
    var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage8_story_original.json"))
    for id: String in original:
        for field: String in original[id]:
            _check(d.settings.interactions[id].get(field)==original[id][field],"Original story field unchanged: "+id+"/"+field)
    _check(original.enkidua_intro.first.size()==7 and original.parents_gift.first.size()==6 and original.shamhat.first.size()==5,"Original first-line counts include gift event")
    d.settings.character_seconds = .001
    d.settings.hold_seconds = .001
    d.settings.hold_per_character = .00001
    d.test_timing_scale = .001
    var state: Node = root.get_node("GameState")
    state.reset_run(false)
    await manager.go_to("CastleF1", "Spawn_Debug", {"instant": true})
    await d.play_interaction("parents_gift")
    _check(state.get_weapon()=="axe" and state.visit_count("parents_gift")==1,"Gift event equips axe and records visit")
    await d.play_interaction("parents_gift")
    _check(state.visit_count("parents_gift")==2 and state.get_weapon()=="axe","Repeat greeting retains axe")
    await manager.go_to("CastleF2", "Spawn_FromBelow", {"instant": true})
    await d.play_interaction("shamhat")
    _check(not state.run_flags.get("shamhat_blessing",false),"First Shamhat conversation gives no blessing")
    await d.play_interaction("shamhat")
    _check(state.run_flags.get("shamhat_blessing",false) and hero.get_max_hp()==270,"Second conversation blesses and increases max HP")
    _check(d.interaction_available("shamhat"),"Blessed Shamhat keeps menu and repeat conversation")
    await manager.go_to("CastleF3", "Spawn_FromBelow", {"instant": true})
    _check(manager.current_level.npcs.cook_a.interactable and not manager.current_level.npcs.cook_b.interactable,"Only nearest CastleF3 cook_a interacts")
    await d.play_interaction("castle_cook")
    _check(not d.interaction_available("castle_cook"),"Cook dialogue is one time")
    await manager.go_to("CastleF4", "Spawn_FromBelow", {"instant": true})
    var keeper: NPC = manager.current_level.npcs.papsukkal
    var at: Vector2 = keeper.position
    await d.play_interaction("inanna")
    _check(keeper.position.is_equal_approx(at),"Papsukkal returns after intercept")
    await d.play_interaction("inanna")
    _check(state.visit_count("inanna")==2,"Papsukkal repeats rejection")
    await manager.go_to("NimrodHome", "Spawn_Start", {"instant": true})
    await d.play_interaction("enkidua_intro")
    await d.play_interaction("enkidua_intro")
    _check(state.visit_count("enkidua_intro")==2,"Enkidua greeting then love repeat")
    for target in [["CastleOutskirts", "Spawn_FromGate", "castle_gatekeeper", "castle_great_gate", "castle_gatekeeper_outer"], ["RearGate", "Spawn_FromVilla", "villa_gatekeeper", "villa_gate", "gatekeeper"]]:
        await manager.go_to(target[0], target[1], {"instant": true})
        var gate: GateController = manager.current_level.doors[target[3]]
        _check(gate._dialogue_locked(),"Story gate initially waits for conversation")
        await d.play_interaction(target[2])
        _check(not gate._dialogue_locked() and not d.interaction_available(target[2]),"Original gate dialogue authorizes once and hides its prompt")
    state.run_flags.erase("dialogue_passage_soliloquy")
    await manager.go_to("DowntownPassage_F8", "Spawn_FromTop", {"instant": true})
    await d.started
    _check(paused and d.active,"F8 soliloquy automatically starts after arrival and pauses time")
    await d.finished
    await process_frame
    _check(state.visit_count("passage_soliloquy")==1,"F8 soliloquy records its first visit")
    state.reset_run(false)
    for id: String in original:
        _check(d.interaction_available(id),"Reset restores first interaction: "+id)
    await _finish("STAGE8_STORY_DIALOGUE")
