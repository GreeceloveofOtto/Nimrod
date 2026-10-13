extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(18)
    await _go("TiamatZone")
    var form: Node=root.get_node("HumbabaForm")
    var rage: Node=root.get_node("Rampage")
    rage.set_death_suspended(true)
    rage.set_value(60)
    cutscene_node.timing_scale=.12
    var observed: Array[String]=[]
    cutscene_node.play("utnapishtim_rampage")
    while cutscene_node.active:
        var stage:=""
        if form.state=="transforming":stage="transform"
        elif form.state=="active" and manager._fade_rect.modulate.a>.9:stage="black_form"
        elif form.state=="active" and hero.displayed_clip.begins_with("claw"):stage="claws"
        elif not form.engaged() and manager._fade_rect.modulate.a>.9:stage="black_human"
        if not stage.is_empty() and not observed.has(stage):observed.append(stage)
        await process_frame
    _check(observed==["transform","claws","black_form","black_human"],"Observed actual render/blackout order: "+str(observed))
    _check(not form.engaged() and rage.value()==60 and rage.death_suspended,"Cutscene removes form without exhaustion and leaves60 suspended")
    var elder: NPC=manager.current_level.npcs["utnapishtim"]
    _check(elder.current_clip=="idle" and manager.current_level.has_node("UtnapishtimBlood") and not manager.player_locked,"Standing old man, grounded pool, player restored")
    _check(root.get_node("Save").read_save()["rampage"]==60,"Automatic save happens after human return")
    # Cancellation while transforming also restores the actor and form resources.
    form.cooldown_left=0
    story_state.set_flag("utnapishtim_done",false)
    cutscene_node.play("utnapishtim_rampage")
    await _wait(.01)
    cutscene_node.cancel()
    await process_frame
    _check(not form.engaged() and not manager.player_locked and not paused,"Interrupted cutscene restores human/control: %s/%s/%s"%[form.state,manager.player_locked,paused])
    await _finish("HUMBABA_CUTSCENE")
