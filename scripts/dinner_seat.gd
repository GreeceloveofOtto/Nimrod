extends Node2D

var prompt: Node2D
var label: Label

func _ready() -> void:
    var seat: Dictionary = get_node("/root/Story").settings["dinner_seat"]
    position = Vector2(float(seat["x"]), float(seat["y"]))
    prompt = AssetVisual.add_image(self, "res://assets/ui/prompt_e.png", Vector2(-16,-144), Vector2(32,32), 60)
    label = Label.new()
    label.text = "앉기"
    label.add_theme_font_override("font", load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    label.position = Vector2(-20,-108)
    label.z_index = 60
    add_child(label)

func available() -> bool:
    return get_node("/root/Story").is_flag("villa_intro_done") and not get_node("/root/Story").is_flag("villa_dinner_done") and not get_node("/root/Story").is_flag("night")

func _process(_delta: float) -> void:
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    var can: bool = available() and is_instance_valid(hero) and not get_node("/root/SceneManager").player_locked and not get_node("/root/Dialogue").input_blocked() and not get_node("/root/Cutscene").active
    visible = can and absf(hero.global_position.x-global_position.x) <= float(get_node("/root/Story").settings["dinner_seat"]["range"])
    if visible and Input.is_action_just_pressed("interact"):
        get_node("/root/Cutscene").play("villa_dinner")
