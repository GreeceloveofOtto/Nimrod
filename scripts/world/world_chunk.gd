extends Node2D
var data: Dictionary = {}
var bodies: Array[StaticBody2D] = []
var entities: Node2D
var collision_count:=0
var built:=false
var phase:=0
var row_cursor:=0
var decor_cursor:=0
var entity_cursor:=0
var origin:=Vector2i.ZERO
var terrain_layer: TileMapLayer
var used: Dictionary = {}


func build_step() -> bool:
    var world: Node=get_node("/root/World")
    if phase==0:
        initialize()
        phase=1
        return false
    if phase==1:
        build_rows()
        row_cursor+=4
        if row_cursor>=data.rows.size():phase=2
        return false
    if phase==2:
        if decor_cursor<data.get("landmarks",[]).size():
            add_landmark(data.landmarks[decor_cursor])
            decor_cursor+=1
            return false
        entities=Node2D.new()
        add_child(entities)
        phase=3
    if phase==3:
        if entity_cursor<data.get("entities",[]).size():
            world.spawn_entity(data.entities[entity_cursor],entities)
            entity_cursor+=1
            return false
        built=true
    return built

func initialize() -> void:
    var world: Node = get_node("/root/World")
    var coords:=Vector2i(int(data.coord[0]),int(data.coord[1]))
    origin=coords*Vector2i(int(world.settings.chunk_size[0]),int(world.settings.chunk_size[1]))
    terrain_layer=TileMapLayer.new()
    terrain_layer.z_index=-3
    terrain_layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    var region: Dictionary = world.region_at(Vector2(origin)+Vector2(32,18))
    terrain_layer.tile_set=world.terrain_set(str(region.id))
    add_child(terrain_layer)

func build_rows() -> void:
    var world: Node=get_node("/root/World")
    var rows: Array = data.rows
    for y in range(row_cursor,mini(row_cursor+4,rows.size())):
        var line: String = str(rows[y])
        for x in range(line.length()):
            var c: String = line[x]
            if c not in ["#","W","="]:continue
            var global_tile:=Vector2i(x,y)+origin
            var mask:=0
            if world.tile_at(global_tile+Vector2i.UP) in ["#","W","="]:mask|=1
            if world.tile_at(global_tile+Vector2i.RIGHT) in ["#","W","="]:mask|=2
            if world.tile_at(global_tile+Vector2i.DOWN) in ["#","W","="]:mask|=4
            if world.tile_at(global_tile+Vector2i.LEFT) in ["#","W","="]:mask|=8
            # Six painted materials; four edge treatments, selected by actual adjacency.
            var material: int = [0,1,3][posmod(global_tile.x/8+global_tile.y/8,3)] if c=="=" else posmod(global_tile.x/12+global_tile.y/8,6)
            var edge: int = 0 if (mask&1)==0 else 1 if (mask&2)==0 else 2 if (mask&4)==0 else 3
            terrain_layer.set_cell(Vector2i(x,y),0,Vector2i(material,edge))
            if used.has(Vector2i(x,y)):continue
            var width:=1
            while x+width<line.length() and line[x+width]==c and not used.has(Vector2i(x+width,y)):width+=1
            var height:=1
            if c!="=":
                while y+height<rows.size():
                    var matches:=true
                    for xx in range(x,x+width):
                        if str(rows[y+height])[xx]!=c or used.has(Vector2i(xx,y+height)):matches=false
                    if not matches:break
                    height+=1
            for yy in range(y,y+height):
                for xx in range(x,x+width):used[Vector2i(xx,yy)]=true
            add_surface(Rect2(Vector2(x,y)*32,Vector2(width*32,8 if c=="=" else height*32)),c)

func add_landmark(piece: Dictionary) -> void:
    var world: Node=get_node("/root/World")
    var catalogue: Dictionary = world.art.get(str(piece.region),{})
    if not catalogue.has("landmarks"):return
    var spec: Dictionary = catalogue.landmarks[int(piece.piece)]
    var sprite:=Sprite2D.new()
    sprite.texture=load(str(catalogue.atlas))
    sprite.region_enabled=true
    sprite.region_filter_clip_enabled=true
    sprite.region_rect=Rect2(float(spec.rect[0]),float(spec.rect[1]),float(spec.rect[2]),float(spec.rect[3]))
    sprite.centered=false
    sprite.scale=Vector2.ONE*float(spec.game_scale)
    sprite.position=Vector2(float(piece.position[0]),float(piece.position[1]))-position-Vector2(float(spec.anchor[0]),float(spec.anchor[1]))*float(spec.game_scale)
    sprite.z_index=-7
    add_child(sprite)
    if int(piece.piece) in [1,6]:
        var light: Node2D=AssetVisual.add_image(self,"res://assets/fx/npc_light_pool.webp",Vector2(float(piece.position[0]),float(piece.position[1]))-position-Vector2(150,45),Vector2(300,70),-6)
        light.modulate=Color(str(world.regions[str(piece.region)].palette)).lightened(.35)
        light.modulate.a=.4

func add_surface(rect: Rect2,kind: String) -> void:
    var body:=StaticBody2D.new()
    body.collision_layer=2 if kind=="=" else 1
    body.set_meta("one_way",kind=="=")
    body.set_meta("wall_climbable",kind=="W")
    body.set_meta("surface_rect",Rect2(rect.position+position,rect.size))
    body.add_to_group("surfaces")
    body.position=rect.get_center()
    var hit:=CollisionShape2D.new()
    var shape:=RectangleShape2D.new()
    shape.size=rect.size
    hit.shape=shape
    hit.one_way_collision=kind=="="
    hit.one_way_collision_margin=6
    body.add_child(hit)
    add_child(body)
    bodies.append(body)
    collision_count+=1
