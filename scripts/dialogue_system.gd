extends Node

signal started
signal finished
signal line_changed(speaker_id: String, line: String)
var active: bool = false
var cancelled: bool = false
var generation: int = 0
var snapshot: Dictionary = {}
var hidden_items: Array[CanvasItem] = []
var camera_tween: Tween
var settings: Dictionary = {}
var balloon: PanelContainer
var text_label: Label
var name_chip: PanelContainer
var name_label: Label
var _speaker: Node2D
var _canvas: CanvasLayer
var input_grace_left: float = 0.0
var highlighted: Node2D
var highlight_color: Color = Color.WHITE
var highlight_name_alpha: float = 1.0
var participants: Dictionary = {}
var live_timer: SceneTreeTimer
var paused_actors: Dictionary = {}
var test_timing_scale := 1.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
    _canvas = CanvasLayer.new()
    _canvas.layer = 90
    add_child(_canvas)
    balloon = PanelContainer.new()
    balloon.name = "DialoguePanel"
    balloon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.06, 0.07, 0.11, 0.93)
    style.border_color = Color(0.82, 0.68, 0.40, 0.9)
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 14
    style.content_margin_bottom = 14
    balloon.add_theme_stylebox_override("panel", style)
    _canvas.add_child(balloon)
    text_label = Label.new()
    text_label.add_theme_font_override("font", load(str(settings["font"])) as Font)
    text_label.add_theme_font_size_override("font_size", int(settings["font_size"]))
    text_label.add_theme_color_override("font_color", Color("f2e9d0"))
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    balloon.add_child(text_label)
    name_chip = PanelContainer.new()
    name_chip.name = "SpeakerChip"
    name_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _canvas.add_child(name_chip)
    name_label = Label.new()
    name_label.add_theme_font_override("font", load(str(settings["font"])) as Font)
    name_label.add_theme_font_size_override("font_size", 20)
    name_label.add_theme_color_override("font_color", Color("f2e9d0"))
    name_chip.add_child(name_label)
    _layout()
    _canvas.hide()

func _process(delta: float) -> void:
    input_grace_left = maxf(0, input_grace_left - delta)
    if active:
        _layout()

func _layout() -> void:
    var screen: Vector2 = get_viewport().get_visible_rect().size
    var width: float = clampf(screen.x * 0.40625, float(settings.get("min_width", 400)), float(settings.get("max_width", 560)))
    balloon.custom_minimum_size = Vector2(width, float(settings.get("min_height", 150)))
    text_label.custom_minimum_size.x = width - 36
    balloon.size.x = width
    balloon.position = Vector2(screen.x - width - float(settings.get("right_margin", 32)), (screen.y - balloon.size.y) * 0.5)
    name_chip.position = balloon.position + Vector2(14, -name_chip.size.y * 0.5)

func input_blocked() -> bool:
    return active or input_grace_left > 0

func speaker_head(speaker: Node2D) -> Vector2:
    if speaker is NPC:
        return speaker.global_position - Vector2(0, float(speaker.stats.get("height_ratio", 1)) * 363 * float(speaker.common.get("visual_scale", 0.3)) * 0.8)
    if speaker is EnemyBase:
        return speaker.global_position + Vector2(0, speaker._local_hurt_rect().position.y + speaker.body_size.y * 0.2)
    return speaker.global_position - Vector2(0, 100)

func _timer(seconds: float) -> void:
    var timer := get_tree().create_timer(maxf(seconds * test_timing_scale, 0.001), true, false, true)
    live_timer = timer
    await timer.timeout
    if live_timer == timer:
        live_timer = null

func resolve_interaction(id: String) -> Dictionary:
    var root: Dictionary = settings.get("interactions", {}).get(id, {})
    if root.has("variants"):
        for variant: Dictionary in root["variants"]:
            if get_node("/root/Story").matches(variant.get("when", {})):
                return variant
        return {}
    return root if get_node("/root/Story").matches(root.get("when", {})) else {}

