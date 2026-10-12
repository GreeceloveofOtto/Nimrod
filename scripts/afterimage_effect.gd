extends Node2D
var hero: NimrodPlayer
var interval_left: float = 0.0
func _physics_process(delta: float) -> void:
    if not is_instance_valid(hero):
        return
    interval_left -= delta
    var rampage: Node = get_node("/root/Rampage")
    if rampage.tier() <= 0 or not get_node("/root/Story").is_flag("prosthetic_equipped") or hero.transition_locked or hero.action not in ["normal","attack","devour"] or (absf(hero.velocity.x)<10 and hero.action == "normal") or interval_left>0:
        return
    interval_left = float(rampage.settings["afterimage_interval"])
    var clone := hero.visual.duplicate() as Sprite2D
    AssetVisual.configure_sprite(clone)
    clone.position = Vector2.ZERO
    clone.z_index = hero.z_index - 1
    get_tree().current_scene.add_child(clone)
    clone.global_position = hero.visual.global_position
    var trail_material := CanvasItemMaterial.new()
    trail_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    clone.material = trail_material
    clone.modulate = Color(1.0,0.12,0.08,float(rampage.tier_data()["alpha"]))
    var tween := clone.create_tween()
    tween.tween_property(clone,"modulate:a",0.0,float(rampage.tier_data()["afterimage_seconds"]))
    tween.tween_callback(clone.queue_free)
