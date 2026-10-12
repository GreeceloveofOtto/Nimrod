extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(12)
    _check(hero.selected_sprite_set()=="axe_onearm","Arm loss before helmet")
    story_state.debug_stage(13)
    _check(story_state.is_flag("helmet_equipped") and hero.selected_sprite_set()=="axe_onearm_helm","Stage13 equips helmet")
    story_state.debug_stage(14)
    _check(hero.selected_sprite_set()=="axe_prosthetic_helm","Stage14 keeps helmet with prosthetic")
    _check(not DirAccess.dir_exists_absolute("res://assets/sprites/player/axe_prosthetic"),"Obsolete no-helmet prosthetic archived")
    var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/player/axe/manifest.json"))
    for id in ["axe_onearm_helm","axe_prosthetic_helm","axe_prosthetic_helm_r40","axe_prosthetic_helm_r50","axe_prosthetic_helm_r90"]:
        var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/player/"+id+"/manifest.json"))
        var clips: Dictionary = {}
        for c: Dictionary in manifest["clips"]:
            clips[c["name"]] = c
            _check(int(c["anchor_px"][0])==320 and int(c["anchor_px"][1])==600,"Foot anchor "+id+"/"+str(c["name"]))
            _check(ResourceLoader.exists("res://assets/"+c["sheet"]),"Physical sheet "+str(c["sheet"]))
        for c: Dictionary in base["clips"]:
            _check(clips.has(c["name"]) or manifest.get("aliases",{}).has(c["name"]),"Every state resolves "+id+"/"+str(c["name"]))
        if clips.has("devour"):
            _check(clips["devour"]["frames"]==8 and clips["devour"]["duration_seconds"]==.7,"Devour timing")
    await _finish("STAGE11_HELMET_SETS")
