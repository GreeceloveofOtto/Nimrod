extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
    for entry in registry["levels"]:
        var spawn: String = str(entry["spawns"].keys()[0])
        await manager.go_to(str(entry["id"]), spawn, {"instant": true})
        for body: StaticBody2D in get_nodes_in_group("surfaces"):
            if not body.has_meta("image_top"):
                continue
            var surface: Rect2 = body.get_meta("surface_rect")
            if bool(body.get_meta("ceiling_surface", false)):
                _check(absf(surface.end.y - float(body.get_meta("image_bottom"))) <= 4, "Ceiling collision matches painted underside")
            else:
                _check(absf(surface.position.y - float(body.get_meta("image_top"))) <= 4, "Surface collision matches painted upper edge: " + str(entry["id"]))
            if body.has_node("SurfaceAccent"):
                var accent: SurfaceAccent = body.get_node("SurfaceAccent")
                _check(absf(accent.global_position.y - surface.position.y) <= 4 and absf(accent.dimensions.x - surface.size.x) <= 4, "Accent follows the adjusted collision width and top")
    await _finish("STAGE7_SURFACE_ALIGNMENT")
