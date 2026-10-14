class_name WorldRoom
extends LevelBase

var room_data: Dictionary = {}
var region_data: Dictionary = {}
var terrain_layer: TileMapLayer
var enemies: Array[EnemyBase] = []
var gameplay: Node2D
var loaded_current := false
var collision_count := 0
var entry_name := "left"

func _ready() -> void:
    # The generic room deliberately does not read or change levels.json.
    level_id = "Zabulistan"
    display_name = "자불리스탄 · " + str(region_data.get("name", ""))
    bgm_name = str(region_data.get("bgm", "cedar_forest"))
    camera_limits = Rect2(Vector2.ZERO, Vector2(float(room_data.size[0])*1280, float(room_data.size[1])*720))
    floor_y = camera_limits.end.y-120
    world_settings = {"surface_layer":1,"one_way_layer":2,"one_way_margin":6,"ground_collision_height":220}
    config = {"width":camera_limits.size.x,"ground":[{"from":0,"to":camera_limits.size.x,"y":floor_y}],"drop_rule":{"mode":"all","chance":get_node("/root/World").density.heal_drop}}
    surface_offsets = {}
    if room_data.entities.any(func(e: Dictionary)->bool:return e.type=="altar"):
        safe_zones.append(Rect2(1100,0,850,camera_limits.size.y))
    var sky: Sprite2D = Sprite2D.new()
    sky.texture = load(str(region_data.background))
    sky.centered = false
    sky.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    sky.region_enabled = true
    sky.region_rect = camera_limits
    sky.modulate = Color(.14,.15,.2,.4)
    sky.z_index = -20
    var sky_depth := Parallax2D.new()
    sky_depth.scroll_scale=Vector2(.18,.12)
    sky_depth.repeat_size=sky.texture.get_size()
    sky.region_rect=Rect2(Vector2.ZERO,sky.texture.get_size())
    sky_depth.add_child(sky)
    add_child(sky_depth)
    # Existing generated props differentiate silhouettes without per-room images.
    var decor: Array = region_data.get("props",[])
    for i in range(decor.size()):
        var prop: Node2D = AssetVisual.add_image(self,str(decor[i]),Vector2(600+i*500,floor_y-220),Vector2(150,220),-5)
        prop.modulate=Color(str(region_data.palette)).lightened(.15)
    var wall: Sprite2D = Sprite2D.new()
    wall.texture=load(str(region_data.wall))
    wall.centered=false
    wall.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
    wall.region_enabled=true
    wall.region_rect=camera_limits
    wall.modulate=Color(.22,.22,.28,.35)
    wall.z_index=-15
    var wall_depth := Parallax2D.new()
    wall_depth.scroll_scale=Vector2(.4,.2)
    wall_depth.repeat_size=Vector2(1280,720)
    wall.region_rect=Rect2(Vector2.ZERO,Vector2(1280,720))
    wall_depth.add_child(wall)
    add_child(wall_depth)
    build_tiles()
    for key in room_data.entries:
        var marker := Marker2D.new()
        marker.name = key
        marker.position = Vector2(float(room_data.entries[key][0]),float(room_data.entries[key][1]))
        add_child(marker)
    # Only current rooms participate in collision and enemy ground lookups.
    visible=false
    process_mode = PROCESS_MODE_DISABLED
    set_collision_enabled(false)

