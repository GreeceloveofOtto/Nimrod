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
@export var interactable: bool = false
@export var three_way: bool = false
@export var initial_pose: String = "front"

enum Pose { LEFT = -1, FRONT = 0, RIGHT = 1 }
var pose: int = Pose.RIGHT
var initial_side: int = Pose.RIGHT
var look_left: float = 0.0
var visual_fade: Sprite2D
var pose_tween: Tween

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
var name_tag: PanelContainer
var name_label: Label
var readability: Dictionary = {}
var _last_display_name: String = ""
var interaction_prompt: Node2D
var interaction_running: bool = false
var sound_frame: int = -1
var cinematic_control := false
var story_pose_locked := false

func _ready() -> void:
    add_to_group("npcs")
    get_node("/root/GameState").run_reset.connect(_on_run_reset)
    var data: Dictionary = _read_json("res://data/npcs.json")
    common = data.get("common", {})
    for entry in data.get("npcs", []):
        if str(entry.get("id", "")) == npc_id:
            stats = entry.duplicate(true)
            stats.merge(get_meta("interaction_overrides", {}), true)
            break
    if display_name.is_empty():
        display_name = str(stats.get("display_name", npc_id))
    face_player = bool(stats.get("face_player", face_player))
    interactable = bool(stats.get("interactable", interactable))
    if sheet_manifest.is_empty():
        sheet_manifest = "res://" + str(stats.get("sheet_dir", "assets/sprites/npcs/" + npc_id)) + "/manifest.json"
    facing = -1 if initial_facing < 0 else 1
    three_way = bool(stats.get("three_way", three_way))
    initial_pose = str(stats.get("initial_pose", initial_pose))
    initial_side = -1 if initial_pose == "left" else 1
    pose = (Pose.FRONT if initial_pose == "front" else initial_side) if three_way else facing
    if three_way:
        facing = initial_side
    visual = Sprite2D.new()
    visual.name = "Visual"
    visual.region_enabled = true
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    visual.scale = Vector2.ONE * float(common.get("visual_scale", 0.30)) * float(stats.get("visual_scale_multiplier", 1.0))
    visual.flip_h = facing < 0 and (not three_way or pose != Pose.FRONT)
    add_child(visual)
    visual_fade = Sprite2D.new()
    visual_fade.name = "VisualFade"
    visual_fade.visible = false
    visual_fade.texture_filter = visual.texture_filter
    add_child(visual_fade)
    _load_clips()
    _make_missing_visual()
    if not clip_data.has(idle_clip) and not clip_data.is_empty():
        idle_clip = str(clip_data.keys()[0])
    play_clip("idle_front" if three_way and pose == Pose.FRONT else idle_clip, bool(stats.get("random_start", false)))
    _reset_look_clock()
    readability = common.get("readability", {})
    _make_readability_fx()
    _make_name_tag()
    if interactable:
        interaction_prompt = load("res://scripts/asset_visual.gd").add_image(self, "res://assets/ui/prompt_e.png", Vector2(-16, -150), Vector2(32, 32), 60)
        interaction_prompt.name = "InteractionPrompt"
        interaction_prompt.visible = false

func _rgba(values: Array) -> Color:
    return Color(float(values[0]), float(values[1]), float(values[2]), float(values[3]))

func _make_readability_fx() -> void:
    var dimensions: Vector2 = Vector2.ZERO
    if textures.has(idle_clip):
        var texture: Texture2D = textures[idle_clip]
        dimensions = AssetVisual.frame_display_size(texture, clip_data[idle_clip], visual.scale)
    else:
        dimensions = Vector2(float(common.get("missing_size", [70, 110])[0]), float(common.get("missing_size", [70, 110])[1])) * float(stats.get("visual_scale_multiplier", 1.0))
    var helper = load("res://scripts/asset_visual.gd")
    var width: float = dimensions.y * float(readability.get("pool_width_height_ratio", 1.4))
    var pool: Node2D = helper.add_image(self, str(readability["light_pool"]), Vector2(-width * 0.5, float(readability["pool_center_y"]) - width * 0.25), Vector2(width, width * 0.5), -2)
    pool.name = "LightPool"
    pool.modulate = _rgba(readability["pool_modulate"])
    var pool_material := CanvasItemMaterial.new()
    pool_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    pool.material = pool_material
    for child in pool.get_children():
        if child is CanvasItem:
            child.use_parent_material = true
    width = dimensions.x * float(readability["shadow_width_ratio"])
    var height: float = float(readability["shadow_height"])
    var shadow: Node2D = helper.add_image(self, str(readability["shadow"]), Vector2(-width * 0.5, -height * 0.5), Vector2(width, height), -1)
    shadow.name = "ContactShadow"
    shadow.modulate.a = float(readability["shadow_alpha"])

