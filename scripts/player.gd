extends CharacterBody2D
class_name NimrodPlayer

signal attack_connected(damage: int, strike: int)
signal damage_received(amount: int, remaining_hp: int)
signal died

const Config = preload("res://scripts/game_constants.gd")
const MAX_HP: int = Config.PLAYER_MAX_HP
const RUN_SPEED: float = Config.PLAYER_RUN_SPEED
const GROUND_ACCEL: float = Config.PLAYER_GROUND_ACCEL
const AIR_ACCEL: float = Config.PLAYER_AIR_ACCEL
const GRAVITY: float = Config.GRAVITY
const JUMP_IMPULSE: float = Config.PLAYER_JUMP_IMPULSE
const JUMP_CUT_GRAVITY: float = Config.PLAYER_JUMP_CUT_GRAVITY
const COYOTE_SECONDS: float = Config.PLAYER_COYOTE_SECONDS
const JUMP_BUFFER_SECONDS: float = Config.PLAYER_JUMP_BUFFER_SECONDS
const COMBO_RESET_SECONDS: float = Config.PLAYER_COMBO_RESET_SECONDS
const ROLL_STARTUP: float = Config.PLAYER_ROLL_STARTUP
const ROLL_INVULNERABLE: float = Config.PLAYER_ROLL_INVULNERABLE
const ROLL_RECOVERY: float = Config.PLAYER_ROLL_RECOVERY
const ROLL_DURATION: float = Config.PLAYER_ROLL_DURATION
const ROLL_SPEED: float = Config.PLAYER_ROLL_SPEED
const DROP_MASK_SECONDS: float = Config.PLAYER_DROP_MASK_SECONDS
const VISUAL_SCALE: float = Config.PLAYER_VISUAL_SCALE
const STAND_BOX: Vector2 = Config.PLAYER_STAND_BOX
const CROUCH_BOX: Vector2 = Config.PLAYER_CROUCH_BOX
const ROLL_BOX: Vector2 = Config.PLAYER_ROLL_BOX
const STAND_CENTER_Y: float = Config.PLAYER_STAND_CENTER_Y
const CROUCH_CENTER_Y: float = Config.PLAYER_CROUCH_CENTER_Y
const ROLL_CENTER_Y: float = Config.PLAYER_ROLL_CENTER_Y
const HITSTOP_SECONDS: float = Config.HITSTOP_SECONDS

@onready var visual: Sprite2D = $Visual
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var platform_check: RayCast2D = $GroundCheck
@onready var camera: Camera2D = $Camera2D
@onready var sfx_attack: AudioStreamPlayer = $SFXAttack
@onready var sfx_roll: AudioStreamPlayer = $SFXRoll
@onready var sfx_jump: AudioStreamPlayer = $SFXJump
@onready var sfx_step: AudioStreamPlayer = $SFXStep
@onready var sfx_land: AudioStreamPlayer = get_node_or_null("SFXLand") as AudioStreamPlayer

var hp: int = MAX_HP
var facing: int = 1
var action: String = "normal" # normal, attack, roll, hurt, dead
var attack_step: int = 0
var attack_clock: float = 0.0
var buffered_attack: bool = false
var combo_next: int = 1
var combo_left: float = 0.0
var roll_clock: float = 0.0
var roll_direction: int = 1
var hurt_clock: float = 0.0
var hurt_duration: float = Config.PLAYER_HURT_SECONDS
var death_clock: float = 0.0
var damage_grace: float = 0.0
var hitstop_left: float = 0.0
var coyote_left: float = 0.0
var jump_buffer_left: float = 0.0
var jump_start_left: float = 0.0
var landing_left: float = 0.0
var crouching: bool = false
var crouch_enter_left: float = 0.0
var crouch_exit_left: float = 0.0
var drop_mask_left: float = 0.0
var debug_hitboxes: bool = false
var attack_already_hit: Dictionary = {}
var displayed_clip: String = ""
var display_clock: float = 0.0
var textures: Dictionary = {}
var clip_data: Dictionary = {}
var hit_rectangle: RectangleShape2D = RectangleShape2D.new()
var debug_rect: Rect2 = Rect2()
var shockwave_rect: Rect2 = Rect2()
var flash_time: float = 0.0
var shake_time: float = 0.0
var shockwave_done: bool = false
var step_timer: float = 0.0
var attack_data: Dictionary = {}
var shockwave_data: Dictionary = {}
var transition_locked: bool = false
var _portal_walking: bool = false
var _portal_walk_direction: int = 1
var _portal_walk_clock: float = 0.0
var _transition_visual: Dictionary = {}
var _restart_requested: bool = false
var direction_cancel_data: Dictionary = {}
var pending_cancel_direction: int = 0
var direction_cancel_buffer_left: float = 0.0
var air_direction_cancels: int = 0
var pull_data: Dictionary = {}
var movement_data: Dictionary = {}
var pull_left: float = 0.0
var pull_elapsed: float = 0.0
var pull_target_x: float = 0.0
var pull_escaped: bool = false
var damage_tick_clock: float = 0.0
var tick_sources: Dictionary = {}

