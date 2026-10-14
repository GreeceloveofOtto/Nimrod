class_name EnemyBase
extends CharacterBody2D

signal damaged(amount: int, hp: int)
signal died(enemy: EnemyBase)

enum State { IDLE, CHASE, WINDUP, ACTIVE, RECOVERY, TURN, STUN, DEAD }

const STATS_PATH: String = "res://data/enemies.json"
const PLAYER_ATTACKS_PATH: String = "res://data/player_attacks.json"
const IMAGE_EFFECT = preload("res://scripts/image_effect.gd")
const HIT_SPARK_PATH: String = "res://assets/sprites/fx/hit_spark.webp"
const HIT_SPARK_FRAME_SIZE: Vector2i = Vector2i(256, 256)
const HIT_SPARK_FRAMES: int = 5
const ENEMY_LAYER: int = 4
const SURFACE_MASK: int = 3
const FALLBACK_ANCHOR: Vector2 = Vector2(320, 600)
const FALLBACK_FRAME_SIZE: Vector2 = Vector2(640, 640)
const TIME_EPSILON: float = 0.000001

@export var enemy_id: String = "melee_beast"
@export var room_bounds: Rect2 = Rect2()
@export var patrol_center: float = -1.0
@export var patrol_range: float = 250.0
@export var safe_min_x: float = 200.0
@export var safe_max_x: float = 3400.0

var stats: Dictionary = {}
var common: Dictionary = {}
var attack_stats: Dictionary = {}
var player_attack_stats: Dictionary = {}
var hp: int = 0
var state: State = State.IDLE
var state_clock: float = 0.0
var facing: int = 1
var pending_facing: int = 1
var turn_flip_applied: bool = false
var hitstop_left: float = 0.0
var stun_left: float = 0.0
var stun_immunity_left: float = 0.0
var recovery_after_stun: float = 0.0
var recovery_duration: float = 0.0
var attack_cooldown_left: float = 0.0
var attack_has_hit: bool = false
var debug_hitboxes: bool = false
var body_size: Vector2 = Vector2.ONE
var visual: Sprite2D
var missing_visual: Node2D
var collider: CollisionShape2D
var textures: Dictionary = {}
var clip_data: Dictionary = {}
var displayed_clip: String = ""
var display_clock: float = 0.0
var current_frame: int = 0
var ignored_player: PhysicsBody2D
var returning_to_patrol: bool = false
var clip_aliases: Dictionary = {}
var no_drop: bool = false
var cinematic_clip := ""
var cinematic_clock := 0.0
var threat_marker: Node2D
var _clip_warnings: Dictionary = {}
var _queued_player_effects: Array[Callable] = []

func _ready() -> void:
    collision_layer = ENEMY_LAYER
    collision_mask = SURFACE_MASK
    add_to_group("enemies")
    _load_stats()
    hp = int(stats.get("hp", 1))
    var dimensions: Array = stats.get("body_size", [1.0, 1.0])
    body_size = Vector2(float(dimensions[0]), float(dimensions[1]))
    if patrol_center < 0.0:
        patrol_center = global_position.x
    collider = CollisionShape2D.new()
    collider.name = "Hurtbox"
    var shape := RectangleShape2D.new()
    shape.size = body_size
    collider.shape = shape
    collider.position.y = float(stats.get("body_offset_y", -body_size.y * 0.5))
    add_child(collider)
    visual = Sprite2D.new()
    visual.name = "Visual"
    visual.region_enabled = true
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    visual.scale = Vector2.ONE * float(stats.get("visual_scale", 0.33))
    add_child(visual)
    _load_sprites()
    _create_missing_visual()
    _show_clip("idle", 0.0)
    _target()
    threat_marker = load("res://scripts/threat_marker.gd").new()
    threat_marker.name = "ThreatMarker"
    add_child(threat_marker)

func _read_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("Missing data: " + path)
        return {}
    var value: Variant = JSON.parse_string(file.get_as_text())
    if not value is Dictionary:
        push_warning("Invalid data: " + path)
        return {}
    return value as Dictionary

