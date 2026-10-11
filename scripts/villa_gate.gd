class_name VillaGate
extends GateController

# The shared controller owns the behavior; this wrapper preserves scene/API compatibility.
func _ready() -> void:
    gate_art = "res://assets/props/doors/villa_gate.webp"
    gate_settings_key = "villa_gate"
    gate_open_seconds = 1.0
    gate_close_seconds = 0.8
    auto_transition_level = "VillaF1"
    auto_transition_spawn = "Spawn_FromGate"
    super._ready()