func _ready() -> void:
    add_to_group("player")
    _load_attack_data()
    _load_sprites()
    collider.shape = collider.shape.duplicate()
    hit_rectangle.size = Vector2(1, 1)
    _set_standing_collider()
    platform_check.enabled = true
    visual.scale = Vector2.ONE * VISUAL_SCALE
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _show_clip("idle", 0.0)

func _load_attack_data() -> void:
    var file := FileAccess.open("res://data/player_attacks.json", FileAccess.READ)
    if file == null:
        push_error("Missing player attack data")
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        push_error("Invalid player attack data")
        return
    for row: Dictionary in parsed.get("attacks", []):
        attack_data[int(row.get("step", 0))] = row
    shockwave_data = parsed.get("shockwave", {})
    direction_cancel_data = parsed.get("direction_cancel", {})
    movement_data = parsed.get("movement", {})
    pull_data = parsed.get("pull", {})

func _load_sprites() -> void:
    var file := FileAccess.open("res://assets/animation_manifest.json", FileAccess.READ)
    if file == null:
        push_error("Missing animation manifest")
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        push_error("Invalid animation manifest")
        return
    for clip_variant in parsed.get("clips", []):
        var clip: Dictionary = clip_variant
        var name: String = str(clip.get("name", ""))
        var path: String = "res://assets/" + str(clip.get("sheet", ""))
        var texture := load(path) as Texture2D
        if texture == null:
            push_error("Missing sprite: " + path)
            continue
        textures[name] = texture
        clip_data[name] = clip

