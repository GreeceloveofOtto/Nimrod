class_name LevelBase
extends Node2D

const LEVELS_PATH: String = "res://data/levels.json"
const Art = preload("res://scripts/asset_visual.gd")

@export var level_id: String = "RearGate"
@export var bgm_name: String = ""
@export var camera_limits: Rect2
@export var display_name: String = ""
@export var safe_zones: Array[Rect2] = []
@export var floor_y: float = 0.0
@export var bg_dim: Color = Color(0.80, 0.80, 0.84)

var config: Dictionary = {}
var world_settings: Dictionary = {}
var arrival_doors: Dictionary = {}
var doors: Dictionary = {}
var npcs: Dictionary = {}
var surface_offsets: Dictionary = {}
var time_modulate: CanvasModulate
var story_props: Array[Node2D] = []

func _ready() -> void:
    add_to_group("current_level")
    _load_config()
    surface_offsets = JSON.parse_string(FileAccess.get_file_as_string("res://data/surface_offsets.json"))
    _make_spawns()
    _make_backgrounds()
    _make_world()
    _make_props()
    _make_doors()
    _make_npcs()
    _connect_gatekeeper()
    _spawn_enemies()
    _make_pickups()
    if config.get("dinner_seat", false):
        add_child(load("res://scripts/dinner_seat.gd").new())
    get_node("/root/Story").changed.connect(refresh_story)
    refresh_story()

func _load_config() -> void:
    var file := FileAccess.open(LEVELS_PATH, FileAccess.READ)
    if file == null:
        push_error("Missing level registry: " + LEVELS_PATH)
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        push_error("Invalid level registry: " + LEVELS_PATH)
        return
    var registry: Dictionary = parsed
    world_settings = registry.get("world", {})
    for candidate in registry.get("levels", []):
        if str(candidate.get("id", "")) == level_id:
            config = candidate
            break
    if config.is_empty():
        push_error("Unregistered level: " + level_id)
        return
    bgm_name = str(config.get("bgm", bgm_name))
    display_name = str(config.get("display_name", display_name))
    floor_y = float(config.get("floor_y", floor_y))
    var dim: Array = config.get("bg_dim", [0.80, 0.80, 0.84])
    bg_dim = Color(float(dim[0]), float(dim[1]), float(dim[2]))
    camera_limits = _rect(config.get("camera_limits", []))
    safe_zones.clear()
    for bounds in config.get("safe_zones", []):
        safe_zones.append(_rect(bounds))

func _vector(value: Array) -> Vector2:
    return Vector2(float(value[0]), float(value[1])) if value.size() >= 2 else Vector2.ZERO

func _rect(value: Array) -> Rect2:
    if value.size() < 4:
        return Rect2()
    return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))

func _make_spawns() -> void:
    var points: Dictionary = config.get("spawns", {})
    for spawn_name in points:
        var marker := Marker2D.new()
        marker.name = str(spawn_name)
        marker.position = _vector(points[spawn_name])
        add_child(marker)

    for entry in config.get("perches", []):
        var perch := Marker2D.new()
        perch.name = str(entry["name"])
        perch.position = _vector(entry["position"])
        perch.set_meta("perch_kind", str(entry.get("kind", "ceiling")))
        add_child(perch)

func get_spawn(spawn_name: String) -> Marker2D:
    return get_node_or_null(NodePath(spawn_name)) as Marker2D

func find_arrival_door(spawn_name: String) -> Node:
    return arrival_doors.get(spawn_name) as Node

func _make_backgrounds() -> void:
    for entry in config.get("backgrounds", []):
        var ratio: float = float(entry.get("ratio", 1.0))
        var at: Vector2 = _vector(entry.get("position", []))
        var size_px: Vector2 = _vector(entry.get("size", []))
        if is_equal_approx(ratio, 1.0):
            var image := Art.add_image(self, str(entry["path"]), at, size_px, int(entry.get("z", 0)))
            image.name = str(entry.get("name", "Background"))
            image.modulate = bg_dim
        else:
            var layer := Parallax2D.new()
            layer.name = str(entry.get("name", "Parallax"))
            layer.scroll_scale = Vector2(ratio, float(entry.get("ratio_y", 0.0)))
            layer.z_index = int(entry.get("z", 0))
            layer.modulate = bg_dim
            if entry.has("repeat_size"):
                layer.repeat_size = _vector(entry["repeat_size"])
                layer.repeat_times = int(entry.get("repeat_times", 4))
            add_child(layer)
            Art.add_image(layer, str(entry["path"]), at, size_px)

