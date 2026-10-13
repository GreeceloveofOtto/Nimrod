extends StaticBody2D
func _ready() -> void:
    add_to_group("tiamat_body")
    set_meta("display_name","티아마트")
    collision_layer=4
    collision_mask=0
    var shape:=CollisionShape2D.new()
    var box:=RectangleShape2D.new()
    box.size=Vector2(320,500)
    shape.shape=box
    shape.position=Vector2(0,-250)
    add_child(shape)
    var hero: NimrodPlayer=get_tree().get_first_node_in_group("player")
    if is_instance_valid(hero):hero.add_collision_exception_with(self)
func get_hurt_rect() -> Rect2:
    return Rect2(global_position+Vector2(-160,-500),Vector2(320,500))
func take_hit(_amount: int, source: Vector2, _step: int) -> Dictionary:
    if not get_node("/root/Story").is_flag("tiamat_talk_done"):
        return {"blocked":false,"damage_dealt":0}
    var fx: Node2D=Stage5FX.spawn(get_parent(),"guard_spark",Vector2(clampf(source.x,global_position.x-160,global_position.x+160),source.y-75),Vector2(100,100))
    fx.modulate=Color(.7,.3,.9)
    get_node("/root/Odyssey").hit_pulse=1
    get_node("/root/SceneManager").player.shake_time=.2
    return {"blocked":false,"damage_dealt":0}
func take_shockwave_hit(amount: int, source: Vector2, step: int=4) -> Dictionary:
    return take_hit(amount,source,step)
