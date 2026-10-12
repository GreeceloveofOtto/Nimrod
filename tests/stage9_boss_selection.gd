extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    for stage in [0,3,7,8]:
        story_state.debug_stage(stage)
        await _go("CedarBossRoom")
        var enemies: Array[Node] = get_nodes_in_group("enemies")
        _check(enemies.size()==(0 if stage==8 else 1),"Boss count at stage %d" % stage)
        if stage<8:
            _check(enemies[0].enemy_id==("humbaba" if stage==7 else "kala_ushumgal"),"Boss identity at stage %d" % stage)
            for frame in range(10):
                await physics_frame
            var boss: EnemyBase=enemies[0]
            _check(boss.is_on_floor(),"Selected boss spawns on collision floor")
            var region:=Rect2i(boss.visual.region_rect)
            var painted: Rect2i=boss.visual.texture.get_image().get_region(region).get_used_rect()
            var bottom: float=boss.visual.global_position.y+(boss.visual.offset.y-region.size.y*.5+painted.end.y)*boss.visual.scale.y
            _check(absf(bottom-boss.global_position.y)<=4,"Selected boss painted feet match floor within four pixels")
        else:
            _check(manager.current_level.doors["boss_arrival"].locked,"Stage10 Melammu must be absorbed before return")
    await _finish("STAGE9_BOSS_SELECTION")