func _make_world() -> void:
    var width: float = float(config.get("width", 0.0))
    var margin: float = float(world_settings.get("outside_margin", 0.0))
    var wall: float = float(world_settings.get("wall_thickness", 0.0))
    var ground_height: float = float(world_settings.get("ground_collision_height", 0.0))
    if config.has("terrain"):
        for segment in config["terrain"]:
            var ground_y: float = float(segment["y"])
            _make_surface(float(segment["from"]), ground_y, float(segment["to"]) - float(segment["from"]), maxf(ground_height, camera_limits.end.y - ground_y + ground_height), false, float(config.get("floor_art_size", [512, 200])[1]), str(segment.get("art", config.get("floor_art", ""))))
            _cover_ground(float(segment["from"]), float(segment["to"]), ground_y, str(segment.get("art", config.get("floor_art", ""))), _vector(config.get("floor_art_size", [512, 200])))
    else:
        _make_surface(-margin, floor_y, width + margin * 2.0, ground_height, false, float(config.get("floor_art_size", [512, 200])[1]), str(config.get("floor_art", "")))
    _make_surface(-wall, -margin, wall, floor_y + ground_height + margin * 2.0, false, 0.0)
    _make_surface(width, -margin, wall, floor_y + ground_height + margin * 2.0, false, 0.0)
    if bool(config.get("ceiling", false)):
        _make_surface(-wall, float(config.get("ceiling_y", 0.0)) - wall, width + wall * 2.0, wall, false, 0.0)
    var tile_size: Vector2 = _vector(config.get("floor_art_size", []))
    if tile_size.x > 0.0 and not config.has("terrain"):
        var tile_x: float = -margin
        while tile_x < width + margin:
            Art.add_image(self, str(config.get("floor_art", "")), Vector2(tile_x, floor_y), tile_size, -4)
            tile_x += tile_size.x
        _fill_underground(-margin, width + margin, floor_y + tile_size.y)
    for section in config.get("floor_sections", []):
        var section_size: Vector2 = _vector(section["size"])
        var start: float = float(section["from"])
        while start < float(section["to"]):
            Art.add_image(self, str(section["path"]), Vector2(start, floor_y), Vector2(minf(section_size.x, float(section["to"]) - start), section_size.y), -3)
            start += section_size.x
    for step in config.get("steps", []):
        var height: float = float(step["height"])
        var x: float = float(step["x"])
        var step_width: float = float(step["width"])
        _make_surface(x, floor_y - height, step_width, height, false, height, str(world_settings["step_art"]))
        Art.add_image(self, str(world_settings["step_art"]), Vector2(x, floor_y - height), Vector2(step_width, height), -3)
    for platform in config.get("platforms", []):
        var at: Vector2 = _vector(platform["position"])
        var platform_width: float = float(platform["width"])
        var art_height: float = float(platform.get("art_height", world_settings["platform_art_height"]))
        _make_surface(at.x, at.y, platform_width, float(world_settings["platform_collision_height"]), true, art_height, str(platform.get("art", world_settings["platform_art"])))
        Art.add_image(self, str(platform.get("art", world_settings["platform_art"])), at, Vector2(platform_width, art_height), -3)
    for obstacle in config.get("obstacles", []):
        var bounds: Rect2 = _rect(obstacle["rect"])
        _make_surface(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y, false, bounds.size.y, str(obstacle["art"]))
        Art.add_image(self, str(obstacle["art"]), bounds.position, bounds.size, -3)
    for ceiling in config.get("ceilings", []):
        var bounds: Rect2 = _rect(ceiling["rect"])
        var body: StaticBody2D = _make_surface(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y, false, bounds.size.y, str(ceiling["art"]), true)
        body.get_node("SurfaceAccent").ceiling_surface = true
        var x: float = bounds.position.x
        while x < bounds.end.x:
            var size_px := Vector2(minf(512.0, bounds.end.x - x), bounds.size.y)
            Art.add_image(self, str(ceiling["art"]), Vector2(x, bounds.position.y), size_px, -3)
            x += size_px.x

