class_name Stage5Enemy
extends EnemyBase

@export var perch_kind: String = "ceiling"
var perched: bool = false
var phase: String = ""
var dive_target: Vector2
var dive_direction: Vector2
var charge_start: Vector2
var contact_left: float = 0.0
var fuse_started: bool = false
var fuse_clock: float = 0.0
var beep_left: float = 0.0
var tick_count: int = 0
var tick_next: float = 0.0
var flame_damaged: bool = false
var flame_effect: Node2D
var loop_sound: Node
var chain_visual: Sprite2D
var hook_visual: Node2D
var pulled_player: NimrodPlayer
var after_tail_turn: bool = false
var forced_turn_seconds: float = 0.0
var guard_left: float = 0.0
var gas_released: bool = false

func _ready() -> void:
    super._ready()
    perched = enemy_id == "wall_diver"
    if enemy_id in ["gas_sac", "wraith_ray"]:
        collision_mask = 0 if enemy_id == "wraith_ray" else SURFACE_MASK
    if enemy_id == "chain_beastman":
        _make_chain()
    if enemy_id == "wraith_ray":
        loop_sound = _play_sfx("wraith_wail_loop")
    _update_visual(0.0)

func _physics_process(delta: float) -> void:
    contact_left = maxf(0.0, contact_left - delta)
    guard_left = maxf(0.0, guard_left - delta)
    if enemy_id == "corpse_bomber" and fuse_started and state != State.DEAD:
        fuse_clock += delta
        beep_left -= delta
        if beep_left <= 0.0:
            _play_sfx("corpse_fuse_beep")
            beep_left = maxf(float(common["corpse_beep_min"]), (float(stats["fuse_seconds"]) - fuse_clock) * float(common["corpse_beep_factor"]))
        visual.modulate = Color(1.0, 0.3, 0.3) if sin(fuse_clock * (float(common["corpse_blink_start"]) + fuse_clock * float(common["corpse_blink_acceleration"]))) > 0.0 else Color.WHITE
        if fuse_clock >= float(stats["fuse_seconds"]):
            _die()
    super._physics_process(delta)

func _integrate_motion(delta: float) -> void:
    if enemy_id in ["gas_sac", "wraith_ray"]:
        if collision_mask != 0:
            move_and_slide()
        if collision_mask == 0:
            global_position += velocity * delta
        return
    if enemy_id == "root_spewer" or perched:
        velocity = Vector2.ZERO
        return
    if enemy_id == "wall_diver" and phase == "perch_dive":
        move_and_slide()
        if is_on_wall() or is_on_floor():
            _land_claw()
        return
    super._integrate_motion(delta)
    if enemy_id == "boar_charger" and state == State.ACTIVE and is_on_wall():
        phase = "crash"
        velocity = Vector2.ZERO
        stun_left = float(stats["crash_stun"])
        recovery_after_stun = 0.0
        _set_state(State.STUN)
        attack_cooldown_left = float(attack_stats["cooldown"])

func _enforce_bounds() -> void:
    super._enforce_bounds()
    if enemy_id in ["gas_sac", "wraith_ray"] or perched or (enemy_id == "wall_diver" and phase == "perch_dive"):
        var level: Node = _level()
        if level != null:
            var top: float = level.camera_limits.position.y + body_size.y * 0.5
            var bottom: float = level.ground_y_at(global_position.x) - body_size.y * 0.5
            global_position.y = clampf(global_position.y, top, bottom)

func _update_idle(delta: float) -> void:
    var player: Node2D = _target()
    if perched:
        velocity = Vector2.ZERO
        if not _player_is_available(player):
            return
        var diff: Vector2 = player.global_position - global_position
        var sensor: Array = stats["sensor_ceiling"] if perch_kind == "ceiling" else stats["sensor_wall"]
        var detected: bool = absf(diff.x) <= float(sensor[0]) and (diff.y >= 0.0 and diff.y <= float(sensor[1]) if perch_kind == "ceiling" else absf(diff.y) <= float(sensor[1]))
        detected = detected or (diff.length() <= float(stats.get("detect_range",700)) and _perch_line_clear(player))
        if detected:
            var toward: int = 1 if diff.x >= 0.0 else -1
            if toward != facing:
                _request_turn(toward)
                return
            phase = "perch_tell"
            dive_target = _player_rect(player).get_center()
            _begin_attack()
        return
    if enemy_id == "corpse_bomber" and _can_detect(player):
        _ignite_fuse()
        return
    super._update_idle(delta)