func _physics_process(delta: float) -> void:
    if transition_locked:
        if _portal_walking:
            _portal_walk_clock += delta
            _show_clip("run", _portal_walk_clock)
            visual.flip_h = _portal_walk_direction < 0
        return
    if Input.is_action_just_pressed("restart"):
        _request_run_restart()
        return
    if Input.is_action_just_pressed("debug_hitbox"):
        debug_hitboxes = not debug_hitboxes
        queue_redraw()

    damage_grace = maxf(0.0, damage_grace - delta)
    damage_tick_clock += delta
    if is_on_floor():
        air_direction_cancels = 0
    flash_time = maxf(0.0, flash_time - delta)
    if debug_hitboxes:
        queue_redraw()

    if action == "dead":
        death_clock += delta
        velocity.x = move_toward(velocity.x, 0.0, GROUND_ACCEL * delta)
        velocity.y += GRAVITY * delta
        move_and_slide()
        _show_clip("death", death_clock)
        if death_clock >= Config.PLAYER_DEATH_RESTART_SECONDS:
            _request_run_restart()
        return

    if pull_left > 0.0:
        pull_elapsed += delta
        if Input.is_action_just_pressed("roll") and pull_elapsed >= float(pull_data.get("escape_after", 0.15)):
            pull_left = 0.0
            pull_escaped = true
            _begin_roll()
        else:
            var motion_x: float = (pull_target_x - global_position.x) * minf(1.0, delta / maxf(delta, pull_left))
            velocity.x = motion_x / delta
            _integrate_vertical(delta)
            move_and_slide()
            pull_left = maxf(0.0, pull_left - delta)
            _refresh_normal_visual(delta)
            return

    if Input.is_action_just_pressed("roll") and (action == "normal" or action == "attack"):
        _begin_roll()

    if action == "roll":
        var grounded_before_roll: bool = is_on_floor()
        _update_roll(delta)
        _integrate_vertical(delta)
        var roll_y_before: float = velocity.y
        move_and_slide()
        _record_landing(grounded_before_roll, roll_y_before)
        _update_drop_mask(delta)
        if action == "roll":
            _show_clip("roll", roll_clock)
        else:
            _refresh_normal_visual(delta)
        _update_camera_shake(delta)
        return

    if action == "hurt":
        var grounded_before_hurt: bool = is_on_floor()
        hurt_clock += delta
        velocity.x = move_toward(velocity.x, 0.0, GROUND_ACCEL * delta)
        _integrate_vertical(delta)
        var hurt_y_before: float = velocity.y
        move_and_slide()
        _record_landing(grounded_before_hurt, hurt_y_before)
        _show_clip("hurt", hurt_clock)
        if hurt_clock >= hurt_duration:
            action = "normal"
        _update_camera_shake(delta)
        return

    if combo_left > 0.0 and action != "attack":
        combo_left = maxf(0.0, combo_left - delta)
        if combo_left <= 0.0:
            combo_next = 1

    if Input.is_action_just_pressed("attack"):
        var attack_axis: float = Input.get_axis("move_left", "move_right")
        if action == "attack" and _can_direction_cancel(attack_axis):
            if hitstop_left > 0.0:
                pending_cancel_direction = 1 if attack_axis > 0.0 else -1
                direction_cancel_buffer_left = float(direction_cancel_data.get("buffer_during_hitstop", 0.12))
            else:
                _direction_cancel_attack(attack_axis)
        elif action == "attack" and attack_step < 4:
            buffered_attack = true
        elif action == "normal":
            var chosen_step: int = 4 if not is_on_floor() else combo_next
            _begin_attack(chosen_step)

    if hitstop_left > 0.0:
        hitstop_left = maxf(0.0, hitstop_left - delta)
        if pending_cancel_direction != 0 and direction_cancel_buffer_left > 0.0 and hitstop_left <= 0.000001:
            _direction_cancel_attack(float(pending_cancel_direction))
        elif pending_cancel_direction != 0:
            direction_cancel_buffer_left = maxf(0.0, direction_cancel_buffer_left - delta)
            if direction_cancel_buffer_left == 0.0:
                pending_cancel_direction = 0
        _refresh_attack_visual()
        _update_camera_shake(delta)
        return

    var grounded_before: bool = is_on_floor()
    coyote_left = COYOTE_SECONDS if grounded_before else maxf(0.0, coyote_left - delta)
    landing_left = maxf(0.0, landing_left - delta)
    crouch_enter_left = maxf(0.0, crouch_enter_left - delta)
    crouch_exit_left = maxf(0.0, crouch_exit_left - delta)
    jump_start_left = maxf(0.0, jump_start_left - delta)

    var move_axis: float = Input.get_axis("move_left", "move_right")
    if action == "normal" and absf(move_axis) > Config.PLAYER_INPUT_DEADZONE and not Input.is_action_pressed("crouch"):
        facing = 1 if move_axis > 0.0 else -1

    _update_crouch(grounded_before)
    var wants_drop: bool = Input.is_action_pressed("crouch") and Input.is_action_just_pressed("jump")
    if wants_drop:
        _try_drop_platform()
    elif Input.is_action_just_pressed("jump"):
        jump_buffer_left = JUMP_BUFFER_SECONDS
    else:
        jump_buffer_left = maxf(0.0, jump_buffer_left - delta)

    if jump_buffer_left > 0.0 and coyote_left > 0.0 and action == "normal" and not crouching:
        velocity.y = JUMP_IMPULSE
        coyote_left = 0.0
        jump_buffer_left = 0.0
        jump_start_left = Config.PLAYER_JUMP_START_SECONDS
        landing_left = 0.0
        sfx_jump.pitch_scale = randf_range(Config.PLAYER_JUMP_PITCH_MIN, Config.PLAYER_JUMP_PITCH_MAX)
        sfx_jump.play()

    var desired_speed: float = move_axis * RUN_SPEED
    if crouching:
        desired_speed = move_axis * float(movement_data.get("crouch_speed", 0.0))
    elif action == "attack":
        desired_speed *= Config.PLAYER_ATTACK_MOVE_SCALE
    var accel: float = GROUND_ACCEL if grounded_before else AIR_ACCEL
    velocity.x = move_toward(velocity.x, desired_speed, accel * delta)
    _integrate_vertical(delta)
    var y_before: float = velocity.y
    move_and_slide()
    _record_landing(grounded_before, y_before)

    _update_footsteps(delta)
    _update_drop_mask(delta)
    if action == "attack":
        _update_attack(delta)
    else:
        _refresh_normal_visual(delta)
    _update_camera_shake(delta)

