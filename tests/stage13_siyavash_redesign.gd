extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    var state: Node = root.get_node("GameState")
    var settings: Dictionary = state.siyavash_settings
    _check(settings["display_name"] == "시야우와르샨", "Updated display spelling")
    var korean_font: Font = load("res://assets/fonts/NimrodUIKorean-Regular.otf")
    _check(korean_font.has_char("샨".unicode_at(0)), "Renamed character has a real font glyph")
    _check(settings["animal_features"] and settings["animal_type"] == "rat", "Subtle rat characteristics enabled")
    _check(settings["age"] == 20 and settings["max_hp"] == 100 and settings["weapon"] == "none" and settings["skills"].is_empty(), "Gameplay contract unchanged")
    _check(settings["eye_color"] == "dark gray-green", "Requested iris color")
    state.switch_character("siyavash")
    root.get_node("Dialogue")._set_speaker(null, "player")
    _check(root.get_node("Dialogue").name_label.text == settings["display_name"], "Player dialogue chip follows current character")
    state.switch_character("nimrod")
    root.get_node("Dialogue")._set_speaker(null, "player")
    _check(root.get_node("Dialogue").name_label.text == "니므롯", "Nimrod dialogue spelling preserved")
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/player/siyavash/manifest.json"))
    var bytes: int = 0
    var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art_manifest.json"))
    for clip: Dictionary in manifest["clips"]:
        var path: String = "res://assets/" + str(clip["sheet"])
        _check(ResourceLoader.exists(path) and load(path) is Texture2D, "Texture loaded: " + str(clip["name"]))
        var catalog_match: bool = false
        for entry: Dictionary in catalog["assets"]:
            if str(entry["path"]) == str(clip["sheet"]):
                catalog_match = int(entry["width"]) == int(clip["image_size"][0]) and int(entry["height"]) == int(clip["image_size"][1])
        _check(catalog_match, "Asset catalog contains current dimensions")
        _check(float(clip["effective_density"]) <= 2.0001 and float(clip["effective_density"]) >= .8, "Player density range")
        _check(int(clip["anchor_px"][0]) == 320 and int(clip["anchor_px"][1]) == 600 and int(clip["stored_padding"]) >= 2, "Existing anchor and safe atlas gutter")
        _check(clip["face_landmarks"].size() == clip["frames"], "Every logical frame has face review coordinates")
        if str(clip["name"]) not in ["dash","wall_cling","wall_jump","crawl"]:
            bytes += FileAccess.get_file_as_bytes(path).size()
    _check(bytes <= 998546, "Replacement sheets fit original byte budget")
    root.get_node("Audio").release_streams()
    print("STAGE13_SIYAVASH_REDESIGN: ", checks, " checks, ", failures, " failures")
    quit(1 if failures else 0)
