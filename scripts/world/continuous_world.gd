class_name ContinuousWorld
extends LevelBase

var enemies: Array[EnemyBase] = []
var chunks: Dictionary = {}
var region_data: Dictionary = {}
var backgrounds: Dictionary = {}
var caption: Label
var caption_tween: Tween
var seen_regions: Dictionary = {}

func _ready() -> void:
    var world: Node = get_node("/root/World")
    level_id="Zabulistan"
    display_name="자불리스탄"
    camera_limits=Rect2(0,0,float(world.settings.width)*32,float(world.settings.height)*32)
    world_settings={"surface_layer":1,"one_way_layer":2,"one_way_margin":6}
    config={"width":camera_limits.size.x,"drop_rule":{"mode":"all","chance":world.density.heal_drop}}
    floor_y=camera_limits.end.y
    add_to_group("current_level")
    for edge: Rect2 in [Rect2(-32,0,32,camera_limits.size.y),Rect2(camera_limits.end.x,0,32,camera_limits.size.y),Rect2(0,-32,camera_limits.size.x,32)]:
        _make_surface(edge.position.x,edge.position.y,edge.size.x,edge.size.y,false,0)
    var hud:=CanvasLayer.new()
    hud.layer=22
    add_child(hud)
    caption=Label.new()
    caption.position=Vector2(400,610)
    caption.size=Vector2(480,48)
    caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    caption.add_theme_font_size_override("font_size",26)
    caption.modulate.a=0
    hud.add_child(caption)

func _process(delta: float) -> void:
    var world: Node = get_node("/root/World")
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    if not world.active or not is_instance_valid(hero):return
    var weights: Dictionary = world.region_weights(hero.position/32.)
    for id in weights:
        if not backgrounds.has(id):make_background(str(id))
    for id in backgrounds:
        var root_layer: Node2D = backgrounds[id]
        root_layer.modulate.a=move_toward(root_layer.modulate.a,float(weights.get(id,0)),delta*2)
        root_layer.visible=root_layer.modulate.a>.001
        for i in range(root_layer.get_child_count()):
            var layer: Sprite2D = root_layer.get_child(i)
            var ratio: float = [.12,.3,.58][i]
            layer.position=hero.position-Vector2(2048,512)
            layer.region_rect.position=Vector2(hero.position.x*ratio/4.,0)
    var region: Dictionary = world.region_at(hero.position/32.)
    region_data=region
    if not seen_regions.has(region.id):
        seen_regions[region.id]=true
        caption.text=str(region.name)
        if caption_tween!=null and caption_tween.is_valid():caption_tween.kill()
        caption_tween=create_tween()
        caption_tween.tween_property(caption,"modulate:a",1.,.3)
        caption_tween.tween_interval(1.4)
        caption_tween.tween_property(caption,"modulate:a",0.,.3)
        get_node("/root/Audio").play_bgm(str(region.bgm))

func make_background(id: String) -> void:
    var root_layer:=Node2D.new()
    root_layer.modulate.a=0
    add_child(root_layer)
    backgrounds[id]=root_layer
    var art: Dictionary = get_node("/root/World").art.get(id,{})
    for i in range(3):
        var sprite:=Sprite2D.new()
        var path: String = str(art.get("backgrounds",["res://assets/backgrounds/deathsea/stars_tile.webp","res://assets/backgrounds/deathsea/stars_tile.webp","res://assets/backgrounds/deathsea/stars_tile.webp"])[i])
        sprite.texture=load(path)
        sprite.centered=false
        sprite.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
        sprite.region_enabled=true
        sprite.region_rect=Rect2(0,0,1024,256)
        sprite.scale=Vector2(4.,4.)
        sprite.z_index=-30+i*5
        sprite.modulate=Color(.55,.59,.68,.85 if i<2 else .28)
        root_layer.add_child(sprite)

func refresh_story() -> void:pass
func reconcile_presence() -> void:pass
func is_point_safe(point: Vector2) -> bool:
    var spawn: Array = get_node("/root/World").settings.spawn
    return point.distance_to(Vector2(float(spawn[0])*32,float(spawn[1])*32))<320
func ground_y_at(x: float) -> float:
    var best: float = floor_y
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    for body: Node in get_tree().get_nodes_in_group("surfaces"):
        var rect: Rect2 = body.get_meta("surface_rect",Rect2())
        if x>=rect.position.x and x<=rect.end.x and rect.position.y>=hero.position.y-8:best=minf(best,rect.position.y)
    return best
func forget_enemy(enemy: EnemyBase) -> void:enemies.erase(enemy)
