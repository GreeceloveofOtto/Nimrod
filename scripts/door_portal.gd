class_name DoorPortal
extends Node2D

@export var door_id: String = ""
@export var target_level: String = ""
@export var target_spawn: String = "Spawn_Start"
@export_file("*.png", "*.webp") var door_art: String = "res://assets/props/doors/castle_interior_door.webp"
@export var locked: bool = false
@export var locked_message: String = "아직 갈 수 없다"
@export var auto_trigger: bool = false
@export var interact_range: float = 90.0
@export var arrival_spawn: String = ""
@export var exit_direction: int = 1

var config: Dictionary = {}
var interaction_data: Dictionary = {}
var visual: Sprite2D
var prompt: Node2D
var frame_size: Vector2 = Vector2.ZERO
var frame_count: int = 1
var open_progress: float = 0.0
var busy: bool = false
var door_tween: Tween
var _arrival_destination: Vector2
var _arrival_prepared: bool = false

func _ready() -> void:
    add_to_group("door_portals")
    var file := FileAccess.open("res://data/interactions.json", FileAccess.READ)
    if file != null:
        var parsed: Variant = JSON.parse_string(file.get_as_text())
        if parsed is Dictionary:
            interaction_data = parsed
    config = interaction_data.get("portal", {})
    _make_art()
    _make_prompt()
    _set_open_progress(0.0)

func _make_art() -> void:
    var key: String = door_art.get_file().get_basename()
    var art: Dictionary = interaction_data.get("door_art", {}).get(key, {})
    var size: Array = art.get("frame_size", config.get("fallback_size", [256, 384]))
    frame_size = Vector2(float(size[0]), float(size[1]))
    frame_count = int(art.get("frames", config.get("fallback_frames", 6)))
    visual = Sprite2D.new()
    visual.name = "DoorArt"
    visual.region_enabled = true
    visual.offset = Vector2(0.0, -frame_size.y * 0.5)
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    add_child(visual)
    if ResourceLoader.exists(door_art):
        visual.texture = load(door_art) as Texture2D
    if visual.texture == null:
        var helper = load("res://scripts/asset_visual.gd")
        helper.add_image(self, door_art, Vector2(-frame_size.x * 0.5, -frame_size.y), frame_size)

func _make_prompt() -> void:
    var size: Array = config.get("prompt_size", [40, 40])
    var dimensions := Vector2(float(size[0]), float(size[1]))
    var at := Vector2(-dimensions.x * 0.5, -frame_size.y - dimensions.y - float(config.get("prompt_gap", 12.0)))
    var helper = load("res://scripts/asset_visual.gd")
    prompt = helper.add_image(self, str(config.get("prompt_path", "res://assets/ui/prompt_e.png")), at, dimensions)
    prompt.name = "InteractionPrompt"
    prompt.visible = false

func _process(_delta: float) -> void:
    var player := _player()
    var available: bool = can_interact(player)
    if prompt != null:
        prompt.visible = available and not auto_trigger and _is_nearest(player)
    if auto_trigger and available:
        interact(player)

func _unhandled_input(event: InputEvent) -> void:
    if auto_trigger or not event.is_action_pressed("interact") or event.is_echo():
        return
    var player := _player()
    if can_interact(player) and _is_nearest(player):
        get_viewport().set_input_as_handled()
        interact(player)

func _player() -> Node2D:
    return get_tree().get_first_node_in_group("player") as Node2D

func _manager() -> Node:
    return get_node_or_null("/root/SceneManager")

func _player_available(player: Node2D) -> bool:
    if player == null or busy or int(player.get("hp")) <= 0:
        return false
    var manager := _manager()
    if manager != null and (bool(manager.get("player_locked")) or bool(manager.get("is_transitioning"))):
        return false
    return true

func _inside_range(player: Node2D) -> bool:
    return player != null and absf(player.global_position.x - global_position.x) <= interact_range and absf(player.global_position.y - global_position.y) <= float(config.get("vertical_range", 120.0))

func can_interact(player: Node2D) -> bool:
    if get_node("/root/Dialogue").active:
        return false
    return _player_available(player) and _inside_range(player)

func _is_nearest(player: Node2D) -> bool:
    if player == null:
        return false
    var distance: float = global_position.distance_squared_to(player.global_position)
    for node in get_tree().get_nodes_in_group("door_portals"):
        if node == self or node.auto_trigger or not node.can_interact(player):
            continue
        var other_distance: float = node.global_position.distance_squared_to(player.global_position)
        if other_distance < distance or (is_equal_approx(other_distance, distance) and node.get_instance_id() < get_instance_id()):
            return false
    return true