func _update_chase(delta: float) -> void:
    var player: Node2D = _target()
    if not _can_detect(player):
        velocity.y = 0.0 if enemy_id in ["gas_sac", "wraith_ray"] else velocity.y
        _set_state(State.IDLE)
        _brake(delta)
        return
    var difference: float = player.global_position.x - global_position.x
    var distance: float = absf(difference)
    var direction: int = 1 if difference >= 0.0 else -1
    if enemy_id == "corpse_bomber":
        if not fuse_started:
            _ignite_fuse()
            return
        if direction != facing:
            _request_turn(direction)
        else:
            velocity.x = facing * float(stats["move_speed"])
        return
    if enemy_id in ["gas_sac", "wraith_ray"]:
        if direction != facing:
            _request_turn(direction)
            return
        velocity = global_position.direction_to(_player_rect(player).get_center()) * float(stats["move_speed"])
        _contact_hit(player)
        return
    if enemy_id == "root_spewer":
        velocity = Vector2.ZERO
        var sensor: Array = stats["sensor"]
        if absf(difference) <= float(sensor[0]) and player.global_position.y <= global_position.y and global_position.y - player.global_position.y <= float(sensor[1]) and attack_cooldown_left <= 0.0:
            _begin_attack()
        return
    if direction != facing:
        if enemy_id == "shell_scorpion" and distance <= float(stats["back_range"]) and randf() < float(stats["tail_chance"]):
            attack_stats = stats["attacks"][1]
            phase = "tail"
            after_tail_turn = true
            _begin_attack()
        else:
            _request_turn(direction)
        _brake(delta)
        return
    if enemy_id == "explosive_spitter":
        var preferred: Array = stats["preferred_distance"]
        if distance < float(preferred[0]):
            velocity.x = -facing * float(stats["move_speed"])
            return
        if distance > float(preferred[1]):
            velocity.x = facing * float(stats["move_speed"])
            return
        if attack_cooldown_left > 0.0:
            _brake(delta)
            return
    if enemy_id == "chain_beastman":
        if distance <= float(stats["attacks"][0]["range"]):
            attack_stats = stats["attacks"][0]
            phase = "tail"
            _begin_attack()
            return
        if distance <= float(stats["chain"]["range"]) and attack_cooldown_left <= 0.0:
            attack_stats = stats["attacks"][1]
            phase = "chain"
            _begin_attack()
            return
    elif distance <= float(attack_stats.get("range", 0.0)) and attack_cooldown_left <= 0.0:
        if enemy_id == "shell_scorpion":
            attack_stats = stats["attacks"][0]
            phase = "claw"
        _begin_attack()
        return
    velocity.x = facing * float(stats["move_speed"])

func _ignite_fuse() -> void:
    fuse_started = true
    fuse_clock = 0.0
    beep_left = 0.0
    phase = "scream"
    velocity.x = 0.0
    _set_state(State.WINDUP)
    _play_sfx("corpse_scream")

func _request_turn(direction: int) -> void:
    forced_turn_seconds = float(stats.get("back_turn_delay", 0.0)) if enemy_id == "shell_scorpion" and is_instance_valid(_target()) and absf(_target().global_position.x - global_position.x) <= float(stats["back_range"]) else 0.0
    super._request_turn(direction)

func _turn_seconds() -> float:
    return forced_turn_seconds if forced_turn_seconds > 0.0 else super._turn_seconds()

func _begin_attack() -> void:
    attack_has_hit = false
    velocity.x = 0.0
    _set_state(State.WINDUP)
    _play_sfx(enemy_id + "_windup")