func _integrate_vertical(delta: float) -> void:
    velocity.y += GRAVITY * delta
    if velocity.y < Config.PLAYER_JUMP_CUT_THRESHOLD and not Input.is_action_pressed("jump"):
        velocity.y += JUMP_CUT_GRAVITY * delta
    velocity.y = minf(velocity.y, Config.PLAYER_MAX_FALL_SPEED)

func _update_crouch(on_ground: bool) -> void:
    var target: bool = action == "normal" and on_ground and Input.is_action_pressed("crouch")
    if crouching == target:
        return
    if not target and crouching and not _can_stand():
        return
    crouching = target
    var box := collider.shape as RectangleShape2D
    if crouching:
        box.size = CROUCH_BOX
        collider.position.y = CROUCH_CENTER_Y
        crouch_enter_left = Config.PLAYER_CROUCH_ENTER_SECONDS
        crouch_exit_left = 0.0
    else:
        box.size = STAND_BOX
        collider.position.y = STAND_CENTER_Y
        crouch_exit_left = Config.PLAYER_CROUCH_EXIT_SECONDS
        crouch_enter_left = 0.0

func _can_stand() -> bool:
    var shape := RectangleShape2D.new()
    shape.size = STAND_BOX - Vector2(2.0, 2.0)
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0.0, global_position + Vector2(0, STAND_CENTER_Y))
    query.collision_mask = Config.PLAYER_COLLISION_MASK
    query.exclude = [get_rid()]
    return get_world_2d().direct_space_state.intersect_shape(query, 2).is_empty()

func _try_drop_platform() -> void:
    if not is_on_floor() or action != "normal":
        return
    platform_check.force_raycast_update()
    if not platform_check.is_colliding():
        return
    set_collision_mask_value(2, false)
    drop_mask_left = DROP_MASK_SECONDS
    global_position.y += Config.PLAYER_DROP_OFFSET
    velocity.y = Config.PLAYER_DROP_SPEED
    coyote_left = 0.0
    jump_buffer_left = 0.0
    crouching = false
    _set_standing_collider()
    _show_clip("drop_through", 0.0)

func _update_drop_mask(delta: float) -> void:
    if drop_mask_left > 0.0:
        drop_mask_left = maxf(0.0, drop_mask_left - delta)
        if drop_mask_left == 0.0:
            set_collision_mask_value(2, true)

func _can_direction_cancel(axis: float) -> bool:
    if not bool(direction_cancel_data.get("enabled", false)) or absf(axis) <= Config.PLAYER_INPUT_DEADZONE or axis * facing >= 0.0:
        return false
    return is_on_floor() or air_direction_cancels < int(direction_cancel_data.get("air_limit", 2))

func _direction_cancel_attack(axis: float) -> void:
    if action != "attack" or not _can_direction_cancel(axis):
        return
    var next_step: int = (attack_step % 4) + 1 if bool(direction_cancel_data.get("keep_combo", true)) else 1
    if not is_on_floor():
        next_step = 4
        air_direction_cancels += 1
    _cancel_attack()
    facing = 1 if axis > 0.0 else -1
    visual.flip_h = facing < 0
    velocity.x = 0.0
    _begin_attack(next_step)

func apply_pull(target_x: float, seconds: float) -> bool:
    if transition_locked or action == "dead" or is_roll_invulnerable():
        return false
    _cancel_attack()
    pull_target_x = target_x
    pull_left = maxf(0.0, seconds)
    pull_elapsed = 0.0
    pull_escaped = false
    velocity.x = 0.0
    return true

func _begin_attack(step: int) -> void:
    if not attack_data.has(clampi(step, 1, 4)):
        return
    if crouching and not _can_stand():
        return
    action = "attack"
    attack_step = clampi(step, 1, 4)
    attack_clock = 0.0
    buffered_attack = false
    attack_already_hit.clear()
    combo_left = 0.0
    shockwave_done = false
    shockwave_rect = Rect2()
    crouching = false
    _set_standing_collider()
    velocity.x += float(facing) * float(attack_data[attack_step]["impulse"])
    _play_attack_sfx(attack_step)
    _refresh_attack_visual()

