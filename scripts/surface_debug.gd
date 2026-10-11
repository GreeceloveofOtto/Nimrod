extends Node2D

# Debug geometry only; never used as map art.
static var enabled: bool = false
var collision_rect: Rect2
var image_top: float = 0.0
var image_width: float = 0.0

func _ready() -> void:
    add_to_group("surface_debug")

func _process(_delta: float) -> void:
    if get_tree().get_first_node_in_group("surface_debug") == self and Input.is_action_just_pressed("debug_surface"):
        enabled = not enabled
    visible = enabled
    if enabled:
        queue_redraw()

func _draw() -> void:
    if enabled:
        draw_rect(collision_rect, Color(0, 1, 1, 0.9), false, 1.5)
        draw_line(Vector2(-image_width * 0.5, image_top), Vector2(image_width * 0.5, image_top), Color(1, 0.5, 0, 0.9), 1.5)
