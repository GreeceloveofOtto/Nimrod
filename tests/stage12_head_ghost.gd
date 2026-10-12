extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(15)
    root.get_node("Rampage").death_suspended = true
    for value in [0,41,51,95]:
        root.get_node("Rampage").set_value(value)
        hero.sync_story_state()
        var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/player/"+hero.sprite_set+"/manifest.json"))
        _check(manifest.get("helmet_horns")==1,"Single-horn design in "+hero.sprite_set)
        _check(manifest.get("helmet_height_allowance_px")==45,"Helmet allowance unchanged")
        for clip: Dictionary in manifest["clips"]:
            _check(float(clip["anchor_px"][0])==320. and float(clip["anchor_px"][1])==600.,"Feet anchor unchanged "+clip["name"])
            hero._show_clip(clip["name"],0)
            _check(hero.visual.texture!=null and hero.visual.visible and hero.visual.region_filter_clip_enabled,"No missing art and region filter clipping "+clip["name"])
            var source: Image=hero.visual.texture.get_image()
            var cell: Image=source.get_region(Rect2i(hero.visual.region_rect))
            var alpha: Image=cell
            var clean := true
            for x in range(alpha.get_width()):
                clean = clean and alpha.get_pixel(x,0).a==0 and alpha.get_pixel(x,1).a==0
            _check(clean,"Two top transparent rows "+clip["name"])
    var one: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/player/axe_onearm_helm/manifest.json"))
    _check(one.get("helmet_horns")==1,"One-arm helmet also matches")
    await _finish("STAGE12_HEAD_GHOST")