func interact(player: Node2D) -> void:
    if not can_interact(player):
        return
    if locked:
        _shake_locked()
        return
    busy = true
    var manager := _manager()
    if manager == null:
        push_warning("DoorPortal requires SceneManager")
        busy = false
        return
    manager.call("set_player_locked", true)
    _sound("door_open")
    await animate_open(true, float(config.get("open_seconds", 0.6)))
    await _walk_into_door(player)
    _sound("portal_whoosh")
    manager.call("go_to", target_level, target_spawn)

func _walk_into_door(player: Node2D) -> void:
    if not is_instance_valid(player):
        return
    var direction: float = signf(global_position.x - player.global_position.x)
    if is_zero_approx(direction):
        direction = float(exit_direction)
    player.call("begin_portal_walk", direction)
    var tween := create_tween().set_parallel(true)
    var seconds: float = float(config.get("enter_seconds", 0.4))
    tween.tween_property(player, "global_position", global_position, seconds)
    tween.tween_property(player, "modulate:a", 0.0, seconds)
    await tween.finished
    if is_instance_valid(player):
        player.call("end_portal_walk")

func prepare_arrival(player: Node2D) -> void:
    busy = true
    _arrival_destination = player.global_position
    if _arrival_destination.is_equal_approx(global_position):
        _arrival_destination.x += float(exit_direction) * float(config.get("arrival_step", 40.0))
    _arrival_prepared = true
    _set_open_progress(1.0)
    player.global_position = global_position
    player.modulate.a = 0.0

func play_arrival(player: Node2D) -> void:
    if not _arrival_prepared:
        prepare_arrival(player)
    var direction: float = signf(_arrival_destination.x - global_position.x)
    if is_zero_approx(direction):
        direction = float(exit_direction)
    player.call("begin_portal_walk", direction)
    var tween := create_tween().set_parallel(true)
    var seconds: float = float(config.get("arrival_walk_seconds", 0.3))
    tween.tween_property(player, "global_position", _arrival_destination, seconds)
    tween.tween_property(player, "modulate:a", 1.0, seconds)
    await tween.finished
    player.call("end_portal_walk")
    _sound("door_close")
    await animate_open(false, float(config.get("close_seconds", 0.5)))
    busy = false
    _arrival_prepared = false

func animate_open(opening: bool, seconds: float) -> Signal:
    if is_instance_valid(door_tween):
        door_tween.kill()
    door_tween = create_tween()
    door_tween.tween_method(_set_open_progress, open_progress, 1.0 if opening else 0.0, seconds)
    # A killed bound tween never emits finished in Godot 4.3. The tree-owned
    # timer completes even when a departing level frees its animated door.
    var timer: SceneTreeTimer = get_tree().create_timer(seconds)
    timer.timeout.connect(_complete_door_animation.bind(door_tween.get_instance_id(), 1.0 if opening else 0.0), CONNECT_ONE_SHOT)
    return timer.timeout

func _complete_door_animation(animation_id: int, target: float) -> void:
    if is_instance_valid(door_tween) and door_tween.get_instance_id() == animation_id and door_tween.is_valid():
        # Timer and Tween can finish on adjacent frames; arrival must publish
        # its exact closed/open frame before waiting portal callers continue.
        _set_open_progress(target)
        door_tween.kill()

func _set_open_progress(value: float) -> void:
    open_progress = clampf(value, 0.0, 1.0)
    if visual != null:
        var frame: int = mini(frame_count - 1, floori(open_progress * frame_count))
        var spec: Dictionary = AssetVisual.sheet_spec(door_art, {"frame_width": frame_size.x, "frame_height": frame_size.y, "frames": frame_count, "anchor_px": [frame_size.x * 0.5, frame_size.y]})
        AssetVisual.apply_frame(visual, spec, frame)

func _shake_locked() -> void:
    if busy:
        return
    busy = true
    _sound("door_locked")
    var manager := _manager()
    if manager != null:
        manager.call("show_toast", locked_message)
    var origin: Vector2 = visual.position
    var cycles: int = int(config.get("locked_shake_cycles", 3))
    var seconds: float = float(config.get("locked_shake_seconds", 0.24)) / float(cycles * 2)
    var strength: float = float(config.get("locked_shake_pixels", 5.0))
    var tween := create_tween()
    for index in range(cycles):
        tween.tween_property(visual, "position:x", origin.x + strength, seconds)
        tween.tween_property(visual, "position:x", origin.x - strength, seconds)
    tween.tween_property(visual, "position", origin, 0.0)
    await tween.finished
    busy = false

func _sound(sound_name: String) -> void:
    var audio := get_node_or_null("/root/Audio")
    if audio != null:
        audio.call("play_sfx", sound_name, global_position)
