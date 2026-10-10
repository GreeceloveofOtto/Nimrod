extends Node2D

const Layout = preload("res://scripts/rear_gate_layout.gd")
const Art = preload("res://scripts/asset_visual.gd")
const UI_FONT_PATH: String = "res://assets/fonts/NimrodUIKorean-Regular.otf"

@onready var hero: NimrodPlayer = $Player
var hp_fill: ColorRect
var hp_text: Label
var door_prompt: Label
var exit_label: Label
var story_label: Label
var story_left: float = Layout.STORY_SECONDS
var ui_font: Font

func _ready() -> void:
    hero.position = Layout.PLAYER_START
    _make_backgrounds()
    _make_world()
    _make_props()
    _spawn_enemies()
    _make_ui()
    _configure_camera()
    _start_music.call_deferred()

func _start_music() -> void:
    var audio := get_node_or_null("/root/Audio")
    if audio != null and audio.has_method("play_bgm"):
        audio.call("play_bgm", "uruk_rear_gate", 1.0)

func _make_backgrounds() -> void:
    for layer_info in Layout.PARALLAX_LAYERS:
        var layer := Parallax2D.new()
        layer.name = str(layer_info["name"])
        layer.scroll_scale = Vector2(float(layer_info["ratio"]), 0.0)
        layer.z_index = int(layer_info["z"])
        add_child(layer)
        Art.add_image(layer, "res://assets/backgrounds/rear_gate/" + str(layer_info["file"]), Vector2.ZERO, layer_info["size"])

func _make_world() -> void:
    _make_surface(Layout.MAP_LEFT - Layout.OUTSIDE_MARGIN, Layout.FLOOR_Y, Layout.MAP_RIGHT + Layout.OUTSIDE_MARGIN * 2.0, Layout.GROUND_HEIGHT, false)
    _make_wall(Layout.MAP_LEFT - Layout.WALL_THICKNESS, -Layout.OUTSIDE_MARGIN, Layout.WALL_THICKNESS, Layout.FLOOR_Y + Layout.GROUND_HEIGHT + Layout.OUTSIDE_MARGIN * 2.0)
    _make_wall(Layout.MAP_RIGHT, -Layout.OUTSIDE_MARGIN, Layout.WALL_THICKNESS, Layout.FLOOR_Y + Layout.GROUND_HEIGHT + Layout.OUTSIDE_MARGIN * 2.0)
    var tile_x: float = Layout.MAP_LEFT - Layout.OUTSIDE_MARGIN
    while tile_x < Layout.MAP_RIGHT + Layout.OUTSIDE_MARGIN:
        Art.add_image(self, "res://assets/tiles/rear_gate/ground_tile.png", Vector2(tile_x, Layout.FLOOR_Y), Layout.GROUND_TILE_SIZE, -4)
        tile_x += Layout.GROUND_TILE_SIZE.x
    for step in Layout.STEPS:
        var height: float = float(step["height"])
        var x: float = float(step["x"])
        var width: float = float(step["width"])
        var top: float = Layout.FLOOR_Y - height
        _make_surface(x, top, width, height, false)
        Art.add_image(self, "res://assets/tiles/rear_gate/step_block.png", Vector2(x, top), Vector2(width, height), -3)
    for x in Layout.PLATFORM_X:
        _make_surface(float(x), Layout.PLATFORM_Y, Layout.PLATFORM_WIDTH, Layout.PLATFORM_COLLISION_HEIGHT, true)
        Art.add_image(self, "res://assets/tiles/rear_gate/platform.png", Vector2(float(x), Layout.PLATFORM_Y), Vector2(Layout.PLATFORM_WIDTH, Layout.PLATFORM_ART_HEIGHT), -3)

func _make_props() -> void:
    Art.add_image(self, "res://assets/props/rear_gate_door.png", Layout.DOOR_CENTER - Vector2(Layout.DOOR_SIZE.x * 0.5, Layout.DOOR_SIZE.y), Layout.DOOR_SIZE, -2)
    Art.add_image(self, "res://assets/props/exit_signpost.png", Layout.EXIT_SIGN_CENTER - Vector2(Layout.EXIT_SIGN_SIZE.x * 0.5, Layout.EXIT_SIGN_SIZE.y), Layout.EXIT_SIGN_SIZE, -2)
    for decoration in Layout.DECORATIONS:
        Art.add_image(self, "res://assets/props/" + str(decoration["file"]), decoration["position"], decoration["size"], int(decoration["z"]))
    var exit_area := Area2D.new()
    exit_area.name = "VillaDirectionExit"
    exit_area.position = Vector2((Layout.EXIT_START + Layout.MAP_RIGHT) * 0.5, Layout.FLOOR_Y - Layout.EXIT_HEIGHT * 0.5)
    exit_area.collision_layer = 0
    exit_area.collision_mask = 1
    var hit := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(Layout.MAP_RIGHT - Layout.EXIT_START, Layout.EXIT_HEIGHT)
    hit.shape = shape
    exit_area.add_child(hit)
    add_child(exit_area)
    exit_area.body_entered.connect(_on_exit_entered)
    exit_area.body_exited.connect(_on_exit_exited)

