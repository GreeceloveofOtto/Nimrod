extends "res://tests/helpers/stage9_support.gd"
var steps: Array[String] = []
func _run() -> void:
    await _start9()
    story_state.set_flag("villa_intro_done")
    await _go("VillaF2")
    var saved: String = hero.weapon
    cutscene_node.step_started.connect(func(kind: String) -> void: steps.append(kind))
    _check(manager.current_level.get_node("DinnerTable/Image").texture.resource_path.ends_with("villa_dining_table_full.webp"),"Intro prepares full table")
    var success: bool = await cutscene_node.play("villa_dinner")
    _check(success and story_state.is_flag("villa_dinner_done"),"Dinner completes once")
    _check(steps.count("spawn_npc")==2 and steps.count("despawn_npc")==2 and steps.count("dialogue")==1,"Both hosts descend, talk and leave")
    _check(hero.weapon==saved and not hero.visual_weapon_hidden and not manager.player_locked and not paused,"Dinner restores weapon, input and time")
    _check(not manager.current_level.npcs.has("shamash") and not manager.current_level.npcs.has("aya"),"Guests depart dining floor")
    await _go("VillaF3")
    _check(manager.current_level.npcs.is_empty(),"Hosts absent until first Kala defeat")
    await _finish("STAGE9_DINNER_CUTSCENE")
