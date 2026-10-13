extends "res://tests/helpers/stage4_support.gd"
func _run() -> void:
    var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprite_trims.json"))
    var gpu: bool = DisplayServer.get_name() != "headless"
    var renders: int=0
    for path: String in registry:
        if not any_new(path):
            continue
        var c: Dictionary=registry[path]
        if not ResourceLoader.exists(path):
            _check(false,"Missing registered atlas "+path)
            continue
        var texture: Texture2D=load(path)
        var source: Image=texture.get_image()
        _check(source.get_size()==Vector2i(int(c["image_size"][0]),int(c["image_size"][1])),"Imported texture matches current atlas dimensions " + path)
        var cell: Vector2i=Vector2i(int(c["storage_trim"]["w"]),int(c["storage_trim"]["h"]))
        _check(int(c.get("stored_padding",0))>=2,"Stored gutter "+path)
        for index in range(int(c.get("stored_columns",c["frames"]))):
            var isolated: Image=source.get_region(Rect2i(Vector2i(index*cell.x,0),cell))
            var clear: bool=true
            for x in range(cell.x):
                clear=clear and isolated.get_pixel(x,0).a==0 and isolated.get_pixel(x,1).a==0 and isolated.get_pixel(x,cell.y-1).a==0 and isolated.get_pixel(x,cell.y-2).a==0
            for y in range(cell.y):
                clear=clear and isolated.get_pixel(0,y).a==0 and isolated.get_pixel(1,y).a==0 and isolated.get_pixel(cell.x-1,y).a==0 and isolated.get_pixel(cell.x-2,y).a==0
            _check(clear,"Four transparent borders "+path+"/"+str(index))
            if not gpu:
                continue
            for zoom in [1,2]:
                var half: Vector2i=cell*zoom+Vector2i(16,16)
                var viewport:=SubViewport.new()
                viewport.size=Vector2i(half.x*2,half.y)
                viewport.transparent_bg=true
                viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
                root.add_child(viewport)
                var atlas:=Sprite2D.new()
                AssetVisual.configure_sprite(atlas)
                atlas.texture=texture
                atlas.centered=false
                atlas.region_enabled=true
                atlas.region_rect=Rect2(index*cell.x,0,cell.x,cell.y)
                atlas.scale=Vector2.ONE*zoom
                atlas.position=Vector2(8,8)
                viewport.add_child(atlas)
                var reference:=Sprite2D.new()
                AssetVisual.configure_sprite(reference)
                reference.texture=ImageTexture.create_from_image(isolated)
                reference.centered=false
                reference.position=Vector2(half.x+8,8)
                reference.scale=Vector2.ONE*zoom
                viewport.add_child(reference)
                await RenderingServer.frame_post_draw
                var painted: Image=viewport.get_texture().get_image()
                var left: Image=painted.get_region(Rect2i(Vector2i.ZERO,half))
                var right: Image=painted.get_region(Rect2i(Vector2i(half.x,0),half))
                _check(left.get_data()==right.get_data(),"GL linear atlas/isolated difference zero "+path+"/"+str(index)+" x"+str(zoom))
                renders+=1
                viewport.queue_free()
    print("STAGE13_FRAME_BLEED: ",checks," checks, ",failures," failures; GL comparisons=",renders,"; renderer=",DisplayServer.get_name())
    if not gpu:
        print("Native pixel rendering requires the separate GL run; headless validates atlas borders only.")
    root.get_node("Audio").release_streams()
    quit(1 if failures else 0)

func any_new(path: String) -> bool:
    return "/siyavash/" in path or "/ninazu_mother/" in path or "/lilith/" in path or "/zu/" in path
