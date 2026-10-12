extends Node2D
var target_level: String = "DeathSea"
var target_spawn: String = "Spawn_FromDilmun"
var required_flag: String = "death_sea_paper"
var width: float = 160
var prompt: Node2D
func _ready() -> void:
    prompt = AssetVisual.add_image(self,"res://assets/ui/prompt_e.png",Vector2(-16,-140),Vector2(32,32),60)
    prompt.name = "InteractionPrompt"
    var label := Label.new()
    label.text = "이동"
    label.position = Vector2(-2,32)
    label.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    prompt.add_child(label)
    prompt.hide()
func _process(_delta: float) -> void:
    var manager: Node = get_node("/root/SceneManager")
    var hero: NimrodPlayer = manager.player
    prompt.visible = is_instance_valid(hero) and absf(hero.global_position.x-global_position.x)<=width*.5 and absf(hero.global_position.y-global_position.y)<160 and not manager.player_locked and not get_node("/root/Dialogue").input_blocked()
    if prompt.visible and Input.is_action_just_pressed("interact"):
        interact()
func interact() -> bool:
    if not get_node("/root/Story").is_flag(required_flag):
        get_node("/root/SceneManager").show_toast("죽음의 바다를 건널 방법이 없다")
        return false
    var manager: Node = get_node("/root/SceneManager")
    if manager.is_transitioning:
        return false
    # The zone is freed with its level. Keep the transition coroutine on the autoload.
    manager.go_to.call_deferred(target_level,target_spawn)
    return true
