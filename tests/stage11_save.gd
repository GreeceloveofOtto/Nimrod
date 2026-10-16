extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var save: Node = root.get_node("Save")
    save.save_path = "user://stage11_save_test.json"
    for suffix in ["",".bak",".tmp"]:
        DirAccess.remove_absolute(save.save_path+suffix)
    await _go("CastleF2")
    story_state.debug_stage(15)
    root.get_node("Rampage").set_value(50)
    hero.position = Vector2(850,620)
    hero.facing = -1
    hero.hp = 100
    hero.skill_cooldown_left = 4
    hero.devour_cooldown_left = 9
    _check(save.save_game(),"Shamhat-level save succeeds")
    var first: Dictionary = save.read_save()
    _check(first["version"]==3 and first["cooldowns"]["anur_light"]==0 and first["cooldowns"]["devour"]==0,"Versioned snapshot clears skill cooldowns")
    _check(not first.has("debug_hp_floor"),"Debug mode is never persisted")
    hero.hp = 80
    _check(save.save_game() and FileAccess.file_exists(save.save_path+".bak"),"Atomic overwrite preserves previous save")
    root.get_node("GameState").reset_run(false)
    hero.reset_run_state()
    _check(await save.resume(false),"Startup-style resume succeeds")
    _check(manager.current_level.level_id=="CastleF2" and hero.position.distance_to(Vector2(850,620))<1 and hero.facing==-1,"Level/position/facing restored")
    _check(hero.hp==80 and root.get_node("Rampage").value()==50 and hero.sprite_set=="axe_prosthetic_helm_r40","HP/rampage/helmet form restored")
    var broken := FileAccess.open(save.save_path,FileAccess.WRITE)
    broken.store_string("broken")
    broken.close()
    _check(save.read_save()["hp"]==100,"Corrupt primary falls back to previous backup")
    _check(JSON.parse_string(FileAccess.get_file_as_string(save.save_path)) is Dictionary,"Backup recovery repairs primary atomically")
    hero.hp = 0
    hero.action = "dead"
    await manager.handle_death()
    _check(hero.hp==hero.get_max_hp() and hero.action=="normal","Death returns to checkpoint at full current maximum")
    await manager.full_reset_run()
    _check(manager.current_level.level_id=="NimrodHome" and root.get_node("GameState").get_weapon()=="none" and not root.get_node("Rampage").unlocked(),"F5 starts a fresh run")
    _check(not FileAccess.file_exists(save.save_path),"F5 deletes disk checkpoint in stage12")
    var migrated: Dictionary = save.migrate_save({"version":0,"level":"CastleF2","position":[800,620],"run_flags":{"prosthetic_equipped":true,"weapon":"axe"}})
    _check(migrated["version"]==3 and migrated["run_flags"]["helmet_equipped"],"Older versions repair missing helmet and defaults")
    for suffix in ["",".bak"]:
        var file := FileAccess.open(save.save_path+suffix,FileAccess.WRITE)
        file.store_string("broken")
        file.close()
    _check(save.read_save().is_empty(),"Both corrupt files produce fresh-game fallback")
    for suffix in ["",".bak",".tmp",".recovery.tmp"]:
        DirAccess.remove_absolute(save.save_path+suffix)
    await _finish("STAGE11_SAVE")
