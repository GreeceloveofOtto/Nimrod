extends CanvasLayer

var player: NimrodPlayer
var config: Dictionary = {}
var ui: Dictionary = {}
var ui_font: Font
var hp_fill: ColorRect
var hp_text: Label
var title: Label
var toast: Label
var story: Label
var _toast_tween: Tween
var _story_tween: Tween
var boss_panel: Control
var boss_fill: ColorRect
var boss_label: Label

func _ready() -> void:
    add_to_group("game_hud")
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/transitions.json"))
    if parsed is Dictionary:
        config = parsed
    ui = config.get("ui", {})
    layer = int(ui.get("canvas_layer", 20))
    var font_path: String = str(ui.get("font", ""))
    if ResourceLoader.exists(font_path):
        ui_font = load(font_path) as Font
    else:
        var fallback := SystemFont.new()
        fallback.font_names = PackedStringArray(["Noto Sans CJK KR", "Noto Sans KR", "sans-serif"])
        ui_font = fallback
    _add_panel("hp_border", Color("d0b17d"))
    _add_panel("hp_background", Color("18202a"))
    hp_fill = _add_panel("hp_fill", Color("d7b168"))
    hp_text = _new_label("hp_label", "", "hp_font_size")
    hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title = _new_label("title", "", "title_font_size")
    _new_label("controls", str(ui.get("controls_text", "")), "controls_font_size")
    story = _new_label("story", str(config.get("story", "")), "story_font_size")
    story.modulate.a = 0.0
    toast = _new_label("toast", "", "toast_font_size")
    toast.modulate.a = 0.0
    boss_panel = Control.new()
    boss_panel.position = Vector2(380, 28)
    boss_panel.visible = false
    add_child(boss_panel)
    var boss_back := ColorRect.new()
    boss_back.size = Vector2(520, 10)
    boss_back.position.y = 28
    boss_back.color = Color("18202a")
    boss_panel.add_child(boss_back)
    boss_fill = ColorRect.new()
    boss_fill.position.y = 28
    boss_fill.size = Vector2(520, 10)
    boss_fill.color = Color("bb6355")
    boss_panel.add_child(boss_fill)
    boss_label = Label.new()
    boss_label.size.x = 520
    boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_label.add_theme_font_override("font", ui_font)
    boss_label.add_theme_font_size_override("font_size", 18)
    boss_panel.add_child(boss_label)

func bind_player(value: NimrodPlayer) -> void:
    player = value

func set_level_name(value: String) -> void:
    title.text = value

func _process(_delta: float) -> void:
    if not is_instance_valid(player) or hp_fill == null:
        return
    hp_fill.size.x = _ui_rect("hp_fill").size.x * clampf(float(player.hp) / float(player.get_max_hp()), 0.0, 1.0)
    hp_text.text = "HP %d / %d" % [player.hp, player.get_max_hp()]
    var boss: KalaUshumgal
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if enemy is KalaUshumgal:
            boss = enemy
    boss_panel.visible = boss != null and boss.battle_started and not boss.battle_finished
    if boss_panel.visible:
        boss_fill.size.x = 520.0 * clampf(float(boss.hp) / float(boss.stats["hp"]), 0, 1)
        boss_label.text = "칼라-우쉬움갈  %d / 1200" % boss.hp

func show_toast(text: String, seconds: float = -1.0) -> void:
    if _toast_tween != null and _toast_tween.is_valid():
        _toast_tween.kill()
    toast.text = text
    toast.modulate.a = 0.0
    var fade: float = float(config["toast_fade_seconds"])
    var hold: float = maxf(0.0, (float(config["toast_seconds"]) if seconds < 0.0 else seconds) - fade * 2.0)
    _toast_tween = create_tween()
    _toast_tween.tween_property(toast, "modulate:a", 1.0, fade)
    _toast_tween.tween_interval(hold)
    _toast_tween.tween_property(toast, "modulate:a", 0.0, fade)

func show_story() -> void:
    if _story_tween != null and _story_tween.is_valid():
        _story_tween.kill()
    story.modulate.a = 1.0
    var fade: float = float(config["toast_fade_seconds"])
    _story_tween = create_tween()
    _story_tween.tween_interval(maxf(0.0, float(config["story_seconds"]) - fade))
    _story_tween.tween_property(story, "modulate:a", 0.0, fade)

func _ui_rect(key: String) -> Rect2:
    var values: Array = ui[key]
    return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))

func _add_panel(key: String, color: Color) -> ColorRect:
    var panel := ColorRect.new()
    var rect: Rect2 = _ui_rect(key)
    panel.position = rect.position
    panel.size = rect.size
    panel.color = color
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(panel)
    return panel

func _new_label(key: String, text: String, font_size_key: String) -> Label:
    var label := Label.new()
    var rect: Rect2 = _ui_rect(key)
    label.text = text
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_override("font", ui_font)
    label.add_theme_font_size_override("font_size", int(ui[font_size_key]))
    label.add_theme_color_override("font_color", Color(str(ui["font_color"])))
    label.add_theme_color_override("font_shadow_color", Color(str(ui["shadow_color"])))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(label)
    return label
