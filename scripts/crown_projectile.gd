extends Node2D
var direction:=Vector2.DOWN
var speed:=450.0
var damage:=11
var charm_seconds:=0.0
var remaining:=900.0
var struck:=false
func _ready() -> void:
    if charm_seconds>0:
        var wave: Node2D=Stage5FX.spawn(self,"gas_cloud",global_position,Vector2(100,70))
        wave.modulate=Color(1,.05,.08,.6)
    else:
        var image:=Sprite2D.new()
        image.texture=load("res://assets/sprites/fx/bone_arrow.webp")
        image.scale=Vector2(.45,.8)
        image.rotation=direction.angle()
        add_child(image)
func _physics_process(delta: float) -> void:
    var before:=global_position
    var next:=before+direction*speed*delta
    var hero: NimrodPlayer=get_tree().get_first_node_in_group("player")
    if hero!=null:
        var body:=Rect2(hero.collider.global_position-(hero.collider.shape as RectangleShape2D).size*.5,(hero.collider.shape as RectangleShape2D).size).grow(14)
        var nearest:=Geometry2D.get_closest_point_to_segment(body.get_center(),before,next)
        if body.has_point(nearest) and not hero.is_roll_invulnerable():
            if charm_seconds>0:hero.reverse_controls(charm_seconds)
            else:hero.receive_damage(damage,{"grant_grace":false})
            queue_free()
            return
    var query:=PhysicsRayQueryParameters2D.create(before,next,1)
    if hero!=null:query.exclude=[hero.get_rid()]
    if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
        queue_free()
        return
    position+=direction*speed*delta
    remaining-=speed*delta
    if remaining<=0:queue_free()