func interaction_available(id: String) -> bool:
    var spec: Dictionary = resolve_interaction(id)
    if spec.is_empty():
        return false
    var flags: Dictionary = get_node("/root/GameState").run_flags
    if bool(spec.get("blessing_gate", id == "shamhat")) and flags.get("shamhat_blessing", false):
        return false
    return not (spec.get("repeat", []) if flags.get(str(spec["flag"]), false) else spec.get("first", [])).is_empty()

func find_speakers() -> Dictionary:
    var found: Dictionary = {"player": get_tree().get_first_node_in_group("player")}
    for npc: NPC in get_tree().get_nodes_in_group("npcs"):
        found[npc.npc_id] = npc
    return found

func play_interaction(id: String, speaker_nodes: Dictionary = {}) -> void:
    if active or not interaction_available(id):
        return
    var state: Node = get_node("/root/GameState")
    var spec: Dictionary = resolve_interaction(id)
    var repeat_visit: bool = bool(state.run_flags.get(str(spec["flag"]), false))
    var lines: Array = spec["repeat"] if repeat_visit else spec["first"]
    var nodes: Dictionary = find_speakers()
    nodes.merge(speaker_nodes, true)
    if spec.has("speakers"):
        for key in nodes.keys():
            if key not in spec["speakers"]:
                nodes.erase(key)
    var first: Node2D = nodes.get(str(lines[0].get("speaker", "player")), nodes.get("player"))
    var intercept: NPC = nodes.get("papsukkal") as NPC if id == "inanna" or bool(spec.get("intercept", false)) else null
    var intercept_position := Vector2.ZERO
    if intercept != null:
        intercept_position = intercept.position
    await play(lines, first, {"participants": nodes, "intercept": intercept})
    if cancelled:
        return
    state.run_flags[str(spec["flag"])] = true
    state.visit_count(id, true)
    for event: Dictionary in spec.get("on_finish", []):
        if event.get("when", "first") in ["always", "repeat" if repeat_visit else "first"]:
            await _event(event, nodes)
    if is_instance_valid(intercept):
        var tween := create_tween()
        tween.tween_property(intercept, "position", intercept_position, float(settings["intercept_seconds"]))
        await tween.finished

func _event(event: Dictionary, nodes: Dictionary) -> void:
    var hero: NimrodPlayer = nodes.get("player") as NimrodPlayer
    match str(event.get("event", "")):
        "axe_gift", "give_axe":
            await give_axe(nodes.get("lugalbanda"), hero)
        "give_blessing":
            if hero != null:
                hero.apply_shamhat_blessing()
        "set_flag", "open_gate":
            var flag: String = str(event.get("flag", ""))
            get_node("/root/Story").set_flag(flag)
            if str(event.get("event")) == "open_gate":
                for gate: Node in get_tree().get_nodes_in_group("gates"):
                    if gate.gate_flag == flag:
                        gate.authorize_open()
                for npc: NPC in get_tree().get_nodes_in_group("npcs"):
                    if str(npc.stats.get("interaction", "")) in ["castle_gatekeeper", "villa_gatekeeper"] and not interaction_available(str(npc.stats["interaction"])):
                        npc.interactable = false
                        if npc.interaction_prompt != null:
                            npc.interaction_prompt.hide()

        "unlock_skill":
            get_node("/root/Story").set_flag("skill_" + str(event["skill"]))
            get_node("/root/SceneManager").show_toast("아누르의 빛을 얻었다 (R)")
        "start_cutscene":
            get_node("/root/Cutscene").play.call_deferred(str(event["cutscene"]))
        "time_skip":
            get_node("/root/Cutscene").play.call_deferred("time_skip")

func _restore_highlight() -> void:
    if is_instance_valid(highlighted):
        highlighted.modulate = highlight_color
        if highlighted is NPC:
            highlighted.name_tag.modulate.a = highlight_name_alpha
    highlighted = null

