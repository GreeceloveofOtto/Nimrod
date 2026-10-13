extends Node
signal closed
var active: bool = false
var selected: int = 0
var items: Array[String] = []
var panel: PanelContainer
var labels: Array[Label] = []
var name_chip: PanelContainer
var canvas: CanvasLayer
var previous_pause: bool = false
var audio_snapshot: Dictionary = {}
var system_mode := false
var systems: Array = []
var input_delay: float = 0

func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    canvas = CanvasLayer.new()
    canvas.layer = 91
    add_child(canvas)
    panel = PanelContainer.new()
    panel.custom_minimum_size = Vector2(520,150)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(.06,.07,.11,.93)
    style.border_color = Color(.82,.68,.40,.9)
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.content_margin_left = 18
    style.content_margin_top = 14
    style.content_margin_right = 18
    style.content_margin_bottom = 14
    panel.add_theme_stylebox_override("panel",style)
    canvas.add_child(panel)
    name_chip = PanelContainer.new()
    var chip_style := StyleBoxFlat.new()
    chip_style.bg_color = Color(.55,.42,.18,1)
    chip_style.set_corner_radius_all(8)
    chip_style.content_margin_left = 10
    chip_style.content_margin_right = 10
    chip_style.content_margin_top = 3
    chip_style.content_margin_bottom = 3
    name_chip.add_theme_stylebox_override("panel",chip_style)
    var caption := Label.new()
    caption.text = "샴하트"
    caption.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    caption.add_theme_font_size_override("font_size",20)
    caption.add_theme_color_override("font_color",Color("f2e9d0"))
    name_chip.add_child(caption)
    canvas.add_child(name_chip)
    canvas.hide()

func menu_available() -> bool:
    var spec: Dictionary = get_node("/root/Dialogue").resolve_interaction("shamhat")
    return not spec.is_empty() and bool(get_node("/root/GameState").run_flags.get(str(spec["flag"]),false))

func open(_speaker: NPC) -> void:
    if active or not menu_available() or not get_node("/root/Save").can_save():
        return
    system_mode=false
    canvas.layer=91
    name_chip.get_child(0).text="샴하트"
    items = ["대화하기","저장하기"]
    if get_node("/root/Rampage").unlocked():
        items.append("폭주 완화 주문")
    for child in panel.get_children():
        panel.remove_child(child)
        child.queue_free()
    labels.clear()
    var box := VBoxContainer.new()
    panel.add_child(box)
    for caption in items:
        var label := Label.new()
        label.text = caption
        label.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
        label.add_theme_font_size_override("font_size",22)
        box.add_child(label)
        labels.append(label)
    selected = 0
    active = true
    input_delay = float(get_node("/root/Dialogue").settings["skip_start_grace"])
    previous_pause = get_tree().paused
    audio_snapshot = get_node("/root/Audio").pause_world_sfx()
    get_tree().paused = true
    canvas.show()
    _update_labels()
    await closed

func _process(delta: float) -> void:
    input_delay = maxf(0,input_delay-delta)
    if active:
        var screen: Vector2 = get_viewport().get_visible_rect().size
        panel.position = Vector2((screen.x-panel.size.x)*.5 if system_mode else screen.x-panel.size.x-32,(screen.y-panel.size.y)*.5)
        name_chip.position = panel.position + Vector2(14,-name_chip.size.y*.5)

func _unhandled_input(event: InputEvent) -> void:
    if not active or input_delay>0 or not event is InputEventKey or not event.pressed or event.echo:
        return
    match event.physical_keycode:
        KEY_F5:
            close()
            get_node("/root/SceneManager").set_player_locked(false)
            get_node("/root/SceneManager").full_reset_run()
        KEY_W,KEY_UP:
            selected = posmod(selected-1,items.size())
            _update_labels()
        KEY_S,KEY_DOWN:
            selected = (selected+1)%items.size()
            _update_labels()
        KEY_ESCAPE:
            if not system_mode:
                close()
        KEY_E,KEY_ENTER,KEY_KP_ENTER:
            choose(selected)
    get_viewport().set_input_as_handled()

func _update_labels() -> void:
    for i in range(labels.size()):
        labels[i].text = ("▶ " if i==selected else "   ")+items[i]
        labels[i].modulate = Color("f2e9d0") if i==selected else Color(.7,.7,.7)
        if system_mode and not bool(systems[i]["unlocked"]):
            labels[i].text += "  [잠김]"
            labels[i].modulate = Color(.32,.32,.36)

func choose(index: int) -> void:
    if not active or index<0 or index>=items.size():
        return
    if system_mode:
        if not bool(systems[index]["unlocked"]):
            get_node("/root/Audio").play_sfx("door_locked")
            return
        var id: String = str(systems[index]["id"])
        close()
        get_node("/root/Odyssey").select_system(id)
        return
    var choice: String = items[index]
    close()
    match choice:
        "대화하기":
            await get_node("/root/Dialogue").play_interaction("shamhat")
        "저장하기":
            get_node("/root/Save").save_game()
        "폭주 완화 주문":
            get_node("/root/Rampage").cure(get_node("/root/SceneManager").player)

func close() -> void:
    canvas.hide()
    active = false
    get_tree().paused = previous_pause
    get_node("/root/Audio").restore_world_sfx(audio_snapshot)
    audio_snapshot.clear()
    get_node("/root/Dialogue").input_grace_left = .2
    closed.emit()

func open_systems() -> void:
    if active:
        return
    systems=JSON.parse_string(FileAccess.get_file_as_string("res://data/choices.json"))["systems"]
    system_mode=true
    canvas.layer=120
    name_chip.get_child(0).text="항성계 선택"
    items.clear()
    for child in panel.get_children():
        panel.remove_child(child)
        child.queue_free()
    labels.clear()
    var box:=VBoxContainer.new()
    panel.add_child(box)
    for row: Dictionary in systems:
        items.append(str(row["label"]))
        var label:=Label.new()
        label.text=str(row["label"])
        label.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
        label.add_theme_font_size_override("font_size",24)
        var line:=HBoxContainer.new()
        box.add_child(line)
        line.add_child(label)
        if not bool(row["unlocked"]):line.add_child(load("res://scripts/ui_lock.gd").new())
        labels.append(label)
    selected=2
    active=true
    previous_pause=get_tree().paused
    audio_snapshot=get_node("/root/Audio").pause_world_sfx()
    get_tree().paused=true
    input_delay=.25
    canvas.show()
    _update_labels()