func _cover_ground(from_x: float, to_x: float, ground_y: float, art: String, tile_size: Vector2) -> void:
    var x: float = from_x
    while x < to_x:
        Art.add_image(self, art, Vector2(x, ground_y), Vector2(minf(tile_size.x, to_x - x), tile_size.y), -4)
        x += tile_size.x
    _fill_underground(from_x, to_x, ground_y + tile_size.y)

func _fill_underground(from_x: float, to_x: float, top: float) -> void:
    var size_px: Vector2 = _vector(world_settings.get("underground_size", [512, 512]))
    var y: float = top
    while y < camera_limits.end.y:
        var x: float = from_x
        while x < to_x:
            Art.add_image(self, str(world_settings.get("underground_art", "")), Vector2(x, y), Vector2(minf(size_px.x, to_x - x), minf(size_px.y, camera_limits.end.y - y)), -5)
            x += size_px.x
        y += size_px.y

func ground_y_at(x: float) -> float:
    for segment in config.get("terrain", []):
        if x >= float(segment["from"]) and x <= float(segment["to"]):
            return float(segment["y"])
    return floor_y

func _make_surface(x: float, y: float, width: float, height: float, one_way: bool = true, art_height: float = -1.0, art_path: String = "", ceiling_surface: bool = false) -> StaticBody2D:
    var image_rect := Rect2(x, y, width, art_height if art_height > 0 else height)
    var edge: Dictionary = surface_offsets.get(art_path, {})
    var visible_top: float = y
    var visible_bottom: float = image_rect.end.y
    if not edge.is_empty():
        var vertical_scale: float = image_rect.size.y / float(edge["image_height"])
        visible_top += float(edge["top_offset_px"]) * vertical_scale
        visible_bottom -= float(edge.get("bottom_offset_px", 0)) * vertical_scale
        # Repeated floors/ceilings span full tile width; finite platforms use bbox.
        if one_way or height < float(world_settings.get("ground_collision_height", 220)):
            var horizontal_scale: float = width / float(edge["image_width"])
            x += float(edge["opaque_x0"]) * horizontal_scale
            width = float(edge["opaque_x1"] - edge["opaque_x0"]) * horizontal_scale
        if ceiling_surface:
            height = maxf(1.0, visible_bottom - visible_top)
        y = visible_top
    var body := StaticBody2D.new()
    body.set_meta("art_path", art_path)
    body.set_meta("image_rect", image_rect)
    body.set_meta("image_top", visible_top)
    body.set_meta("image_bottom", visible_bottom)
    body.set_meta("ceiling_surface", ceiling_surface)
    body.name = "OneWayPlatform" if one_way else "Floor"
    body.collision_layer = int(world_settings.get("one_way_layer" if one_way else "surface_layer", 0))
    body.collision_mask = 0
    body.add_to_group("surfaces")
    body.set_meta("one_way", one_way)
    body.set_meta("surface_rect", Rect2(x, y, width, height))
    body.position = Vector2(x + width * 0.5, y + height * 0.5)
    add_child(body)
    var hit := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(width, height)
    hit.shape = shape
    hit.one_way_collision = one_way
    hit.one_way_collision_margin = float(world_settings.get("one_way_margin", 0.0))
    body.add_child(hit)
    if is_zero_approx(art_height):
        return body # Invisible world limits have no matching terrain image.
    var accent: Node2D = load("res://scripts/surface_accent.gd").new()
    accent.name = "SurfaceAccent"
    accent.position = -Vector2(width, height) * 0.5
    accent.dimensions = Vector2(width, visible_bottom - visible_top)
    accent.one_way = one_way
    accent.ground_floor = height >= float(world_settings.get("ground_collision_height", 220.0)) and is_equal_approx(image_rect.position.y, ground_y_at(x + width * 0.5))
    accent.level_id = level_id
    accent.z_index = -2
    body.add_child(accent)
    if GameConstants.DEBUG_SURFACE and not art_path.is_empty():
        var debug: Node2D = load("res://scripts/surface_debug.gd").new()
        debug.name = "SurfaceDebug"
        debug.z_index = 80
        debug.collision_rect = Rect2(-Vector2(width, height) * 0.5, Vector2(width, height))
        debug.image_top = visible_top - body.global_position.y
        debug.image_width = width
        body.add_child(debug)
    return body

