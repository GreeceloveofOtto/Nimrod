class_name CedarFX
extends RefCounted

static func spawn(parent: Node, effect_name: String, at: Vector2, size: Vector2 = Vector2.ZERO) -> Node2D:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage6_fx.json"))
    for spec in data.get("fx", []):
        if str(spec["name"]) != effect_name:
            continue
        var effect: Node2D = load("res://scripts/image_effect.gd").new()
        var frame := Vector2i(int(spec["frame_size"][0]), int(spec["frame_size"][1]))
        effect.configure(str(spec["path"]), frame, int(spec["frames"]), float(spec["duration"]), bool(spec["loop"]), Vector2(frame) * 0.5)
        if size != Vector2.ZERO:
            effect.scale = size / Vector2(frame)
        effect.z_index = 15
        parent.add_child(effect)
        effect.global_position = at
        return effect
    return null
