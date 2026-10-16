extends "res://tests/helpers/stage9_support.gd"

func _run() -> void:
    await _start9()
    story_state.debug_stage(21)
    root.get_node("GameState").switch_character("siyavash")
    await _go("HwaniraPlaza")
    var world: Node=root.get_node("World")
    world.invulnerable=true
    await world.enter()
    _check(world.decode_row("2#3:1F2^")=="##:::F^^","String RLE includes all new glyphs")
    _check(world.decode_row([["#",2],[".",3]])=="##...","Legacy RLE remains readable")
    _check(world.settings.navigation.size()==360 and str(world.settings.navigation[0]).length()==640,"Chunk RLE restores the complete navigation grid")
    _check(world.tile_at(Vector2i(8,8))==":" and not world.solid_at(Vector2i(8,8)),"Exterior cells are physically empty")
    _check(world.solid_at(Vector2i(12,133)),"Ceiling spikes are solid")
    _check(not world.saving_allowed(),"Terrain changes preserve the world save ban")
    _check(world.deaths_total==0 and world.deaths_zabulistan==0,"Entering terrain does not change death counts")
    hero.position=Vector2(74,136)*32
    world.schedule_stream(hero.position)
    while not world.streaming_idle():await process_frame
    var gate_actor: Node
    var fake_chunk: Node
    for chunk: Node in world.loaded.values():
        if not chunk.fake_tiles.is_empty():fake_chunk=chunk
        if chunk.entities!=null:
            for child: Node in chunk.entities.get_children():
                if child.get("spec")!=null and str(child.spec.get("uid",""))=="gate_landing_vision":gate_actor=child
    _check(is_instance_valid(gate_actor) and is_instance_valid(fake_chunk),"Fake-wall picture and existing gate share one loaded location")
    _check(world.tile_at(Vector2i(73,133))=="F" and gate_actor.gate.collision_layer==1,"Closed fake wall blocks sight and uses the existing gate collision")
    world.abilities["vision"]=true
    world.hero_motion.vision=true
    for i in range(4):await process_frame
    _check(world.switches.has("gate_landing_vision"),"Vision uses the existing persistent gate flag")
    _check(world.tile_at(Vector2i(73,133))=="." and gate_actor.gate.collision_layer==0,"Revealed wall becomes passable")
    _check(fake_chunk.fake_layer.get_used_cells().is_empty(),"Stone picture disappears with the revealed gate")
    world.hero_motion.vision=false
    world.abilities.clear()
    world.switches.erase("gate_landing_vision")
    for i in range(3):await process_frame
    _check(world.tile_at(Vector2i(73,133))=="F","Restoring a closed flag restores the wall picture")
    hero.position=Vector2(12.5,137)*32
    world.schedule_stream(hero.position)
    while not world.streaming_idle():await process_frame
    hero.action="normal"
    hero.damage_grace=0
    hero.hp=100
    world.invulnerable=false
    for loaded_chunk: Node in world.loaded.values():loaded_chunk.hazard_cooldown=0
    for i in range(4):await physics_frame
    _check(hero.hp==88,"Merged ceiling spike contact deals the existing 12 damage once")
    world.invulnerable=true
    var visible_missing: Array=[]
    for node: Node in root.find_children("MISSING_TEXTURE","",true,false):
        if node is CanvasItem and node.is_visible_in_tree():visible_missing.append(node.get_path())
    print("VISIBLE_MISSING: ",visible_missing)
    _check(visible_missing.is_empty(),"Generated terrain and reused props have no missing textures")
    for key: String in ["crust","fill","backwall","supports","foreground"]:
        _check(load(str(world.carved_art[key])) is Texture2D,"Generated image loads: "+key)
    await _go("HwaniraPlaza")
    _finish("stage15_carved_terrain")
