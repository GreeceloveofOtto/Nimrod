class_name SurfaceAccent
extends Node2D

# A visibility aid placed only on collision surfaces.
static var globally_enabled: bool = true
var dimensions := Vector2.ONE
var one_way: bool = false
var ground_floor: bool = false
var level_id: String = ""
var settings: Dictionary = {}

func _ready() -> void:
    add_to_group("surface_accents")
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/surface_accent.json"))
    for key in settings.get("levels", {}).get(level_id, {}):
        settings[key] = settings["levels"][level_id][key]
    queue_redraw()

func _process(_delta: float) -> void:
    if get_tree().get_first_node_in_group("surface_accents") == self and Input.is_action_just_pressed("surface_accents"):
        globally_enabled = not globally_enabled
    visible = globally_enabled and bool(settings.get("enabled", true))

func _color(values: Array) -> Color:
    return Color(float(values[0]), float(values[1]), float(values[2]), float(values[3]))

func _draw() -> void:
    if settings.is_empty() or dimensions.x < 12.0:
        return
    var inset: float = minf(float(settings["inset"]), dimensions.x * 0.2)
    var color: Color = _color(settings["one_way_color"] if one_way else settings["solid_color"])
    if one_way:
        var x: float = inset
        while x < dimensions.x - inset:
            draw_line(Vector2(x, 1), Vector2(minf(x + float(settings["dash"]), dimensions.x - inset), 1), color, float(settings["line_width"]))
            x += float(settings["dash"]) + float(settings["gap"])
    else:
        draw_line(Vector2(inset, 1), Vector2(dimensions.x - inset, 1), color, float(settings["line_width"]))
    var band: float = minf(float(settings["top_band"]), dimensions.y)
    var bright := Color(color.r, color.g, color.b, float(settings["top_alpha"]))
    draw_polygon(PackedVector2Array([Vector2(inset, 0), Vector2(dimensions.x - inset, 0), Vector2(dimensions.x - inset, band), Vector2(inset, band)]), PackedColorArray([bright, bright, Color(bright, 0), Color(bright, 0)]))
    if not ground_floor:
        band = float(settings["bottom_band"])
        var dark := Color(0, 0, 0, float(settings["bottom_alpha"]))
        draw_polygon(PackedVector2Array([Vector2(inset, dimensions.y), Vector2(dimensions.x - inset, dimensions.y), Vector2(dimensions.x - inset, dimensions.y + band), Vector2(inset, dimensions.y + band)]), PackedColorArray([dark, dark, Color(dark, 0), Color(dark, 0)]))
