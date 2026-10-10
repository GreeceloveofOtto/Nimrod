extends Node2D

const ASSET_VISUAL = preload("res://scripts/asset_visual.gd")

@export var pickup_id: String = "healing_vomit"

var config: Dictionary = {}
var prompt: Node2D

func _ready() -> void:
    add_to_group("healing_pickups")
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/pickups.json"))
    if parsed is Dictionary:
        config = parsed.get(pickup_id, {})
    var dimensions: Array = config.get("art_size", [0.0, 0.0])
    var size_px: Vector2 = Vector2(float(dimensions[0]), float(dimensions[1]))
    ASSET_VISUAL.add_image(self, str(config.get("art", "")), Vector2(-size_px.x * 0.5, -size_px.y), size_px)
    var prompt_dimensions: Array = config.get("prompt_size", [0.0, 0.0])
    var prompt_size: Vector2 = Vector2(float(prompt_dimensions[0]), float(prompt_dimensions[1]))
    var offset: Array = config.get("prompt_offset", [0.0, 0.0])
    prompt = ASSET_VISUAL.add_image(self, str(config.get("prompt_art", "")), Vector2(float(offset[0]), float(offset[1])) - prompt_size * 0.5, prompt_size)
    prompt.visible = false

func _process(_delta: float) -> void:
    var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
    var available: bool = player != null and global_position.distance_to(player.global_position) <= float(config.get("interact_range", 0.0))
    if available and player.has_method("is_transition_locked"):
        available = not bool(player.call("is_transition_locked"))
    if available:
        available = int(player.get("hp")) > 0
    prompt.visible = available
    if available and Input.is_action_just_pressed("interact"):
        interact(player)

func interact(player: Node2D) -> void:
    if player == null or not player.has_method("heal"):
        return
    var restored: int = int(player.call("heal", int(config.get("heal_amount", 0))))
    # Keep the drop available at full health and while transitions lock healing.
    if restored > 0:
        queue_free()
