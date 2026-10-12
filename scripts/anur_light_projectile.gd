class_name AnurLightProjectile
extends Node2D

var direction := 1
var damage := 36
var settings: Dictionary = {}
var travelled := 0.0
var hits: Dictionary = {}
var hero: NimrodPlayer

func _ready() -> void:
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/skills.json"))["anur_light"]
    var effect: Node2D = load("res://scripts/image_effect.gd").new()
    var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage9_fx.json"))["anur_light_projectile"]
    var size := Vector2i(int(art["frame_size"][0]),int(art["frame_size"][1]))
    effect.configure("res://" + str(settings["projectile"]), size,int(art["frames"]),float(art["duration"]),true,Vector2(size)*.5)
    effect.scale = Vector2(direction,1)*float(art["scale"])
    add_child(effect)

func _physics_process(delta: float) -> void:
    var distance: float = minf(float(settings["speed"])*delta,float(settings["range"])-travelled)
    var width: float = float(settings["box"][0])
    var height: float = float(settings["box"][1])
    var shape := RectangleShape2D.new()
    shape.size = Vector2(width,height)
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0,global_position)
    query.motion = Vector2(direction*distance,0)
    query.collision_mask = 1
    if is_instance_valid(hero):
        query.exclude = [hero.get_rid()]
    var space := get_world_2d().direct_space_state
    var fractions: PackedFloat32Array = space.cast_motion(query)
    var blocked: bool = not space.intersect_shape(query,1).is_empty() or fractions[0] < 1
    var end: Vector2 = global_position + query.motion*fractions[0]
    var swept := Rect2(Vector2(minf(global_position.x,end.x)-width*.5,global_position.y-height*.5),Vector2(absf(end.x-global_position.x)+width,height))
    var candidates: Array[EnemyBase] = []
    for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
        if enemy.hp > 0 and not hits.has(enemy.get_instance_id()) and swept.intersects(enemy.get_hurt_rect()):
            candidates.append(enemy)
    candidates.sort_custom(func(a: EnemyBase,b: EnemyBase) -> bool: return direction*a.global_position.x < direction*b.global_position.x)
    for enemy in candidates:
        hits[enemy.get_instance_id()] = true
        enemy.take_light_hit(damage, global_position, float(settings["stun"]))
        spawn_fx(get_parent(),enemy.get_hurt_rect().get_center(),"anur_light_impact")
        get_node("/root/Audio").play_sfx("anur_hit")
        if hits.size() >= int(settings["pierce"]):
            queue_free()
            return
    travelled += global_position.distance_to(end)
    global_position = end
    if blocked or travelled >= float(settings["range"]):
        queue_free()

static func spawn_fx(parent: Node, at: Vector2, id: String) -> Node2D:
    var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage9_fx.json"))[id]
    var size_px := Vector2i(int(art["frame_size"][0]),int(art["frame_size"][1]))
    var effect: Node2D = load("res://scripts/image_effect.gd").new()
    effect.configure("res://"+str(art["path"]),size_px,int(art["frames"]),float(art["duration"]),false,Vector2(size_px)*.5)
    effect.scale = Vector2.ONE*float(art["scale"])
    effect.z_index = 20
    parent.add_child(effect)
    effect.global_position = at
    return effect
