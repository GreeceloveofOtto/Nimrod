extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    var locations: Array[Array] = [["CastleF1","Spawn_FromRearGate"],["CastleF2","Spawn_FromBelow"],["CastleF4","Spawn_FromBelow"],["VillaF3","Spawn_FromBelow"]]
    var total: int = 0
    for place: Array in locations:
        await manager.go_to(place[0],place[1])
        for npc: NPC in manager.current_level.npcs.values():
            total += 1
            npc.set_process(false)
            _check(npc.three_way and npc.textures.has("idle_front"), "Royal NPC has generated front clip")
            npc.pose = NPC.Pose.RIGHT
            npc.face_cooldown_left = 0.0
            hero.global_position.x = npc.global_position.x - 220
            npc._update_three_way()
            _check(npc.pose == NPC.Pose.LEFT and npc.visual.flip_h, "220px left chooses left side")
            _check(npc.visual_fade.visible and npc.visual.modulate.a == 0.0, "Direction changes crossfade instead of snapping")
            hero.global_position.x = npc.global_position.x
            npc._update_three_way()
            _check(npc.pose == NPC.Pose.LEFT, "Cooldown holds prior pose")
            await _wait(0.13)
            _check(not npc.visual_fade.visible and is_equal_approx(npc.visual.modulate.a,1.0), "Crossfade finishes at 0.12sec")
            npc.face_cooldown_left = 0.0
            npc._update_three_way()
            _check(npc.pose == NPC.Pose.FRONT and npc.current_clip == "idle_front" and not npc.visual.flip_h, "Within 140px chooses unflipped front")
            npc.face_cooldown_left = 0.0
            hero.global_position.x += 180
            npc._update_three_way()
            _check(npc.pose == NPC.Pose.FRONT, "140–220px hysteresis holds front")
            hero.global_position.x = npc.global_position.x + 220
            npc._update_three_way()
            _check(npc.pose == NPC.Pose.RIGHT and npc.current_clip == "idle", "220px right chooses right side")
            await _wait(0.13)
            npc.face_cooldown_left = 0.0
            npc.look_left = 0.0
            hero.global_position.x += 800
            npc._update_three_way()
            _check(npc.pose == NPC.Pose.FRONT and npc.look_left >= 4 and npc.look_left <= 8, "Far NPC looks around on random 4–8sec schedule")
            _check(npc.name_tag.get_parent() == npc and npc.name_tag.scale.x > 0, "Name tag is independent of pose flipping")
    _check(total == 7, "All seven royal NPCs use three directions")
    await manager.go_to("VillaF1","Spawn_FromGate")
    for npc: NPC in manager.current_level.npcs.values():
        _check(not npc.three_way and not npc.clip_data.has("idle_front"), "Toin sheets remain unchanged and two-way")
    await _finish("STAGE4_NPC_FACING")
