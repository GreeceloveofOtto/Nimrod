extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var required: Array = ["idle","walk","run","crouch_enter","crouch_idle","crouch_exit","jump_start","jump_rise","fall","land","drop_through","roll","hurt","death","attack_1","attack_2","attack_3","attack_4"]
    for set_id in ["axe","axe_onearm","axe_prosthetic"]:
        var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/player/"+set_id+"/manifest.json"))
        var clips: Dictionary = {}
        for clip: Dictionary in data["clips"]:
            clips[clip["name"]] = clip
            _check(int(clip["anchor_px"][0])==320 and int(clip["anchor_px"][1])==600 and clip["frame_width"]==640 and clip["frame_height"]==640,"Canonical anchor/frame "+set_id+"/"+str(clip["name"]))
            _check(ResourceLoader.exists("res://assets/"+str(clip["sheet"])),"All clips present "+str(clip["sheet"]))
        for name in required:
            _check(clips.has(name),"Common clip "+set_id+"/"+str(name))
        var clip: Dictionary = clips["idle"]
        var image: Image = (load("res://assets/"+str(clip["sheet"])) as Texture2D).get_image()
        var crop: Dictionary = clip["storage_trim"]
        var bound: Rect2i = image.get_region(Rect2i(0,0,int(crop["w"]),int(crop["h"]))).get_used_rect()
        var height: float = bound.size.y/float(clip["storage_scale"][1])
        _check(absf(height-363)<=363*.03,"Same display height "+set_id)
        var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/player/axe/manifest.json"))
        for original: Dictionary in old["clips"]:
            _check(clips[original["name"]]["duration_seconds"]==original["duration_seconds"] and clips[original["name"]]["frames"]==original["frames"],"Unchanged action timing and logical frames "+set_id+"/"+str(original["name"]))
    await _finish("STAGE10_SPRITE_SETS")