func _update_windup(delta: float) -> void:
    _brake(delta)
    var seconds: float = float(attack_stats.get("windup", 0.0))
    if phase == "perch_tell":
        seconds = float(stats["tell_seconds"])
    elif phase == "scream":
        seconds = float(stats["scream_seconds"])
    elif phase == "smash_windup":
        seconds = float(attack_stats["smash_windup"])
    if state_clock >= seconds:
        if phase == "scream":
            phase = "run"
            _set_state(State.CHASE)
        else:
            _begin_active()

func _begin_active() -> void:
    _set_state(State.ACTIVE)
    _play_sfx(enemy_id + "_attack")
    if phase == "perch_tell":
        perched = false
        phase = "perch_dive"
        dive_direction = global_position.direction_to(dive_target)
        velocity = dive_direction * float(stats["dive_speed"])
        _play_sfx("wall_diver_screech")
    elif enemy_id == "boar_charger":
        charge_start = global_position
        velocity.x = facing * float(stats["charge_speed"])
        _play_sfx("boar_charge_rumble")
    elif enemy_id == "root_spewer":
        tick_count = 0
        tick_next = 0.0
        flame_damaged = false
        _play_sfx("beast_ranged_flame_start")
        loop_sound = _play_sfx("beast_ranged_flame_loop")
        var box: Rect2 = get_attack_rect()
        flame_effect = IMAGE_EFFECT.new()
        flame_effect.configure("res://assets/sprites/fx/root_flame.webp", Vector2i(256, 512), 6, 0.6, true, Vector2(128, 508))
        flame_effect.scale = Vector2(box.size.x / 256.0, box.size.y / 512.0)
        add_child(flame_effect)
    elif enemy_id == "chain_beastman":
        if phase == "chain":
            phase = "chain_throw"
            attack_cooldown_left = float(attack_stats["cooldown"])
            _play_sfx("chain_launch")
        elif phase == "smash_windup":
            phase = "smash"
            attack_has_hit = false

func _update_active(delta: float) -> void:
    var seconds: float = float(attack_stats.get("active", 0.0))
    if enemy_id == "explosive_spitter":
        if not attack_has_hit:
            attack_has_hit = true
            var player: Node2D = _target()
            if _player_is_available(player):
                var projectile := Stage5Projectile.new()
                projectile.configure(stats["projectile"], _player_rect(player).get_center())
                projectile.position = get_parent().to_local(global_position + Vector2(facing * body_size.x * 0.4, -body_size.y * 0.7))
                get_parent().add_child(projectile)
                _play_sfx("spit_launch")
    elif enemy_id == "wall_diver" and phase == "perch_dive":
        if global_position.distance_to(dive_target) <= float(stats["dive_speed"]) * delta or state_clock >= float(stats["dive_seconds"]):
            _land_claw()
        return
    elif enemy_id == "root_spewer":
        while tick_count < int(attack_stats["tick_count"]) and state_clock + TIME_EPSILON >= tick_next:
            _flame_tick()
    elif enemy_id == "boar_charger":
        velocity.x = facing * float(stats["charge_speed"])
        var ahead: Vector2 = global_position + Vector2(facing * (body_size.x * 0.5 + float(common["ledge_probe_x"])), 0.0)
        var probe := PhysicsRayQueryParameters2D.create(ahead - Vector2(0, 5), ahead + Vector2(0, float(common["ledge_probe_down"])), SURFACE_MASK)
        var player: Node2D = _target()
        probe.exclude = [get_rid()]
        if player is PhysicsBody2D:
            probe.exclude.append(player.get_rid())
        if get_world_2d().direct_space_state.intersect_ray(probe).is_empty() or absf(global_position.x - charge_start.x) >= float(stats["charge_distance"]):
            _finish_active()
            return
        _melee_hit()
    elif enemy_id == "chain_beastman":
        _update_chain(delta)
        return
    else:
        _melee_hit()
        if enemy_id == "wall_diver" and phase == "landing_claw":
            seconds = float(attack_stats["active"])
    if state_clock >= seconds:
        _finish_active()

