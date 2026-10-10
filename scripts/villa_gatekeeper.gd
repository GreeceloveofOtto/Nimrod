class_name VillaGatekeeper
extends NPC

@export var gesture_face_player: bool = true

var gate: Node2D
var gesture_active: bool = false
var gesture_triggered: bool = false
var trigger_frame: int = 2

func _ready() -> void:
    super._ready()
    clip_frame_changed.connect(_on_clip_frame_changed)

func bind_gate(value: Node2D, frame: int) -> void:
    gate = value
    trigger_frame = frame

func begin_open_gate(player: Node2D) -> void:
    if gesture_active:
        return
    if player != null and gesture_face_player:
        face_toward(player.global_position.x, true)
    gesture_active = true
    gesture_triggered = false
    play_clip("open_gate")

func _on_clip_frame_changed(clip: String, frame: int) -> void:
    if clip != "open_gate" or not gesture_active or gesture_triggered or frame < trigger_frame:
        return
    gesture_triggered = true
    if is_instance_valid(gate):
        gate.call("keeper_open_frame_reached")

func finish_open_gate() -> void:
    gesture_active = false
    gesture_triggered = false
    play_clip("idle")
