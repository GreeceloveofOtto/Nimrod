extends CanvasLayer
var panel: Control
var canvas: Control
var label: Label
var footer: Label
var opened:=false
var pause_menu:=false
var previous_pause:=false
var audio_state: Dictionary = {}
var debug_layer: CanvasLayer
var debug_text: Label
var redraw_clock:=0.
var ability_strip: Control
var shown_abilities: String=""

func _ready() -> void:
    layer=55
    ability_strip=Control.new()
    ability_strip.position=Vector2(20,60)
    ability_strip.size=Vector2(224,28)
    ability_strip.draw.connect(draw_ability_icons)
    add_child(ability_strip)
    process_mode=PROCESS_MODE_ALWAYS
    panel=Control.new()
    panel.visible=false
    add_child(panel)
    var shade:=ColorRect.new()
    shade.color=Color(.02,.03,.05,.97)
    shade.size=Vector2(1280,720)
    panel.add_child(shade)
    canvas=Control.new()
    canvas.position=Vector2(80,100)
    canvas.size=Vector2(1120,500)
    canvas.draw.connect(draw_map)
    panel.add_child(canvas)
    label=make_label(Vector2(80,35),24)
    footer=make_label(Vector2(80,620),20)
    # The debug path is compiled out of release exports and disabled in shared ZIPs.
    if OS.is_debug_build() and bool(get_parent().settings.get("developer_overlay",false)):
        debug_layer=CanvasLayer.new()
        debug_layer.layer=90
        debug_layer.visible=false
        add_child(debug_layer)
        debug_text=Label.new()
        debug_text.position=Vector2(20,200)
        debug_layer.add_child(debug_text)

func make_label(at: Vector2,size_px: int) -> Label:
    var result:=Label.new()
    result.position=at
    result.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    result.add_theme_font_size_override("font_size",size_px)
    panel.add_child(result)
    return result

func _process(delta: float) -> void:
    var world: Node = get_parent()
    ability_strip.visible=world.active and not opened
    var signature: String=str(world.abilities)
    if signature!=shown_abilities:
        shown_abilities=signature
        ability_strip.queue_redraw()
    if not world.active and opened and not pause_menu:close()
    if not world.active and not opened:return
    redraw_clock+=delta
    if opened and redraw_clock>.15:
        redraw_clock=0
        footer.text="색끈 %d/60 · 이번 시도 불씨 %d · 이번 시도 능력 %d/7\n죽음 %d회" % [world.cord_ids.size(),world.embers,world.abilities.size(),world.deaths_zabulistan]
        if not pause_menu:
            var owned: PackedStringArray = []
            for id in world.abilities:
                if world.has_ability(str(id)):owned.append(str(world.abilities_data.abilities[id].name))
            footer.text="색끈 %d/60 · 이번 시도 불씨 %d · 이번 시도 능력 %d/7\n%s\n죽음 %d회" % [world.cord_ids.size(),world.embers,world.abilities.size()," · ".join(owned),world.deaths_zabulistan]
        if pause_menu:footer.text="자불리스탄 죽음 %d회 · 전체 죽음 %d회\nA/D 이동 · Space 점프 · J 공격 · K 회피 · E 상호작용\nQ 질주 · F 시야 · R 빛 · M 지도 · Esc 계속" % [world.deaths_zabulistan,world.deaths_total]
        canvas.queue_redraw()
    if debug_text!=null and debug_layer.visible:
        debug_text.text="청크 %s · 로드 %d/9 · 활성 %d / 정지 %d · %.2f ms" % [world.stream_center,world.loaded.size(),world.active_enemies,world.sleeping_enemies,world.last_load_ms]

func _unhandled_input(event: InputEvent) -> void:
    var world: Node = get_parent()
    var is_pause: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE
    if not world.active and not is_pause:return
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F3 and debug_layer!=null:
        debug_layer.visible=not debug_layer.visible
        get_viewport().set_input_as_handled()
        return
    if (event.is_action_pressed("map_toggle") or is_pause) and not world.transitioning:
        if opened:close()
        elif not get_tree().paused and not get_node("/root/SceneManager").player_locked:
            open_map(is_pause)
        get_viewport().set_input_as_handled()

func open_map(as_pause: bool = false) -> void:
    if opened:return
    opened=true
    pause_menu=as_pause
    previous_pause=get_tree().paused
    audio_state=get_node("/root/Audio").pause_world_sfx()
    get_tree().paused=true
    panel.visible=true
    canvas.visible=not as_pause
    footer.position=Vector2(80,250 if as_pause else 620)
    label.text="일시정지" if as_pause else "자불리스탄 · M 닫기"
    redraw_clock=1
    _process(0)

func close() -> void:
    if not opened:return
    opened=false
    panel.visible=false
    get_tree().paused=previous_pause
    get_node("/root/Audio").restore_world_sfx(audio_state)

