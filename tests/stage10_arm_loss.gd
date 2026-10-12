extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(7)
    await _go("CedarBossRoom")
    var boss: Humbaba = get_nodes_in_group("enemies")[0]
    hero.global_position = Vector2(500,400) # airborne and rolling cannot evade cinematic strike
    hero.hp = 1
    hero.action = "roll"
    hero.roll_clock = .1
    boss._physics_process(.016)
    await _wait(.02)
    if cutscene_node.active:
        await cutscene_node.completed
    await process_frame
    _check(hero.hp==1,"Opening damage cannot kill HP1 hero")
    _check(story_state.is_flag("arm_lost") and hero.weapon=="axe" and hero.sprite_set=="axe_onearm","Forced axe and one-arm set")
    _check(not boss.opening_pending and not manager.player_locked,"Opening stagger ends")
    _check(hero.collider.shape.size==hero.STAND_BOX,"Forced rolling hit restores standing collider")
    hero.hp = 180
    await cutscene_node.play("opening_strike")
    _check(hero.hp==180,"Opening hit only once per run")
    root.get_node("GameState").set_weapon("staff")
    _check(hero.weapon=="axe","Other weapons disabled after arm loss")
    await _finish("STAGE10_ARM_LOSS")