func _make_props() -> void:
    for decoration in config.get("decorations", []):
        if not get_node("/root/Story").matches(decoration.get("presence", {})):
            continue
        var prop := Art.add_image(self, str(decoration["path"]), _vector(decoration["position"]), _vector(decoration["size"]), int(decoration.get("z", 0)))
        if decoration.has("name"):
            prop.name = str(decoration["name"])
        if decoration.has("story_art"):
            prop.set_meta("story_art", decoration)
            story_props.append(prop)

func _new_script_node(path: String) -> Node2D:
    if not ResourceLoader.exists(path):
        push_warning("Missing level actor script: " + path)
        return null
    var actor_script := ResourceLoader.load(path) as Script
    if actor_script == null or not actor_script.can_instantiate():
        push_warning("Invalid level actor script: " + path)
        return null
    return actor_script.new() as Node2D

func _set_if_present(actor: Node, property_name: String, value: Variant) -> void:
    for property in actor.get_property_list():
        if str(property["name"]) == property_name:
            actor.set(property_name, value)
            return

func _make_doors() -> void:
    for entry in config.get("doors", []):
        var kind: String = str(entry.get("kind", ""))
        var script_key: String = "villa_gate_script" if kind == "villa_gate" else ("gate_controller_script" if kind == "great_gate" else "door_script")
        var door: Node2D = _new_script_node(str(world_settings.get(script_key, "")))
        if door == null:
            continue
        door.name = str(entry["door_id"])
        door.position = _vector(entry["position"])
        for property in ["door_id", "target_level", "target_spawn", "door_art", "locked", "locked_message", "auto_trigger", "interact_range", "arrival_spawn", "exit_direction", "arrival_walk_pixels", "gate_settings_key", "gate_open_seconds", "gate_close_seconds", "auto_transition_level", "auto_transition_spawn", "opens_without_keeper", "requires_dialogue", "gate_flag", "interact_label"]:
            if entry.has(property):
                _set_if_present(door, property, entry[property])
        if entry.has("door_art"):
            _set_if_present(door, "gate_art", entry["door_art"])
        if entry.has("story_action"):
            door.set_meta("story_action", entry["story_action"])
        doors[str(entry["door_id"])] = door
        var arrival: String = str(entry.get("arrival_spawn", ""))
        if not arrival.is_empty():
            arrival_doors[arrival] = door
        add_child(door)

func _make_npcs() -> void:
    for entry in config.get("npcs", []):
        if get_node("/root/Story").matches(entry.get("presence", {})):
            spawn_npc(entry)

func spawn_npc(entry: Dictionary) -> NPC:
    var instance_id: String = str(entry.get("instance_id", entry["id"]))
    if is_instance_valid(npcs.get(instance_id)):
        return npcs[instance_id]
    var script_key: String = "gatekeeper_script" if str(entry.get("kind", "")) == "gatekeeper" else "npc_script"
    var npc: NPC = _new_script_node(str(world_settings.get(script_key, ""))) as NPC
    if npc == null:
        return null
    npc.name = instance_id
    npc.position = _vector(entry["position"])
    npc.set_meta("interaction_overrides", entry)
    npc.npc_id = str(entry["id"])
    for property in ["idle_clip", "face_player", "initial_facing", "random_start", "interactable", "gesture_face_player"]:
        if entry.has(property):
            _set_if_present(npc, property, entry[property])
    npcs[instance_id] = npc
    add_child(npc)
    return npc

