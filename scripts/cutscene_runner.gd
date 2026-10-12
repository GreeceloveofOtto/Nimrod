extends Node

signal completed(cutscene_id: String)
signal step_started(kind: String)
var active := false
var settings: Dictionary = {}
var generation := 0
var actor_states: Dictionary = {}
var previous_pause := false
var saved_weapon_hidden := false
var timer: SceneTreeTimer
var motion: Tween
var timing_scale := 1.0
var current_id := ""
var audio_states: Dictionary = {}
var spawned_actors: Array[Node] = []

func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/cutscenes.json"))

func actor(actor_id: String) -> Node2D:
    if actor_id == "player":
        return get_node("/root/SceneManager").player
    for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
        if enemy.enemy_id == actor_id:
            return enemy
    if is_instance_valid(get_node("/root/SceneManager").current_level):
        return get_node("/root/SceneManager").current_level.npcs.get(actor_id) as Node2D
    return null

func _control(node: Node) -> void:
    if not is_instance_valid(node):
        return
    if not actor_states.has(node):
        actor_states[node] = {"mode": node.process_mode, "z": node.z_index if node is CanvasItem else 0}
        if node is NPC:
            actor_states[node].merge({"face":node.face_player, "cinematic":node.cinematic_control})
    node.process_mode = PROCESS_MODE_ALWAYS
    if node is NPC:
        node.cinematic_control = true

func _wait(seconds: float) -> void:
    timer = get_tree().create_timer(maxf(.001, seconds * timing_scale), true)
    await timer.timeout
    timer = null

func play(cutscene_id: String) -> bool:
    if active or not settings.get("cutscenes", {}).has(cutscene_id) or not is_instance_valid(get_node("/root/SceneManager").player):
        return false
    active = true
    current_id = cutscene_id
    spawned_actors.clear()
    generation += 1
    var token: int = generation
    previous_pause = get_tree().paused
    audio_states = get_node("/root/Audio").pause_world_sfx()
    saved_weapon_hidden = get_node("/root/SceneManager").player.visual_weapon_hidden
    get_node("/root/Chapter").saved_camera_zoom = get_node("/root/SceneManager").player.camera.zoom
    get_tree().paused = true
    _control(get_node("/root/SceneManager"))
    _control(get_node("/root/SceneManager").player)
    get_node("/root/SceneManager").set_player_locked(true)
    for step: Dictionary in settings["cutscenes"][cutscene_id]:
        if generation != token or not is_instance_valid(get_node("/root/SceneManager").player):
            break
        step_started.emit(str(step["type"]))
        await _step(step)
    var succeeded: bool = token == generation
    _restore()
    if succeeded and cutscene_id == "villa_dinner" and get_node("/root/Story").settings.get("objective_toast", true):
        get_node("/root/SceneManager").show_toast(str(get_node("/root/Story").settings["objective_text"]), float(get_node("/root/Story").settings["objective_seconds"]))
    completed.emit(cutscene_id)
    return succeeded