func _land_claw() -> void:
    phase = "landing_claw"
    velocity = Vector2.ZERO
    attack_has_hit = false
    _set_state(State.ACTIVE)

func _melee_hit() -> void:
    var player: Node2D = _target()
    if not attack_has_hit and _player_in_attack(player):
        var opts: Dictionary = {"knockback": Vector2(facing * float(stats.get("contact_knockback", 0.0)), 0)}
        attack_has_hit = bool(player.call("receive_damage", int(attack_stats["damage"]), opts))

func _flame_tick() -> void:
    tick_count += 1
    tick_next = tick_count * float(attack_stats["tick_interval"])
    var player: Node2D = _target()
    if _player_in_attack(player):
        var accepted: bool = player.receive_damage(int(attack_stats["damage"]), {"stagger": not flame_damaged, "stagger_seconds": float(attack_stats["first_stagger"]), "grant_grace": false, "tick_group": "root_flame", "tick_source": get_instance_id(), "overlap_interval": float(common["overlap_tick_seconds"])})
        flame_damaged = flame_damaged or accepted

func _contact_hit(player: Node2D) -> void:
    if contact_left <= 0.0 and _player_is_available(player) and get_hurt_rect().intersects(_player_rect(player)):
        if player.receive_damage(int(stats["contact_damage"]), {"stagger": enemy_id != "wraith_ray"}):
            contact_left = float(stats["contact_interval"])

func _finish_active() -> void:
    _stop_flame()
    if enemy_id != "chain_beastman":
        attack_cooldown_left = float(attack_stats.get("cooldown", 0.0))
    var recovery: float = float(stats["landing_recovery"]) if enemy_id == "wall_diver" and phase == "landing_claw" else float(attack_stats.get("recovery", 0.0))
    _begin_recovery(recovery)

func _update_recovery(delta: float) -> void:
    if state_clock >= recovery_duration and enemy_id == "shell_scorpion" and after_tail_turn:
        after_tail_turn = false
        attack_stats = stats["attacks"][0]
        _set_state(State.CHASE)
        _request_turn(-facing)
        return
    super._update_recovery(delta)

func _update_stun(delta: float) -> void:
    if enemy_id == "boar_charger" and phase == "crash":
        _brake(delta)
        stun_left = maxf(0.0, stun_left - delta)
        if stun_left <= 0.0:
            phase = ""
            _set_state(State.CHASE)
        return
    super._update_stun(delta)

func _on_hit(seconds: float) -> void:
    if enemy_id == "boar_charger" and state in [State.WINDUP, State.ACTIVE]:
        return
    if enemy_id == "chain_beastman" and phase == "tail" and state in [State.WINDUP, State.ACTIVE, State.RECOVERY]:
        return
    if enemy_id == "root_spewer" and state in [State.WINDUP, State.ACTIVE]:
        _stop_flame()
        attack_cooldown_left = float(attack_stats["cooldown"])
        _apply_stun(float(attack_stats["interrupt_stun"]), true)
        recovery_after_stun = 0.0
        return
    if enemy_id == "explosive_spitter" and state == State.WINDUP:
        attack_cooldown_left = float(attack_stats["cooldown"])
    if enemy_id == "wall_diver":
        perched = false
        phase = ""
    if enemy_id == "chain_beastman":
        _release_pull()
        _hide_chain()
    _apply_stun(seconds)

func _receive_hit(damage: int, from_pos: Vector2, step: int, shockwave: bool) -> Dictionary:
    if enemy_id == "shell_scorpion" and state != State.DEAD and (from_pos.x - global_position.x) * facing >= 0.0:
        Stage5FX.spawn(get_parent(), "guard_spark", get_hurt_rect().get_center(), Vector2.ONE * 192.0 * float(common["guard_spark_scale"]))
        _play_sfx("guard_block")
        guard_left = float(common["guard_spark_seconds"])
        return {"blocked": true, "damage_dealt": 0}
    return super._receive_hit(damage, from_pos, step, shockwave)

