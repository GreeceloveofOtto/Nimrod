extends SceneTree
func _initialize() -> void:
    _run.call_deferred()
func _run() -> void:
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1280,720)
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var sprite:=Sprite2D.new()
    sprite.centered=false
    sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    viewport.add_child(sprite)
    var directory: String="res://archive/stage15_map/background_parity"
    DirAccess.make_dir_recursive_absolute(directory)
    for index in [0,2]:
        for version in ["before","after"]:
            var path: String="res://archive/stage15_map/art/before/landing_background_%d.webp" % index if version=="before" else "res://assets/world/zabulistan_v2/landing/background_%d.webp" % index
            var source: Image=Image.load_from_file(ProjectSettings.globalize_path(path))
            print("PARITY_SOURCE: ",index," ",version," ",source.get_size()," ",FileAccess.get_sha256(path))
            sprite.texture=ImageTexture.create_from_image(source)
            sprite.scale=Vector2(4096,1024)/Vector2(source.get_size())
            sprite.modulate=Color(.55,.59,.68,.85 if index==0 else .28)
            for i in range(3):
                sprite.position=-[Vector2.ZERO,Vector2(1024,128),Vector2(2400,256)][i]
                await process_frame
                await RenderingServer.frame_post_draw
                viewport.get_texture().get_image().save_png(directory+"/layer%d_%d_%s.png" % [index,i,version])
    viewport.queue_free()
    await process_frame
    print("BACKGROUND_PARITY_GL: 12 images captured")
    quit()
