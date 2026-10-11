class_name GateController
extends DoorPortal

@export_file("*.png", "*.webp") var gate_art: String = ""
@export var gate_open_seconds: float = 1.2
@export var gate_close_seconds: float = 1.0
@export var trigger_radius: float = 300.0
@export var close_radius: float = 600.0
@export var open_frame_for_gate_start: int = 3
@export var inner_gatekeeper: NPC
@export var outer_gatekeeper: NPC
@export var blocker: CollisionShape2D
@export var auto_transition_level: String = ""
@export var auto_transition_spawn: String = ""
@export var requires_dialogue: bool = false
@export var opens_without_keeper: bool = false
@export var gate_settings_key: String = "great_gate"

# Compatibility property for saved villa scenes and previous regression checks.
var gate_requires_dialogue: bool:
    get:
        return requires_dialogue
    set(value):
        requires_dialogue = value

enum GateState { CLOSED, REQUESTED, OPENING, OPEN, CLOSING }

var gate_state: GateState = GateState.CLOSED
var gate_config: Dictionary = {}
var gatekeeper: Node2D
var wall: StaticBody2D
var wall_shape: CollisionShape2D
var entry_armed: bool = true
var approach_armed: bool = true

func _ready() -> void:
    if not gate_art.is_empty():
        door_art = gate_art
    auto_trigger = not auto_transition_level.is_empty()
    target_level = auto_transition_level
    target_spawn = auto_transition_spawn
    super._ready()
    gate_config = interaction_data.get(gate_settings_key, {})
    trigger_radius = float(gate_config.get("open_distance", trigger_radius))
    close_radius = float(gate_config.get("close_distance", close_radius))
    _make_wall()
    if is_instance_valid(inner_gatekeeper):
        bind_gatekeeper(inner_gatekeeper)

func bind_gatekeeper(keeper: Node2D) -> void:
    gatekeeper = keeper
    inner_gatekeeper = keeper as NPC
    if is_node_ready() and is_instance_valid(gatekeeper):
        gatekeeper.call("bind_gate", self, open_frame_for_gate_start - 1)

func _make_wall() -> void:
    if is_instance_valid(blocker):
        wall_shape = blocker
        return
    wall = StaticBody2D.new()
    wall.name = "ClosedGateBarrier"
    wall.collision_layer = 1
    wall.collision_mask = 0
    add_child(wall)
    wall_shape = CollisionShape2D.new()
    var dimensions: Array = gate_config.get("collision_size", [36, 360])
    var shape := RectangleShape2D.new()
    shape.size = Vector2(float(dimensions[0]), float(dimensions[1]))
    wall_shape.shape = shape
    wall_shape.position.y = -shape.size.y * 0.5
    wall.add_child(wall_shape)
    blocker = wall_shape

func _process(_delta: float) -> void:
    if prompt != null:
        prompt.visible = false
    var player := _player()
    if player == null or busy:
        return
    var distance: float = absf(player.global_position.x - global_position.x)
    if not approach_armed and distance > trigger_radius:
        approach_armed = true
    if not entry_armed and distance > float(gate_config.get("entry_rearm_distance", 80.0)):
        entry_armed = true
    if not _player_available(player):
        return
    # TODO: a future dialogue system may authorize the gate here.
    if gate_requires_dialogue:
        return
    if gate_state == GateState.CLOSED and approach_armed and distance <= trigger_radius:
        _request_open(player)
    elif gate_state == GateState.OPEN and distance >= close_radius:
        _close_gate()
    if can_interact(player):
        interact(player)

func can_interact(player: Node2D) -> bool:
    if auto_transition_level.is_empty() or gate_requires_dialogue or locked or gate_state != GateState.OPEN or not entry_armed:
        return false
    if not _player_available(player):
        return false
    return absf(player.global_position.x - global_position.x) <= float(gate_config.get("trigger_half_width", 40.0)) and absf(player.global_position.y - global_position.y) <= float(config.get("vertical_range", 120.0))

func _request_open(player: Node2D) -> void:
    gate_state = GateState.REQUESTED
    if is_instance_valid(gatekeeper):
        gatekeeper.call("begin_open_gate", player)
    else:
        if opens_without_keeper:
            keeper_open_frame_reached()
        else:
            gate_state = GateState.CLOSED
            push_warning("Gatekeeper missing; gate remains closed")

func keeper_open_frame_reached() -> void:
    if gate_state != GateState.REQUESTED or gate_requires_dialogue:
        return
    gate_state = GateState.OPENING
    _sound(str(gate_config.get("open_sound", "door_open")))
    await animate_open(true, gate_open_seconds)
    gate_state = GateState.OPEN
    wall_shape.set_deferred("disabled", true)
    if is_instance_valid(gatekeeper):
        gatekeeper.call("finish_open_gate")

func _close_gate() -> void:
    if gate_state != GateState.OPEN:
        return
    gate_state = GateState.CLOSING
    wall_shape.set_deferred("disabled", false)
    _sound(str(gate_config.get("close_sound", "door_close")))
    await animate_open(false, gate_close_seconds)
    gate_state = GateState.CLOSED

func interact(player: Node2D) -> void:
    if not can_interact(player):
        return
    var manager := _manager()
    if manager == null:
        return
    busy = true
    entry_armed = false
    manager.call("set_player_locked", true)
    await _walk_into_door(player)
    _sound("portal_whoosh")
    manager.call("go_to", target_level, target_spawn)

func prepare_arrival(player: Node2D) -> void:
    entry_armed = false
    approach_armed = false
    gate_state = GateState.OPEN
    wall_shape.set_deferred("disabled", true)
    super.prepare_arrival(player)

func play_arrival(player: Node2D) -> void:
    await super.play_arrival(player)
    gate_state = GateState.CLOSED
    wall_shape.set_deferred("disabled", false)
    # The returning player must leave the entry strip before it can trigger again.
    entry_armed = false
