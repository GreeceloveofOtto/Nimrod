extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    for buff in [false,true]:
        root.get_node("GameState").reset_run(false)
        if buff:
            hero.apply_shamhat_blessing()
        hero.hp = 1
        await cutscene_node.play("skip_castle_return")
        _check(hero.hp==hero.get_max_hp(),"Time skip fully heals including current buffs")
        _check(manager.current_level.level_id=="CastleF1" and is_equal_approx(hero.position.x,760),"Wake location")
        _check(not manager.player_locked and not paused,"Input and time restored")
    await _finish("STAGE10_HEAL")
