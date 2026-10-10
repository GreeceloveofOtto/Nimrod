extends EnemyBase

const HEALING_PICKUP = preload("res://scripts/healing_pickup.gd")

var flight: Dictionary = {}
var hover_clock: float = 0.0
var dive_target: Vector2 = Vector2.ZERO
var dive_direction: Vector2 = Vector2.ZERO
var dive_distance: float = 0.0
var dive_travelled: float = 0.0
var wing_loop: Node
var death_origin: Vector2 = Vector2.ZERO
var death_landed: bool = false
var death_landed_clock: float = 0.0
var drop_spawned: bool = false

func _init() -> void:
    enemy_id = "sky_beast"

func _ready() -> void:
    super._ready()
    flight = stats.get("flight", {})
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    _enforce_bounds()
    _show_clip("fly_idle", 0.0)
    _update_wing_loop()

func _physics_process(delta: float) -> void:
    if state != State.DEAD and hitstop_left <= 0.0:
        hover_clock += delta
    super._physics_process(delta)
    if is_instance_valid(wing_loop) and wing_loop is Node2D:
        (wing_loop as Node2D).global_position = global_position

func _integrate_motion(_delta: float) -> void:
    var before: Vector2 = global_position
    move_and_slide()
    if state == State.ACTIVE:
        dive_travelled += global_position.distance_to(before)
        if get_slide_collision_count() > 0 or dive_travelled >= dive_distance:
            _finish_active()

func _flight_bounds() -> Rect2:
    var level: Node = _level()
    if level != null and level.has_method("get_flight_bounds"):
        return level.call("get_flight_bounds") as Rect2
    var bounds: Array = flight.get("fallback_bounds", [0.0, 0.0, 0.0, 0.0])
    return Rect2(float(bounds[0]), float(bounds[1]), float(bounds[2]), float(bounds[3]))

func _floor_y() -> float:
    var level: Node = _level()
    if level != null:
        return float(level.get("floor_y"))
    return float(flight.get("fallback_floor_y", 0.0))

func _enforce_bounds() -> void:
    if flight.is_empty():
        return
    var allowed: Rect2 = _flight_bounds()
    # Leave the whole physical hurtbox inside the open terrace boundaries.
    var low_x: float = allowed.position.x + body_size.x * 0.5
    var high_x: float = allowed.end.x - body_size.x * 0.5
    var low_y: float = allowed.position.y + body_size.y * 0.5
    var high_y: float = minf(allowed.end.y, _floor_y() - body_size.y * 0.5)
    var before: Vector2 = global_position
    global_position.x = clampf(global_position.x, low_x, high_x)
    global_position.y = clampf(global_position.y, low_y, high_y)
    if not is_equal_approx(before.x, global_position.x):
        velocity.x = 0.0
    if not is_equal_approx(before.y, global_position.y):
        velocity.y = 0.0
    if state == State.ACTIVE and not before.is_equal_approx(global_position):
        _finish_active()

func _update_idle(delta: float) -> void:
    var player: Node2D = _target()
    if _can_detect(player):
        _set_state(State.CHASE)
    _hover(delta, player if _player_is_available(player) else null)

func _update_chase(delta: float) -> void:
    var player: Node2D = _target()
    if not _can_detect(player):
        _set_state(State.IDLE)
        _hover(delta, null)
        return
    var difference: float = player.global_position.x - global_position.x
    var direction: int = 1 if difference >= 0.0 else -1
    if direction != facing:
        _request_turn(direction)
        _brake(delta)
        return
    if attack_cooldown_left <= 0.0:
        _begin_attack()
    else:
        _hover(delta, player)

func _hover(delta: float, player: Node2D) -> void:
    var altitudes: Array = flight.get("hover_altitude", [0.0, 0.0])
    var phase: float = hover_clock * TAU / maxf(TIME_EPSILON, float(flight.get("hover_cycle_seconds", 1.0)))
    var height: float = lerpf(float(altitudes[0]), float(altitudes[1]), (sin(phase) + 1.0) * 0.5)
    var target_x: float = player.global_position.x if player != null else patrol_center
    var target_floor: float = player.global_position.y if player != null else _floor_y()
    var target: Vector2 = Vector2(target_x + sin(phase) * float(flight.get("hover_sway", 0.0)), target_floor - height)
    var difference: Vector2 = target - global_position
    var desired: Vector2 = Vector2(clampf(difference.x, -float(stats.get("move_speed", 0.0)), float(stats.get("move_speed", 0.0))), clampf(difference.y, -float(flight.get("hover_vertical_speed", 0.0)), float(flight.get("hover_vertical_speed", 0.0))))
    velocity = velocity.move_toward(desired, float(flight.get("hover_acceleration", 0.0)) * delta)

func _begin_attack() -> void:
    var player: Node2D = _target()
    if not _player_is_available(player):
        return
    # The body center is frozen now; subsequent player movement cannot retarget.
    dive_target = _player_rect(player).get_center()
    attack_has_hit = false
    _set_state(State.WINDUP)
    _play_sfx("sky_beast_windup_screech")

func _update_windup(delta: float) -> void:
    _brake(delta)
    if state_clock >= float(attack_stats.get("windup", 0.0)):
        _begin_active()

func _begin_active() -> void:
    dive_direction = (dive_target - global_position).normalized()
    if dive_direction.is_zero_approx():
        dive_direction = Vector2(facing, 0.0)
    dive_distance = global_position.distance_to(dive_target) + float(attack_stats.get("overshoot_distance", 0.0))
    dive_travelled = 0.0
    velocity = dive_direction * float(attack_stats.get("dive_speed", 0.0))
    _set_state(State.ACTIVE)
    _play_sfx("sky_beast_dive_whoosh")

