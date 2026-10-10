class_name NPC
extends Node2D

signal interacted
signal clip_frame_changed(clip: String, frame: int)
signal clip_finished(clip: String)

@export var npc_id: String = "lugalbanda"
@export var display_name: String = ""
@export_file("*.json") var sheet_manifest: String = ""
@export var idle_clip: String = "idle"
@export var face_player: bool = true
@export var initial_facing: int = 1

var stats: Dictionary = {}
var common: Dictionary = {}
var clip_data: Dictionary = {}
var textures: Dictionary = {}
var visual: Sprite2D
var missing_visual: Node2D
var current_clip: String = ""
var current_frame: int = -1
var clip_clock: float = 0.0
var facing: int = 1
var face_cooldown_left: float = 0.0
var animation_finished: bool = false

func _ready() -> void:
    add_to_group("npcs")
    var data: Dictionary = _read_json("res://data/npcs.json")
    common = data.get("common", {})
    for entry in data.get("npcs", []):
        if str(entry.get("id", "")) == npc_id:
            stats = entry
            break
    if display_name.is_empty():
        display_name = str(stats.get("display_name", npc_id))
    face_player = bool(stats.get("face_player", face_player))
    if sheet_manifest.is_empty():
        sheet_manifest = "res://" + str(stats.get("sheet_dir", "assets/sprites/npcs/" + npc_id)) + "/manifest.json"
    facing = -1 if initial_facing < 0 else 1
    visual = Sprite2D.new()
    visual.name = "Visual"
    visual.region_enabled = true
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    visual.scale = Vector2.ONE * float(common.get("visual_scale", 0.30))
    visual.flip_h = facing < 0
    add_child(visual)
    _load_clips()
    _make_missing_visual()
    if not clip_data.has(idle_clip) and not clip_data.is_empty():
        idle_clip = str(clip_data.keys()[0])
    play_clip(idle_clip, bool(stats.get("random_start", false)))

func _read_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("Missing NPC data: " + path)
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    return parsed as Dictionary if parsed is Dictionary else {}

func _load_clips() -> void:
    var manifest: Dictionary = _read_json(sheet_manifest)
    for entry in manifest.get("clips", []):
        var clip: Dictionary = entry
        var clip_name: String = str(clip.get("name", ""))
        clip_data[clip_name] = clip
        var path: String = str(clip.get("sheet", clip_name + ".png"))
        if path.begins_with("sprites/"):
            path = "res://assets/" + path
        elif not path.begins_with("res://"):
            path = sheet_manifest.get_base_dir().path_join(path)
        if ResourceLoader.exists(path):
            var texture: Texture2D = load(path) as Texture2D
            if texture != null:
                textures[clip_name] = texture
        else:
            push_warning("MISSING_TEXTURE: " + path)
    # The debug fallback still observes timing while an artist supplies PNGs.
    for entry in stats.get("clips", []):
        var name_value: String = str(entry.get("name", "idle"))
        if not clip_data.has(name_value):
            clip_data[name_value] = {
                "frames": int(entry.get("frames", 1)),
                "duration_seconds": float(entry.get("duration", 1.0)),
                "loop": bool(entry.get("loop", true)),
                "frame_width": int(common.get("frame_size", [640, 640])[0]),
                "frame_height": int(common.get("frame_size", [640, 640])[1]),
                "anchor_px": common.get("anchor_px", [320, 600]),
            }

func _make_missing_visual() -> void:
    missing_visual = Node2D.new()
    missing_visual.name = "MISSING_TEXTURE"
    add_child(missing_visual)
    var dimensions: Array = common.get("missing_size", [70, 110])
    var size := Vector2(float(dimensions[0]), float(dimensions[1]))
    var box := ColorRect.new()
    box.color = Color.GRAY
    box.position = Vector2(-size.x * 0.5, -size.y)
    box.size = size
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    missing_visual.add_child(box)
    var label := Label.new()
    label.text = "MISSING"
    label.position = box.position
    label.size = size
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    missing_visual.add_child(label)

func _process(delta: float) -> void:
    face_cooldown_left = maxf(0.0, face_cooldown_left - delta)
    if face_player:
        var player := get_tree().get_first_node_in_group("player") as Node2D
        if player != null:
            face_toward(player.global_position.x)
    clip_clock += delta
    _refresh_visual()

func face_toward(target_x: float, force: bool = false) -> void:
    var distance: float = target_x - global_position.x
    if not force and (absf(distance) < float(common.get("face_threshold", 120.0)) or face_cooldown_left > 0.0):
        return
    if is_zero_approx(distance):
        return
    var next_facing: int = -1 if distance < 0.0 else 1
    if next_facing != facing:
        facing = next_facing
        visual.flip_h = facing < 0
        face_cooldown_left = float(common.get("face_cooldown", 0.5))

func play_clip(clip: String, random_start: bool = false) -> void:
    current_clip = clip
    clip_clock = 0.0
    current_frame = -1
    animation_finished = false
    if random_start and clip_data.has(clip):
        clip_clock = randf() * float(clip_data[clip].get("duration_seconds", 1.0))
    _refresh_visual()

func _refresh_visual() -> void:
    if not clip_data.has(current_clip):
        visual.visible = false
        missing_visual.visible = true
        return
    var clip: Dictionary = clip_data[current_clip]
    var frames: int = maxi(1, int(clip.get("frames", 1)))
    var duration: float = maxf(0.001, float(clip.get("duration_seconds", 1.0)))
    var loop: bool = bool(clip.get("loop", true))
    var next_frame: int = floori(clip_clock / duration * frames)
    next_frame = next_frame % frames if loop else mini(frames - 1, next_frame)
    if next_frame != current_frame:
        current_frame = next_frame
        clip_frame_changed.emit(current_clip, current_frame)
    var texture: Texture2D = textures.get(current_clip) as Texture2D
    visual.visible = texture != null
    missing_visual.visible = texture == null
    if texture != null:
        var width: float = float(clip.get("frame_width", 640))
        var height: float = float(clip.get("frame_height", 640))
        var anchor: Array = clip.get("anchor_px", [320, 600])
        visual.texture = texture
        visual.region_rect = Rect2(current_frame * width, 0.0, width, height)
        visual.offset = Vector2(width * 0.5 - float(anchor[0]), height * 0.5 - float(anchor[1]))
        visual.flip_h = facing < 0
    if not loop and clip_clock >= duration and not animation_finished:
        animation_finished = true
        clip_finished.emit(current_clip)

# Deliberately empty: there is no dialogue in this stage.
func interact(_player: Node2D) -> void:
    pass
