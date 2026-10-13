extends Node2D
var prompt: Node2D
func _ready() -> void:
    position=Vector2(float(get_node("/root/Odyssey").settings["climb_x"]),get_parent().floor_y)
    prompt=AssetVisual.add_image(self,"res://assets/ui/prompt_e.png",Vector2(-20,-150),Vector2(40,40),20)
    prompt.visible=false
func available() -> bool:
    return get_node("/root/Story").is_flag("utnapishtim_done") and not get_node("/root/Cutscene").active and not get_node("/root/Dialogue").active
func _process(_delta: float) -> void:
    var hero: NimrodPlayer=get_node("/root/SceneManager").player
    prompt.visible=available() and not hero.transition_locked and absf(hero.global_position.x-global_position.x)<=float(get_node("/root/Odyssey").settings["climb_range"])
    if prompt.visible and Input.is_action_just_pressed("interact"):
        get_node("/root/Cutscene").play("huluppu_climb")