func _step(step: Dictionary) -> void:
    var node: Node2D = actor(str(step.get("actor", "player")))
    var level: LevelBase = get_node("/root/SceneManager").current_level as LevelBase
    match str(step["type"]):
        "time_skip":
            await get_node("/root/Chapter").time_skip(str(step["id"]))
        "story_event":
            await get_node("/root/Chapter").event(str(step["event"]))
        "fade_actor":
            if is_instance_valid(node):
                _control(node)
                motion = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
                motion.tween_property(node, "modulate:a", 0., float(step["seconds"])*timing_scale)
                await motion.finished
        "sound":
            get_node("/root/Chapter").cutscene_sound(str(step["id"]))
        "bgm":
            get_node("/root/Audio").play_bgm(str(step["id"]))
        "zoom":
            var camera: Camera2D = get_node("/root/SceneManager").player.camera
            _control(camera)
            motion = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
            motion.tween_property(camera, "zoom", Vector2.ONE*float(step["to"]), float(step["seconds"])*timing_scale)
            await motion.finished
        "walk_fade":
            if is_instance_valid(node):
                _control(node)
                node.cinematic_clip = "walk"
                node.cinematic_clock = 0
                node.facing = 1 if float(step["x"]) >= node.global_position.x else -1
                motion = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
                motion.tween_property(node, "global_position:x", float(step["x"]), float(step["seconds"])*timing_scale)
                motion.tween_property(get_node("/root/SceneManager")._fade_rect, "modulate:a", 1., float(step["fade_seconds"])*timing_scale)
                await motion.finished
        "lock_player":
            get_node("/root/SceneManager").set_player_locked(true)
        "unlock_player":
            pass # The finalizer releases input only after every step completes.
        "wait":
            await _wait(float(step["seconds"]))
        "set_weapon_visibility":
            get_node("/root/SceneManager").player.set_weapon_visibility(bool(step["hidden"]))
        "face":
            if is_instance_valid(node):
                _control(node)
                node.facing = int(step["dir"])
                if node is NPC:
                    node.pose = node.facing
        "play_clip":
            if is_instance_valid(node):
                _control(node)
                var clip: String = str(step["clip"])
                if clip.begins_with("sit"):
                    if not actor_states[node].has("seat_y"):
                        actor_states[node]["seat_y"] = node.global_position.y
                        actor_states[node]["seat_level"] = level.level_id
                    node.global_position.y = float(actor_states[node]["seat_y"]) + float(get_node("/root/Story").settings["dinner_seat"]["y_offset"])
                    node.z_index = -3
                elif clip == "stand_up":
                    if actor_states[node].has("seat_y"):
                        node.global_position.y = float(actor_states[node]["seat_y"])
                        actor_states[node].erase("seat_y")
                    node.z_index = int(actor_states[node]["z"])
                if node is NPC:
                    node.play_clip(clip)
                elif node is EnemyBase:
                    node.cinematic_clip = clip
                    node.cinematic_clock = 0
                    node._show_clip(clip, 0)
                elif node is NimrodPlayer:
                    node.cinematic_clip = clip
                    node.cinematic_clock = 0
                    node._show_clip(clip, 0)
                if not bool(step.get("loop", false)):
                    await _wait(float(node.clip_data.get(clip, {}).get("duration_seconds", .35)))
        "walk_to":
            if is_instance_valid(node):
                _control(node)
                var destination: float = float(step["x"])
                node.facing = 1 if destination >= node.global_position.x else -1
                if node is NPC:
                    node.pose = node.facing
                    node.play_clip("walk")
                elif node is EnemyBase:
                    node._show_clip("walk", 0)
                else:
                    node.cinematic_clip = "walk"
                    node.cinematic_clock = 0
                motion = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
                motion.tween_property(node, "global_position:x", destination, float(step["seconds"]) * timing_scale)
                await motion.finished
        "door_open", "door_close":
            if is_instance_valid(level):
                var door: DoorPortal = level.doors.get(str(step["door_id"])) as DoorPortal
                if is_instance_valid(door):
                    _control(door)
                    await door.animate_open(str(step["type"]) == "door_open", float(step.get("seconds", .6)) * timing_scale)
        "spawn_npc":
            if is_instance_valid(level):
                var entry: Dictionary = step["npc"]
                level.spawn_npc(entry)
                var spawned: Node = actor(str(entry.get("instance_id", entry["id"])))
                spawned_actors.append(spawned)
                _control(spawned)
        "despawn_npc":
            if is_instance_valid(level) and is_instance_valid(node):
                level.npcs.erase(str(step["actor"]))
                node.get_parent().remove_child(node)
                node.queue_free()
        "dialogue":
            await get_node("/root/Dialogue").play_interaction(str(step["interaction_id"]))
        "fade":
            await get_node("/root/SceneManager")._fade_to(float(step["alpha"]), float(step["seconds"]) * timing_scale)
        "set_flag":
            get_node("/root/Story").set_flag(str(step["flag"]))
        "teleport_player":
            await get_node("/root/SceneManager").go_to(str(step["level"]), str(step["spawn"]), {"instant":true, "preserve_fade":true})
            get_node("/root/SceneManager").set_player_locked(true)

func _restore() -> void:
    for node in actor_states:
        if is_instance_valid(node):
            node.process_mode = actor_states[node]["mode"]
            if node is CanvasItem:
                node.z_index = actor_states[node]["z"]
            if node is Node2D and actor_states[node].has("seat_y") and actor_states[node]["seat_level"] == get_node("/root/SceneManager").current_level.level_id:
                node.global_position.y = float(actor_states[node]["seat_y"])
            if node is EnemyBase:
                node.cinematic_clip = ""
            if node is NPC:
                node.face_player = actor_states[node]["face"]
                node.cinematic_control = actor_states[node]["cinematic"]
                node.play_clip("idle_front" if node.three_way and node.pose == NPC.Pose.FRONT else node.idle_clip)
    actor_states.clear()
    get_node("/root/Chapter").finish_cutscene()
    if is_instance_valid(get_node("/root/SceneManager").player):
        get_node("/root/SceneManager").player.cinematic_clip = ""
        get_node("/root/SceneManager").player.set_weapon_visibility(saved_weapon_hidden)
        get_node("/root/SceneManager").player.modulate.a = 1
        get_node("/root/SceneManager").player.velocity = Vector2.ZERO
    get_node("/root/SceneManager")._fade_rect.modulate.a = 0
    get_node("/root/Audio").restore_world_sfx(audio_states)
    audio_states.clear()
    get_tree().paused = previous_pause
    active = false
    spawned_actors.clear()
    get_node("/root/SceneManager").set_player_locked(false)

func cancel() -> void:
    if not active:
        return
    generation += 1
    get_node("/root/Dialogue").cancel()
    var fade: Tween = get_node("/root/SceneManager")._fade_tween
    if is_instance_valid(fade) and fade.is_valid():
        fade.kill()
        fade.finished.emit()
    for controlled in actor_states:
        if is_instance_valid(controlled) and controlled is DoorPortal:
            if is_instance_valid(controlled.door_tween):
                controlled.door_tween.kill()
            controlled._set_open_progress(0)
    var level: LevelBase = get_node("/root/SceneManager").current_level as LevelBase
    for spawned in spawned_actors:
        if is_instance_valid(spawned):
            if is_instance_valid(level):
                level.npcs.erase(spawned.npc_id)
            spawned.queue_free()
    if current_id == "villa_dinner" and not get_node("/root/Story").is_flag("villa_dinner_done"):
        get_node("/root/GameState").run_flags.erase("story_dialogue_villa_dinner")
    if timer != null:
        timer.timeout.emit()
        timer = null
    if is_instance_valid(motion) and motion.is_valid():
        motion.kill()
        motion.finished.emit()
    _restore()
