extends Node2D
var spec: Dictionary = {}
var prompt: Label
var gate: StaticBody2D
var timer := 0.0
var base_position := Vector2.ZERO
var consumed := false
var texture_node: Node2D

func _ready() -> void:
    if str(spec.type) in ["altar","crystal","life","lore_item","switch","portal"]:add_to_group("world_interactables")
    base_position=position
    var art: Dictionary = get_node("/root/World").read_json("res://data/world/art.json")
    var kind: String = str(spec.type)
    var size: Vector2 = Vector2(48,48)
    if kind in ["gate","portal","breakable_wall"]:size=Vector2(56,160)
    elif kind in ["altar","switch"]:size=Vector2(76,80)
    elif kind in ["spikes","poison","wind"]:size=Vector2(float(spec.size[0]),float(spec.size[1]))
    elif kind in ["crumble","moving_platform"]:size=Vector2(float(spec.size[0]),float(spec.size[1]))
    elif kind=="healing":
        var pickup: Node2D = load("res://scripts/healing_pickup.gd").new()
        add_child(pickup)
        return
    texture_node=AssetVisual.add_image(self,str(art.get(kind,art.crystal)),Vector2(-size.x*.5,-size.y),size)
    texture_node.modulate=Color(str(get_node("/root/World").regions[str(spec.region)].palette)).lightened(.3)
    if kind in ["gate","crumble","moving_platform","breakable_wall"]:
        gate=load("res://scripts/world/world_breakable.gd").new() if kind=="breakable_wall" else StaticBody2D.new()
        if kind=="breakable_wall":gate.prop_owner=self
        gate.collision_layer=5 if kind=="breakable_wall" else 1 if kind=="gate" else 2
        gate.set_meta("one_way",kind not in ["gate","breakable_wall"])
        gate.add_to_group("surfaces")
        var box:=RectangleShape2D.new()
        box.size=size
        var hit:=CollisionShape2D.new()
        hit.shape=box
        hit.position=Vector2(0,-size.y*.5)
        hit.one_way_collision=kind not in ["gate","breakable_wall"]
        gate.add_child(hit)
        add_child(gate)
        gate.set_meta("surface_rect",Rect2(global_position-Vector2(size.x*.5,size.y),size))
    prompt=Label.new()
    prompt.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    prompt.text="E" if kind not in ["gate","spikes","poison","wind","falling_rock","crumble","moving_platform"] else str(spec.get("art_hint",""))
    prompt.position=Vector2(-15,-size.y-28)
    add_child(prompt)
    prompt.visible=false

func _process(delta: float) -> void:
    var world: Node = get_node("/root/World")
    if not world.active or consumed or world.transitioning or str(spec.type)=="healing":return
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    if not is_instance_valid(hero) or hero.transition_locked or hero.hp<=0:return
    timer+=delta
    if str(spec.type)=="falling_rock":position.y=base_position.y-500+minf(500,pow(fmod(timer,4),2)*450)
    var kind: String = str(spec.type)
    var available: bool = global_position.distance_to(hero.position)<100 and world.nearest_interactable==self and hero.action=="normal"
    var allowed: bool = world.meets(spec.get("requires",[]))
    if spec.has("opens_with"):allowed=bool(world.switches.get(str(spec.opens_with),false))
    if kind=="gate":
        if spec.get("secret",false):
            if allowed and world.hero_motion.vision:world.switches[str(spec.uid)]=true
            allowed=world.switches.has(str(spec.uid))
        available=global_position.distance_to(hero.position)<190
        gate.collision_layer=0 if allowed else 1
        visible=not allowed
        if available and not allowed and fmod(timer,2)<delta:get_node("/root/SceneManager").show_toast("필요한 능력: "+str(spec.art_hint),1)
    elif kind=="moving_platform":
        var d:=Vector2(float(spec.delta[0]),float(spec.delta[1]))
        position=base_position+d*(sin(timer*TAU/float(spec.seconds))*.5+.5)
        gate.constant_linear_velocity=d*cos(timer*TAU/float(spec.seconds))*PI/float(spec.seconds)
        gate.set_meta("surface_rect",Rect2(global_position-Vector2(float(spec.size[0])*.5,float(spec.size[1])),Vector2(float(spec.size[0]),float(spec.size[1]))))
    elif kind=="crumble":
        if absf(hero.global_position.x-global_position.x)<float(spec.size[0])*.5 and absf(hero.position.y-(position.y-float(spec.size[1])))<8:
            consumed=true
            await get_tree().create_timer(float(spec.seconds),false).timeout
            queue_free()
    elif kind in ["spikes","poison","wind","falling_rock"]:
        var in_zone: bool = absf(hero.global_position.x-global_position.x)<float(spec.size[0])*.5 and absf(hero.global_position.y-global_position.y)<float(spec.size[1])+124
        if in_zone:
            if kind=="wind":hero.velocity.x+=90*delta
            elif fmod(timer,1)<delta:hero.receive_damage(8 if kind=="poison" else 12,{"source":"world_"+kind})
    else:
        prompt.visible=available and allowed
        if kind=="switch" and spec.get("one_way",false) and hero.global_position.x<global_position.x:prompt.visible=false
        if kind=="portal" and spec.get("one_way",false) and hero.position.x<position.x:prompt.visible=false
        if prompt.visible and Input.is_action_just_pressed("interact"):interact()
    if spec.get("requires",[]).has("vision") and kind not in ["gate","breakable_wall"]:visible=world.hero_motion.vision

func interact() -> bool:
    var world: Node = get_node("/root/World")
    if consumed or not world.meets(spec.get("requires",[])):return false
    if spec.type=="switch" and spec.get("one_way",false) and get_node("/root/SceneManager").player.global_position.x<global_position.x:return false
    match str(spec.type):
        "altar":
            if not world.acquire(str(spec.id)):return false
            world.collected[str(spec.id)]=true
            world.altar_animation.call_deferred()
        "crystal":
            world.crystals+=1
            world.collected[str(spec.id)]=true
        "life":
            world.fragments+=1
            world.collected[str(spec.id)]=true
            get_node("/root/SceneManager").player.heal(10)
        "lore_item":world.collected[str(spec.id)]=true
        "switch":
            world.switches[str(spec.target)]=true
            get_node("/root/SceneManager").show_toast("지름길이 열렸다",1)
            return true
        "portal":
            if not world.can_exit():return false
            world.switches[str(spec.target)]=true
            return true
        _:return false
    consumed=true
    queue_free()
    return true