func _load_stats() -> void:
    var data: Dictionary = _read_json(STATS_PATH)
    common = data.get("common", {})
    for candidate in data.get("enemies", []):
        if str(candidate.get("id", "")) == enemy_id:
            stats = candidate.duplicate(true)
            _scale_stats(stats)
            break
    if stats.is_empty():
        push_warning("Enemy stats missing: " + enemy_id)
    var attacks: Array = stats.get("attacks", [])
    if not attacks.is_empty():
        attack_stats = attacks[0]
    player_attack_stats = _read_json(PLAYER_ATTACKS_PATH)

func _load_sprites() -> void:
    var folder: String = "res://assets/sprites/enemies/" + enemy_id + "/"
    var manifest: Dictionary = _read_json(folder + "manifest.json")
    clip_aliases = manifest.get("aliases", {})
    for entry in manifest.get("clips", []):
        var clip: Dictionary = entry
        var clip_name: String = str(clip.get("name", ""))
        clip_data[clip_name] = clip
        var sheet: String = str(clip.get("sheet", clip_name + ".png"))
        var path: String = folder + sheet
        if sheet.begins_with("res://"):
            path = sheet
        elif sheet.begins_with("sprites/"):
            path = "res://assets/" + sheet
        if not ResourceLoader.exists(path):
            push_warning("MISSING_TEXTURE: " + path)
            continue
        var texture: Texture2D = load(path) as Texture2D
        if texture != null:
            textures[clip_name] = texture

func _create_missing_visual() -> void:
    missing_visual = Node2D.new()
    missing_visual.name = "MISSING_TEXTURE"
    add_child(missing_visual)
    var box := ColorRect.new()
    box.color = Color.GRAY
    box.position = _local_hurt_rect().position
    box.size = body_size
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    missing_visual.add_child(box)
    var label := Label.new()
    label.text = "MISSING"
    label.position = box.position
    label.size = body_size
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    missing_visual.add_child(label)

func _physics_process(delta: float) -> void:
    if not cinematic_clip.is_empty():
        cinematic_clock += delta
        _show_clip(cinematic_clip, cinematic_clock)
        return
    if Input.is_action_just_pressed("debug_hitbox"):
        debug_hitboxes = not debug_hitboxes
        queue_redraw()
    if debug_hitboxes:
        queue_redraw()
    attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
    stun_immunity_left = maxf(0.0, stun_immunity_left - delta)
    if state == State.DEAD:
        _update_dead(delta)
        return
    if hitstop_left > 0.0:
        hitstop_left = maxf(0.0, hitstop_left - delta)
        if hitstop_left <= TIME_EPSILON:
            hitstop_left = 0.0
        return

    state_clock += delta
    match state:
        State.IDLE:
            _update_idle(delta)
        State.CHASE:
            _update_chase(delta)
        State.WINDUP:
            _update_windup(delta)
        State.ACTIVE:
            _update_active(delta)
        State.RECOVERY:
            _update_recovery(delta)
        State.TURN:
            _update_turn(delta)
        State.STUN:
            _update_stun(delta)
    _integrate_motion(delta)
    _enforce_bounds()
    _update_visual(delta)

func _integrate_motion(delta: float) -> void:
    velocity.y = minf(float(common.get("max_fall_speed", 1100.0)), velocity.y + float(common.get("gravity", 1750.0)) * delta)
    move_and_slide()

func _level() -> Node:
    return get_tree().get_first_node_in_group("current_level")

func _target() -> Node2D:
    var candidate: Node = get_tree().get_first_node_in_group("player")
    if candidate is Node2D and int(candidate.get("hp")) > 0:
        # The existing player occupies layer 1, which is also a floor layer.
        # Keep the required masks and explicitly exclude only the player body.
        if candidate is PhysicsBody2D and ignored_player != candidate:
            ignored_player = candidate as PhysicsBody2D
            add_collision_exception_with(ignored_player)
            ignored_player.add_collision_exception_with(self)
        return candidate as Node2D
    return null

func _player_is_available(player: Node2D) -> bool:
    if player == null:
        return false
    if player.has_method("is_transition_locked") and bool(player.call("is_transition_locked")):
        return false
    var level: Node = _level()
    if level != null and level.has_method("is_point_safe"):
        if bool(level.call("is_point_safe", player.global_position)):
            return false
    return true

func _can_detect(player: Node2D) -> bool:
    return not returning_to_patrol and _player_is_available(player) and global_position.distance_to(player.global_position) <= float(stats.get("detect_range", 0.0))

