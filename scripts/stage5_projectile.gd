class_name Stage5Projectile
extends Node2D

var spec: Dictionary = {}
var target: Vector2
var direction: Vector2
var struck_player: bool = false
var armed: bool = false
var effect: Node2D

func configure(settings: Dictionary, destination: Vector2) -> void:
    spec = settings.duplicate(true)
    target = destination

func _ready() -> void:
    add_to_group("stage5_projectiles")
    direction = global_position.direction_to(target)
    effect = Stage5FX.spawn(self, "spit_projectile", global_position, Vector2.ONE * float(spec["collision_radius"]) * 2.0)

func _physics_process(delta: float) -> void:
    if armed:
        return
    var previous: Vector2 = global_position
    var step: float = float(spec["speed"]) * delta
    var next: Vector2 = previous + direction * minf(step, previous.distance_to(target))
    var player := get_tree().get_first_node_in_group("player") as NimrodPlayer
    var query := PhysicsRayQueryParameters2D.create(previous, next, 3)
    if player != null:
        query.exclude = [player.get_rid()]
    var obstacle: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
    if not obstacle.is_empty():
        next = obstacle["position"]
    if player != null and not struck_player:
        var body := player.get_hurt_rect().grow(float(spec["collision_radius"]))
        var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(body.get_center(), previous, next)
        if body.has_point(nearest):
            struck_player = true
            player.receive_damage(int(spec["direct_damage"]), {"stagger_seconds": float(spec["direct_stagger"])})
    global_position = next
    if not obstacle.is_empty() or next.distance_to(target) <= 0.01:
        arm()

func arm() -> void:
    if armed:
        return
    armed = true
    var hazard := Stage5Hazard.new()
    hazard.configure("explosion", {"fuse": spec["fuse"], "radius": spec["radius"], "damage": spec["explosion_damage"], "knockback": spec["knockback"]})
    hazard.position = get_parent().to_local(global_position)
    get_parent().add_child(hazard)
    queue_free()
