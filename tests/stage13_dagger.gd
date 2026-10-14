extends "res://tests/helpers/stage9_support.gd"

func _run() -> void:
    await _start9()
    var state: Node = root.get_node("GameState")
    var dialogue: Node = root.get_node("Dialogue")
    var save: Node = root.get_node("Save")
    save.save_path = "user://stage13_dagger.json"
    var original_weapon: String = state.get_weapon()
    story_state.debug_stage(20)
    state.switch_character("siyavash")
    await _go("HwaniraPlaza")
    hero.set_physics_process(false)
    hero.position = Vector2(1890, 880)
    var text: Array = ["시야우와르샨, 그동안 수고했어. 사실 나에게도 힘든 과정이었지.", "그래서 오늘은 교육을 쉬고, 나와 함께 자불리스탄으로 가자.", "정말요? 드디어, 자불리스탄이 가볼 수 있는 겁니까?", "그래, 어서가자. 꽤 먼 길이다.", "맞다, 참. 지금까지의 과정을 통과했다는 의미에서 주는 선물이다. 내가 예전에 마잔다란에서 얻었던 물건인데, 내 손에는 맞지 않아서 새 것이나 다름없지."]
    var spec: Dictionary = dialogue.resolve_interaction("laodastahma_talk")
    for i in range(5):
        _check(spec["first"][i]["text"] == text[i], "Exact authored dialogue line " + str(i + 1))
    _check(spec["repeat"][0]["text"] == text[3], "Repeat fourth line unchanged")
    _check(manager.current_level.npcs.size() == 6, "Six plaza heroes")
    var boxes: Array[Rect2] = []
    for npc: NPC in manager.current_level.npcs.values():
        _check(npc.global_position.y == 880 and not npc.textures.is_empty() and not npc.missing_visual.visible, "Grounded generated NPC " + npc.npc_id)
        _check(npc.interactable == (npc.npc_id == "laodastahma"), "Teacher-only interaction " + npc.npc_id)
        _check(npc.has_node("LightPool") and npc.has_node("NameTag"), "Readability helpers " + npc.npc_id)
        var texture_image: Image = npc.visual.texture.get_image()
        var bounds: Rect2i = texture_image.get_region(Rect2i(npc.visual.region_rect)).get_used_rect()
        var foot_y: float = npc.visual.position.y + (npc.visual.offset.y + bounds.position.y + bounds.size.y - texture_image.get_region(Rect2i(npc.visual.region_rect)).get_height() * .5) * npc.visual.scale.y
        _check(absf(foot_y) <= 4, "Visible boots within4px of ground " + npc.npc_id)
        var size_px: Vector2 = AssetVisual.frame_display_size(npc.visual.texture, npc.clip_data[npc.current_clip], Vector2.ONE * .3)
        var box := Rect2(npc.global_position + Vector2(-size_px.x / 2, -size_px.y), size_px)
        for other in boxes:_check(not box.intersects(other), "Hero silhouettes do not overlap")
        boxes.append(box)
    dialogue.test_timing_scale = .005
    dialogue.play_interaction("laodastahma_talk")
    while dialogue.active or dialogue.dagger_gift_running:
        dialogue.skip_line()
        await process_frame
    await _wait(.05)
    _check(dialogue.dagger_gift_count == 1 and not paused and not manager.player_locked, "Skipped dialogue executes gift exactly once and unlocks input")
    _check(hero.weapon == "dagger" and hero.max_step == 5, "Dagger autoequipped")
    _check(manager.main.get_node("HUD").dagger_icon.visible and manager.main.get_node("HUD").toast.text == "J: 5연타 콤보", "Dagger HUD and help toast updated")
    _check(story_state.is_flag("dagger_acquired") and story_state.is_flag("laodastahma_talk_done") and story_state.stage() == 21, "Stage21 flags")
    _check(state.run_flags["weapon"] == original_weapon, "Nimrod weapon unaffected")
    var teacher: NPC = manager.current_level.npcs["laodastahma"]
    await dialogue.give_dagger(teacher, hero)
    _check(dialogue.dagger_gift_count == 1, "Gift duplicate rejected")
    root.get_node("World").timing_scale=.001
    await dialogue.play_interaction("laodastahma_talk")
    _check(dialogue.dagger_gift_count == 1 and dialogue.name_label.text == "라오다스타흐마", "Repeat remains available without duplicate gift")
    await _wait(.05)
    while cutscene_node.active:await process_frame
    _check(root.get_node("World").active,"Repeat travel starts world")
    await _go("HwaniraPlaza")
    hero.position=Vector2(1890,880)
    _check(hero.textures["idle"] == load("res://assets/sprites/player/siyavash/idle.webp") and hero.textures["roll"] == load("res://assets/sprites/player/siyavash/roll.webp"), "Shared nonattack textures use ResourceLoader cache")
    _check(hero.clip_data.size() == 26 and hero.clip_data.has("attack_5"), "Five attacks plus twenty-one reused movement clips")
    var values: Array = [14,14,16,18,22]
    var durations: Array = [.24,.24,.28,.30,.42]
    var total := 0
    for i in range(1,6):
        _check(hero.attack_data[i]["damage"] == values[i-1], "Dagger damage " + str(i))
        _check(is_equal_approx(hero.attack_data[i]["duration"], durations[i-1]) and is_equal_approx(hero.clip_data["attack_" + str(i)]["duration_seconds"], durations[i-1]), "Dagger motion and attack duration match " + str(i))
        _check(hero.clip_data["attack_" + str(i)]["frames"] == (6 if i == 5 else 4), "Frame count " + str(i))
        total += int(hero.attack_data[i]["damage"])
        hero._begin_attack(i)
        hero._update_attack(float(hero.attack_data[i]["duration"]) + .01)
        _check(hero.action == "normal", "Attack " + str(i) + " completes")
    _check(total == 84 and hero.shockwave_data["damage"] == 20 and hero.shockwave_data["hitbox"]["width"] == 160, "84 plus 20 wave equals104")
    _check(hero.shockwave_done and hero.weapon_hitstop == .04, "Fifth strike emits wave and uses .04 hitstop")
    hero._begin_attack(1)
    hero.air_direction_cancels = 0
    hero.facing = 1
    hero._direction_cancel_attack(-1)
    _check(hero.facing == -1 and hero.attack_step == 5 and hero.air_direction_cancels == 1, "Air cancellation uses final strike")
    hero._direction_cancel_attack(1)
    hero._direction_cancel_attack(-1)
    _check(hero.facing == 1 and hero.air_direction_cancels == 2, "Air cancellation limit two")
    hero._cancel_attack()
    var target := EnemyBase.new()
    target.enemy_id = "melee_beast"
    manager.current_level.add_child(target)
    target.set_physics_process(false)
    target.global_position = hero.global_position + Vector2(50, 0)
    target.hp = 1000
    target.stats["knockback_multiplier"] = 1.0
    await physics_frame
    await physics_frame
    await process_frame
    hero.facing = 1
    hero._begin_attack(5)
    hero._update_attack(.16)
    var trail_count := 0
    for effect: Node in hero.get_parent().get_children():
        if effect.get_meta("dagger_trail", false):trail_count += 1
    _check(trail_count > 0, "Generated light FX reused for active dagger trail")
    print("DAGGER_DAMAGE_FIXTURE: hp=", target.hp, " hero=", hero.global_position, " target=", target.get_hurt_rect(), " hit=", hero._attack_rect(), " action=", hero.action)
    _check(target.hp == 978, "Final dagger strike deals22")
    hero._update_attack(.14)
    _check(target.hp == 958 and hero.shockwave_done, "Wave independently deals20 to same target")
    _check(target.velocity.x == 80 and target.stun_left <= .1501, "Wave uses80 knockback and .15 stagger")
    target.queue_free()
    await process_frame
    hero._cancel_attack()
    hero.set_physics_process(true)
    await physics_frame
    await physics_frame
    hero.set_physics_process(false)
    _check(hero.is_on_floor(), "Grounded combo fixture")
    hero._begin_attack(1)
    for step in range(1,5):
        hero.buffered_attack = true
        hero._update_attack(float(hero.attack_data[step]["duration"]) + .01)
        _check(hero.attack_step == step + 1, "Buffered grounded combo reaches " + str(step + 1))
    hero._cancel_attack()
    _check(save.save_checkpoint("character"), "Dagger checkpoint")
    _check(await save.resume(), "Dagger checkpoint restores")
    _check(hero.weapon == "dagger" and hero.max_step == 5 and state.siyavash_progress["weapon"] == "dagger", "Independent weapon survives reload")
    var old: Dictionary = save.snapshot_data()
    old["siyavash_progress"] = {"siyavash_started":true,"system_laochachahra_selected":true}
    _check(save.migrate_save(old)["story_stage"] == 20 and not save.migrate_save(old)["siyavash_progress"].has("weapon"), "Old stage20 save remains unarmed")
    state.switch_character("nimrod")
    _check(hero.weapon == original_weapon and hero.max_step == 4, "Nimrod axe restored")
    save.erase_save()
    await _finish("STAGE13_DAGGER")