func _update_idle(delta: float) -> void:
    var player: Node2D = _target()
    if _can_detect(player):
        _set_state(State.CHASE)
        return
    _return_to_patrol(delta)

func _return_to_patrol(delta: float) -> void:
    var bounds: Vector2 = _ground_roam_bounds()
    var home: float = clampf(patrol_center, bounds.x, bounds.y)
    var difference: float = home - global_position.x
    if absf(difference) <= float(common.get("patrol_arrival_distance", 4.0)):
        _brake(delta)
        returning_to_patrol = false
        return
    var direction: int = 1 if difference > 0.0 else -1
    if direction != facing:
        _request_turn(direction)
        _brake(delta)
    else:
        velocity.x = direction * float(stats.get("move_speed", 0.0))

func _update_chase(delta: float) -> void:
    _brake(delta)

func _update_windup(delta: float) -> void:
    _brake(delta)
    if state_clock >= float(attack_stats.get("windup", 0.0)):
        _begin_active()

func _update_active(delta: float) -> void:
    _brake(delta)
    if state_clock >= float(attack_stats.get("active", 0.0)):
        _finish_active()

func _update_recovery(delta: float) -> void:
    _brake(delta)
    if state_clock >= recovery_duration:
        recovery_after_stun = 0.0
        _set_state(State.CHASE if _can_detect(_target()) else State.IDLE)

func _update_turn(delta: float) -> void:
    _brake(delta)
    var delay: float = _turn_seconds()
    # Four equally timed frames: index 2 (the third frame) begins at halfway.
    var frames: int = maxi(3, int(clip_data.get("turn", {}).get("frames", 4)))
    if not turn_flip_applied and state_clock >= delay * 2.0 / frames:
        facing = pending_facing
        visual.flip_h = facing < 0
        turn_flip_applied = true
    if state_clock >= delay:
        _set_state(State.CHASE if _can_detect(_target()) else State.IDLE)

func _update_stun(delta: float) -> void:
    _brake(delta)
    stun_left = maxf(0.0, stun_left - delta)
    if stun_left <= 0.0:
        if state_clock >= float(common.get("max_stun_seconds", 0.6)) - delta:
            stun_immunity_left = float(common.get("stun_cap_grace_seconds", 0.12))
        if recovery_after_stun > 0.0:
            _begin_recovery(recovery_after_stun)
        else:
            _set_state(State.CHASE if _can_detect(_target()) else State.IDLE)

func _brake(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, float(common.get("knockback_friction", 2400.0)) * delta)

func _ground_roam_bounds() -> Vector2:
    var low: float = safe_min_x + body_size.x * 0.5
    var high: float = safe_max_x - body_size.x * 0.5
    var level: Node = _level()
    if level != null and level.has_method("get_enemy_roam_bounds"):
        var allowed: Vector2 = level.call("get_enemy_roam_bounds", Vector2(patrol_center, global_position.y), body_size)
        low = allowed.x
        high = allowed.y
    low = maxf(low, patrol_center - patrol_range)
    high = minf(high, patrol_center + patrol_range)
    if low > high:
        high = low
    return Vector2(low, high)

func _enforce_bounds() -> void:
    if room_bounds.has_area():
        var old_x: float = global_position.x
        global_position.x = clampf(global_position.x, room_bounds.position.x + body_size.x * 0.5, room_bounds.end.x - body_size.x * 0.5)
        if not is_equal_approx(old_x, global_position.x):
            velocity.x = 0
    var bounds: Vector2 = _ground_roam_bounds()
    var attempted_x: float = global_position.x
    global_position.x = clampf(global_position.x, bounds.x, bounds.y)
    if (global_position.x <= bounds.x and velocity.x < 0.0) or (global_position.x >= bounds.y and velocity.x > 0.0):
        velocity.x = 0.0
        if state == State.CHASE:
            returning_to_patrol = true
            _set_state(State.IDLE)
    # Bounds are applied after physics, including knockback frames.
    if attempted_x != global_position.x and state == State.IDLE:
        returning_to_patrol = true

func _set_state(next: State) -> void:
    state = next
    state_clock = 0.0
    display_clock = 0.0

