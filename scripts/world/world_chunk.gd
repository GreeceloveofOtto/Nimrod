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
var used:=PackedByteArray()
var carved:=false
var fill_layer: TileMapLayer
var transition_layer: TileMapLayer
var backwall_layer: TileMapLayer
var backwall_big_layer: TileMapLayer
var support_layer: TileMapLayer
var ornament_layer: TileMapLayer
var extras: Array = []
var extra_cursor:=0
var palette:=Color.WHITE
var fake_layer: TileMapLayer
var fake_tiles: Array[Vector2i] = []
var fake_open_cached:=false
var hazards: Array[Area2D] = []
var hazard_cooldown:=0.


func build_step() -> bool:
    var world: Node=get_node("/root/World")
    if phase==0:
        initialize()
        phase=1
        return false
    if phase==1:
        build_rows()
        row_cursor+=4
        if row_cursor>=data.rows.size():
            used=PackedByteArray()
            data.erase("rows")
            phase=2
        return false
    if phase==2:
        if decor_cursor<data.get("landmarks",[]).size():
            add_landmark(data.landmarks[decor_cursor])
            decor_cursor+=1
            return false
        phase=4
        return false
    if phase==4:
        if extra_cursor<extras.size():
            add_extra(extras[extra_cursor])
            extra_cursor+=1
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
        data={"id":data.id,"coord":data.coord}
        extras=[]
    return built

func initialize() -> void:
    var world: Node = get_node("/root/World")
    var coords:=Vector2i(int(data.coord[0]),int(data.coord[1]))
    origin=coords*Vector2i(int(world.settings.chunk_size[0]),int(world.settings.chunk_size[1]))
    used.resize(64*36)
    terrain_layer=TileMapLayer.new()
    terrain_layer.z_index=-3
    terrain_layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    var region: Dictionary = world.region_at(Vector2(origin)+Vector2(32,18))
    carved=str(region.id) in world.settings.get("carved_regions",[])
    palette=Color(str(region.palette))
    if carved:
        terrain_layer.tile_set=world.carved_set("crust")
        terrain_layer.modulate=tint(float(world.carved_art.crust_light))
        fill_layer=make_layer("fill",-4,tint(float(world.carved_art.fill_light)))
        transition_layer=make_layer("crust",-4,tint(float(world.carved_art.transition_light)))
        backwall_layer=make_layer("backwall",-8,tint(float(world.carved_art.backwall_light)))
        backwall_big_layer=make_layer("backwall",-8,tint(float(world.carved_art.backwall_light)))
        backwall_big_layer.scale=Vector2.ONE*2.
        support_layer=make_layer("supports",-2,Color(.65,.53,.39))
        ornament_layer=make_layer("supports",-2,Color(.75,.82,.91))
        fake_layer=make_layer("crust",1,tint(float(world.carved_art.crust_light)))
        support_layer.scale=Vector2.ONE*.5
        ornament_layer.scale=Vector2.ONE*.5
        for item: Array in data.get("decor",[]):extras.append({"kind":"support","value":item})
        for item: Array in world.settings.get("terrain_lights",[]):
            if owns_tile(Vector2i(int(item[0]),int(item[1]))):extras.append({"kind":"light","value":item})
        for item: Array in world.settings.get("foreground",[]):
            if owns_tile(Vector2i(int(item[1]),int(item[2]))):extras.append({"kind":"foreground","value":item})
    else:terrain_layer.tile_set=world.terrain_set(str(region.id))
    add_child(terrain_layer)

func build_rows() -> void:
    var world: Node=get_node("/root/World")
    var rows: Array = data.rows
    for y in range(row_cursor,mini(row_cursor+4,rows.size())):
        var line: String = str(rows[y])
        for x in range(line.length()):
            var c: String = line[x]
            if carved:paint_carved(Vector2i(x,y),c)
            if c not in ["#","W","=","^"]:continue
            if not carved:
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
            if used[y*64+x]!=0:continue
            var width:=1
            while x+width<line.length() and line[x+width]==c and used[y*64+x+width]==0:width+=1
            var height:=1
            if c!="=":
                while y+height<rows.size():
                    var matches:=true
                    for xx in range(x,x+width):
                        if str(rows[y+height])[xx]!=c or used[(y+height)*64+xx]!=0:matches=false
                    if not matches:break
                    height+=1
            for yy in range(y,y+height):
                for xx in range(x,x+width):used[yy*64+xx]=1
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
    if carved:sprite.modulate=Color(.58,.59,.61,.8)
    add_child(sprite)
    if not carved and int(piece.piece) in [1,6]:
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
    var shape: RectangleShape2D=get_node("/root/World").surface_shape(rect.size)
    hit.shape=shape
    hit.one_way_collision=kind=="="
    hit.one_way_collision_margin=6
    body.add_child(hit)
    add_child(body)
    bodies.append(body)
    collision_count+=1
    if kind=="^":add_spike_contact(rect)