func _spawn_enemies() -> void:
    for spawn in Layout.SPAWNS:
        var enemy_id: String = str(spawn["id"])
        var path: String = "res://scripts/enemy_" + ("melee" if enemy_id == "melee_beast" else "ranged") + "_beast.gd"
        if not ResourceLoader.exists(path):
            push_warning("Enemy script is unavailable: " + path)
            continue
        var enemy_script := ResourceLoader.load(path) as Script
        if enemy_script == null:
            continue
        var enemy: CharacterBody2D = enemy_script.new()
        enemy.name = enemy_id.capitalize().replace(" ", "") + str(int(spawn["x"]))
        enemy.set("enemy_id", enemy_id)
        enemy.set("patrol_center", float(spawn["x"]))
        enemy.set("patrol_range", Layout.PATROL_RANGE)
        enemy.set("safe_min_x", Layout.SAFE_ZONE_END)
        enemy.set("safe_max_x", Layout.EXIT_START)
        enemy.position = Vector2(float(spawn["x"]), Layout.FLOOR_Y)
        add_child(enemy)

func _make_wall(x: float, y: float, width: float, height: float) -> void:
    _make_surface(x, y, width, height, false)

func _make_surface(x: float, y: float, width: float, height: float, one_way: bool) -> void:
    var body := StaticBody2D.new()
    body.name = "OneWayPlatform" if one_way else "Floor"
    body.collision_layer = 2 if one_way else 1
    body.collision_mask = 0
    body.position = Vector2(x + width * 0.5, y + height * 0.5)
    add_child(body)
    var hit := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(width, height)
    hit.shape = shape
    hit.one_way_collision = one_way
    hit.one_way_collision_margin = Layout.ONE_WAY_MARGIN
    body.add_child(hit)

func _configure_camera() -> void:
    hero.camera.limit_left = int(Layout.MAP_LEFT)
    hero.camera.limit_right = int(Layout.MAP_RIGHT)
    hero.camera.limit_top = 0
    hero.camera.limit_bottom = Layout.CAMERA_BOTTOM

func _new_label(text: String, position: Vector2, size: Vector2, font_size: int = 20) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position
    label.size = size
    label.add_theme_font_override("font", ui_font)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("eed8b5"))
    label.add_theme_color_override("font_shadow_color", Color("101721"))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _make_ui() -> void:
    if ResourceLoader.exists(UI_FONT_PATH):
        ui_font = load(UI_FONT_PATH) as Font
    if ui_font == null:
        push_warning("Missing portable Korean font: " + UI_FONT_PATH)
        var fallback_font := SystemFont.new()
        fallback_font.font_names = PackedStringArray(["Noto Sans CJK KR", "Noto Sans KR", "sans-serif"])
        ui_font = fallback_font
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)
    var border := ColorRect.new()
    border.position = Layout.HUD_BORDER_POSITION
    border.size = Layout.HUD_BORDER_SIZE
    border.color = Color("d0b17d")
    layer.add_child(border)
    var hp_bg := ColorRect.new()
    hp_bg.position = Layout.HUD_HP_BACKGROUND_POSITION
    hp_bg.size = Layout.HUD_HP_BACKGROUND_SIZE
    hp_bg.color = Color("18202a")
    layer.add_child(hp_bg)
    hp_fill = ColorRect.new()
    hp_fill.position = Layout.HUD_HP_FILL_POSITION
    hp_fill.size = Layout.HUD_HP_FILL_SIZE
    hp_fill.color = Color("d7b168")
    layer.add_child(hp_fill)
    hp_text = _new_label("HP 180 / 180", Layout.HUD_HP_LABEL_POSITION, Layout.HUD_HP_LABEL_SIZE, 18)
    hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    layer.add_child(hp_text)
    layer.add_child(_new_label("우루크 · 루갈성 후문", Layout.HUD_TITLE_POSITION, Layout.HUD_TITLE_SIZE, 24))
    layer.add_child(_new_label("A/D·←/→ 이동   Space 점프   J 도끼   K 구르기   S 수그리기   S+Space 발판 내려가기   F1 판정   R 재시작", Layout.HUD_CONTROLS_POSITION, Layout.HUD_CONTROLS_SIZE, 16))
    story_label = _new_label("루갈성의 마지막 횃불이 등을 비춘다.\n니므롯은 폐허를 건너 별장으로 향한다.", Layout.HUD_STORY_POSITION, Layout.HUD_STORY_SIZE, 19)
    layer.add_child(story_label)
    door_prompt = _new_label("E", Layout.DOOR_PROMPT_POSITION, Layout.DOOR_PROMPT_SIZE, 26)
    door_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    door_prompt.z_index = 25
    add_child(door_prompt)
    exit_label = _new_label("별장 방향 →", Layout.EXIT_LABEL_POSITION, Layout.EXIT_LABEL_SIZE, 24)
    exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    exit_label.z_index = 25
    add_child(exit_label)

func _process(delta: float) -> void:
    if hp_fill == null:
        return
    hp_fill.size.x = Layout.HUD_HP_FILL_SIZE.x * clampf(float(hero.hp) / float(NimrodPlayer.MAX_HP), 0.0, 1.0)
    hp_text.text = "HP %d / %d" % [hero.hp, NimrodPlayer.MAX_HP]
    door_prompt.visible = absf(hero.position.x - Layout.DOOR_CENTER.x) <= Layout.DOOR_INTERACT_DISTANCE and absf(hero.position.y - Layout.FLOOR_Y) < Layout.DOOR_INTERACT_VERTICAL_RANGE
    story_left = maxf(0.0, story_left - delta)
    story_label.modulate.a = clampf(story_left, 0.0, 1.0)

func _on_exit_entered(body: Node2D) -> void:
    if body == hero:
        exit_label.text = "별장 방향 →"
        exit_label.add_theme_color_override("font_color", Color("fff0c0"))

func _on_exit_exited(body: Node2D) -> void:
    if body == hero:
        exit_label.add_theme_color_override("font_color", Color("eed8b5"))
