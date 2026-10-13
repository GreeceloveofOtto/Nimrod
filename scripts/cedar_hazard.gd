class_name CedarHazard
extends Node2D

var spec: Dictionary = {}
var age: float = 0.0
var hit: bool = false
var effect: Node2D
var direction := Vector2.RIGHT
var travelled: float = 0.0
var effect_started: bool = false

func _ready() -> void:
    add_to_group("cedar_hazards")
    var size_values: Array = spec.get("size", [90, 200])
    effect = CedarFX.spawn(self, str(spec.get("fx", "bone_spike")), global_position, Vector2(float(size_values[0]), float(size_values[1])))
    if effect != null:
        effect.visible = float(spec.get("delay", 0.0)) <= 0.0
        effect.set_process(effect.visible)
        effect_started = effect.visible

func _physics_process(delta: float) -> void:
    age += delta
    var delay: float = float(spec.get("delay", 0.0))
    if is_instance_valid(effect):
        effect.visible = age >= delay
        if effect.visible and not effect_started:
            effect_started = true
            effect.clock = 0.0
            effect.set_process(true)
    if age < delay:
        return
    var player: NimrodPlayer = get_tree().get_first_node_in_group("player") as NimrodPlayer
    var previous: Vector2 = global_position
    var speed: float = float(spec.get("speed", 0.0))
    if speed > 0.0:
        var step: Vector2 = direction * speed * delta
        var ray := PhysicsRayQueryParameters2D.create(previous, previous + step, 3)
        if player != null:
            ray.exclude = [player.get_rid()]
        var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(ray)
        if not result.is_empty():
            queue_free()
            return
        global_position += step
        travelled += step.length()
    if player != null and not hit:
        var hero_box: Rect2 = player.get_hurt_rect()
        var size_values: Array = spec.get("size", [90, 200])
        var size_px := Vector2(float(size_values[0]), float(size_values[1]))
        var connects: bool = Rect2(global_position - size_px * 0.5, size_px).intersects(hero_box)
        if speed > 0.0:
            var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(hero_box.get_center(), previous, global_position)
            connects = hero_box.grow(size_px.y * 0.5).has_point(nearest)
        if spec.has("radius"):
            var near_point := Vector2(clampf(global_position.x, hero_box.position.x, hero_box.end.x), clampf(global_position.y, hero_box.position.y, hero_box.end.y))
            connects = near_point.distance_to(global_position) <= float(spec["radius"])
        if connects and not player.is_roll_invulnerable() and not player.is_transition_locked():
            hit = true
            var knock: float = float(spec.get("knockback", 0.0))
            if int(spec.get("damage", 0)) > 0:
                player.receive_damage(int(spec["damage"]), {"grant_grace": bool(spec.get("grant_grace", true)), "knockback": Vector2(signf(player.global_position.x - global_position.x) * knock, 0)})
            elif knock > 0.0:
                player.velocity.x = signf(player.global_position.x - global_position.x) * knock
            if speed > 0.0:
                queue_free()
                return
    if age >= delay + float(spec.get("seconds", 0.6)) or travelled >= float(spec.get("range", 2000.0)):
        queue_free()