func _make_name_tag() -> void:
    name_tag = PanelContainer.new()
    name_tag.name = "NameTag"
    name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
    name_tag.z_index = int(readability["name_z"])
    name_tag.modulate.a = float(readability["name_alpha"])
    var panel := StyleBoxFlat.new()
    panel.bg_color = _rgba(readability["panel_color"])
    var radius: int = int(readability["corner_radius"])
    panel.set_corner_radius_all(radius)
    panel.content_margin_left = float(readability["margin_x"])
    panel.content_margin_right = float(readability["margin_x"])
    panel.content_margin_top = float(readability["margin_y"])
    panel.content_margin_bottom = float(readability["margin_y"])
    name_tag.add_theme_stylebox_override("panel", panel)
    add_child(name_tag)
    name_label = Label.new()
    name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var settings := LabelSettings.new()
    settings.font = load(str(readability["font"])) as Font
    settings.font_size = int(readability["font_size"])
    settings.font_color = Color(str(readability["font_color"]))
    settings.outline_size = 0
    settings.shadow_size = 1
    settings.shadow_color = _rgba(readability["shadow_color"])
    settings.shadow_offset = Vector2(float(readability["shadow_offset"][0]), float(readability["shadow_offset"][1]))
    name_label.label_settings = settings
    name_tag.add_child(name_label)
    _update_name_text()

func _update_name_text() -> void:
    if name_label == null or _last_display_name == display_name:
        return
    _last_display_name = display_name
    name_label.text = display_name
    name_tag.reset_size()
    _center_name_tag.call_deferred()

func _center_name_tag() -> void:
    if not is_inside_tree():
        return
    await get_tree().process_frame
    if not is_inside_tree() or not is_instance_valid(name_tag):
        return
    name_tag.position = Vector2(-name_tag.size.x * 0.5, float(readability["name_offset_y"]))

func _update_readability(delta: float) -> void:
    _update_name_text()
    var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
    var near: bool = player != null and global_position.distance_to(player.global_position) <= float(readability["range"])
    var brightness: float = float(readability["near_brightness"]) if near else 1.0
    var seconds: float = maxf(0.001, float(readability["seconds"]))
    var value: float = move_toward(modulate.r, brightness, (float(readability["near_brightness"]) - 1.0) * delta / seconds)
    modulate = Color(value, value, value, 1.0)
    var alpha: float = float(readability["near_name_alpha"]) if near else float(readability["name_alpha"])
    name_tag.modulate.a = move_toward(name_tag.modulate.a, alpha, (float(readability["near_name_alpha"]) - float(readability["name_alpha"])) * delta / seconds)

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
    _update_readability(delta)
    if interaction_prompt != null:
        var actor: NimrodPlayer = get_tree().get_first_node_in_group("player") as NimrodPlayer
        var available: bool = actor != null and not actor.is_transition_locked() and actor.action != "dead" and not cinematic_control and not interaction_running and not get_node("/root/Dialogue").input_blocked() and not _interaction_complete()
        interaction_prompt.visible = available and interactable and absf(interaction_center().x-actor.global_position.x) <= float(stats.get("interact_range", 120.0)) and absf(interaction_center().y-actor.global_position.y) <= float(stats.get("interact_vertical_range", 120.0))
        if interaction_prompt.visible and Input.is_action_just_pressed("interact"):
            interact(actor)
    face_cooldown_left = maxf(0.0, face_cooldown_left - delta)
    look_left -= delta
    if three_way and not cinematic_control and not story_pose_locked:
        _update_three_way()
    elif face_player and not cinematic_control and not story_pose_locked:
        var player := get_tree().get_first_node_in_group("player") as Node2D
        if player != null:
            face_toward(player.global_position.x)
    clip_clock += delta
    _refresh_visual()

func _reset_look_clock() -> void:
    var options: Dictionary = common.get("three_way", {})
    look_left = randf_range(float(options.get("look_min", 4.0)), float(options.get("look_max", 8.0)))

func _update_three_way() -> void:
    var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
    if player == null or face_cooldown_left > 0.0:
        return
    var dx: float = player.global_position.x - global_position.x
    var options: Dictionary = common.get("three_way", {})
    if absf(dx) >= float(options.get("look_distance", 700.0)):
        if look_left <= 0.0:
            _change_pose(Pose.FRONT if pose != Pose.FRONT else initial_side)
            _reset_look_clock()
        return
    _reset_look_clock()
    if absf(dx) <= float(options.get("front_distance", 140.0)):
        _change_pose(Pose.FRONT)
    elif absf(dx) >= float(options.get("side_distance", 220.0)):
        _change_pose(Pose.LEFT if dx < 0 else Pose.RIGHT)

