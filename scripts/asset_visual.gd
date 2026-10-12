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
    configure_sprite(sprite)
    sprite.region_enabled = true
    var original := Vector2(float(spec["frame_width"]), float(spec["frame_height"]))
    var anchor: Array = spec.get("anchor_px", [original.x * 0.5, original.y * 0.5])
    var crop: Dictionary = spec.get("storage_trim", spec.get("trim", {"x": 0, "y": 0, "w": original.x, "h": original.y}))
    var density: Array = spec.get("storage_scale", [1.0, 1.0])
    var factor := Vector2(float(density[0]), float(density[1]))
    if not sprite.has_meta("canonical_scale"):
        sprite.set_meta("canonical_scale", sprite.scale)
    sprite.scale = Vector2(sprite.get_meta("canonical_scale")) / factor
    var size := Vector2(float(crop["w"]), float(crop["h"]))
    var stored_frame: int = int(spec.get("frame_map", [])[frame]) if spec.get("frame_map", []).size() > frame else frame
    var columns: int = maxi(1, int(spec.get("stored_columns", spec.get("columns", spec.get("frames", 1)))))
    sprite.region_rect = Rect2(Vector2((stored_frame % columns) * size.x, floori(float(stored_frame) / columns) * size.y), size)
    var offset := Vector2(float(crop["x"]), float(crop["y"])) + size * 0.5 - Vector2(float(anchor[0]), float(anchor[1])) * factor
    if sprite.flip_h:
        offset.x = -offset.x
    sprite.offset = offset

static func configure_sprite(sprite: Sprite2D) -> void:
    sprite.region_filter_clip_enabled = true
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

static func frame_display_size(texture: Texture2D, spec: Dictionary, scale_px: Vector2) -> Vector2:
    var crop: Dictionary = spec.get("storage_trim", spec.get("trim", {"w":spec["frame_width"],"h":spec["frame_height"]}))
    return Vector2(texture.get_image().get_region(Rect2i(0,0,int(crop["w"]),int(crop["h"]))).get_used_rect().size) * scale_px

# Image assets provide all world artwork. The gray box is a debugging aid only.
static func add_image(parent: Node, path: String, at: Vector2, size: Vector2, z: int = 0) -> Node2D:
    var holder := Node2D.new()
    holder.position = at
    holder.z_index = z
    holder.set_meta("art_path",path)
    parent.add_child(holder)
    if ResourceLoader.exists(path):
        var texture := ResourceLoader.load(path) as Texture2D
        if texture != null:
            var sprite := Sprite2D.new()
            AssetVisual.configure_sprite(sprite)
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
