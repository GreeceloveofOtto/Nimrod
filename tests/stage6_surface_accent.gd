extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    await manager.go_to("CastleOutskirts","Spawn_Debug")
    var accents: Array[Node] = get_nodes_in_group("surface_accents")
    var solid: int=0
    var one_way: int=0
    var ground: int=0
    for accent: SurfaceAccent in accents:
        _check(accent.get_parent() is StaticBody2D,"Accent attaches only to collision surface")
        _check(accent.z_index==-2,"Accent above terrain and below actors")
        if accent.one_way:one_way+=1
        else:solid+=1
        if accent.ground_floor:ground+=1
    _check(solid>0 and one_way>0 and ground>0,"Solid floors, one-way ledges and ground present")
    Input.action_press("surface_accents")
    accents[0]._process(0)
    Input.action_release("surface_accents")
    _check(not SurfaceAccent.globally_enabled and not accents[0].visible,"F3 hides visibility aid")
    SurfaceAccent.globally_enabled=true
    for sample in [["DowntownPassage_F1", "Spawn_FromAbove"], ["DowntownPassage_F7", "Spawn_FromAbove"], ["CedarBossRoom", "Spawn_FromForest"], ["HomeRoad", "Spawn_FromPassage"]]:
        await manager.go_to(sample[0], sample[1])
        var level: LevelBase = manager.current_level
        for platform in level.config.get("platforms", []):
            var at := Vector2(platform["position"][0], platform["position"][1])
            var matched: bool = false
            for body: Node in get_nodes_in_group("surfaces"):
                if not body.has_meta("image_rect"): continue
                var image_rect: Rect2 = body.get_meta("image_rect")
                if image_rect.position.is_equal_approx(at) and is_equal_approx(image_rect.size.x, platform["width"]):
                    var accent: SurfaceAccent = body.get_node_or_null("SurfaceAccent")
                    var visible_height: float = float(body.get_meta("image_bottom")) - float(body.get_meta("image_top"))
                    matched = accent != null and absf(accent.global_position.y - float(body.get_meta("image_top"))) <= 4 and absf(accent.dimensions.y - visible_height) <= 4
                    break
            _check(matched, "%s/%s underside aid follows the measured opaque image bounds" % [sample[0], platform["id"]])
        for ceiling in level.config.get("ceilings", []):
            var rect: Array = ceiling["rect"]
            var found: bool = false
            for body: Node in get_nodes_in_group("surfaces"):
                if not body.has_meta("image_rect"): continue
                var image_rect: Rect2 = body.get_meta("image_rect")
                if image_rect.position.is_equal_approx(Vector2(rect[0],rect[1])):
                    var accent: SurfaceAccent = body.get_node_or_null("SurfaceAccent")
                    found = accent != null and accent.ceiling_surface and absf(accent.global_position.y - float(body.get_meta("image_top"))) <= 4
            _check(found, "Tunnel ceiling accent follows its measured bounds")
        for body in level.get_children():
            if body is StaticBody2D and body.position.x < 0 and body.position.y < level.floor_y:
                _check(not body.has_node("SurfaceAccent"), "Invisible boundary has no unsupported highlight")
    await _finish("STAGE6_SURFACE_ACCENT")
