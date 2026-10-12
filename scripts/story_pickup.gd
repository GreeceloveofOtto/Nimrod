extends Node2D
var kind := "melammu"
var prompt: Node2D
var busy := false
func _ready() -> void:
    add_to_group("story_pickups")
    var size_px := Vector2(64,64) if kind=="melammu" else Vector2(80,80)
    AssetVisual.add_image(self,"res://assets/props/"+("melammu_pickup" if kind=="melammu" else "gugalanna_helm")+".webp",Vector2(-size_px.x*.5,-size_px.y),size_px)
    var pool := AssetVisual.add_image(self,"res://assets/fx/npc_light_pool.webp",Vector2(-60,-65),Vector2(120,60),-1)
    pool.modulate = Color(1,.12,.04,.5) if kind=="melammu" else Color(1,.85,.4,.4)
    var blend := CanvasItemMaterial.new()
    blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    pool.material = blend
    for child in pool.get_children():
        if child is CanvasItem:
            child.use_parent_material = true
    if kind=="melammu":
        var pulse := create_tween().set_loops()
        pulse.tween_property(pool,"modulate:a",.2,.6)
        pulse.tween_property(pool,"modulate:a",.5,.6)
    prompt = AssetVisual.add_image(self,"res://assets/ui/prompt_e.png",Vector2(-16,-105),Vector2(32,32),60)
    prompt.name = "InteractionPrompt"
    var label := Label.new()
    label.text = "삼키기" if kind=="melammu" else "장착"
    label.position = Vector2(-24,32)
    label.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf") as Font)
    prompt.add_child(label)
    prompt.hide()
func _process(_delta: float) -> void:
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    prompt.visible = not busy and is_instance_valid(hero) and not hero.transition_locked and not get_node("/root/Dialogue").input_blocked() and hero.global_position.distance_to(global_position)<=120
    if prompt.visible and Input.is_action_just_pressed("interact"):
        interact()
func interact() -> void:
    if busy or get_node("/root/Cutscene").active:
        return
    busy = true
    prompt.hide()
    hide()
    if kind=="melammu":
        # The level (and this pickup) is freed mid-cutscene; the autoload owns it.
        get_node("/root/Cutscene").play("melammu_absorb")
        return
    await get_node("/root/Chapter").event("helm")
    get_node("/root/Chapter").schedule_helm_departure()
    queue_free()
