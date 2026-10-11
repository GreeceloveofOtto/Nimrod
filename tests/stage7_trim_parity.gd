extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprite_trims.json"))
    var sprite := Sprite2D.new()
    root.add_child(sprite)
    for path: String in registry:
        var spec: Dictionary = registry[path]
        var crop: Dictionary = spec["trim"]
        var anchor: Array = spec["anchor_px"]
        var texture := load(path) as Texture2D
        _check(texture != null, "Trimmed texture loads: " + path)
        _check(texture.get_width() == int(crop["w"]) * int(spec["frames"]) and texture.get_height() == int(crop["h"]), "Uniform crop matches texture dimensions")
        var last: int = int(spec["frames"]) - 1
        for flip in [false, true]:
            sprite.flip_h = flip
            AssetVisual.apply_frame(sprite, spec, last)
            _check(sprite.region_rect == Rect2(last * float(crop["w"]), 0, float(crop["w"]), float(crop["h"])), "Last frame uses cropped stride")
            var expected := Vector2(float(crop["x"]) + float(crop["w"]) / 2 - float(anchor[0]), float(crop["y"]) + float(crop["h"]) / 2 - float(anchor[1]))
            if flip: expected.x = -expected.x
            _check(sprite.offset.is_equal_approx(expected), "Trim preserves original anchor in both directions")
    sprite.queue_free()
    print("STAGE7_TRIM_PARITY: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