func _request_turn(direction: int) -> void:
    if direction == facing or state in [State.WINDUP, State.ACTIVE, State.RECOVERY, State.STUN, State.DEAD]:
        return
    pending_facing = direction
    turn_flip_applied = false
    _set_state(State.TURN)

func _turn_seconds() -> float:
    return float(stats.get("turn_delay", 0.0))

func _begin_attack() -> void:
    attack_has_hit = false
    _set_state(State.WINDUP)
    _play_sfx("beast_" + _audio_kind() + "_windup")

func _begin_active() -> void:
    _set_state(State.ACTIVE)

func _finish_active() -> void:
    _begin_recovery(float(attack_stats.get("recovery", 0.0)))

func _begin_recovery(seconds: float) -> void:
    recovery_duration = seconds
    recovery_after_stun = 0.0
    _set_state(State.RECOVERY)

func _audio_kind() -> String:
    return "ranged" if enemy_id == "ranged_beast" else "melee"

func _play_sfx(sound_name: String) -> Node:
    var audio: Node = get_node_or_null("/root/Audio")
    if audio != null and audio.has_method("play_sfx"):
        return audio.call("play_sfx", sound_name, global_position) as Node
    return null

func _local_hurt_rect() -> Rect2:
    var center_y: float = float(stats.get("body_offset_y", -body_size.y * 0.5))
    return Rect2(Vector2(-body_size.x * 0.5, center_y - body_size.y * 0.5), body_size)

func get_hurt_rect() -> Rect2:
    var box: Rect2 = _local_hurt_rect()
    box.position += global_position
    return box

func get_attack_rect() -> Rect2:
    if state != State.ACTIVE:
        return Rect2()
    var box: Dictionary = attack_stats.get("hitbox", {})
    var size_px := Vector2(float(box.get("width", 0.0)), float(box.get("height", 0.0)))
    var offset: float = float(box.get("offset_x", 0.0))
    var x: float = offset if facing > 0 else -offset - size_px.x
    return Rect2(global_position + Vector2(x, float(box.get("top", 0.0))), size_px)

func _player_rect(player: Node2D) -> Rect2:
    if player.has_method("get_hurt_rect"):
        return player.get_hurt_rect()
    var hit: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if hit != null and hit.shape is RectangleShape2D:
        var size_px: Vector2 = (hit.shape as RectangleShape2D).size * hit.global_scale.abs()
        return Rect2(hit.global_position - size_px * 0.5, size_px)
    return Rect2(player.global_position, Vector2.ZERO)

func _player_in_attack(player: Node2D) -> bool:
    if not _player_is_available(player):
        return false
    return get_attack_rect().intersects(_player_rect(player))

func take_hit(damage: int, from_pos: Vector2, step: int) -> Dictionary:
    return _receive_hit(damage, from_pos, step, false)

func take_shockwave_hit(damage: int, from_pos: Vector2, step: int = 4) -> Dictionary:
    return _receive_hit(damage, from_pos, step, true)

func _strike_data(step: int, shockwave: bool) -> Dictionary:
    var hero: NimrodPlayer = get_tree().get_first_node_in_group("player") as NimrodPlayer
    var weapon: String = hero.weapon if hero != null else "axe"
    var specification: Dictionary = player_attack_stats.get("weapons", {}).get(weapon, player_attack_stats)
    if shockwave:
        return specification.get("shockwave", player_attack_stats.get("shockwave", {}))
    for attack in specification.get("attacks", []):
        if int(attack.get("step", 0)) == step:
            return attack
    return {}

var light_stagger_override := -1.0

func _receive_hit(damage: int, from_pos: Vector2, step: int, shockwave: bool) -> Dictionary:
    if state == State.DEAD:
        return {"blocked": false, "damage_dealt": 0}
    var dealt: int = mini(hp, maxi(0, damage))
    var strike: Dictionary = _strike_data(step, shockwave)
    var hero: NimrodPlayer = get_tree().get_first_node_in_group("player") as NimrodPlayer
    if hero != null and hero.weapon == "dagger" and hero.get_meta("dagger_wave", false):
        strike = hero.shockwave_data
    hp = maxi(0, hp - damage)
    var direction: float = 1.0 if global_position.x >= from_pos.x else -1.0
    velocity.x = direction * float(strike.get("knockback", 0.0)) * float(stats.get("knockback_multiplier", 1.0))
    hitstop_left = float(common.get("hitstop_seconds", 0.05))
    _spawn_hit_spark(from_pos)
    _play_sfx(str(stats.get("hurt_sfx", "beast_" + _audio_kind() + "_hurt")))
    damaged.emit(damage, hp)
    if hp <= 0:
        _die()
        return {"blocked": false, "damage_dealt": dealt}
    _on_hit(light_stagger_override if light_stagger_override >= 0 else float(strike.get("stagger", 0.0)))
    return {"blocked": false, "damage_dealt": dealt}