func _set_speaker(actor: Node2D, id: String) -> void:
    _restore_highlight()
    _speaker = actor
    name_label.text = "니므롯" if id == "player" or actor is NimrodPlayer else actor.display_name if actor is NPC else "칼라-우쉬움갈"
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.42, 0.30, 0.16, 1) if actor is NimrodPlayer else Color(0.55, 0.42, 0.18, 1)
    style.set_corner_radius_all(8)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 3
    style.content_margin_bottom = 3
    name_chip.add_theme_stylebox_override("panel", style)
    name_chip.reset_size()
    if actor is NPC:
        highlighted = actor
        highlight_color = actor.modulate
        highlight_name_alpha = actor.name_tag.modulate.a
        actor.modulate = Color(1.12, 1.12, 1.12)
        actor.name_tag.modulate.a = 1
        if actor.three_way and not actor.cinematic_control:
            if is_instance_valid(actor.pose_tween):
                actor.pose_tween.kill()
            actor.pose = NPC.Pose.FRONT
            actor.play_clip("idle_front")
            actor.visual_fade.hide()
            actor.visual.modulate.a = 1

func play(lines: Array, speaker: Node2D, options: Dictionary = {}) -> void:
    if active or lines.is_empty() or not is_instance_valid(speaker):
        return
    active = true
    cancelled = false
    generation += 1
    var token: int = generation
    participants = options.get("participants", {})
    var hero: NimrodPlayer = get_tree().get_first_node_in_group("player") as NimrodPlayer
    var camera: Camera2D = hero.camera if hero != null else null
    snapshot = {"camera": camera, "paused": get_tree().paused}
    if camera != null:
        snapshot.merge({"zoom": camera.zoom, "position": camera.position, "offset": camera.offset, "mode": camera.process_mode, "smoothing": camera.position_smoothing_enabled})
    for prompt_name in ["InteractionPrompt", "Prompt", "PromptE"]:
        for item: CanvasItem in get_tree().root.find_children(prompt_name, "CanvasItem", true, false):
            if item.visible:
                hidden_items.append(item)
                item.hide()
    var hud: Node = get_tree().get_first_node_in_group("game_hud")
    if hud != null:
        for item: CanvasItem in [hud.toast, hud.story]:
            if item.visible:
                hidden_items.append(item)
                item.hide()
    get_tree().paused = true
    if get_node("/root/Cutscene").active:
        for node in get_node("/root/Cutscene").actor_states:
            if is_instance_valid(node):
                paused_actors[node] = node.process_mode
                node.process_mode = PROCESS_MODE_PAUSABLE
    started.emit()
    var intercept: NPC = options.get("intercept") as NPC
    if intercept != null and hero != null:
        var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        tween.tween_property(intercept, "position:x", intercept.position.x + signf(hero.global_position.x - intercept.global_position.x) * float(settings["intercept_pixels"]), float(settings["intercept_seconds"]))
        await tween.finished
    if camera != null:
        camera.process_mode = Node.PROCESS_MODE_ALWAYS
        camera.position_smoothing_enabled = false
        var focus: Vector2 = (speaker_head(speaker) + speaker_head(hero)) * 0.5
        var actor_min := focus
        var actor_max := focus
        if participants.size() > 1:
            focus = Vector2.ZERO
            var count := 0
            for member in participants.values():
                if is_instance_valid(member):
                    var at := speaker_head(member)
                    actor_min = actor_min.min(at)
                    actor_max = actor_max.max(at)
                    focus += at
                    count += 1
            if count > 0:
                focus /= count
        var solo: bool = speaker is NimrodPlayer and participants.size() <= 1
        var zoom: float = float(settings["solo_zoom"] if solo else settings["zoom"])
        var viewport_size: Vector2 = get_viewport().get_visible_rect().size
        zoom = minf(zoom, 1.35)
        if participants.size() > 1:
            zoom = minf(zoom, (viewport_size.x - balloon.custom_minimum_size.x - 96) / maxf(240, actor_max.x - actor_min.x + 140))
        focus.x += viewport_size.x / (6 * zoom)
        var half_size: Vector2 = viewport_size / (2 * zoom)
        focus.x = clampf(focus.x, camera.limit_left + half_size.x, maxf(camera.limit_left + half_size.x, camera.limit_right - half_size.x))
        focus.y = clampf(focus.y, camera.limit_top + half_size.y, maxf(camera.limit_top + half_size.y, camera.limit_bottom - half_size.y))
        camera_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
        camera_tween.tween_property(camera, "zoom", Vector2.ONE * zoom, float(settings["camera_seconds"]))
        camera_tween.tween_property(camera, "offset", focus - camera.global_position, float(settings["camera_seconds"]))
        await camera_tween.finished
        if token != generation:
            return
    _canvas.show()
    for row in lines:
        var spec: Dictionary = row if row is Dictionary else {"text": str(row)}
        var speaker_id: String = str(spec.get("speaker", ""))
        var actor: Node2D = participants.get(speaker_id, speaker)
        if spec.get("speaker") is Node2D:
            actor = spec["speaker"]
        if not str(spec.get("event", "")).is_empty():
            _canvas.hide()
            await _event(spec, participants)
            _canvas.show()
            continue
        _set_speaker(actor, speaker_id)
        var line: String = str(spec.get("text", ""))
        text_label.text = line
        text_label.visible_characters = 0
        balloon.reset_size()
        _layout()
        line_changed.emit(speaker_id, line)
        for i in range(line.length()):
            text_label.visible_characters = i + 1
            if line[i] != " ":
                get_node("/root/Audio").play_sfx("speech_blip", null, 0.04)
            await _timer(float(options.get("character_seconds", settings["character_seconds"])))
            if token != generation:
                return
        await _timer(float(options.get("hold_seconds", maxf(float(settings["hold_seconds"]), float(settings.get("hold_per_character", 0.05)) * line.length()))))
        if token != generation:
            return
    _canvas.hide()
    _restore_highlight()
    if is_instance_valid(camera):
        camera_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
        for key in ["zoom", "position", "offset"]:
            camera_tween.tween_property(camera, key, snapshot[key], float(settings["camera_seconds"]))
        await camera_tween.finished
        if token != generation:
            return
    _restore()
    finished.emit()

