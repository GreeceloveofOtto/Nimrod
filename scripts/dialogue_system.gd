extends Node

signal started
signal finished
var active: bool = false
var cancelled: bool = false
var generation: int = 0
var snapshot: Dictionary = {}
var hidden_items: Array[CanvasItem] = []
var camera_tween: Tween
var settings: Dictionary = {}
var balloon: PanelContainer
var text_label: Label
var pointer: Control
var _speaker: Node2D
var _canvas: CanvasLayer

class BalloonTail extends Control:
    func _draw() -> void:
        draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(24, 0), Vector2(12, 16)]), Color(0.06, 0.07, 0.11, 0.93))

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
    _canvas = CanvasLayer.new()
    _canvas.layer = 90
    add_child(_canvas)
    balloon = PanelContainer.new()
    balloon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.06, 0.07, 0.11, 0.93)
    style.border_color = Color(0.82, 0.68, 0.40, 0.9)
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    balloon.add_theme_stylebox_override("panel", style)
    _canvas.add_child(balloon)
    text_label = Label.new()
    text_label.add_theme_font_override("font", load(str(settings["font"])) as Font)
    text_label.add_theme_font_size_override("font_size", int(settings["font_size"]))
    text_label.add_theme_color_override("font_color", Color("f2e9d0"))
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.custom_minimum_size.x = 440
    balloon.add_child(text_label)
    pointer = BalloonTail.new()
    _canvas.add_child(pointer)
    _canvas.hide()

func _process(_delta: float) -> void:
    if not active or not is_instance_valid(_speaker):
        return
    var head: Vector2 = speaker_head(_speaker)
    var screen: Vector2 = _speaker.get_viewport_transform() * head
    balloon.position = Vector2(clampf(screen.x - balloon.size.x * 0.5, 12.0, 1280.0 - balloon.size.x - 12.0), clampf(screen.y - balloon.size.y - 36.0, 10.0, 650.0))
    pointer.position = Vector2(clampf(screen.x - 12.0, balloon.position.x + 14, balloon.position.x + balloon.size.x - 38), balloon.position.y + balloon.size.y - 1)
    pointer.queue_redraw()

func speaker_head(speaker: Node2D) -> Vector2:
    if speaker.is_in_group("npcs"):
        return speaker.global_position - Vector2(0, float(speaker.stats.get("height_ratio", 1.0)) * 363.0 * speaker.visual.scale.y * 0.80)
    if speaker.is_in_group("enemies"):
        return speaker.global_position + Vector2(0, speaker._local_hurt_rect().position.y + speaker.body_size.y * 0.20)
    return speaker.global_position - Vector2(0, 100)

func _timer(seconds: float) -> void:
    await get_tree().create_timer(seconds, true, false, true).timeout

func play(lines: Array, speaker: Node2D, options: Dictionary = {}) -> void:
    if active or lines.is_empty() or not is_instance_valid(speaker):
        return
    active = true
    cancelled = false
    generation += 1
    var token: int = generation
    _speaker = speaker
    var freeze: bool = bool(options.get("freeze", true))
    var zoom_in: bool = bool(options.get("zoom", freeze))
    var was_paused: bool = get_tree().paused
    var player: Node2D = get_tree().get_first_node_in_group("player")
    var camera: Camera2D = player.camera if player != null else null
    var previous_zoom: Vector2 = camera.zoom if camera != null else Vector2.ONE
    var previous_position: Vector2 = camera.position if camera != null else Vector2.ZERO
    var previous_offset: Vector2 = camera.offset if camera != null else Vector2.ZERO
    var previous_mode: int = camera.process_mode if camera != null else Node.PROCESS_MODE_INHERIT
    var previous_smoothing: bool = camera.position_smoothing_enabled if camera != null else false
    var hidden: Array[CanvasItem] = []
    for tag in get_tree().root.find_children("NameTag", "PanelContainer", true, false):
        if tag.visible:
            hidden.append(tag)
            tag.hide()
    for prompt_name in ["InteractionPrompt", "Prompt", "PromptE"]:
        for item in get_tree().root.find_children(prompt_name, "CanvasItem", true, false):
            if item.visible:
                hidden.append(item)
                item.hide()
    var hud: Node = get_tree().get_first_node_in_group("game_hud")
    if hud != null and hud.toast.visible:
        hidden.append(hud.toast)
        hud.toast.hide()
    hidden_items = hidden
    snapshot = {"camera":camera,"zoom":previous_zoom,"position":previous_position,"offset":previous_offset,"smoothing":previous_smoothing,"mode":previous_mode,"paused":was_paused}
    if freeze:
        get_tree().paused = true
    started.emit()
    if zoom_in and camera != null:
        camera.process_mode = Node.PROCESS_MODE_ALWAYS
        camera.position_smoothing_enabled = false
        var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
        camera_tween = tween
        tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(camera, "zoom", Vector2.ONE * float(settings["zoom"]), float(settings["camera_seconds"]))
        tween.tween_property(camera, "offset", speaker_head(speaker) - player.global_position - camera.position, float(settings["camera_seconds"]))
        await tween.finished
        if token != generation:
            return
    _canvas.show()
    for row in lines:
        var line: String = str(row.get("text", "")) if row is Dictionary else str(row)
        if row is Dictionary and row.get("speaker") is Node2D:
            _speaker = row["speaker"]
        text_label.text = line
        text_label.visible_characters = 0
        balloon.reset_size()
        for i in range(line.length()):
            text_label.visible_characters = i + 1
            if line[i] != " ":
                get_node("/root/Audio").play_sfx("speech_blip", null, 0.04)
            await _timer(float(options.get("character_seconds", settings["character_seconds"])))
            if token != generation:
                return
        await _timer(float(row.get("hold_seconds", options.get("hold_seconds", settings["hold_seconds"]))) if row is Dictionary else float(options.get("hold_seconds", settings["hold_seconds"])))
        if token != generation:
            return
    _canvas.hide()
    if zoom_in and is_instance_valid(camera):
        var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
        camera_tween = tween
        tween.tween_property(camera, "zoom", previous_zoom, float(settings["camera_seconds"]))
        tween.tween_property(camera, "position", previous_position, float(settings["camera_seconds"]))
        tween.tween_property(camera, "offset", previous_offset, float(settings["camera_seconds"]))
        await tween.finished
        if token != generation:
            return
        camera.position_smoothing_enabled = previous_smoothing
        camera.process_mode = previous_mode
        camera.reset_smoothing()
    for item in hidden:
        if is_instance_valid(item):
            item.show()
    get_tree().paused = was_paused
    _speaker = null
    active = false
    snapshot.clear()
    hidden_items.clear()
    finished.emit()

func cancel() -> void:
    if not active:
        return
    generation += 1
    cancelled = true
    if camera_tween != null and camera_tween.is_valid():
        camera_tween.kill()
        camera_tween.finished.emit()
    var camera: Camera2D = snapshot.get("camera")
    if is_instance_valid(camera):
        camera.zoom = snapshot["zoom"]
        camera.position = snapshot["position"]
        camera.offset = snapshot["offset"]
        camera.position_smoothing_enabled = snapshot["smoothing"]
        camera.process_mode = snapshot["mode"]
        camera.reset_smoothing()
    for item in hidden_items:
        if is_instance_valid(item):
            item.show()
    get_tree().paused = bool(snapshot.get("paused", false))
    hidden_items.clear()
    snapshot.clear()
    _canvas.hide()
    _speaker = null
    active = false
    finished.emit()