func tint(strength: float) -> Color:
    return Color(palette.r*strength,palette.g*strength,palette.b*strength,1.)

func make_layer(kind: String,depth: int,color: Color) -> TileMapLayer:
    var layer:=TileMapLayer.new()
    layer.name="Terrain_"+kind+"_"+str(depth)
    layer.tile_set=get_node("/root/World").carved_set(kind)
    layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    layer.z_index=depth
    layer.modulate=color
    add_child(layer)
    return layer

func owns_tile(at: Vector2i) -> bool:
    return Rect2i(origin,Vector2i(64,36)).has_point(at)

func solid_mask(at: Vector2i) -> int:
    var world: Node=get_node("/root/World")
    var mask:=0
    for index in range(4):
        if world.solid_at(at+[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT][index]):mask|=1<<index
    return mask

func paint_carved(at: Vector2i,glyph: String) -> void:
    var world: Node=get_node("/root/World")
    var cell:=at+origin
    if glyph=="F":
        if not fake_tiles.has(at):fake_tiles.append(at)
        if world.tile_at(cell)==".":glyph="."
    var variant: int=posmod(cell.x*7+cell.y*13,3)
    if glyph==".":
        var block:=Vector2i(at.x&~1,at.y&~1)
        var global_block:=block+origin
        var large: bool=true
        for offset: Vector2i in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.ONE]:
            if world.tile_at(global_block+offset)!=".":large=false;break
        if large:
            if at!=block:return
            var mask:=0
            if world.solid_at(global_block+Vector2i.UP) or world.solid_at(global_block+Vector2i(1,-1)):mask|=1
            if world.solid_at(global_block+Vector2i(2,0)) or world.solid_at(global_block+Vector2i(2,1)):mask|=2
            if world.solid_at(global_block+Vector2i(0,2)) or world.solid_at(global_block+Vector2i(1,2)):mask|=4
            if world.solid_at(global_block+Vector2i.LEFT) or world.solid_at(global_block+Vector2i(-1,1)):mask|=8
            backwall_big_layer.set_cell(Vector2i(at.x>>1,at.y>>1),0,Vector2i(mask,variant))
        else:
            backwall_layer.set_cell(at,0,Vector2i(solid_mask(cell),variant))
    elif glyph=="=":
        support_layer.set_cell(at,0,Vector2i(3,0))
    elif glyph in ["#","W","^","F"]:
        var mask:=solid_mask(cell)
        if glyph=="F":fake_layer.set_cell(at,0,Vector2i(mask,variant))
        elif mask!=15:
            terrain_layer.set_cell(at,0,Vector2i(mask,variant))
            if not world.solid_at(cell+Vector2i.UP):ornament_layer.set_cell(at+Vector2i.UP,0,Vector2i(0,1))
            if not world.solid_at(cell+Vector2i.DOWN) and posmod(cell.x*7+cell.y*13,4)==0:ornament_layer.set_cell(at+Vector2i.DOWN,0,Vector2i(1,1))
        else:
            var inner: int=-1
            var diagonals: Array[Vector2i]=[Vector2i(-1,-1),Vector2i(1,-1),Vector2i(1,1),Vector2i(-1,1)]
            for index in range(4):
                if not world.solid_at(cell+diagonals[index]):inner=16+index;break
            if inner>=16:
                terrain_layer.set_cell(at,0,Vector2i(inner,variant))
                return
            var near_empty:=false
            for offset: Vector2i in [Vector2i(0,-2),Vector2i(1,-1),Vector2i(2,0),Vector2i(1,1),Vector2i(0,2),Vector2i(-1,1),Vector2i(-2,0),Vector2i(-1,-1)]:
                if not world.solid_at(cell+offset):near_empty=true;break
            if near_empty:transition_layer.set_cell(at,0,Vector2i(mask,variant))
            else:fill_layer.set_cell(at,0,Vector2i(posmod(cell.x,2),posmod(cell.y,2)))