func _update_attack(delta: float) -> void:
    var before: float = attack_clock
    attack_clock += delta
    var tuning: Dictionary = attack_data[attack_step]
    if before < float(tuning["active_end"]) and attack_clock >= float(tuning["active_start"]):
        _resolve_axe_hit()
    if attack_step == 4 and not shockwave_done and attack_clock >= float(shockwave_data["start"]):
        _resolve_shockwave()
        shockwave_done = true
    if attack_clock >= float(tuning["duration"]):
        var finished_step: int = attack_step
        if buffered_attack and finished_step < 4 and is_on_floor():
            _begin_attack(finished_step + 1)
            return
        action = "normal"
        attack_step = 0
        attack_clock = 0.0
        buffered_attack = false
        combo_next = finished_step + 1 if finished_step < 4 else 1
        combo_left = COMBO_RESET_SECONDS if finished_step < 4 else 0.0
        debug_rect = Rect2()
        shockwave_rect = Rect2()
    _refresh_attack_visual()
    if debug_hitboxes:
        queue_redraw()

func _configured_hitbox(tuning: Dictionary) -> Rect2:
    var box: Dictionary = tuning["hitbox"]
    var size := Vector2(float(box["width"]), float(box["height"]))
    var offset_x: float = float(box["offset_x"])
    var start_x: float = offset_x if facing > 0 else -offset_x - size.x
    return Rect2(Vector2(start_x, float(box["top"])), size)

func _attack_rect() -> Rect2:
    return _configured_hitbox(attack_data[attack_step])

func _resolve_axe_hit() -> void:
    var area: Rect2 = _attack_rect()
    debug_rect = area
    hit_rectangle.size = area.size
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = hit_rectangle
    query.transform = Transform2D(0.0, global_position + area.position + area.size * 0.5)
    query.collision_mask = Config.ENEMY_COLLISION_LAYER
    query.collide_with_bodies = true
    query.collide_with_areas = false
    query.exclude = [get_rid()]
    for hit in get_world_2d().direct_space_state.intersect_shape(query, Config.ATTACK_QUERY_LIMIT):
        var obj: Object = hit.get("collider")
        if obj == null or not obj.has_method("take_hit"):
            continue
        var id: int = obj.get_instance_id()
        if attack_already_hit.has(id):
            continue
        attack_already_hit[id] = true
        var tuning: Dictionary = attack_data[attack_step]
        var damage: int = int(tuning["damage"])
        # Knockback uses the attacker's origin; the axe tip can pass the target.
        var result: Variant = obj.call("take_hit", damage, global_position, attack_step)
        if result is Dictionary and bool(result.get("blocked", false)):
            _guard_recoil()
            continue
        _play_shared_sfx("axe_hit_heavy" if attack_step == 4 else "axe_hit_flesh")
        hitstop_left = HITSTOP_SECONDS
        shake_time = maxf(shake_time, float(tuning["shake"]))
        attack_connected.emit(damage, attack_step)

func _resolve_shockwave() -> void:
    shockwave_rect = _configured_hitbox(shockwave_data)
    _play_shared_sfx("shockwave")
    debug_rect = shockwave_rect if debug_hitboxes else debug_rect
    hit_rectangle.size = shockwave_rect.size
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = hit_rectangle
    query.transform = Transform2D(0.0, global_position + shockwave_rect.position + shockwave_rect.size * 0.5)
    query.collision_mask = Config.ENEMY_COLLISION_LAYER
    query.collide_with_bodies = true
    query.collide_with_areas = false
    query.exclude = [get_rid()]
    for hit in get_world_2d().direct_space_state.intersect_shape(query, Config.ATTACK_QUERY_LIMIT):
        var obj: Object = hit.get("collider")
        if obj == null or not obj.has_method("take_hit"):
            continue
        var id: int = obj.get_instance_id()
        if attack_already_hit.has(id):
            continue
        attack_already_hit[id] = true
        var damage: int = int(shockwave_data["damage"])
        var result: Variant
        if obj.has_method("take_shockwave_hit"):
            result = obj.call("take_shockwave_hit", damage, global_position, 4)
        else:
            result = obj.call("take_hit", damage, global_position, 4)
        if result is Dictionary and bool(result.get("blocked", false)):
            _guard_recoil()
            continue
        _play_shared_sfx("axe_hit_heavy")
        hitstop_left = HITSTOP_SECONDS
        shake_time = maxf(shake_time, float(shockwave_data["shake"]))
        attack_connected.emit(damage, 4)

