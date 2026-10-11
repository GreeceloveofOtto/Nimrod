extends Node2D

# Image-only transient effects; a missing image is visibly a debug placeholder.
var sheet_path: String = ""
var frame_size: Vector2i = Vector2i.ONE
var frame_count: int = 1
var duration: float = 1.0
var looped: bool = false
var anchor: Vector2 = Vector2.ZERO
var clock: float = 0.0
var sprite: Sprite2D

func configure(path: String, size_px: Vector2i, frames: int, seconds: float, repeats: bool = false, origin: Vector2 = Vector2.ZERO) -> void:
    sheet_path = path
    frame_size = size_px
    frame_count = maxi(1, frames)
    duration = maxf(0.001, seconds)
    looped = repeats
    anchor = origin

func _ready() -> void:
    if ResourceLoader.exists(sheet_path):
        var texture: Texture2D = load(sheet_path) as Texture2D
        if texture != null:
            sprite = Sprite2D.new()
            sprite.texture = texture
            sprite.region_enabled = true
            sprite.region_rect = Rect2(Vector2.ZERO, Vector2(frame_size))
            AssetVisual.apply_frame(sprite, _spec(), 0)
            sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
            add_child(sprite)
            return
    push_warning("MISSING_TEXTURE: " + sheet_path)
    var missing := ColorRect.new()
    missing.position = -anchor
    missing.size = Vector2(frame_size)
    missing.color = Color.GRAY
    missing.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(missing)
    var label := Label.new()
    label.text = "MISSING"
    label.position = -anchor
    label.size = Vector2(frame_size)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(label)

func _process(delta: float) -> void:
    clock += delta
    if not looped and clock >= duration:
        queue_free()
        return
    if sprite != null:
        var phase: float = fmod(clock, duration) if looped else clock
        var frame: int = clampi(int(phase / duration * frame_count), 0, frame_count - 1)
        AssetVisual.apply_frame(sprite, _spec(), frame)

func _spec() -> Dictionary:
    var spec: Dictionary = AssetVisual.sheet_spec(sheet_path, {"frame_width": frame_size.x, "frame_height": frame_size.y, "frames": frame_count}).duplicate()
    spec["anchor_px"] = [anchor.x, anchor.y]
    return spec