func draw_map() -> void:
    var world: Node = get_parent()
    if not world.active:return
    var width: int = int(world.settings.width)/8
    var height: int = int(world.settings.height)/8
    var cell:=Vector2(1120./width,500./height)
    for y in range(height):
        for x in range(width):
            if world.explored[y*width+x]==0:continue
            var region: Dictionary = world.region_at(Vector2(x*8,y*8))
            canvas.draw_rect(Rect2(Vector2(x,y)*cell,cell),Color(str(region.palette)).lightened(.1))
            # Actual terrain, rather than abstract rectangular room outlines.
            for yy in range(8):
                for xx in range(8):
                    if world.tile_at(Vector2i(x*8+xx,y*8+yy)) in ["#","W","^","F","="]:
                        canvas.draw_rect(Rect2((Vector2(x,y)+Vector2(xx,yy)/8.)*cell,cell/8.),Color(.7,.75,.8,.75))
    for item: Dictionary in world.settings.map_icons:
        var at:=Vector2(float(item.position[0]),float(item.position[1]))/256.
        var index: int = clampi(int(at.y),0,height-1)*width+clampi(int(at.x),0,width-1)
        var is_site: bool=str(item.type)=="site"
        if world.explored[index]==0 and not (is_site and world.discovered_sites.has(str(item.uid))):continue
        if not is_site and (world.collected.has(str(item.uid)) or world.cord_ids.has(str(item.uid))):continue
        var colors: Dictionary={"site":Color.GOLD,"ember":Color.ORANGE_RED,"cord":Color.SALMON,"gate":Color.ORANGE,"switch":Color.SEA_GREEN,"return_pier":Color.SKY_BLUE}
        if item.type=="gate":
            var unlocked: bool = world.meets(item.get("requires",[]))
            if item.get("secret",false):unlocked=world.switches.has(str(item.uid))
            if item.has("opens_with"):unlocked=world.switches.has(str(item.opens_with))
            if unlocked:continue
            canvas.draw_rect(Rect2(at*cell-Vector2(3,4),Vector2(6,8)),Color.ORANGE,false,1.5)
        elif is_site:
            var color: Color=Color.GOLD.darkened(.5) if world.collected.has(str(item.uid)) else Color.GOLD
            canvas.draw_circle(at*cell,4.,color)
            draw_symbol(canvas,at*cell,world.abilities_data.abilities.keys().find(str(item.ability)),4.,Color.WHITE)
        else:canvas.draw_circle(at*cell,3.,colors.get(str(item.type),Color.WHITE))
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    canvas.draw_circle(hero.position/256.*cell,4.,Color.WHITE)

# Code-only UI glyphs; these never draw world art or character sprites.
func draw_ability_icons() -> void:
    var world: Node=get_parent()
    var slot:=0
    var ids: Array=world.abilities_data.abilities.keys()
    for i in range(ids.size()):
        if not world.has_ability(str(ids[i])):continue
        var at:=Vector2(slot*29+12,12)
        ability_strip.draw_style_box(icon_frame(),Rect2(at-Vector2(11,11),Vector2(22,22)))
        draw_symbol(ability_strip,at,i,7.,Color(.85,.76,.5))
        slot+=1

func icon_frame() -> StyleBoxFlat:
    var box:=StyleBoxFlat.new()
    box.bg_color=Color(.03,.04,.06,.85)
    box.border_color=Color(.58,.54,.4)
    box.set_border_width_all(1)
    return box

func draw_symbol(surface: CanvasItem,at: Vector2,index: int,radius: float,color: Color) -> void:
    match index:
        0:
            for shift in [-.4,.4]:
                surface.draw_line(at+Vector2(-radius,shift*radius-radius*.5),at+Vector2(radius*.4,shift*radius),color,1.5)
                surface.draw_line(at+Vector2(radius*.4,shift*radius),at+Vector2(-radius,shift*radius+radius*.5),color,1.5)
        1:
            surface.draw_line(at+Vector2(-radius,0),at+Vector2(0,-radius),color,1.5)
            surface.draw_line(at+Vector2(0,-radius),at+Vector2(radius,0),color,1.5)
            surface.draw_line(at+Vector2(0,-radius),at+Vector2(0,radius),color,1.5)
        2,3:
            surface.draw_line(at+Vector2(radius,-radius),at+Vector2(radius,radius),color,1.5)
            surface.draw_line(at+Vector2(-radius,radius*.5),at+Vector2(radius*.5,-radius*.5 if index==3 else radius*.5),color,1.5)
        4:surface.draw_rect(Rect2(at-Vector2(radius,radius*.25),Vector2(radius*2,radius*.5)),color,false,1.5)
        5:surface.draw_arc(at,radius,0,TAU,12,color,1.5)
        6:
            surface.draw_line(at+Vector2(-radius,radius),at+Vector2(radius,-radius),color,1.5)
            surface.draw_line(at+Vector2(radius*.1,-radius),at+Vector2(radius,-radius),color,1.5)
