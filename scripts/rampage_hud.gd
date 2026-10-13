extends Control
var font: Font
var shown_value:=0.0
var gauge_tween: Tween
var clock: float = 0
func _ready() -> void:
    mouse_filter = MOUSE_FILTER_IGNORE
    get_node("/root/Rampage").changed.connect(_gauge_changed)
    shown_value=float(get_node("/root/Rampage").value())
    font = load("res://assets/fonts/NimrodUIKorean-Regular.otf") as Font
func _process(delta: float) -> void:
    clock += delta
    visible = get_node("/root/Rampage").unlocked()
    queue_redraw()
func _draw() -> void:
    var rampage: Node = get_node("/root/Rampage")
    if not rampage.unlocked():
        return
    var number: int = rampage.value()
    var alpha: float = .75+.25*sin(clock*6) if number>=78 else 1
    draw_string(font,Vector2(0,16),"폭주 정도  %d / 100"%number,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f2e9d0"))
    draw_rect(Rect2(0,24,240,12),Color("18202a"))
    draw_rect(Rect2(0,24,240*shown_value/100,12),Color(1,lerpf(.32,.06,float(number)/100),.08,alpha))
    draw_rect(Rect2(0,24,240,12),Color("d0b17d"),false,2)
    for mark in [30,40,50,90]:
        draw_line(Vector2(2.4*mark,24),Vector2(2.4*mark,36),Color("f2e9d0"),1)
    var slot := Rect2(58,52,42,42)
    draw_rect(slot,Color("18202a"))
    draw_rect(slot,Color("d0b17d"),false,2)
    draw_string(font,Vector2(73,79),"L",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f2e9d0"))
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    if is_instance_valid(hero):
        var ratio: float = clampf(hero.devour_cooldown_left/float(rampage.settings["devour"]["cooldown"]),0,1)
        draw_rect(Rect2(60,54+38*(1-ratio),38,38*ratio),Color(0,0,0,.65))

func _gauge_changed() -> void:
    if gauge_tween!=null and gauge_tween.is_valid():gauge_tween.kill()
    gauge_tween=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    gauge_tween.tween_method(func(v: float) -> void: shown_value=v; queue_redraw(),shown_value,float(get_node("/root/Rampage").value()),.3)
