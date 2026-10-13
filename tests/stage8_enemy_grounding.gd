extends "res://tests/helpers/stage4_support.gd"
func _run() -> void:
    await _start()
    var report: Array[String] = []
    for id: String in manager.levels:
        var level: Dictionary = manager.levels[id]
        var spawn: String = str(level.spawns.keys()[0])
        await manager.go_to(id,spawn,{"instant": true})
        for i in range(10):
            await physics_frame
        for enemy: EnemyBase in get_nodes_in_group("enemies"):
            if enemy.enemy_id in ["sky_beast","gas_sac","wraith_ray","cedar_wisp","wall_diver","zu"]:
                continue
            _check(enemy.is_on_floor(),id+"/"+enemy.name+" ground collision")
            var ray := PhysicsRayQueryParameters2D.create(enemy.global_position-Vector2(0,4),enemy.global_position+Vector2(0,8),3,[enemy.get_rid()])
            var hit: Dictionary = enemy.get_world_2d().direct_space_state.intersect_ray(ray)
            _check(not hit.is_empty(),id+"/"+enemy.name+" surface within4px")
            var region := Rect2i(enemy.visual.region_rect)
            var painted: Rect2i = enemy.visual.texture.get_image().get_region(region).get_used_rect()
            var art_bottom: float = enemy.visual.global_position.y + (enemy.visual.offset.y - region.size.y * .5 + painted.end.y) * enemy.visual.scale.y
            _check(not hit.is_empty() and absf(art_bottom-float(hit.get("position",Vector2.ZERO).y)) <= 4,"Painted feet align with collision surface within4px")
            if enemy.enemy_id == "cedar_demon":
                _check(not hit.is_empty() and str(hit.collider.get_meta("art_path", "")).contains("cedar_branch"),"Demon stands on a visible branch")
            report.append(id+"/"+enemy.name+" floor="+str(enemy.is_on_floor()))
    var output := FileAccess.open("res://docs/STAGE8_GROUNDING_RUNTIME.txt",FileAccess.WRITE)
    output.store_string("RUNTIME "+str(checks)+" checks / "+str(failures)+" failures\n"+"\n".join(report))
    output.close()
    await _finish("STAGE8_ENEMY_GROUNDING")