func add_extra(extra: Dictionary) -> void:
    var row: Array=extra.value
    if extra.kind=="support":
        var at:=Vector2i(int(row[1]),int(row[2]))-origin
        var direction: int=int(row[3])
        var flip: int=TileSetAtlasSource.TRANSFORM_FLIP_H if direction==1 else 0
        if int(row[0])==0:support_layer.set_cell(at+Vector2i(-1 if direction==-1 else 1,0),0,Vector2i(0,0),flip)
        else:
            for y in range(int(row[4])):support_layer.set_cell(at+Vector2i(direction,-y),0,Vector2i(1,0))
    elif extra.kind=="light":
        var at:=Vector2i(int(row[0]),int(row[1]))-origin
        support_layer.set_cell(at,0,Vector2i(3,1))
        var world: Node=get_node("/root/World")
        for gap in range(1,17):
            if world.solid_at(at+origin+Vector2i(0,-gap)):break
            support_layer.set_cell(at+Vector2i(0,-gap),0,Vector2i(1,0))
        var light: Node2D=AssetVisual.add_image(self,"res://assets/fx/npc_light_pool.webp",Vector2(at)*32-Vector2(64,20),Vector2(160,160),-6)
        light.modulate=Color(1.,.74,.42,.3)
        light.material=world.light_material
    elif extra.kind=="foreground":
        var at:=Vector2i(int(row[1]),int(row[2]))-origin
        var world: Node=get_node("/root/World")
        var silhouette: Node2D=AssetVisual.add_image(self,str(world.carved_art.foreground),Vector2(at)*32-Vector2(17,168),Vector2(34,168),5)
        silhouette.modulate=Color(.025,.03,.045,.85)

func add_spike_contact(rect: Rect2) -> void:
    var area:=Area2D.new()
    area.collision_layer=0
    area.collision_mask=1
    area.position=rect.get_center()
    var collision:=CollisionShape2D.new()
    var shape:=RectangleShape2D.new()
    shape.size=rect.size+Vector2(12,12)
    collision.shape=shape
    area.add_child(collision)
    add_child(area)
    hazards.append(area)
    var world: Node=get_node("/root/World")
    var below:=Vector2i((rect.position+Vector2(0,rect.size.y))/32)+origin
    var ceiling: bool=not world.solid_at(below)
    var at:=rect.position+Vector2(0,rect.size.y-12) if ceiling else rect.position-Vector2(0,20)
    var visual: Node2D=AssetVisual.add_image(self,"res://assets/world/shared/spikes.webp",at,Vector2(rect.size.x,32),-1)
    visual.get_node("Image").flip_v=ceiling

func _physics_process(delta: float) -> void:
    if hazards.is_empty():return
    hazard_cooldown=maxf(0,hazard_cooldown-delta)
    var world: Node=get_node("/root/World")
    if not world.active or world.transitioning or hazard_cooldown>0:return
    var hero: NimrodPlayer=get_node("/root/SceneManager").player
    if not is_instance_valid(hero) or hero.transition_locked or hero.hp<=0:return
    for area: Area2D in hazards:
        if area.get_overlapping_bodies().has(hero):
            hero.receive_damage(int(world.settings.terrain_spikes.damage),{"source":"world_spikes"})
            hazard_cooldown=float(world.settings.terrain_spikes.interval)
            return

func _process(_delta: float) -> void:
    if fake_tiles.is_empty():return
    var world: Node=get_node("/root/World")
    var opened: bool=world.tile_at(fake_tiles[0]+origin)=="."
    if opened==fake_open_cached:return
    fake_open_cached=opened
    var dirty: Dictionary={}
    for tile: Vector2i in fake_tiles:
        for y in range(-2,3):
            for x in range(-2,3):
                var at:=tile+Vector2i(x,y)
                if not owns_tile(at+origin):continue
                var block:=Vector2i(at.x&~1,at.y&~1)
                for offset: Vector2i in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.ONE]:dirty[block+offset]=true
    for at: Vector2i in dirty:
        for layer: TileMapLayer in [terrain_layer,fill_layer,transition_layer,backwall_layer,fake_layer]:layer.erase_cell(at)
        backwall_big_layer.erase_cell(Vector2i(at.x>>1,at.y>>1))
    for at: Vector2i in dirty:paint_carved(at,world.tile_at(at+origin))
