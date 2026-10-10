extends SceneTree

var checks: int = 0
var failures: int = 0
var manager: Node
var main: Node2D
var hero: NimrodPlayer
var cancelled_animation_returned: bool = false

func _initialize() -> void:
    _run.call_deferred()

func _check(value: bool, description: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("FAIL: " + description)

func _wait(seconds: float) -> void:
    await create_timer(seconds).timeout

func _await_cancelled_animation(door: DoorPortal) -> void:
    await door.animate_open(true, 1.0)
    cancelled_animation_returned = true

func _run() -> void:
    main = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main
    manager = root.get_node("SceneManager")
    await manager.transition_finished
    hero = manager.player
    hero.set_physics_process(false)
    await manager.go_to("CastleF1", "Spawn_FromRearGate")
    var level: LevelBase = manager.current_level
    _check(hero.get_node_or_null("NameTag") == null, "Player has no NPC name tag")
    for npc: NPC in level.npcs.values():
        var tag: PanelContainer = npc.get_node("NameTag")
        _check(tag.get_parent() == npc and tag.get_parent() != npc.visual, "Name tag stays on NPC root")
        _check(tag.get_child(0).text == npc.display_name, "Name tag matches Korean NPC name")
        _check(tag.z_index == 50 and is_equal_approx(tag.position.y, 14.0), "Name tag is below foot anchor")
        var settings: LabelSettings = tag.get_child(0).label_settings
        _check(settings.outline_size == 0 and settings.font_size == 18 and settings.shadow_offset == Vector2(1, 1), "Name styling uses only shadow")
        _check(settings.font == load("res://assets/fonts/NimrodUIKorean-Regular.otf"), "Same Korean font as HUD")
        var x: float = tag.position.x
        npc.face_cooldown_left = 0.0
        npc.face_toward(npc.global_position.x - 200.0)
        _check(npc.visual.flip_h and tag.scale.x > 0.0 and is_equal_approx(tag.position.x, x), "NPC flip does not mirror or move text")
        _check(npc.get_node("LightPool").material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "Generated light pool is additive")
        _check(is_equal_approx(npc.get_node("ContactShadow").modulate.a, 0.45), "Generated contact shadow keeps required alpha")
    var actor: NPC = level.npcs["lugalbanda"]
    hero.global_position = actor.global_position + Vector2(200, 0)
    await _wait(0.2)
    _check(is_equal_approx(actor.modulate.r, 1.12) and is_equal_approx(actor.name_tag.modulate.a, 1.0), "Within 220px NPC and name brighten in 0.15s")
    hero.global_position.x = 1800
    await _wait(0.2)
    _check(is_equal_approx(actor.modulate.r, 1.0) and is_equal_approx(actor.name_tag.modulate.a, 0.85), "Leaving range restores NPC/name")
    actor.display_name = "루갈반다 · 군주"
    await _wait(0.05)
    _check(is_equal_approx(actor.name_tag.position.x, -actor.name_tag.size.x * 0.5), "Changed name re-centers after layout")
    _check(level.get_node("Interior").modulate == level.bg_dim and level.doors["door_up"].modulate == Color.WHITE, "Only background is dimmed")
    await manager.go_to("CastleF3", "Spawn_FromBelow")
    level = manager.current_level
    for cook: NPC in level.npcs.values():
        _check(is_equal_approx(cook.visual.scale.x, 0.39), "All Toin cooks use exactly 1.30 display scale")
        _check(is_equal_approx(float(cook.stats["height_ratio"]), float(cook.stats["source_height_ratio"]) * 1.30), "Toin expected ratio includes multiplier once")
    await manager.go_to("CastleF1", "Spawn_FromRearGate")
    hero.hp = 123
    var door: DoorPortal = manager.current_level.doors["castle_front_gate"]
    _check(not door.locked and door.target_level == "CastleFront", "Castle front portal unlocked")
    hero.global_position = door.global_position
    door.interact(hero)
    await manager.transition_finished
    level = manager.current_level
    _check(level.level_id == "CastleFront" and hero.hp == 123 and hero.global_position.x == 3900.0, "Front portal arrives at x3900 preserving HP")
    _check(level.camera_limits.end.x == 4400 and hero.camera.limit_right == 4400, "Front camera matches 4400 map")
    _check(is_zero_approx(level.doors["castle_front_exterior"].open_progress), "Arrival front door closes")
    _check(str(root.get_node("Audio")._bgm_name) == "castle_front", "Front map BGM selected")
    var outer: NPC = level.npcs["castle_gatekeeper_outer"]
    var inner: VillaGatekeeper = level.npcs["castle_gatekeeper_inner"]
    _check(outer.display_name == "문지기" and inner.display_name == "문지기", "Both keepers display name tags")
    _check(not outer.interactable and outer.get_node_or_null("InteractionPrompt") == null, "Outer keeper has no E prompt")
    _check(inner.facing == -1 and not inner.face_player and not inner.gesture_face_player, "Inner keeper faces gate on left")
    var gate: GateController = level.doors["castle_great_gate"]
    _check(gate.auto_transition_level.is_empty() and gate.blocker.shape.size == Vector2(60, 440), "Great gate is a local passage with 60x440 blocker")
    _check(gate.gate_open_seconds == 1.2 and gate.gate_close_seconds == 1.0, "Great gate timing remains configurable")
    gate.set_process(false)
    hero.global_position = Vector2(2800, level.floor_y)
    for step in range(40):
        await physics_frame
        hero.velocity = Vector2(600, 0)
        hero.move_and_slide()
    _check(hero.global_position.x <= 2852.1, "Closed great gate physically blocks walking")
    hero.velocity = Vector2.ZERO
    hero.global_position.x = 3180
    inner.set_process(false)
    gate._process(0.0)
    _check(gate.gate_state == GateController.GateState.REQUESTED, "Approach from right requests keeper")
    inner.clip_clock = 0.31
    inner._refresh_visual()
    _check(gate.gate_state == GateController.GateState.REQUESTED, "Second gesture frame leaves gate shut")
    inner.clip_clock = 0.321
    inner._refresh_visual()
    _check(gate.gate_state == GateController.GateState.OPENING, "Third gesture frame starts gate")
    await _wait(0.65)
    _check(not gate.blocker.disabled, "Barrier stays while partially open")
    await _wait(0.65)
    _check(gate.blocker.disabled and inner.current_clip == "idle", "Fully open releases barrier and keeper")
    hero.global_position = Vector2(2800, level.floor_y)
    for step in range(40):
        await physics_frame
        hero.velocity = Vector2(600, 0)
        hero.move_and_slide()
    _check(hero.global_position.x > 3000, "Open great gate permits physical traversal")
    hero.velocity = Vector2.ZERO
    hero.global_position.x = 2900
    gate._process(0.0)
    _check(not manager.is_transitioning and not manager.player_locked and not gate.can_interact(hero), "Walking into great gate does not transition")
    hero.global_position.x = 3500
    gate._process(0.0)
    await _wait(1.05)
    _check(gate.gate_state == GateController.GateState.CLOSED and not gate.blocker.disabled, "600px departure closes great gate")
    hero.global_position.x = 2620
    gate._process(0.0)
    _check(gate.gate_state == GateController.GateState.REQUESTED, "Approach from left also requests gate")
    gate.requires_dialogue = true
    inner.clip_clock = 0.321
    inner._refresh_visual()
    _check(gate.gate_state == GateController.GateState.REQUESTED, "Dialogue TODO hook prevents gate start")
    var enemies: Array[Node] = get_nodes_in_group("enemies")
    _check(enemies.size() == 3, "Front map reuses two melee and one ranged beast")
    hero.global_position = Vector2(2400, level.floor_y)
    for enemy: EnemyBase in enemies:
        _check(not enemy._can_detect(hero), "Safe hero cannot be chased")
        enemy.global_position.x = 2350
        enemy._enforce_bounds()
        _check(enemy.get_hurt_rect().end.x <= 2300.01, "Whole enemy body clamped before safe courtyard")
    var locked: DoorPortal = level.doors["downtown_passage_entrance"]
    _check(locked.locked and locked.target_level == "DowntownPassage_F1", "Future downtown target stored behind lock")
    hero.global_position = locked.global_position
    locked.interact(hero)
    await _wait(0.03)
    _check(main.get_node("HUD").toast.text == "아직 들어갈 수 없다" and not manager.player_locked, "Downtown lock shakes/toasts without loading unknown scene")
    await _wait(0.30)
    door = level.doors["castle_front_exterior"]
    _await_cancelled_animation(door)
    await _wait(0.03)
    door.door_tween.kill()
    await _wait(1.05)
    _check(cancelled_animation_returned, "Killed door animation releases its waiting caller")
    hero.global_position = door.global_position
    door.interact(hero)
    await manager.transition_finished
    _check(manager.current_level.level_id == "CastleF1" and hero.global_position.x == 220.0 and hero.hp == 123, "Front return arrives F1 x220 preserving HP")
    manager.set_player_locked(true)
    for child in root.get_node("Audio").get_children():
        if child.has_method("stop"):
            child.call("stop")
    main.queue_free()
    await _wait(0.2)
    print("STAGE3_FRONT: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
