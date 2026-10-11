extends RefCounted
class_name AssetVisual

static var _sheet_specs: Dictionary = {}
static var _sheet_specs_loaded: bool = false

static func sheet_spec(path: String, defaults: Dictionary = {}) -> Dictionary:
    if not _sheet_specs_loaded:
        _sheet_specs_loaded = true
        if FileAccess.file_exists("res://data/sprite_trims.json"):
            var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprite_trims.json"))
            if parsed is Dictionary:
                _sheet_specs = parsed
    return _sheet_specs.get(path, defaults)

static func apply_frame(sprite: Sprite2D, spec: Dictionary, frame: int) -> void:
    var original := Vector2(float(spec["frame_width"]), float(spec["frame_height"]))
    var anchor: Array = spec.get("anchor_px", [original.x * 0.5, original.y * 0.5])
    var crop: Dictionary = spec.get("trim", {"x": 0, "y": 0, "w": original.x, "h": original.y})
    var size := Vector2(float(crop["w"]), float(crop["h"]))
    var columns: int = maxi(1, int(spec.get("columns", spec.get("frames", 1))))
    sprite.region_rect = Rect2(Vector2((frame % columns) * size.x, floori(float(frame) / columns) * size.y), size)
    var offset := Vector2(float(crop["x"]), float(crop["y"])) + size * 0.5 - Vector2(float(anchor[0]), float(anchor[1]))
    # Sprite2D flips texture coordinates, so mirror the crop origin explicitly.
    if sprite.flip_h:
        offset.x = -offset.x
    sprite.offset = offset

# Image assets provide all world artwork. The gray box is a debugging aid only.
static func add_image(parent: Node, path: String, at: Vector2, size: Vector2, z: int = 0) -> Node2D:
    var holder := Node2D.new()
    holder.position = at
    holder.z_index = z
    parent.add_child(holder)
    if ResourceLoader.exists(path):
        var texture := ResourceLoader.load(path) as Texture2D
        if texture != null:
            var sprite := Sprite2D.new()
            sprite.name = "Image"
            sprite.texture = texture
            sprite.centered = false
            sprite.scale = size / texture.get_size()
            sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
            holder.add_child(sprite)
            return holder
    push_warning("MISSING_TEXTURE: " + path)
    var fallback := ColorRect.new()
    fallback.name = "MISSING_TEXTURE"
    fallback.size = size
    fallback.color = Color(0.42, 0.42, 0.42, 1.0)
    fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(fallback)
    var label := Label.new()
    label.name = "MissingLabel"
    label.text = "MISSING\n" + path.get_file()
    label.size = size
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 16)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(label)
    return holder