func get_attack_rect() -> Rect2:
    if state != State.ACTIVE:
        return Rect2()
    if enemy_id == "chain_beastman" and phase != "tail" and phase != "smash":
        return Rect2()
    var rect: Rect2 = super.get_attack_rect()
    if enemy_id == "root_spewer":
        rect.position.x = global_position.x - rect.size.x * 0.5
    if enemy_id == "shell_scorpion" and phase == "tail":
        var box: Dictionary = attack_stats["hitbox"]
        rect.position.x = global_position.x + (-float(box["offset_x"]) - rect.size.x if facing > 0 else float(box["offset_x"]))
    return rect

func _on_death() -> void:
    _stop_flame()
    _release_pull()
    _hide_chain()
    if enemy_id == "corpse_bomber":
        queue_player_effect(_spawn_hazard.bind("explosion", stats["explosion"].duplicate(true)))
    super._on_death()
    if enemy_id == "gas_sac":
        _show_clip("death_swell", 0.0)
    elif enemy_id == "corpse_bomber":
        _show_clip("explode", 0.0)

func _spawn_hazard(kind: String, settings: Dictionary) -> Stage5Hazard:
    var hazard := Stage5Hazard.new()
    hazard.configure(kind, settings)
    hazard.position = get_parent().to_local(get_hurt_rect().get_center())
    get_parent().add_child(hazard)
    return hazard

func _update_dead(delta: float) -> void:
    if enemy_id == "gas_sac":
        state_clock += delta
        _show_clip("death_swell", state_clock)
        visual.modulate = Color(1.0, 0.65, 0.3) if sin(state_clock * float(common["gas_blink_rate"])) > 0.0 else Color.WHITE
        if not gas_released and state_clock >= float(stats["death_swell_seconds"]):
            gas_released = true
            _play_sfx("gas_burst")
            _spawn_hazard("gas", stats["gas"])
        if gas_released:
            _show_clip("burst", state_clock - float(stats["death_swell_seconds"]))
            if state_clock >= float(stats["death_swell_seconds"]) + float(clip_data.get("burst", {}).get("duration_seconds", 0.3)):
                queue_free()
    elif enemy_id == "corpse_bomber":
        state_clock += delta
        _show_clip("explode", state_clock)
        if state_clock >= float(clip_data.get("explode", {}).get("duration_seconds", 0.3)):
            queue_free()
    else:
        super._update_dead(delta)

func _update_visual(delta: float) -> void:
    if visual == null:
        return
    if state == State.DEAD:
        return
    display_clock += delta
    var clip: String = "idle"
    if perched:
        clip = "perch_ceiling" if perch_kind == "ceiling" else "perch_wall"
    elif enemy_id == "gas_sac":
        clip = "float"
    elif enemy_id == "wraith_ray":
        clip = "glide"
    elif absf(velocity.x) > 0.0:
        clip = "crawl" if enemy_id == "wall_diver" else "run" if enemy_id == "corpse_bomber" else "walk"
    match state:
        State.WINDUP:
            clip = "tell" if phase == "perch_tell" else "scream" if phase == "scream" else "telegraph" if enemy_id == "boar_charger" else phase + "_windup" if enemy_id == "chain_beastman" or enemy_id == "shell_scorpion" else "windup"
            if phase == "smash_windup":
                clip = "smash_windup"
        State.ACTIVE:
            clip = "spit" if enemy_id == "explosive_spitter" else "spew" if enemy_id == "root_spewer" else "charge" if enemy_id == "boar_charger" else "dive" if phase == "perch_dive" else "claw"
            if enemy_id == "shell_scorpion":
                clip = "tail_strike" if phase == "tail" else "claw_attack"
            if enemy_id == "chain_beastman":
                clip = {"tail": "tail_sweep", "chain_throw": "chain_throw", "pull": "pull_hold", "pull_pending": "chain_throw", "smash": "smash"}.get(phase, "idle")
        State.RECOVERY:
            clip = phase + "_recovery" if enemy_id == "shell_scorpion" else "tail_recovery" if enemy_id == "chain_beastman" and phase == "tail" else "smash_recovery" if enemy_id == "chain_beastman" else "recovery"
        State.TURN:
            clip = "turn"
        State.STUN:
            clip = "crash_stun" if phase == "crash" else "hurt"
    if guard_left > 0.0:
        clip = "guard_block"
    _show_clip(clip, state_clock if state not in [State.IDLE, State.CHASE] else display_clock)

