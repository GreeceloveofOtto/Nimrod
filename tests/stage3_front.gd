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
        npc.face_toward(npc.global_position.x - 220.0)
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
    _check(level.level_id == "CastleFront" and hero.hp == 123 and hero.global_position.x == 2100.0, "Front portal arrives at x2100 preserving HP")
    _check(level.camera_limits.end.x == 2600 and hero.camera.limit_right == 2600, "Front camera matches 2600 map")
    _check(is_zero_approx(level.doors["castle_front_exterior"].open_progress), "Arrival front door closes")
    _check(str(root.get_node("Audio")._bgm_name) == "castle_front", "Front map BGM selected")
    _check(get_nodes_in_group("enemies").is_empty(), "Split courtyard contains no enemies")
    var gate: GateController = level.doors["castle_great_gate"]
    _check(gate.auto_transition_level == "CastleOutskirts", "Great gate now connects split exterior")
    await manager.go_to("CastleOutskirts", "Spawn_FromGate")
    level = manager.current_level
    var outer: NPC = level.npcs["castle_gatekeeper_outer"]
    _check(outer.display_name == "문지기" and not outer.interactable, "Outer keeper retains noninteractive name tag")
    _check(get_nodes_in_group("enemies").size() == 15, "Outskirts reuses ten melee and five ranged beasts")
    var locked: DoorPortal = level.doors["downtown_passage_entrance"]
    _check(not locked.locked and locked.target_level == "DowntownPassage_F8", "Downtown entrance now connects top floor")
    hero.global_position = locked.global_position
    locked.interact(hero)
    await manager.transition_finished
    _check(manager.current_level.level_id == "DowntownPassage_F8" and hero.hp == 123, "Passage entry preserves HP")
    await manager.go_to("CastleFront", "Spawn_FromCastle")
    level = manager.current_level
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