func _guard_recoil() -> void:
    velocity.x = 0.0
    move_and_collide(Vector2(-facing * float(direction_cancel_data.get("guard_recoil_pixels", 50.0)), 0.0))

func _begin_roll() -> void:
    var move_axis: float = Input.get_axis("move_left", "move_right")
    if absf(move_axis) > Config.PLAYER_INPUT_DEADZONE:
        facing = 1 if move_axis > 0.0 else -1
    roll_direction = facing
    visual.flip_h = facing < 0
    if action == "attack":
        _cancel_attack()
    if action == "normal" and crouching:
        crouching = false
    _set_short_collider()
    action = "roll"
    roll_clock = 0.0
    velocity.x = 0.0
    buffered_attack = false
    hitstop_left = 0.0
    _show_clip("roll", 0.0)
    sfx_roll.play()

func _update_roll(delta: float) -> void:
    roll_clock += delta
    if roll_clock < ROLL_STARTUP:
        velocity.x = 0.0
    elif roll_clock < ROLL_STARTUP + ROLL_INVULNERABLE:
        velocity.x = float(roll_direction) * ROLL_SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, Config.PLAYER_ROLL_DECEL * delta)
    if roll_clock >= ROLL_DURATION:
        action = "normal"
        _restore_safe_collider()
        roll_clock = ROLL_DURATION

func _cancel_attack() -> void:
    action = "normal"
    attack_step = 0
    attack_clock = 0.0
    buffered_attack = false
    combo_next = 1
    combo_left = 0.0
    attack_already_hit.clear()
    debug_rect = Rect2()
    shockwave_rect = Rect2()
    shockwave_done = false
    hitstop_left = 0.0
    pending_cancel_direction = 0
    direction_cancel_buffer_left = 0.0
    queue_redraw()

func _restore_safe_collider() -> void:
    if _can_stand():
        _set_standing_collider()
        crouching = false
    else:
        _set_crouching_collider()
        crouching = true

func _set_standing_collider() -> void:
    var box := collider.shape as RectangleShape2D
    box.size = STAND_BOX
    collider.position.y = STAND_CENTER_Y

func _set_crouching_collider() -> void:
    var box := collider.shape as RectangleShape2D
    box.size = CROUCH_BOX
    collider.position.y = CROUCH_CENTER_Y

func _set_short_collider() -> void:
    var box := collider.shape as RectangleShape2D
    box.size = ROLL_BOX
    collider.position.y = ROLL_CENTER_Y

func is_roll_invulnerable() -> bool:
    return action == "roll" and roll_clock >= ROLL_STARTUP and roll_clock < ROLL_STARTUP + ROLL_INVULNERABLE

func receive_damage(amount: int, opts: Dictionary = {}) -> bool:
    var stagger: bool = bool(opts.get("stagger", true))
    var grant_grace: bool = bool(opts.get("grant_grace", true))
    if transition_locked or amount <= 0 or action == "dead" or is_roll_invulnerable():
        return false
    # Tick damage has its own clock and must not inherit ordinary hit grace.
    if grant_grace and damage_grace > 0.0:
        return false
    if opts.has("tick_group"):
        var group: String = str(opts["tick_group"])
        var source: int = int(opts.get("tick_source", 0))
        var previous: Dictionary = tick_sources.get(group, {})
        if not previous.is_empty() and source != int(previous["source"]) and damage_tick_clock - float(previous["clock"]) < float(opts.get("overlap_interval", 0.2)):
            return false
        tick_sources[group] = {"source": source, "clock": damage_tick_clock}
    hp = maxi(0, hp - amount)
    flash_time = Config.PLAYER_DAMAGE_FLASH_SECONDS
    shake_time = Config.PLAYER_DAMAGE_SHAKE_SECONDS
    if stagger:
        _play_shared_sfx("player_hurt")
    damage_received.emit(amount, hp)
    if hp == 0:
        pull_left = 0.0
        if action == "roll":
            _restore_safe_collider()
        _cancel_attack()
        action = "dead"
        death_clock = 0.0
        died.emit()
        return true
    if grant_grace:
        damage_grace = Config.PLAYER_DAMAGE_GRACE_SECONDS
    if stagger:
        pull_left = 0.0
        if action == "roll":
            _restore_safe_collider()
        _cancel_attack()
        action = "hurt"
        hurt_clock = 0.0
        hurt_duration = maxf(0.0, float(opts.get("stagger_seconds", opts.get("hurt_duration", Config.PLAYER_HURT_SECONDS))))
    var knockback: Variant = opts.get("knockback", Vector2.ZERO)
    if knockback is Vector2 and knockback != Vector2.ZERO:
        velocity += knockback
    return true

