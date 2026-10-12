extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var chapter: Node = root.get_node("Chapter")
    var expected: Dictionary = {"castle_return":"", "home_5days":"5일 후", "home_11days":"11일 후", "home_after_loss":"오랜 시간이 흐른 뒤", "after_gugalanna":"오랜 시간이 흐른 뒤", "to_dilmun":"오랜 시간이 흐른 뒤"}
    for id in expected:
        story_state.debug_stage(14)
        var spec: Dictionary = chapter.skips["skips"][id]
        _check(spec["caption"]==expected[id],"Exact caption "+id)
        await cutscene_node.play("skip_"+id)
        _check(manager.current_level.level_id==spec["spawn"]["level"],"Time skip destination "+id)
        _check(not chapter.caption.visible and not manager.player_locked and manager._fade_rect.modulate.a==0,"Caption/fade/input restored "+id)
    await _finish("STAGE10_TIME_SKIPS")