func _on_hit(seconds: float) -> void:
    _apply_stun(seconds)

func _apply_stun(seconds: float, force: bool = false) -> void:
    if seconds <= 0.0 or (stun_immunity_left > 0.0 and not force):
        return
    var maximum: float = float(common.get("max_stun_seconds", 0.6))
    if state == State.STUN:
        # Do not reset the episode clock: repeated hits cannot prolong it forever.
        stun_left = maxf(stun_left, minf(seconds, maxf(0.0, maximum - state_clock)))
        return
    if state == State.RECOVERY:
        recovery_after_stun = maxf(0.0, recovery_duration - state_clock)
    elif state in [State.WINDUP, State.ACTIVE]:
        # Interrupted attacks must still pay their full recovery before turning.
        recovery_after_stun = float(attack_stats.get("recovery", 0.0))
    stun_left = minf(seconds, maximum)
    _set_state(State.STUN)

func _spawn_hit_spark(from_pos: Vector2) -> void:
    var effect: Node2D = IMAGE_EFFECT.new()
    effect.configure(HIT_SPARK_PATH, HIT_SPARK_FRAME_SIZE, HIT_SPARK_FRAMES, float(common.get("hit_spark_seconds", 0.15)), false, Vector2(HIT_SPARK_FRAME_SIZE) * 0.5)
    effect.scale = Vector2.ONE * float(common.get("hit_spark_scale", 0.24))
    var hero: NimrodPlayer = get_tree().get_first_node_in_group("player") as NimrodPlayer
    if hero != null and hero.weapon == "dagger" and hero.attack_data.has(hero.attack_step):
        var color: Array = hero.attack_data[hero.attack_step]["fx_color"]
        effect.modulate = Color(float(color[0]), float(color[1]), float(color[2]), float(color[3]))
    effect.z_index = 20
    var scene: Node = get_tree().current_scene
    if scene == null:
        scene = get_parent()
    scene.add_child(effect)
    effect.global_position = Vector2(lerpf(global_position.x, from_pos.x, 0.25), get_hurt_rect().get_center().y)

func _die() -> void:
    _on_death()
    collision_layer = 0
    collision_mask = 0
    collider.set_deferred("disabled", true)
    velocity = Vector2.ZERO
    hitstop_left = 0.0
    _set_state(State.DEAD)
    _play_sfx(str(stats.get("death_sfx", "beast_" + _audio_kind() + "_death")))
    died.emit(self)
    _show_clip("death", 0.0)

func get_drop_chance() -> float:
    if no_drop:
        return 0.0
    var level: Node = _level()
    if level != null and level.get("config") is Dictionary:
        var rule: Dictionary = level.config.get("drop_rule", {})
        if str(rule.get("mode", "")) == "only_listed":
            return float(rule.get("listed", {}).get(enemy_id, 0.0))
        if str(rule.get("mode", "")) == "all":
            return float(rule.get("chance", 0.0))
    return float(stats.get("drop_chance", 0.0))

func _on_death() -> void:
    if randf() < get_drop_chance():
        var level: Node = _level()
        if level == null:
            return
        var pickup: Node2D = load("res://scripts/healing_pickup.gd").new()
        pickup.pickup_id = str(stats.get("drop_id", "healing_vomit"))
        level.add_child(pickup)
        pickup.global_position = global_position