func is_transition_locked() -> bool:
    return transition_locked

func set_transition_locked(locked: bool) -> void:
    if transition_locked == locked:
        return
    transition_locked = locked
    if locked:
        _transition_visual = {"clip": displayed_clip, "clock": display_clock}
        for sound in [sfx_attack, sfx_roll, sfx_jump, sfx_step, sfx_land]:
            if sound != null:
                sound.stop()
    else:
        end_portal_walk()
        var saved_clip: String = str(_transition_visual.get("clip", "idle"))
        _show_clip(saved_clip, float(_transition_visual.get("clock", 0.0)))
        _transition_visual.clear()
    queue_redraw()

# Door choreography changes presentation only. Combat state, velocity, facing,
# roll progress and all other gameplay clocks resume when the lock is released.
func begin_portal_walk(direction: float) -> void:
    _portal_walking = true
    _portal_walk_direction = 1 if direction >= 0.0 else -1
    _portal_walk_clock = 0.0

func end_portal_walk() -> void:
    _portal_walking = false

func _request_run_restart() -> void:
    if _restart_requested:
        return
    _restart_requested = true
    var manager := get_node_or_null("/root/SceneManager")
    if manager != null and manager.player == self:
        manager.restart_run.call_deferred()
    else:
        get_tree().reload_current_scene()

func reset_run_state() -> void:
    _cancel_attack()
    hp = MAX_HP
    facing = 1
    action = "normal"
    velocity = Vector2.ZERO
    roll_clock = 0.0
    roll_direction = 1
    hurt_clock = 0.0
    hurt_duration = Config.PLAYER_HURT_SECONDS
    death_clock = 0.0
    damage_grace = 0.0
    hitstop_left = 0.0
    coyote_left = 0.0
    jump_buffer_left = 0.0
    jump_start_left = 0.0
    landing_left = 0.0
    crouching = false
    crouch_enter_left = 0.0
    crouch_exit_left = 0.0
    drop_mask_left = 0.0
    flash_time = 0.0
    shake_time = 0.0
    step_timer = 0.0
    _restart_requested = false
    pull_left = 0.0
    pull_elapsed = 0.0
    pull_escaped = false
    air_direction_cancels = 0
    tick_sources.clear()
    damage_tick_clock = 0.0
    end_portal_walk()
    _set_standing_collider()
    collision_mask = Config.PLAYER_COLLISION_MASK
    camera.offset = Vector2.ZERO
    modulate = Color.WHITE
    _show_clip("idle", 0.0)
    if transition_locked:
        _transition_visual = {"clip": "idle", "clock": 0.0}
    damage_received.emit(0, hp)

func heal(amount: int) -> int:
    if amount <= 0 or action == "dead" or transition_locked:
        return 0
    var restored: int = mini(amount, MAX_HP - hp)
    hp += restored
    return restored

func _play_shared_sfx(name: String) -> void:
    var audio: Node = get_node_or_null("/root/Audio")
    if audio != null and audio.has_method("play_sfx"):
        audio.call("play_sfx", name, global_position)

func _record_landing(was_grounded: bool, vertical_speed: float) -> void:
    if not was_grounded and is_on_floor():
        landing_left = Config.PLAYER_LANDING_SOFT_SECONDS if vertical_speed < Config.PLAYER_LANDING_HARD_THRESHOLD else Config.PLAYER_LANDING_HARD_SECONDS
        if sfx_land != null:
            sfx_land.play()

func _refresh_attack_visual() -> void:
    if action == "attack":
        _show_clip("attack_%d" % attack_step, attack_clock)
    else:
        _refresh_normal_visual(0.0)

