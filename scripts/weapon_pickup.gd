extends Node2D

var spec: Dictionary = {}
var prompt: Node2D

func _ready() -> void:
    if get_node("/root/GameState").run_flags.get(str(spec["flag"]), false):
        queue_free()
        return
    add_to_group("weapon_pickups")
    var size_px := Vector2(float(spec["size"][0]), float(spec["size"][1]))
    AssetVisual.add_image(self, str(spec["art"]), Vector2(-size_px.x * 0.5, -size_px.y), size_px)
    var pool := AssetVisual.add_image(self, "res://assets/fx/npc_light_pool.webp", Vector2(-60, -70), Vector2(120, 60), -1)
    pool.modulate = Color(1.0, 0.92, 0.78, 0.15)
    var blend := CanvasItemMaterial.new()
    blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    pool.material = blend
    for image in pool.get_children():
        if image is CanvasItem:
            image.use_parent_material = true
    prompt = AssetVisual.add_image(self, "res://assets/ui/prompt_e.png", Vector2(-16, -160), Vector2(32, 32), 60)
    prompt.name = "InteractionPrompt"
    prompt.hide()

func _process(_delta: float) -> void:
    var hero := get_tree().get_first_node_in_group("player") as NimrodPlayer
    var available: bool = hero != null and not hero.transition_locked and hero.action != "dead" and not get_node("/root/Dialogue").active
    prompt.visible = available and global_position.distance_to(hero.global_position) <= float(spec["range"])
    if prompt.visible and Input.is_action_just_pressed("interact"):
        interact(hero)

func interact(_hero: NimrodPlayer) -> void:
    if get_node("/root/GameState").run_flags.get(str(spec["flag"]), false):
        return
    get_node("/root/GameState").run_flags[str(spec["flag"])] = true
    get_node("/root/GameState").set_weapon(str(spec["weapon"]))
    get_node("/root/SceneManager").show_toast(str(spec["toast"]))
    queue_free()