func _update_dead(delta: float) -> void:
    state_clock += delta
    _show_clip("death", state_clock)
    var clip: Dictionary = clip_data.get("death", {})
    var animation_seconds: float = float(clip.get("duration_seconds", 0.0))
    var fade_seconds: float = float(common.get("death_fade_seconds", 0.4))
    if state_clock > animation_seconds:
        modulate.a = clampf(1.0 - (state_clock - animation_seconds) / maxf(0.001, fade_seconds), 0.0, 1.0)
    if state_clock >= animation_seconds + fade_seconds:
        queue_free()

func _active_clip() -> String:
    return "attack"

func _update_visual(delta: float) -> void:
    var clip: String = "idle"
    match state:
        State.IDLE, State.CHASE:
            clip = "walk" if absf(velocity.x) > 0.0 else "idle"
        State.WINDUP:
            clip = "windup"
        State.ACTIVE:
            clip = _active_clip()
        State.RECOVERY:
            clip = "recovery"
        State.TURN:
            clip = "turn"
        State.STUN:
            clip = "hurt"
    display_clock += delta
    var explicit_clock: float = state_clock if state not in [State.IDLE, State.CHASE] else display_clock
    _show_clip(clip, explicit_clock)

func _scale_stats(data: Dictionary) -> void:
    var factor: float = float(data.get("size_multiplier", 1.0))
    if is_equal_approx(factor, 1.0):
        return
    var distance_factor: float = float(data.get("range_multiplier", 1.0))
    var range_cap: float = float(data.get("range_cap", 900.0))
    var area_factor: float = float(data.get("aoe_multiplier", 1.0))
    data["visual_scale"] = float(data.get("visual_scale", 0.3)) * factor
    for key in ["body_size", "sensor", "sensor_wall", "sensor_ceiling"]:
        if data.has(key):
            var multiplier: float = factor if key == "body_size" else distance_factor
            for i in range(data[key].size()):
                data[key][i] = float(data[key][i]) * multiplier
    if data.has("body_offset_y"):
        data["body_offset_y"] = float(data["body_offset_y"]) * factor
    for key in ["detect_range", "retreat_distance", "back_range"]:
        if data.has(key):
            data[key] = minf(range_cap, float(data[key]) * distance_factor)
    if data.has("preferred_distance"):
        for i in range(data["preferred_distance"].size()):
            data["preferred_distance"][i] = minf(range_cap, float(data["preferred_distance"][i]) * distance_factor)
    for attack in data.get("attacks", []):
        attack["range"] = minf(range_cap, float(attack.get("range", 0.0)) * distance_factor)
        for key in attack.get("hitbox", {}):
            attack["hitbox"][key] = float(attack["hitbox"][key]) * factor
    for key in ["projectile", "explosion", "gas"]:
        if data.has(key):
            var section: Dictionary = data[key]
            if section.has("radius"):
                section["radius"] = float(section["radius"]) * area_factor
            if section.has("height"):
                section["height"] = float(section["height"]) * area_factor
            if section.has("collision_radius"):
                section["collision_radius"] = float(section["collision_radius"]) * factor
    if data.has("chain"):
        data["chain"]["range"] = minf(range_cap, float(data["chain"]["range"]) * distance_factor)
        data["chain"]["pull_offset"] = float(data["chain"]["pull_offset"]) * factor

func resolve_clip(requested: String) -> String:
    if textures.has(requested):
        return requested
    var resolved: String = str(clip_aliases.get(requested, ""))
    if textures.has(resolved):
        return resolved
    if not _clip_warnings.has(requested):
        _clip_warnings[requested] = true
        push_warning("Clip fallback: %s/%s" % [enemy_id, requested])
    resolved = str(clip_aliases.get("idle", "idle"))
    if textures.has(resolved):
        return resolved
    return str(textures.keys()[0]) if not textures.is_empty() else requested

func _show_clip(clip_name: String, seconds: float) -> void:
    clip_name = resolve_clip(clip_name)
    displayed_clip = clip_name
    var clip: Dictionary = clip_data.get(clip_name, {})
    var texture: Texture2D = textures.get(clip_name) as Texture2D
    visual.visible = texture != null
    missing_visual.visible = texture == null
    visual.flip_h = facing < 0
    var frames: int = maxi(1, int(clip.get("frames", 1)))
    var duration_seconds: float = float(clip.get("duration_seconds", common.get("missing_clip_seconds", 1.0)))
    if clip_name.begins_with("turn"):

        duration_seconds = _turn_seconds()
    var phase: float = fmod(seconds, maxf(0.001, duration_seconds)) if bool(clip.get("loop", false)) else seconds
    current_frame = clampi(int(phase / maxf(0.001, duration_seconds) * frames), 0, frames - 1)
    if texture == null:
        return
    visual.texture = texture
    AssetVisual.apply_frame(visual, clip, current_frame)

