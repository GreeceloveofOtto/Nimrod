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

var config: Dictionary = {}
var world_settings: Dictionary = {}
var arrival_doors: Dictionary = {}
var doors: Dictionary = {}
var npcs: Dictionary = {}

func _ready() -> void:
    add_to_group("current_level")
    _load_config()
    _make_spawns()
    _make_backgrounds()
    _make_world()
    _make_props()
    _make_doors()
    _make_npcs()
    _connect_gatekeeper()
    _spawn_enemies()

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
        else:
            var layer := Parallax2D.new()
            layer.name = str(entry.get("name", "Parallax"))
            layer.scroll_scale = Vector2(ratio, 0.0)
            layer.z_index = int(entry.get("z", 0))
            add_child(layer)
            Art.add_image(layer, str(entry["path"]), at, size_px)

func _make_world() -> void:
    var width: float = float(config.get("width", 0.0))
    var margin: float = float(world_settings.get("outside_margin", 0.0))
    var wall: float = float(world_settings.get("wall_thickness", 0.0))
    var ground_height: float = float(world_settings.get("ground_collision_height", 0.0))
    _make_surface(-margin, floor_y, width + margin * 2.0, ground_height, false)
    _make_surface(-wall, -margin, wall, floor_y + ground_height + margin * 2.0, false)
    _make_surface(width, -margin, wall, floor_y + ground_height + margin * 2.0, false)
    if bool(config.get("ceiling", false)):
        _make_surface(-wall, -wall, width + wall * 2.0, wall, false)
    var tile_size: Vector2 = _vector(config.get("floor_art_size", []))
    if tile_size.x > 0.0:
        var tile_x: float = -margin
        while tile_x < width + margin:
            Art.add_image(self, str(config.get("floor_art", "")), Vector2(tile_x, floor_y), tile_size, -4)
            tile_x += tile_size.x
    for step in config.get("steps", []):
        var height: float = float(step["height"])
        var x: float = float(step["x"])
        var step_width: float = float(step["width"])
        _make_surface(x, floor_y - height, step_width, height, false)
        Art.add_image(self, str(world_settings["step_art"]), Vector2(x, floor_y - height), Vector2(step_width, height), -3)
    for platform in config.get("platforms", []):
        var at: Vector2 = _vector(platform["position"])
        var platform_width: float = float(platform["width"])
        _make_surface(at.x, at.y, platform_width, float(world_settings["platform_collision_height"]), true)
        Art.add_image(self, str(world_settings["platform_art"]), at, Vector2(platform_width, float(world_settings["platform_art_height"])), -3)

func _make_surface(x: float, y: float, width: float, height: float, one_way: bool) -> void:
    var body := StaticBody2D.new()
    body.name = "OneWayPlatform" if one_way else "Floor"
    body.collision_layer = int(world_settings.get("one_way_layer" if one_way else "surface_layer", 0))
    body.collision_mask = 0
    body.position = Vector2(x + width * 0.5, y + height * 0.5)
    add_child(body)
    var hit := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(width, height)
    hit.shape = shape
    hit.one_way_collision = one_way
    hit.one_way_collision_margin = float(world_settings.get("one_way_margin", 0.0))
    body.add_child(hit)

func _make_props() -> void:
    for decoration in config.get("decorations", []):
        Art.add_image(self, str(decoration["path"]), _vector(decoration["position"]), _vector(decoration["size"]), int(decoration.get("z", 0)))

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
        var script_key: String = "villa_gate_script" if str(entry.get("kind", "")) == "villa_gate" else "door_script"
        var door: Node2D = _new_script_node(str(world_settings.get(script_key, "")))
        if door == null:
            continue
        door.name = str(entry["door_id"])
        door.position = _vector(entry["position"])
        for property in ["door_id", "target_level", "target_spawn", "door_art", "locked", "locked_message", "auto_trigger", "interact_range", "arrival_spawn", "exit_direction", "arrival_walk_pixels"]:
            if entry.has(property):
                _set_if_present(door, property, entry[property])
        doors[str(entry["door_id"])] = door
        var arrival: String = str(entry.get("arrival_spawn", ""))
        if not arrival.is_empty():
            arrival_doors[arrival] = door
        add_child(door)

func _make_npcs() -> void:
    for entry in config.get("npcs", []):
        var script_key: String = "gatekeeper_script" if str(entry.get("kind", "")) == "gatekeeper" else "npc_script"
        var npc: Node2D = _new_script_node(str(world_settings.get(script_key, "")))
        if npc == null:
            continue
        npc.name = str(entry["id"])
        npc.position = _vector(entry["position"])
        _set_if_present(npc, "npc_id", str(entry["id"]))
        for property in ["idle_clip", "face_player", "initial_facing", "random_start"]:
            if entry.has(property):
                _set_if_present(npc, property, entry[property])
        npcs[str(entry["id"])] = npc
        add_child(npc)

func _connect_gatekeeper() -> void:
    var gate: Node = doors.get("villa_gate") as Node
    var keeper: Node = npcs.get("gatekeeper") as Node
    if gate != null and keeper != null and gate.has_method("bind_gatekeeper"):
        gate.call("bind_gatekeeper", keeper)

func _spawn_enemies() -> void:
    var enemy_scripts: Dictionary = world_settings.get("enemy_scripts", {})
    for entry in config.get("enemies", []):
        var enemy_id: String = str(entry["id"])
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
            _set_if_present(enemy, "patrol_center", float(entry.get("patrol_center", at.x)))
            _set_if_present(enemy, "patrol_range", float(entry.get("patrol_range", 0.0)))
            _set_if_present(enemy, "safe_min_x", camera_limits.position.x)
            _set_if_present(enemy, "safe_max_x", camera_limits.end.x)
            add_child(enemy)
            if enemy_id != "sky_beast":
                var dimensions: Variant = enemy.get("body_size")
                if dimensions is Vector2:
                    enemy.global_position = constrain_enemy(enemy.global_position, dimensions)

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
