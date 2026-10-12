extends Node2D
# Attack telegraph UI only. Boss/world/FX artwork always comes from images.
func _process(_delta: float) -> void:
    queue_redraw()
func _draw() -> void:
    var boss: Gugalanna = get_parent() as Gugalanna
    if boss.state!=EnemyBase.State.WINDUP:
        return
    if boss.pattern=="stomp":
        draw_line(Vector2(-boss.global_position.x,-2),Vector2(2600-boss.global_position.x,-2),Color(1,.03,.02,.4),6)
    elif boss.pattern=="rake":
        var radius: float = float(boss.attack_stats["radius"])
        var height: float = float(boss.attack_stats["height"])
        var cap: float = asin(minf(1.,height/radius))
        var points := PackedVector2Array([Vector2.ZERO])
        for i in range(25):
            var angle: float = cap*float(i)/24
            points.append(Vector2(cos(angle)*radius*boss.facing,-sin(angle)*radius))
        points.append(Vector2(0,-height))
        draw_colored_polygon(points,Color(1,.03,.02,.18))