func _change_pose(next_pose: int) -> void:
    if pose == next_pose:
        return
    if is_instance_valid(pose_tween):
        pose_tween.kill()
    visual_fade.texture = visual.texture
    visual_fade.region_enabled = true
    visual_fade.region_rect = visual.region_rect
    visual_fade.offset = visual.offset
    visual_fade.scale = visual.scale
    visual_fade.flip_h = visual.flip_h
    visual_fade.modulate.a = 1.0
    visual_fade.visible = visual.visible
    pose = next_pose
    if pose != Pose.FRONT:
        facing = pose
    play_clip("idle_front" if pose == Pose.FRONT else "idle")
    visual.modulate.a = 0.0
    pose_tween = create_tween().set_parallel(true)
    var seconds: float = float(common.get("three_way", {}).get("fade_seconds", 0.12))
    pose_tween.tween_property(visual_fade, "modulate:a", 0.0, seconds)
    pose_tween.tween_property(visual, "modulate:a", 1.0, seconds)
    pose_tween.chain().tween_callback(visual_fade.hide)
    face_cooldown_left = float(common.get("face_cooldown", 0.5))
    _resize_pose_shadow()

func _resize_pose_shadow() -> void:
    var shadow: Node2D = get_node_or_null("ContactShadow")
    var frame_sounds: Dictionary = stats.get("frame_sfx",{}).get(current_clip,{})
    if current_frame != sound_frame and current_frame == int(frame_sounds.get("frame",-2)):
        get_node("/root/Audio").play_sfx(str(frame_sounds["sfx"]),global_position,.2)
    sound_frame = current_frame
    var texture: Texture2D = textures.get(current_clip) as Texture2D
    if shadow == null or texture == null:
        return
    var width: float = AssetVisual.frame_display_size(texture, clip_data[current_clip], visual.scale).x * float(readability["shadow_width_ratio"])
    shadow.position.x = -width * 0.5
    var image: Sprite2D = shadow.get_node_or_null("Image") as Sprite2D
    if image != null:
        image.scale.x = width / image.texture.get_width()
        image.position.x = width * 0.5

func face_toward(target_x: float, force: bool = false) -> void:
    if three_way:
        if force or face_cooldown_left <= 0.0:
            var dx: float = target_x - global_position.x
            var options: Dictionary = common.get("three_way", {})
            if absf(dx) <= float(options.get("front_distance", 140.0)):
                _change_pose(Pose.FRONT)
            elif absf(dx) >= float(options.get("side_distance", 220.0)):
                _change_pose(Pose.LEFT if dx < 0 else Pose.RIGHT)
        return
    var distance: float = target_x - global_position.x
    if not force and (absf(distance) < float(common.get("face_threshold", 120.0)) or face_cooldown_left > 0.0):
        return
    if is_zero_approx(distance):
        return
    var next_facing: int = -1 if distance < 0.0 else 1
    if next_facing != facing:
        facing = next_facing
        visual.flip_h = facing < 0 and (not three_way or pose != Pose.FRONT)
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
    var frame_sounds: Dictionary = stats.get("frame_sfx",{}).get(current_clip,{})
    if current_frame != sound_frame and current_frame == int(frame_sounds.get("frame",-2)):
        get_node("/root/Audio").play_sfx(str(frame_sounds["sfx"]),global_position,.2)
    sound_frame = current_frame
    var texture: Texture2D = textures.get(current_clip) as Texture2D
    visual.visible = texture != null
    missing_visual.visible = texture == null
    if texture != null:
        visual.texture = texture
        visual.flip_h = facing < 0 and (not three_way or pose != Pose.FRONT)
        AssetVisual.apply_frame(visual, clip, current_frame)
    if not loop and clip_clock >= duration and not animation_finished:
        animation_finished = true
        clip_finished.emit(current_clip)

func interact(_player: Node2D) -> void:
    var interaction_id: String = str(stats.get("interaction", ""))
    if interaction_running or not interactable or not get_node("/root/Dialogue").interaction_available(interaction_id):
        return
    interaction_running = true
    interacted.emit()
    if npc_id in ["shimati", "urshanabi"]:
        get_node("/root/Dialogue").play_interaction.call_deferred(interaction_id)
        interaction_running = false
        return
    if npc_id == "shamhat" and get_node("/root/Choice").menu_available():
        await get_node("/root/Choice").open(self)
    else:
        await get_node("/root/Dialogue").play_interaction(interaction_id)
    interaction_running = false
    if _interaction_complete() and interaction_prompt != null:
        interaction_prompt.hide()

func interaction_center() -> Vector2:
    if str(stats.get("interaction", "")) == "parents_gift":
        var father: NPC = get_parent().get_node_or_null("lugalbanda") as NPC
        var mother: NPC = get_parent().get_node_or_null("ninsun") as NPC
        if father != null and mother != null:
            return (father.global_position + mother.global_position) * 0.5
    return global_position

func _interaction_complete() -> bool:
    return not get_node("/root/Dialogue").interaction_available(str(stats.get("interaction", "")))

func _on_run_reset() -> void:
    interactable = bool(stats.get("interactable", false))
    interaction_running = false