func _stop_flame() -> void:
    if is_instance_valid(flame_effect):
        flame_effect.queue_free()
    flame_effect = null
    if is_instance_valid(loop_sound) and enemy_id == "root_spewer":
        get_node("/root/Audio").stop_sfx(loop_sound)
        loop_sound = null

func _make_chain() -> void:
    chain_visual = Sprite2D.new()
    chain_visual.name = "ChainPNG"
    chain_visual.centered = false
    chain_visual.region_enabled = true
    chain_visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    var path: String = "res://assets/sprites/fx/chain_segment.webp"
    if ResourceLoader.exists(path):
        chain_visual.texture = load(path)
    else:
        AssetVisual.add_image(chain_visual, path, Vector2.ZERO, Vector2(64,24))
    add_child(chain_visual)
    hook_visual = Stage5FX.spawn(self, "chain_hook", global_position)
    _hide_chain()

func _hide_chain() -> void:
    if is_instance_valid(chain_visual):
        chain_visual.visible = false
    if is_instance_valid(hook_visual):
        hook_visual.visible = false

func _release_pull() -> void:
    if is_instance_valid(pulled_player):
        pulled_player.pull_left = 0.0
    pulled_player = null

func _update_chain(_delta: float) -> void:
    if phase == "tail":
        _melee_hit()
        if state_clock >= float(attack_stats["active"]):
            _finish_active()
        return
    var player := _target() as NimrodPlayer
    if phase == "chain_throw":
        var chain: Dictionary = stats["chain"]
        var length: float = float(chain["range"]) * minf(1.0, state_clock / float(chain["throw_seconds"]))
        var height: float = float(common["chain_height_offset"])
        if chain_visual != null:
            chain_visual.visible = true
            chain_visual.position = Vector2(0.0 if facing > 0 else -length, height)
            chain_visual.region_rect = Rect2(0, 0, length, 24)
        if hook_visual != null:
            hook_visual.visible = true
            hook_visual.position = Vector2(facing * length, height)
        var hook := Rect2(global_position + Vector2(minf(0.0, facing * length), height - 12), Vector2(length, 24))
        if _player_is_available(player) and not player.is_roll_invulnerable() and hook.intersects(_player_rect(player)):
            pulled_player = player
            phase = "pull_pending"
            queue_player_effect(_apply_chain_pull.bind(player, global_position.x + facing * float(chain["pull_offset"]), float(chain["pull_seconds"])))
            return
        if state_clock >= float(chain["throw_seconds"]):
            _hide_chain()
            _begin_recovery(float(chain["miss_recovery"]))
    elif phase == "pull":
        if state_clock >= float(stats["chain"]["pull_seconds"]):
            _release_pull()
            _hide_chain()
            phase = "smash_windup"
            _set_state(State.WINDUP)
    elif phase == "smash":
        _melee_hit()
        if state_clock >= float(attack_stats["smash_active"]):
            _finish_active()

func _exit_tree() -> void:
    _release_pull()
    if is_instance_valid(loop_sound):
        get_node("/root/Audio").stop_sfx(loop_sound)

func _apply_chain_pull(player: NimrodPlayer, target_x: float, seconds: float) -> void:
    if not is_instance_valid(player) or state == State.DEAD or phase != "pull_pending":
        return
    if player.apply_pull(target_x, seconds):
        phase = "pull"
        _set_state(State.ACTIVE)
        _play_sfx("chain_pull")
    else:
        _hide_chain()
        _begin_recovery(float(stats["chain"]["miss_recovery"]))

func _perch_line_clear(player: Node2D) -> bool:
    var query := PhysicsRayQueryParameters2D.create(global_position,_player_rect(player).get_center(),collision_mask,[get_rid(),player.get_rid()])
    return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