func refresh_story() -> void:
    if not is_inside_tree():
        return
    for entry: Dictionary in config.get("npcs", []):
        var key: String = str(entry.get("instance_id", entry["id"]))
        if get_node("/root/Story").matches(entry.get("presence", {})):
            spawn_npc(entry)
        elif is_instance_valid(npcs.get(key)):
            var npc: NPC = npcs[key]
            npcs.erase(key)
            remove_child(npc)
            npc.queue_free()
    for entry: Dictionary in config.get("doors", []):
        var target_door: DoorPortal = doors.get(str(entry["door_id"])) as DoorPortal
        if target_door != null and entry.has("story_targets"):
            target_door.target_level = str(entry["target_level"])
            target_door.target_spawn = str(entry["target_spawn"])
            for rule: Dictionary in entry["story_targets"]:
                if get_node("/root/Story").matches(rule.get("when", {})):
                    target_door.target_level = str(rule["level"])
                    target_door.target_spawn = str(rule["spawn"])
                    break
        if entry.has("story_lock"):
            var door: Node = doors.get(str(entry["door_id"]))
            if is_instance_valid(door):
                door.locked = get_node("/root/Story").matches(entry["story_lock"])
                door.locked_message = str(entry["story_locked_message"])
    for prop in story_props:
        if not is_instance_valid(prop):
            continue
        var entry: Dictionary = prop.get_meta("story_art")
        var state: String = "prep" if get_node("/root/Story").is_flag("night") else "full" if get_node("/root/Story").is_flag("villa_intro_done") and not get_node("/root/Story").is_flag("villa_dinner_done") else "almost"
        var image: Sprite2D = prop.get_node_or_null("Image") as Sprite2D
        if image != null:
            var path: String = str(entry["story_art"][state])
            var texture: Texture2D = load(path if path.begins_with("res://") else "res://"+path) as Texture2D
            image.texture = texture
            image.scale = _vector(entry["size"]) / texture.get_size()
    if level_id == "VillaF3":
        for key in ["shamash", "aya"]:
            var host: NPC = npcs.get(key)
            if is_instance_valid(host):
                host.story_pose_locked = get_node("/root/Story").is_flag("night")
                if host.story_pose_locked:
                    host.pose = NPC.Pose.RIGHT if key == "shamash" else NPC.Pose.LEFT
                    host.facing = host.pose
                    host.play_clip("idle")
    get_node("/root/Chapter").refresh_level(self)
    apply_time_of_day()

func apply_time_of_day() -> void:
    if time_modulate == null:
        time_modulate = CanvasModulate.new()
        time_modulate.name = "TimeOfDay"
        add_child(time_modulate)
    var colors: Array = get_node("/root/Story").settings["night_color"]
    time_modulate.color = Color(float(colors[0]),float(colors[1]),float(colors[2])) if get_node("/root/Story").is_flag("night") else Color.WHITE
    for npc: NPC in npcs.values():
        var pool: CanvasItem = npc.get_node_or_null("LightPool")
        if pool != null:
            var rgba: Array = npc.readability["pool_modulate"]
            pool.modulate = Color(float(rgba[0])/time_modulate.color.r, float(rgba[1])/time_modulate.color.g, float(rgba[2])/time_modulate.color.b, float(rgba[3]))

func _connect_gatekeeper() -> void:
    for entry in config.get("doors", []):
        var gate: Node = doors.get(str(entry["door_id"])) as Node
        if gate == null or not gate.has_method("bind_gatekeeper"):
            continue
        var keeper: Node = npcs.get(str(entry.get("inner_gatekeeper_id", "gatekeeper"))) as Node
        if keeper != null:
            gate.call("bind_gatekeeper", keeper)
        if entry.has("outer_gatekeeper_id"):
            _set_if_present(gate, "outer_gatekeeper", npcs.get(str(entry["outer_gatekeeper_id"])))

