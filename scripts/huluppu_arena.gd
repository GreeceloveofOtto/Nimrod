extends Node
var bosses: Array[EnemyBase] = []
var major_owner: EnemyBase
var major_gap := 0.0
var opening := 0.0
var healing_clock := 0.0
var finished := false
var rows: Array[Dictionary] = []
var hud: CanvasLayer
func _ready() -> void:
    opening=float(get_node("/root/Odyssey").settings["crown_opening_seconds"])
    hud=CanvasLayer.new()
    hud.layer=16
    add_child(hud)
    var index:=0
    for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
        if enemy.get_parent()!=get_parent():continue
        bosses.append(enemy)
        enemy.set_meta("arena",self)
        enemy.died.connect(_boss_died)
        var panel:=Panel.new()
        panel.position=Vector2(390,18+index*37)
        panel.size=Vector2(520,30)
        var style:=StyleBoxFlat.new()
        style.bg_color=Color(.06,.06,.10,.93)
        style.border_color=Color(.72,.55,.28)
        style.set_border_width_all(1)
        panel.add_theme_stylebox_override("panel",style)
        hud.add_child(panel)
        var fill:=ColorRect.new()
        fill.color=Color(.5,.12,.19,.8)
        fill.position=Vector2(2,2)
        fill.size=Vector2(516,26)
        panel.add_child(fill)
        var label:=Label.new()
        label.position=Vector2(10,2)
        label.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
        label.add_theme_font_size_override("font_size",18)
        panel.add_child(label)
        rows.append({"boss":enemy,"fill":fill,"label":label})
        index+=1
    spawn_healing()
func _process(delta: float) -> void:
    if get_node("/root/Cutscene").active or get_node("/root/SceneManager").player_locked:return
    opening=maxf(0,opening-delta)
    major_gap=maxf(0,major_gap-delta)
    healing_clock+=delta
    if healing_clock>=float(get_node("/root/Odyssey").settings["heal_interval"]):
        healing_clock=0
        spawn_healing()
    for row: Dictionary in rows:
        var boss: EnemyBase=row["boss"]
        var hp: int=boss.hp if is_instance_valid(boss) else 0
        row["fill"].size.x=516.*float(hp)/float(boss.stats["hp"]) if is_instance_valid(boss) else 0
        row["label"].text="%s  %d"%[str(boss.stats["display_name"]) if is_instance_valid(boss) else "처치",hp]
func can_attack(boss: EnemyBase, major: bool=false) -> bool:
    if opening>0 or finished:return false
    if is_instance_valid(major_owner) and major_owner!=boss:return false
    return not major or major_gap<=0
func acquire(boss: EnemyBase) -> bool:
    if not can_attack(boss,true):return false
    major_owner=boss
    return true
func release(boss: EnemyBase) -> void:
    if major_owner==boss:
        major_owner=null
        major_gap=float(get_node("/root/Odyssey").settings["major_attack_gap"])
func spawn_healing() -> void:
    for pair: Array in get_node("/root/Odyssey").settings["heal_positions"]:
        var at:=Vector2(float(pair[0]),float(pair[1]))
        var found:=false
        for item in get_tree().get_nodes_in_group("healing_pickups"):
            if item.get_parent()==get_parent() and item.global_position.distance_to(at)<60:
                found=true
        if not found:
            var item: Node2D=load("res://scripts/healing_pickup.gd").new()
            item.position=at
            get_parent().add_child(item)
func _boss_died(boss: EnemyBase) -> void:
    release(boss)
    for other in bosses:
        if is_instance_valid(other) and other.hp>0:return
    if not finished:
        finished=true
        get_node("/root/Cutscene").play.call_deferred("huluppu_victory")
