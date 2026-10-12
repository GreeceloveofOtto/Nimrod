extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(15)
    var rage: Node = root.get_node("Rampage")
    _check(hero.selected_sprite_set()=="axe_prosthetic_helm","Baseline helmet and prosthetic")
    hero.action = "attack"
    hero.attack_step = 2
    hero.attack_clock = .16
    for row in [[41,"r40"],[51,"r50"],[91,"r90"]]:
        rage.death_suspended = true
        rage.set_value(row[0])
        hero.sync_story_state()
        _check(hero.sprite_set=="axe_prosthetic_helm_"+row[1],"Selected visual tier "+row[1])
        _check(hero.attack_clock==.16 and hero.attack_step==2,"Tier switch preserves attack clock/step")
        _check(hero.rampage_flash_left>0,"Tier change flashes")
    rage.set_value(40)
    hero.sync_story_state()
    _check(hero.sprite_set=="axe_prosthetic_helm","Cure threshold returns to baseline")
    rage.set_value(31)
    hero.velocity.x=100
    hero.get_node("AfterimageEffect")._physics_process(.1)
    await process_frame
    _check(main.get_children().any(func(child: Node): return child is Sprite2D),"Afterimage duplicates sprite")
    await _finish("STAGE11_FORMS")
