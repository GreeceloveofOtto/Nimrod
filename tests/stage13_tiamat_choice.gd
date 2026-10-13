extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var saga: Node=root.get_node("Odyssey")
    var choice: Node=root.get_node("Choice")
    var save: Node=root.get_node("Save")
    save.save_path="user://stage13_choice.json"
    story_state.debug_stage(19)
    story_state.set_flag("tiamat_talk_done",false)
    await _go("TiamatCollapsed")
    hero.global_position=Vector2(2400,880)
    saga._talk_tiamat()
    await dialogue_node.finished
    await process_frame
    _check(story_state.is_flag("tiamat_talk_done"),"Auto dialogue ends with story flag")
    _check(dialogue_node.name_label.text=="티아마트","Tiamat name chip")
    _check(not manager.player_locked and not paused,"Free movement after dialogue")
    _check(saga.tiamat_seconds>9.8,"10 seconds start after dialogue closes")
    var before: float=saga.tiamat_seconds
    paused=true
    await create_timer(.3,true).timeout
    _check(is_equal_approx(before,saga.tiamat_seconds),"Tiamat countdown pauses")
    paused=false
    saga.tiamat_seconds=.03
    saga.settings["darkness_seconds"]=.03
    await _wait(.2)
    _check(choice.active and choice.system_mode and story_state.is_flag("choice_pending"),"Blackness opens pending menu")
    _check(save.read_save().get("choice_pending",false) and save.read_save().get("story_stage",0)==19,"Quiet autosave persists pending choice")
    for i in [0,1,3]:
        choice.choose(i)
        _check(choice.active and root.get_node("GameState").active_character=="nimrod","Locked system rejected")
    choice.close()
    _check(await save.resume(),"Load pending save")
    await process_frame
    _check(choice.active and manager._fade_rect.modulate.a==1,"Load directly restores black menu")
    choice.choose(2)
    await manager.transition_finished
    await _wait(1.4)
    _check(manager.current_level.level_id=="HwaniraPlaza" and not manager.player_locked,"Unlocked system enters plaza")
    _check(root.get_node("GameState").active_character=="siyavash" and hero.hp==100,"Siyavash starts at HP100")
    var stored: Dictionary=save.read_save()
    _check(stored.get("story_stage",0)==20 and stored.get("active_character","")=="siyavash" and stored.get("selected_system","")=="laochachahra" and not stored.get("choice_pending",true),"Selection autosaved")
    await _finish("STAGE13_TIAMAT_CHOICE")
