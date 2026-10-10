class_name VillaGate
extends DoorPortal

@export var gate_requires_dialogue: bool = false

enum GateState { CLOSED, REQUESTED, OPENING, OPEN, CLOSING }

var gate_state: GateState = GateState.CLOSED
var gate_config: Dictionary = {}
var gatekeeper: Node2D
var wall: StaticBody2D
var wall_shape: CollisionShape2D
var entry_armed: bool = true

func _ready() -> void:
    door_art = "res://assets/props/doors/villa_gate.png"
    auto_trigger = true
    target_level = "VillaF1"
    target_spawn = "Spawn_FromGate"
    super._ready()
    gate_config = interaction_data.get("villa_gate", {})
    _make_wall()
    if is_instance_valid(gatekeeper):
        bind_gatekeeper(gatekeeper)

func bind_gatekeeper(keeper: Node2D) -> void:
    gatekeeper = keeper
    if is_node_ready() and is_instance_valid(gatekeeper):
        gatekeeper.call("bind_gate", self, int(gate_config.get("keeper_trigger_frame", 2)))

func _make_wall() -> void:
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

func _process(_delta: float) -> void:
    if prompt != null:
        prompt.visible = false
    var player := _player()
    if player == null or busy:
        return
    var distance: float = absf(player.global_position.x - global_position.x)
    if not entry_armed and distance > float(gate_config.get("entry_rearm_distance", 80.0)):
        entry_armed = true
    if not _player_available(player):
        return
    # TODO: a future dialogue system may authorize the gate here.
    if gate_requires_dialogue:
        return
    if gate_state == GateState.CLOSED and distance <= float(gate_config.get("open_distance", 300.0)):
        _request_open(player)
    elif gate_state == GateState.OPEN and distance >= float(gate_config.get("close_distance", 600.0)):
        _close_gate()
    if can_interact(player):
        interact(player)

func can_interact(player: Node2D) -> bool:
    if gate_requires_dialogue or locked or gate_state != GateState.OPEN or not entry_armed:
        return false
    if not _player_available(player):
        return false
    return absf(player.global_position.x - global_position.x) <= float(gate_config.get("trigger_half_width", 40.0)) and absf(player.global_position.y - global_position.y) <= float(config.get("vertical_range", 120.0))

func _request_open(player: Node2D) -> void:
    gate_state = GateState.REQUESTED
    if is_instance_valid(gatekeeper):
        gatekeeper.call("begin_open_gate", player)
    else:
        push_warning("Villa gatekeeper missing; opening gate directly")
        keeper_open_frame_reached()

func keeper_open_frame_reached() -> void:
    if gate_state != GateState.REQUESTED or gate_requires_dialogue:
        return
    gate_state = GateState.OPENING
    _sound("door_open")
    await animate_open(true, float(gate_config.get("open_seconds", 1.0)))
    gate_state = GateState.OPEN
    wall_shape.set_deferred("disabled", true)
    if is_instance_valid(gatekeeper):
        gatekeeper.call("finish_open_gate")

func _close_gate() -> void:
    if gate_state != GateState.OPEN:
        return
    gate_state = GateState.CLOSING
    wall_shape.set_deferred("disabled", false)
    _sound("door_close")
    await animate_open(false, float(gate_config.get("close_seconds", 0.8)))
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
    gate_state = GateState.OPEN
    wall_shape.set_deferred("disabled", true)
    super.prepare_arrival(player)

func play_arrival(player: Node2D) -> void:
    await super.play_arrival(player)
    gate_state = GateState.CLOSED
    wall_shape.set_deferred("disabled", false)
    # The returning player must leave the entry strip before it can trigger again.
    entry_armed = false
