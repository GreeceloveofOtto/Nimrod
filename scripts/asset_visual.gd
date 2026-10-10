extends RefCounted
class_name AssetVisual

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