func _update_active(_delta: float) -> void:
    velocity = dive_direction * float(attack_stats.get("dive_speed", 0.0))
    var player: Node2D = _target()
    if not attack_has_hit and _player_in_attack(player):
        if bool(player.call("receive_damage", int(attack_stats.get("damage", 0)))):
            attack_has_hit = true
    if state_clock >= float(attack_stats.get("active", 0.0)):
        _finish_active()

func get_attack_rect() -> Rect2:
    return get_hurt_rect() if state == State.ACTIVE else Rect2()

func _finish_active() -> void:
    if state != State.ACTIVE:
        return
    attack_cooldown_left = float(attack_stats.get("cooldown", 0.0))
    super._finish_active()

func _update_recovery(delta: float) -> void:
    var desired: Vector2 = Vector2(0.0, -float(attack_stats.get("recovery_rise_speed", 0.0)))
    velocity = velocity.move_toward(desired, float(attack_stats.get("recovery_deceleration", 0.0)) * delta)
    if state_clock >= recovery_duration:
        recovery_after_stun = 0.0
        _set_state(State.CHASE if _can_detect(_target()) else State.IDLE)

func _brake(delta: float) -> void:
    velocity = velocity.move_toward(Vector2.ZERO, float(common.get("knockback_friction", 0.0)) * delta)

func _on_hit(_seconds: float) -> void:
    var interrupted: bool = state in [State.WINDUP, State.ACTIVE]
    if interrupted:
        attack_cooldown_left = float(attack_stats.get("cooldown", 0.0))
        dive_direction = Vector2.ZERO
        velocity.y = 0.0
    _apply_stun(float(attack_stats.get("interrupt_stun", 0.0)), interrupted)
    if interrupted:
        # A cancelled dive returns to hover after stun; completed dives recover.
        recovery_after_stun = 0.0

func _set_state(next: State) -> void:
    super._set_state(next)
    _update_wing_loop()

func _update_wing_loop() -> void:
    var should_play: bool = state in [State.IDLE, State.CHASE, State.TURN]
    if should_play and not is_instance_valid(wing_loop) and not flight.is_empty():
        wing_loop = _play_sfx("sky_beast_wingflap_loop")
        if is_instance_valid(wing_loop):
            wing_loop.set("volume_db", float(flight.get("wing_volume_db", 0.0)))
    elif not should_play:
        _stop_wing_loop()

func _stop_wing_loop() -> void:
    if is_instance_valid(wing_loop):
        wing_loop.call("stop")
        wing_loop.queue_free()
    wing_loop = null

func _on_death() -> void:
    _stop_wing_loop()
    death_origin = global_position
    death_landed = false
    death_landed_clock = 0.0

func _update_dead(delta: float) -> void:
    state_clock += delta
    _show_clip("death", state_clock)
    visual.modulate = Color.WHITE
    if not death_landed:
        velocity.y = minf(float(flight.get("death_fall_speed", 0.0)), velocity.y + float(flight.get("death_gravity", 0.0)) * delta)
        global_position.y += velocity.y * delta
        var phase: float = state_clock * float(flight.get("death_spiral_rate", 0.0))
        global_position.x = death_origin.x + sin(phase) * float(flight.get("death_spiral_radius", 0.0))
        visual.rotation = sin(phase) * float(flight.get("death_spiral_rotation", 0.0))
        var ground: float = _floor_y() - body_size.y * 0.5
        if global_position.y >= ground:
            global_position.y = ground
            velocity = Vector2.ZERO
            death_landed = true
            _roll_drop()
    else:
        death_landed_clock += delta
        var fade: float = float(common.get("death_fade_seconds", 0.0))
        modulate.a = clampf(1.0 - death_landed_clock / maxf(TIME_EPSILON, fade), 0.0, 1.0)
        if death_landed_clock >= fade:
            queue_free()

func _roll_drop() -> void:
    if drop_spawned:
        return
    drop_spawned = true
    if randf() >= float(flight.get("drop_chance", 0.0)):
        return
    var pickup: Node2D = HEALING_PICKUP.new()
    pickup.pickup_id = str(flight.get("drop_id", "healing_vomit"))
    var destination: Node = _level()
    if destination == null:
        destination = get_parent()
    destination.add_child(pickup)
    pickup.global_position = Vector2(global_position.x, _floor_y())

func _update_visual(delta: float) -> void:
    var clip: String = "fly_idle"
    match state:
        State.WINDUP:
            clip = "windup"
        State.ACTIVE:
            clip = "dive"
        State.RECOVERY:
            clip = "recovery"
        State.TURN:
            clip = "turn"
        State.STUN:
            clip = "hurt"
    display_clock += delta
    _show_clip(clip, display_clock if state in [State.IDLE, State.CHASE] else state_clock)
    var gain: float = 1.0
    if state == State.WINDUP:
        var phase: float = state_clock / maxf(TIME_EPSILON, float(attack_stats.get("windup", 0.0)))
        gain = lerpf(1.0, float(attack_stats.get("windup_flash_gain", 1.0)), absf(sin(phase * PI * float(attack_stats.get("windup_flash_cycles", 1.0)))))
    visual.modulate = Color(gain, gain, gain)

func _exit_tree() -> void:
    _stop_wing_loop()