func build_tiles() -> void:
    terrain_layer = TileMapLayer.new()
    terrain_layer.name = "Terrain"
    terrain_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    terrain_layer.z_index = -3
    var tiles := TileSet.new()
    tiles.tile_size = Vector2i(40,40)
    var atlas := TileSetAtlasSource.new()
    atlas.texture = load(str(region_data.atlas))
    atlas.texture_region_size = Vector2i(40,40)
    atlas.margins = Vector2i(2,2)
    atlas.separation = Vector2i(4,4)
    var lookup: Dictionary = get_node("/root/World").autotile.lookup
    for coords: Array in lookup.values():atlas.create_tile(Vector2i(int(coords[0]),int(coords[1])))
    tiles.add_source(atlas,0)
    terrain_layer.tile_set = tiles
    add_child(terrain_layer)
    var lines: Array = room_data.layout
    var used: Dictionary = {}
    for y in range(lines.size()):
        for x in range(str(lines[y]).length()):
            var c: String = str(lines[y])[x]
            if c not in ["#","W","="]:continue
            var mask := 0
            for item: Array in [[0,-1,1],[1,0,2],[0,1,4],[-1,0,8]]:
                var nx: int = x+int(item[0])
                var ny: int = y+int(item[1])
                if ny>=0 and ny<lines.size() and nx>=0 and nx<str(lines[ny]).length() and str(lines[ny])[nx] in ["#","W","="]:mask |= int(item[2])
            var atlas_coords: Array = lookup[str(mask)]
            terrain_layer.set_cell(Vector2i(x,y),0,Vector2i(int(atlas_coords[0]),int(atlas_coords[1])))
            if used.has(Vector2i(x,y)):continue
            var width := 1
            while x+width<str(lines[y]).length() and str(lines[y])[x+width]==c and not used.has(Vector2i(x+width,y)):width+=1
            var height := 1
            if c!="=":
                while y+height<lines.size():
                    var matches := true
                    for xx in range(x,x+width):
                        if str(lines[y+height])[xx]!=c or used.has(Vector2i(xx,y+height)):matches=false
                    if not matches:break
                    height+=1
            for yy in range(y,y+height):
                for xx in range(x,x+width):used[Vector2i(xx,yy)]=true
            var surface: StaticBody2D = _make_surface(x*40,y*40,width*40,12 if c=="=" else height*40,c=="=",0)
            surface.set_meta("wall_climbable",c=="W")
            collision_count+=1
    # Restrict openings to their authored intervals, including upper camera edges.
    for side in ["left","right"]:
        var opening: Dictionary = {}
        for exit: Dictionary in room_data.exits:
            if exit.side==side:opening=exit;break
        var x: float = -40 if side=="left" else camera_limits.end.x
        if opening.is_empty():_make_surface(x,0,40,camera_limits.size.y,false,0)
        else:
            if float(opening.from)>0:_make_surface(x,0,40,float(opening.from),false,0)
            if float(opening.to)<camera_limits.size.y:_make_surface(x,float(opening.to),40,camera_limits.size.y-float(opening.to),false,0)
    var upper: Dictionary = {}
    for exit: Dictionary in room_data.exits:
        if exit.side=="top":upper=exit;break
    if upper.is_empty():_make_surface(0,-40,camera_limits.size.x,40,false,0)
    else:
        _make_surface(0,-40,float(upper.from),40,false,0)
        _make_surface(float(upper.to),-40,camera_limits.size.x-float(upper.to),40,false,0)

func set_collision_enabled(enabled: bool) -> void:
    for child in get_children():
        if child is StaticBody2D:child.collision_layer=(2 if child.get_meta("one_way",false) else 1) if enabled else 0

func activate(entry: String) -> void:
    visible=true
    loaded_current = true
    entry_name = entry
    add_to_group("current_level")
    process_mode = PROCESS_MODE_INHERIT
    set_collision_enabled(true)
    gameplay = Node2D.new()
    gameplay.name = "CurrentEntities"
    add_child(gameplay)
    var world: Node = get_node("/root/World")
    for entity: Dictionary in room_data.entities:
        if str(entity.type) in ["enemy","boss"]:
            if entity.type=="boss" and world.collected.has(str(entity.boss_id)):continue
            var path: String = "res://scripts/world/world_boss.gd" if entity.type=="boss" else "res://scripts/enemy_"+str(entity.id)+".gd"
            var enemy: EnemyBase = load(path).new()
            enemy.enemy_id=str(entity.id)
            enemy.position = Vector2(float(entity.position[0]),float(entity.position[1]))
            enemy.safe_min_x = 320
            enemy.safe_max_x = camera_limits.end.x-320
            enemy.room_bounds = camera_limits
            enemy.no_drop = entity.type=="boss"
            gameplay.add_child(enemy)
            world.scale_enemy(enemy,entity,region_data)
            enemy.died.connect(world.enemy_died.bind(entity))
            enemy.tree_exiting.connect(_forget_enemy.bind(enemy))
            enemies.append(enemy)
        else:
            if world.collected.has(str(entity.get("id",""))):continue
            var actor: Node2D = load("res://scripts/world/world_object.gd").new()
            actor.spec = entity
            actor.position = Vector2(float(entity.position[0]),float(entity.position[1]))
            gameplay.add_child(actor)
    for gate: Dictionary in room_data.gates:
        var actor: Node2D = load("res://scripts/world/world_object.gd").new()
        actor.spec = gate.duplicate(true)
        actor.spec["type"] = "gate"
        actor.position = Vector2(float(gate.position[0]),float(gate.position[1]))
        gameplay.add_child(actor)
    for exit: Dictionary in room_data.exits:
        if exit.side=="portal":
            var actor: Node2D = load("res://scripts/world/world_object.gd").new()
            actor.spec = exit.duplicate(true)
            actor.spec["type"]="portal"
            actor.position=Vector2(float(exit.position[0]),float(exit.position[1]))
            gameplay.add_child(actor)

func deactivate() -> void:
    visible=false
    loaded_current=false
    remove_from_group("current_level")
    process_mode=PROCESS_MODE_DISABLED
    set_collision_enabled(false)
    enemies.clear()
    if is_instance_valid(gameplay):
        remove_child(gameplay)
        gameplay.queue_free()

func refresh_story() -> void:pass
func reconcile_presence() -> void:pass
func ground_y_at(_x: float) -> float:return floor_y
func is_point_safe(point: Vector2) -> bool:
    return point.distance_to(get_spawn(entry_name).position)<320 or super.is_point_safe(point)

func _forget_enemy(enemy: EnemyBase) -> void:
    enemies.erase(enemy)
