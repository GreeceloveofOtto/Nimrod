extends Control
func _ready() -> void:
    custom_minimum_size=Vector2(26,28)
    mouse_filter=MOUSE_FILTER_IGNORE
func _draw() -> void:
    draw_arc(Vector2(13,10),7,PI,TAU,12,Color(.45,.42,.38),2,true)
    draw_rect(Rect2(4,10,18,16),Color(.3,.28,.25),true)
    draw_rect(Rect2(4,10,18,16),Color(.45,.42,.38),false,1)
