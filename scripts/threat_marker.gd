class_name ThreatMarker
extends Node2D

# These are UI indicators, never monster or map art.
static var globally_enabled: bool = true
var settings: Dictionary
var age: float = 0.0
var dead_alpha: float = 1.0
var ground_point: Vector2
var projection_alpha: float = 1.0
var shadow: Node2D
var current_color: Color = Color("C8473B")
var enemy: EnemyBase

class GroundShadow extends Node2D:
    var marker: ThreatMarker
    func _draw() -> void:
        if marker == null or not marker.visible:
            return
        var width: float = marker.enemy.body_size.x * float(marker.settings["shadow_width_ratio"]) * marker.projection_alpha
        var height: float = float(marker.settings["shadow_height"])
        var points := PackedVector2Array([Vector2.ZERO])
        var rgba: Array = marker.settings["shadow_color"]
        var shade := Color(float(rgba[0]), float(rgba[1]), float(rgba[2]), float(rgba[3]) * marker.projection_alpha)
        var colors := PackedColorArray([shade])
        for i in range(25):
            points.append(Vector2(cos(TAU * i / 24.0) * width * 0.5, sin(TAU * i / 24.0) * height * 0.5))
            colors.append(Color(shade.r, shade.g, shade.b, 0.0))
        # Independent triangles retain a transparent outer edge.
        for i in range(1, points.size() - 1):
            draw_polygon(PackedVector2Array([points[0], points[i], points[i + 1]]), PackedColorArray([colors[0], colors[i], colors[i + 1]]))

func _ready() -> void:
    add_to_group("threat_markers")
    enemy = get_parent() as EnemyBase
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemy_markers.json"))
    for key in settings.get("overrides", {}).get(enemy.enemy_id, {}):
        settings[key] = settings["overrides"][enemy.enemy_id][key]
    z_index = 25
    shadow = GroundShadow.new()
    shadow.marker = self
    shadow.z_index = -26
    add_child(shadow)

func _process(delta: float) -> void:
    age += delta
    if get_tree().get_first_node_in_group("threat_markers") == self and Input.is_action_just_pressed("threat_markers"):
        globally_enabled = not globally_enabled
    var dying: bool = enemy.state == EnemyBase.State.DEAD
    if enemy.has_method("marker_is_dangerous") and bool(enemy.call("marker_is_dangerous")):
        dying = false
    dead_alpha = move_toward(dead_alpha, 0.0 if dying else 1.0, delta / float(settings["death_fade"]))
    var level: Node = enemy._level()
    var screen: Vector2 = enemy.get_global_transform_with_canvas().origin
    var onscreen: bool = Rect2(Vector2(-enemy.body_size.x, -enemy.body_size.y), get_viewport_rect().size + enemy.body_size * 2.0).has_point(screen)
    visible = globally_enabled and bool(settings["enabled"]) and dead_alpha > 0.0 and onscreen and (level == null or not level.is_point_safe(enemy.global_position))
    modulate.a = dead_alpha
    current_color = Color(str(settings["windup_color"] if enemy.state == EnemyBase.State.WINDUP else settings["triangle_color"]))
    var ray := PhysicsRayQueryParameters2D.create(enemy.global_position + Vector2(0, -2), enemy.global_position + Vector2(0, float(settings["shadow_ray_length"])), 3, [enemy.get_rid()])
    var hero: Node = get_tree().get_first_node_in_group("player")
    if hero is CollisionObject2D:
        ray.exclude = [enemy.get_rid(), hero.get_rid()]
    var result: Dictionary = enemy.get_world_2d().direct_space_state.intersect_ray(ray)
    shadow.visible = not result.is_empty()
    if not result.is_empty():
        var distance: float = enemy.global_position.distance_to(result["position"])
        projection_alpha = clampf(1.0 - distance / float(settings["shadow_ray_length"]), 0.20, 1.0)
        shadow.global_position = result["position"]
    shadow.queue_redraw()
    queue_redraw()

func _draw() -> void:
    if enemy == null:
        return
    var warning: bool = enemy.state == EnemyBase.State.WINDUP
    var frequency: float = float(settings["bob_hz"]) * (2.0 if warning else 1.0)
    var alpha: float = float(settings["triangle_alpha"])
    if enemy.enemy_id == "wall_diver":
        if bool(enemy.get("perched")):
            alpha *= float(settings["perch_alpha"])
    if enemy.enemy_id == "corpse_bomber" and bool(enemy.get("fuse_started")):
        alpha *= 0.45 + 0.55 * absf(sin(age * (8.0 + float(enemy.get("fuse_clock")) * 12.0)))
    if enemy.enemy_id == "cedar_demon" and bool(enemy.get("perched")):
        alpha *= float(settings["perch_alpha"])
    if enemy.has_method("marker_blinks") and bool(enemy.call("marker_blinks")):
        alpha *= 0.4 + 0.6 * absf(sin(age * 22.0))
    var width: float = clampf(enemy.body_size.x * float(settings["triangle_size_ratio"]), float(settings["triangle_min"]), float(settings["triangle_max"]))
    var height: float = float(settings["triangle_height"])
    var y: float = enemy._local_hurt_rect().position.y - float(settings["head_gap"]) + sin(age * TAU * frequency) * float(settings["bob_pixels"])
    var vertices := PackedVector2Array([Vector2(-width * 0.5, y - height), Vector2(width * 0.5, y - height), Vector2(0, y)])
    draw_colored_polygon(PackedVector2Array([vertices[0] + Vector2.ONE, vertices[1] + Vector2.ONE, vertices[2] + Vector2.ONE]), Color(0, 0, 0, 0.35 * alpha))
    var color: Color = current_color
    color.a = alpha
    draw_polygon(vertices, PackedColorArray([color, color, color.darkened(0.25)]))
