extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(13)
    await _go("VillaF3","Spawn_FromSkip")
    hero.hp = 1
    var before: int = hero.get_max_hp()
    await dialogue_node.play_interaction("villa_prosthetic")
    _check(story_state.is_flag("prosthetic_equipped") and hero.sprite_set=="axe_prosthetic_helm","Mid-line prosthetic event")
    _check(hero.get_max_hp()==245 and hero.get_max_hp()-before==30,"Flat HP stacks20+15+30")
    _check(is_equal_approx(hero.modifiers.multiplier("attack"),1.35) and is_equal_approx(hero.modifiers.multiplier("attack_speed"),1.1),"Additive attack35/speed10 percent")
    _check(hero.hp==31,"Current HP increases by max HP delta")
    _check(not manager.current_level.doors["villa_up_locked"].locked,"Rooftop unlock")
    hero.apply_shamhat_blessing()
    _check(hero.get_max_hp()==368,"Flat HP before percent multiplier, round")
    await _finish("STAGE10_PROSTHETIC")