func _refresh_normal_visual(delta: float) -> void:
    var clip_name: String = "idle"
    var specific_t: float = -1.0
    if crouching:
        if crouch_enter_left > 0.0:
            clip_name = "crouch_enter"
            specific_t = Config.PLAYER_CROUCH_ENTER_SECONDS - crouch_enter_left
        else:
            clip_name = "crouch_idle"
    elif crouch_exit_left > 0.0:
        clip_name = "crouch_exit"
        specific_t = Config.PLAYER_CROUCH_EXIT_SECONDS - crouch_exit_left
    elif not is_on_floor():
        if velocity.y < 0.0:
            clip_name = "jump_start" if jump_start_left > 0.0 else "jump_rise"
            if clip_name == "jump_start":
                specific_t = Config.PLAYER_JUMP_START_SECONDS - jump_start_left
        else:
            clip_name = "fall"
    elif landing_left > 0.0:
        clip_name = "land"
        specific_t = Config.PLAYER_LANDING_CLIP_SECONDS - landing_left
    elif absf(velocity.x) > Config.PLAYER_IDLE_SPEED_THRESHOLD:
        clip_name = "run"
    _show_clip(clip_name, specific_t, delta)

func _show_clip(name: String, explicit_time: float = -1.0, delta: float = 0.0) -> void:
    if not clip_data.has(name):
        return
    if displayed_clip != name:
        displayed_clip = name
        display_clock = 0.0
        visual.texture = textures[name]
    if explicit_time >= 0.0:
        display_clock = explicit_time
    else:
        display_clock += delta
    var clip: Dictionary = clip_data[name]
    var count: int = int(clip.get("frames", 1))
    var duration: float = maxf(0.001, float(clip.get("duration_seconds", 1.0)))
    var looped: bool = bool(clip.get("loop", false))
    var local_t: float = fmod(display_clock, duration) if looped else minf(display_clock, duration)
    var index: int = clampi(int(floor(local_t * float(count) / duration)), 0, count - 1)
    var boundaries: Array = clip.get("frame_boundaries_seconds", [])
    if boundaries.size() == count + 1:
        index = count - 1
        for frame in range(count):
            if local_t < float(boundaries[frame + 1]):
                index = frame
                break
    var width: int = int(clip.get("frame_width", 512))
    var height: int = int(clip.get("frame_height", 512))
    var cols: int = int(clip.get("columns", 1))
    visual.region_rect = Rect2(Vector2((index % cols) * width, floori(float(index) / float(cols)) * height), Vector2(width, height))
    var anchor: Array = clip.get("anchor_px", [256, 468])
    var anchor_x: float = float(anchor[0])
    var anchor_y: float = float(anchor[1])
    visual.offset = Vector2(width * 0.5 - anchor_x, height * 0.5 - anchor_y)
    visual.flip_h = facing < 0
    visual.modulate = Color("e2fcff") if flash_time > 0.0 else Color.WHITE

func _update_camera_shake(delta: float) -> void:
    shake_time = maxf(0.0, shake_time - delta)
    if shake_time <= 0.0:
        camera.offset = Vector2.ZERO
        return
    var t: float = Time.get_ticks_msec() / 1000.0
    camera.offset = Vector2(cos(t * Config.PLAYER_SHAKE_SPEED.x), sin(t * Config.PLAYER_SHAKE_SPEED.y)) * Config.PLAYER_SHAKE_STRENGTH

func _update_footsteps(delta: float) -> void:
    var moving: bool = is_on_floor() and action == "normal" and absf(velocity.x) > Config.PLAYER_STEP_SPEED_THRESHOLD and not crouching
    if not moving:
        step_timer = 0.0
        return
    step_timer -= delta
    if step_timer <= 0.0:
        sfx_step.play()
        step_timer = Config.PLAYER_RUN_STEP_SECONDS if absf(velocity.x) > RUN_SPEED * Config.PLAYER_STEP_RUN_THRESHOLD else Config.PLAYER_WALK_STEP_SECONDS

func _play_attack_sfx(step: int) -> void:
    if step < 1 or step >= Config.PLAYER_ATTACK_SOUND_PATHS.size():
        return
    sfx_attack.stream = load(Config.PLAYER_ATTACK_SOUND_PATHS[step]) as AudioStream
    sfx_attack.play()

func _draw() -> void:
    if debug_hitboxes and not transition_locked:
        if debug_rect.size != Vector2.ZERO:
            draw_rect(debug_rect, Color(0.2, 1.0, 0.95, 0.25), true)
            draw_rect(debug_rect, Color(0.2, 1.0, 0.95, 0.85), false, 2.0)
        if shockwave_rect.size != Vector2.ZERO:
            draw_rect(shockwave_rect, Color(1.0, 0.9, 0.3, 0.22), true)
            draw_rect(shockwave_rect, Color(1.0, 0.9, 0.3, 0.85), false, 2.0)