func _restore() -> void:
    var camera: Camera2D = snapshot.get("camera")
    if is_instance_valid(camera):
        camera.zoom = snapshot["zoom"]
        camera.position = snapshot["position"]
        camera.offset = snapshot["offset"]
        camera.position_smoothing_enabled = snapshot["smoothing"]
        camera.process_mode = snapshot["mode"]
        camera.reset_smoothing()
    _restore_highlight()
    for item in hidden_items:
        if is_instance_valid(item):
            item.show()
    for node in paused_actors:
        if is_instance_valid(node):
            node.process_mode = paused_actors[node]
    paused_actors.clear()
    get_tree().paused = bool(snapshot.get("paused", false))
    hidden_items.clear()
    snapshot.clear()
    _canvas.hide()
    _speaker = null
    active = false
    input_grace_left = float(settings["input_grace"])

func cancel() -> void:
    if not active:
        return
    generation += 1
    cancelled = true
    if live_timer != null:
        live_timer.timeout.emit()
        live_timer = null
    if camera_tween != null and camera_tween.is_valid():
        camera_tween.kill()
        camera_tween.finished.emit()
    _restore()
    finished.emit()
func give_axe(father: Node2D, hero: NimrodPlayer) -> void:
    if not is_instance_valid(hero) or not is_instance_valid(father):
        return
    var spec: Dictionary = settings["parent_gift"]
    var gift := Node2D.new()
    gift.process_mode = Node.PROCESS_MODE_ALWAYS
    gift.z_index = 70
    get_tree().current_scene.add_child(gift)
    AssetVisual.add_image(gift, str(spec["gift_art"]), Vector2(-33, -21), Vector2(66, 42))
    gift.global_position = father.global_position + Vector2(20, -68)
    var tween := gift.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(gift, "global_position", hero.global_position + Vector2(0, -60), float(spec["gift_seconds"]))
    await tween.finished
    gift.queue_free()
    if cancelled or not is_instance_valid(hero):
        return
    get_node("/root/GameState").set_weapon("axe")
    get_node("/root/SceneManager").show_toast("니므롯의 도끼를 얻었다")
