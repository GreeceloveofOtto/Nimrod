extends StaticBody2D
var prop_owner: Node2D
var hp := 30
func take_hit(damage: int,_from_pos: Vector2,_step: int) -> Dictionary:
    if hp<=0:return {"damage_dealt":0}
    hp-=damage
    if hp<=0:
        var world: Node = get_node("/root/World")
        world.collected[str(prop_owner.spec.id)]=true
        AnurLightProjectile.spawn_fx(get_parent(),global_position-Vector2(0,60),"anur_light_impact")
        prop_owner.queue_free()
    return {"damage_dealt":damage,"blocked":false}
