extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    await manager.go_to("CastleF2","Spawn_FromBelow")
    manager.current_level.safe_zones.clear()
    var enemy: EnemyBase = load("res://scripts/enemy_melee_beast.gd").new()
    enemy.position=Vector2(400,620)
    manager.current_level.add_child(enemy)
    enemy.set_physics_process(false)
    var marker: ThreatMarker = enemy.threat_marker
    _check(marker != null and marker.get_parent()==enemy,"All enemies receive marker")
    marker._process(.01)
    _check(marker.visible,"Live onscreen enemy marker visible")
    Input.action_press("threat_markers")
    marker._process(0)
    Input.action_release("threat_markers")
    _check(not ThreatMarker.globally_enabled and not marker.visible,"F2 toggles markers")
    ThreatMarker.globally_enabled=true
    enemy.state=EnemyBase.State.DEAD
    marker._process(.15)
    _check(not marker.visible and marker.dead_alpha==0,"Dead marker fades0.15")
    enemy.state=EnemyBase.State.WINDUP
    marker._process(.15)
    _check(marker.visible and marker.current_color.is_equal_approx(Color("FF5A44")),"Windup marker restored in bright warning red")
    manager.current_level.safe_zones.append(Rect2(0,0,1000,1000))
    marker._process(0)
    _check(not marker.visible,"Safe zones suppress markers")
    await _finish("STAGE6_THREAT_MARKER")