func _spawn_enemies() -> void:
    var enemy_scripts: Dictionary = world_settings.get("enemy_scripts", {})
    for entry in config.get("enemies", []):
        if not get_node("/root/Story").matches(entry.get("presence", {})):
            continue
        var enemy_id: String = str(entry["id"])
        if config.has("boss_by_flags") and enemy_id == "kala_ushumgal":
            for rule: Dictionary in config["boss_by_flags"]:
                if get_node("/root/Story").matches(rule["when"]):
                    enemy_id = str(rule["id"])
                    break
            if enemy_id.is_empty():
                continue
        var path: String = str(enemy_scripts.get(enemy_id, ""))
        for index in range(maxi(0, int(entry.get("count", 1)))):
            var enemy: Node2D = _new_script_node(path)
            if enemy == null:
                continue
            var at: Vector2 = _vector(entry["position"])
            at.x += float(index) * float(world_settings.get("enemy_copy_spacing", 0.0))
            enemy.name = enemy_id + "_" + str(int(at.x))
            enemy.position = at
            _set_if_present(enemy, "enemy_id", enemy_id)
            _set_if_present(enemy, "perch_kind", str(entry.get("perch_kind", "ceiling")))
            _set_if_present(enemy, "patrol_center", float(entry.get("patrol_center", at.x)))
            _set_if_present(enemy, "patrol_range", float(entry.get("patrol_range", 0.0)))
            if entry.has("room_bounds"):
                _set_if_present(enemy, "room_bounds", _rect(entry["room_bounds"]))
            _set_if_present(enemy, "safe_min_x", camera_limits.position.x)
            _set_if_present(enemy, "safe_max_x", camera_limits.end.x)
            add_child(enemy)
            if enemy_id != "sky_beast":
                var dimensions: Variant = enemy.get("body_size")
                if dimensions is Vector2:
                    enemy.global_position = constrain_enemy(enemy.global_position, dimensions)
            enemy.call_deferred("snap_to_ground")

func is_point_safe(point: Vector2) -> bool:
    for zone in safe_zones:
        if point.x >= zone.position.x and point.x <= zone.end.x and point.y >= zone.position.y and point.y <= zone.end.y:
            return true
    return false

func get_enemy_roam_bounds(enemy_position: Vector2, body_size: Vector2) -> Vector2:
    var half_width: float = body_size.x * 0.5
    var low: float = camera_limits.position.x + half_width
    var high: float = camera_limits.end.x - half_width
    for zone in safe_zones:
        if enemy_position.y < zone.position.y or enemy_position.y - body_size.y > zone.end.y:
            continue
        if zone.position.x <= camera_limits.position.x or zone.end.x <= enemy_position.x:
            low = maxf(low, zone.end.x + half_width)
        elif zone.end.x >= camera_limits.end.x or zone.position.x >= enemy_position.x:
            high = minf(high, zone.position.x - half_width)
        elif enemy_position.x - zone.position.x < zone.end.x - enemy_position.x:
            high = minf(high, zone.position.x - half_width)
        else:
            low = maxf(low, zone.end.x + half_width)
    return Vector2(low, maxf(low, high))

func constrain_enemy(enemy_position: Vector2, body_size: Vector2) -> Vector2:
    var bounds: Vector2 = get_enemy_roam_bounds(enemy_position, body_size)
    return Vector2(clampf(enemy_position.x, bounds.x, bounds.y), enemy_position.y)

func get_flight_bounds() -> Rect2:
    return _rect(config.get("flight_bounds", []))

func _make_pickups() -> void:
    for item in config.get("weapon_pickups", []):
        var weapon_item: Node2D = load("res://scripts/weapon_pickup.gd").new()
        weapon_item.spec = item
        weapon_item.position = _vector(item["position"])
        add_child(weapon_item)
    for item in config.get("pickups", []):
        var pickup: Node2D = load("res://scripts/healing_pickup.gd").new()
        pickup.pickup_id = str(item.get("id", "healing_vomit"))
        pickup.position = _vector(item["position"])
        add_child(pickup)
