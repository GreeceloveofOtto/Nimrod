extends CanvasLayer
var panel: Control
var canvas: Control
var label: Label
var summary: Label
var minimap: Control
var opened := false
var minimap_enabled := true
var previous_pause := false
var cache: Dictionary = {}
var redraw_clock := 0.0

func _ready() -> void:
    cache=get_parent().read_json("res://data/world/zabulistan/map_index.json")
    layer=55
    process_mode=PROCESS_MODE_ALWAYS
    panel=Control.new()
    panel.visible=false
    add_child(panel)
    var shade:=ColorRect.new()
    shade.color=Color(.02,.03,.05,.96)
    shade.size=Vector2(1280,720)
    panel.add_child(shade)
    canvas=Control.new()
    canvas.position=Vector2(80,120)
    canvas.size=Vector2(1120,480)
    canvas.draw.connect(draw_map.bind(canvas,false))
    panel.add_child(canvas)
    label=Label.new()
    label.position=Vector2(80,40)
    label.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    label.add_theme_font_size_override("font_size",24)
    panel.add_child(label)
    minimap=Control.new()
    minimap.position=Vector2(1030,40)
    minimap.size=Vector2(230,125)
    minimap.draw.connect(draw_map.bind(minimap,true))
    add_child(minimap)
    summary=Label.new()
    summary.position=Vector2(20,106)
    summary.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    summary.add_theme_font_size_override("font_size",14)
    add_child(summary)

func _process(delta: float) -> void:
    var world: Node = get_parent()
    summary.visible=world.active
    minimap.visible=world.active and minimap_enabled and not opened
    if not world.active:
        if opened:close()
        return
    redraw_clock+=delta
    if redraw_clock>.2:
        redraw_clock=0
        summary.text="생명 조각 %d/60 · 결정 %d · 능력 %d/7\n%s (%d,%d) · 활성 %d / 정지 %d\nQ 질주 · F 시야 · R 빛 · M 지도 · S+E 아래 방" % [world.fragments,world.crystals,world.abilities.size(),world.current_id,int(cache[world.current_id].grid_pos[0]),int(cache[world.current_id].grid_pos[1]),world.active_enemies,world.sleeping_enemies]
        canvas.queue_redraw()
        minimap.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    var world: Node = get_parent()
    if not world.active:
        if GameConstants.ENABLE_DEBUG_TELEPORT and event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.physical_keycode in [KEY_0,KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9] and get_node("/root/GameState").active_character=="siyavash" and not get_node("/root/SceneManager").player_locked:
            get_node("/root/GameState").set_weapon("dagger")
            var number: int = 10 if event.physical_keycode==KEY_0 else event.physical_keycode-KEY_0
            for region: Dictionary in world.regions.values():
                if int(region.number)==number:world.enter.call_deferred(str(region.id)+"_00","left")
            get_viewport().set_input_as_handled()
        return
    if event is InputEventKey and event.pressed and event.ctrl_pressed and event.physical_keycode==KEY_M:
        minimap_enabled=not minimap_enabled
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("map_toggle") and not world.transitioning:
        if opened:close()
        elif not get_tree().paused and not get_node("/root/SceneManager").player_locked:
            opened=true
            previous_pause=get_tree().paused
            get_tree().paused=true
            panel.visible=true
            label.text="자불리스탄 · 방문 기록 / M 닫기"
            canvas.queue_redraw()
        get_viewport().set_input_as_handled()
    if not GameConstants.ENABLE_DEBUG_TELEPORT or not event is InputEventKey or not event.pressed or event.echo:return
    if get_node("/root/SceneManager").player_locked or world.transitioning or get_node("/root/Dialogue").active or get_node("/root/Cutscene").active:return
    if event.ctrl_pressed:get_viewport().set_input_as_handled()
    if event.ctrl_pressed and event.physical_keycode in [KEY_0,KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9]:
        if opened:close()
        var number: int = 10 if event.physical_keycode==KEY_0 else event.physical_keycode-KEY_0
        for region: Dictionary in world.regions.values():
            if int(region.number)==number:world.enter.call_deferred(str(region.id)+"_00","left")
    elif event.ctrl_pressed and event.physical_keycode==KEY_G:
        for id in world.abilities_data.abilities:world.abilities[id]=true
    elif event.ctrl_pressed and event.physical_keycode==KEY_B:world.abilities.clear()
    elif event.ctrl_pressed and event.physical_keycode==KEY_V:world.reveal_all=not world.reveal_all
    elif event.ctrl_pressed and event.physical_keycode==KEY_I:world.invulnerable=not world.invulnerable

func close() -> void:
    opened=false
    panel.visible=false
    get_tree().paused=previous_pause

func room_data(id: String) -> Dictionary:
    if not cache.has(id):
        var data: Dictionary = get_parent().read_json(str(get_parent().index[id]))
        cache[id]={"grid_pos":data.grid_pos,"region":data.region,"map":data.map,"exits":data.exits}
    return cache[id]

func draw_map(target: Control,small: bool) -> void:
    var world: Node = get_parent()
    if not world.active or world.current_id.is_empty():return
    var current: Dictionary = room_data(world.current_id)
    var cell: Vector2 = Vector2(1120./float(world.settings.map_grid[0]),480./float(world.settings.map_grid[1])) if not small else Vector2(40,28)
    for id in world.index:
        var room: Dictionary = room_data(str(id))
        var delta: Vector2 = Vector2(float(room.grid_pos[0]-current.grid_pos[0])/3,float(room.grid_pos[1]-current.grid_pos[1])/2)
        if small and (absf(delta.x)>2 or absf(delta.y)>2):continue
        var at: Vector2 = Vector2(float(room.grid_pos[0])/3,float(room.grid_pos[1])/2)*cell if not small else Vector2(100,56)+delta*cell
        var rect:=Rect2(at,cell-Vector2(3,3))
        if world.visited.has(id) or world.reveal_all:
            var color:=Color(str(world.regions[room.region].palette)).lightened(.25)
            target.draw_rect(rect,color)
            target.draw_rect(rect,Color(.5,.5,.5),false,1)
            for icon: Dictionary in room.map.icons:
                var p: Vector2 = rect.position+Vector2(float(icon.position[0])/3840,float(icon.position[1])/1440)*rect.size
                target.draw_circle(p,2,{"altar":Color.GOLD,"life":Color.LIGHT_CORAL,"gate":Color.ORANGE,"boss":Color.RED,"secret":Color.MEDIUM_PURPLE}.get(str(icon.kind),Color.CYAN))
            if id==world.current_id:
                var hero: NimrodPlayer = get_node("/root/SceneManager").player
                target.draw_circle(rect.position+hero.position/Vector2(3840,1440)*rect.size,4,Color.WHITE)
        else:
            for exit: Dictionary in current.exits:
                if exit.target_room==id:target.draw_rect(rect,Color(.4,.4,.45,.4),false,1)