func _draw() -> void:
    # Debug geometry only. Creature and effect art always comes from PNGs.
    if not debug_hitboxes or state == State.DEAD:
        return
    draw_rect(_local_hurt_rect(), Color(0.2, 0.5, 1.0, 0.85), false, 2.0)
    draw_arc(Vector2.ZERO, float(stats.get("detect_range", 0.0)), 0.0, TAU, 64, Color(0.9, 0.8, 0.3, 0.5), 1.0)
    var attack_box: Rect2 = get_attack_rect()
    if attack_box.has_area():
        attack_box.position -= global_position
        draw_rect(attack_box, Color(1.0, 0.15, 0.15, 0.25), true)
        draw_rect(attack_box, Color(1.0, 0.15, 0.15, 0.9), false, 2.0)

func queue_player_effect(effect: Callable) -> void:
    if effect.is_valid() and is_inside_tree():
        _queued_player_effects.append(effect)
        if not get_tree().physics_frame.is_connected(_flush_player_effects):
            get_tree().physics_frame.connect(_flush_player_effects, CONNECT_ONE_SHOT)

func _flush_player_effects() -> void:
    var effects: Array[Callable] = _queued_player_effects.duplicate()
    _queued_player_effects.clear()
    for effect: Callable in effects:
        if effect.is_valid() and is_inside_tree():
            effect.call()

func _notification(what: int) -> void:
    if what == NOTIFICATION_EXIT_TREE:
        if get_tree().physics_frame.is_connected(_flush_player_effects):
            get_tree().physics_frame.disconnect(_flush_player_effects)
        _queued_player_effects.clear()

# Ground placement uses actual collision surfaces, including one-way platforms.
func snap_to_ground() -> void:
    if not is_inside_tree():
        return
    if enemy_id in ["sky_beast", "gas_sac", "wraith_ray", "cedar_wisp", "wall_diver"]:
        return
    await get_tree().physics_frame
    if not is_inside_tree():
        return
    var bottom: float = collider.position.y + body_size.y * 0.5
    var feet: Vector2 = global_position + Vector2(0, bottom)
    var query := PhysicsRayQueryParameters2D.create(feet - Vector2(0, 8), feet + Vector2(0, float(common["ground_snap_range"])), SURFACE_MASK, [get_rid()])
    var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        push_error("No ground within 600px: " + str(get_parent().level_id) + "/" + name)
        return
    global_position.y = float(hit["position"].y) - bottom - float(common["ground_snap_margin"])
    velocity = Vector2(0, float(common.get("gravity", 1750)) / 60.0)
    move_and_slide()

func take_light_hit(damage: int, from_pos: Vector2, stagger: float) -> Dictionary:
    light_stagger_override = stagger
    var result: Dictionary = take_hit(damage,from_pos,1)
    light_stagger_override = -1
    return result

# Devour bypasses armor, guard and stagger immunity, but respects cinematic invulnerability.
func take_fixed_damage(amount: int, from_pos: Vector2) -> Dictionary:
    if hp <= 0 or state == State.DEAD or not cinematic_clip.is_empty():
        return {"blocked":false,"damage_dealt":0}
    if enemy_id in ["humbaba","gugalanna"] and not bool(get("battle_started")):
        return {"blocked":false,"damage_dealt":0}
    if enemy_id == "humbaba" and (bool(get("phase_roaring")) or bool(get("opening_pending"))):
        return {"blocked":false,"damage_dealt":0}
    if enemy_id == "kala_ushumgal" and str(get("phase")) == "phase_transition":
        return {"blocked":false,"damage_dealt":0}
    var dealt: int = mini(hp,amount)
    hp -= amount
    hitstop_left = float(common.get("hitstop_seconds",.05))
    _spawn_hit_spark(from_pos)
    damaged.emit(dealt,hp)
    if hp <= 0:
        _die()
    return {"blocked":false,"damage_dealt":dealt}
