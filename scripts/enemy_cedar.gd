class_name CedarEnemy
extends EnemyBase

var phase: String = ""
var guard_left: float = 0.0
var guard_broken_left: float = 0.0
var hop_cooldown: float = 0.0
var hop_start := Vector2.ZERO
var perched: bool = false
var next_pattern: int = 0
var tick_index: int = 0
var forced_roll: float = -1.0
var loop_sound: Node

func _ready() -> void:
    super._ready()
    if enemy_id == "cedar_wisp":
        collision_mask = 0
        loop_sound = _play_sfx("wisp_wail_loop")
    perched = enemy_id == "cedar_demon"
    _update_visual(0)

func _roll() -> float:
    return forced_roll if forced_roll >= 0.0 else randf()

func _physics_process(delta: float) -> void:
    guard_broken_left = maxf(0, guard_broken_left - delta)
    hop_cooldown = maxf(0, hop_cooldown - delta)
    guard_left = maxf(0, guard_left - delta)
    super._physics_process(delta)

func _integrate_motion(delta: float) -> void:
    if enemy_id == "cedar_wisp":
        global_position += velocity * delta
    elif perched:
        velocity = Vector2.ZERO
    elif phase == "hop":
        var fraction: float = clampf(state_clock / float(stats["hop"]["seconds"]), 0, 1)
        var desired: Vector2 = hop_start + Vector2(-facing * float(stats["hop"]["distance"]) * fraction, -sin(PI * fraction) * float(stats["hop"]["height"]))
        move_and_collide(desired - global_position)
        velocity = Vector2.ZERO
    else:
        super._integrate_motion(delta)

func _enforce_bounds() -> void:
    if enemy_id == "cedar_wisp":
        var level: Node = _level()
        if level != null:
            var limits: Rect2 = level.camera_limits
            global_position = Vector2(clampf(global_position.x, limits.position.x + body_size.x * .5, limits.end.x - body_size.x * .5), clampf(global_position.y, limits.position.y + body_size.y * .5, limits.end.y - body_size.y * .5))
    else:
        super._enforce_bounds()

func _update_idle(delta: float) -> void:
    if perched:
        var hero: Node2D = _target()
        if hero != null:
            var sensor: Array = stats["perch_sensor"]
            var difference: Vector2 = hero.global_position - global_position
            if _player_is_available(hero) and absf(difference.x) <= float(sensor[0]) and difference.y > 0 and difference.y <= float(sensor[1]):
                phase = "tell"
                _set_state(State.WINDUP)
                _play_sfx("demon_screech")
        return
    if enemy_id == "cedar_wisp":
        _update_chase(delta)
        return
    super._update_idle(delta)

func _update_chase(delta: float) -> void:
    var player: Node2D = _target()
    if not _can_detect(player):
        _set_state(State.IDLE)
        _brake(delta)
        return
    var difference: Vector2 = player.global_position - global_position
    if enemy_id == "cedar_wisp":
        var desired: int = -1 if difference.x < 0 else 1
        if desired != facing:
            _request_turn(desired)
            return
        velocity = difference.normalized() * float(stats["move_speed"])
        if get_hurt_rect().intersects(_player_rect(player)):
            player.receive_damage(int(stats["contact_damage"]))
            _start_fuse()
        return
    if guard_left > 0.0:
        velocity.x = 0
        return
    var direction: int = -1 if difference.x < 0 else 1
    if direction != facing:
        _request_turn(direction)
        return
    if enemy_id == "cedar_archer":
        if absf(difference.x) <= float(stats["hop"]["range"]) and hop_cooldown <= 0:
            _begin_hop()
            return
        var preferred: Array = stats["preferred_distance"]
        velocity.x = -facing * float(stats["move_speed"]) if absf(difference.x) < float(preferred[0]) else (facing * float(stats["move_speed"]) if absf(difference.x) > float(preferred[1]) else 0.0)
        if velocity.x == 0 and attack_cooldown_left <= 0:
            _begin_attack()
    elif absf(difference.x) <= float(attack_stats.get("range", 170)) and absf(difference.y) < body_size.y and attack_cooldown_left <= 0:
        _begin_attack()
    else:
        velocity.x = facing * float(stats["move_speed"])

func _request_turn(direction: int) -> void:
    if enemy_id == "cedar_colossus" and state in [State.IDLE, State.CHASE] and direction != facing:
        var player: Node2D = _target()
        if player != null and player.get("action") == "roll" and _roll() < float(stats["rear_chance"]):
            pending_facing = direction
            attack_stats = stats["attacks"][2]
            phase = "rear_poke"
            attack_has_hit = false
            _set_state(State.WINDUP)
            return
    super._request_turn(direction)

func _begin_attack() -> void:
    if enemy_id == "cedar_colossus":
        attack_stats = stats["attacks"][next_pattern % 2]
        next_pattern += 1
    else:
        attack_stats = stats["attacks"][0]
    phase = str(attack_stats["id"])
    attack_has_hit = false
    tick_index = 0
    _set_state(State.WINDUP)
    _play_sfx(enemy_id + "_windup")

func _update_windup(delta: float) -> void:
    _brake(delta)
    if phase == "fuse":
        if state_clock >= float(stats["fuse_seconds"]):
            _explode_wisp()
    elif phase == "shield":
        if guard_left <= 0:
            _set_state(State.CHASE)
            phase = ""
    elif phase == "tell":
        if state_clock >= float(clip_data.get("tell", {}).get("duration_seconds", .2)):
            phase = "fall"
            perched = false
            _set_state(State.ACTIVE)
    elif state_clock >= float(attack_stats["windup"]):
        _begin_active()

func _begin_active() -> void:
    _set_state(State.ACTIVE)
    attack_has_hit = false
    _play_sfx(enemy_id + "_attack")
    if enemy_id == "cedar_archer":
        var player: Node2D = _target()
        var at: Vector2 = global_position - Vector2(0, body_size.y * .65)
        _hazard({"fx":"bone_arrow", "size":[96,24], "speed":stats["arrow"]["speed"], "damage":stats["arrow"]["damage"], "seconds":2, "range":stats["arrow"]["range"]}, at, at.direction_to(_player_rect(player).get_center()) if player != null else Vector2(facing, 0))
        _play_sfx("archer_shot")
    elif enemy_id == "cedar_colossus" and phase == "slam":
        var wave: Dictionary = stats["shockwave"]
        _hazard({"fx":"bone_spike_ground", "size":[wave["width"],wave["height"]], "damage":0, "knockback":wave["knockback"], "seconds":wave["seconds"]}, global_position - Vector2(0, float(wave["height"]) * .5))
        _play_sfx("colossus_slam")
        _play_sfx("colossus_shockwave")

func _update_active(delta: float) -> void:
    if phase == "hop":
        if state_clock >= float(stats["hop"]["seconds"]):
            phase = ""
            _begin_recovery(.1)
        return
    if phase == "fall":
        velocity = Vector2(0, float(stats["fall_speed"]))
        if is_on_floor():
            phase = "land_stab"
            attack_stats = stats["attacks"][1]
            _set_state(State.ACTIVE)
            attack_has_hit = false
        return
    if enemy_id == "cedar_sentinel" and phase == "thrust":
        velocity.x = facing * float(attack_stats["forward_distance"]) / float(attack_stats["active"])
    else:
        _brake(delta)
    var player: Node2D = _target()
    if enemy_id == "cedar_demon" and phase == "claws":
        while tick_index < stats["claw_damage"].size() and state_clock + TIME_EPSILON >= tick_index * float(stats["claw_interval"]):
            if _player_in_attack(player):
                player.receive_damage(int(stats["claw_damage"][tick_index]), {"grant_grace":false, "stagger":tick_index==0, "stagger_seconds":.18})
            tick_index += 1
    elif enemy_id != "cedar_archer" and not attack_has_hit and _player_in_attack(player):
        attack_has_hit = bool(player.receive_damage(int(attack_stats["damage"])))
    if state_clock + TIME_EPSILON >= float(attack_stats["active"]):
        if enemy_id == "cedar_sentinel" and phase == "thrust":
            attack_stats = stats["attacks"][1]
            phase = "slash"
            _set_state(State.WINDUP)
        elif phase == "land_stab":
            phase = "claws"
            attack_stats = stats["attacks"][0]
            tick_index = 0
            _set_state(State.WINDUP)
        else:
            attack_cooldown_left = float(attack_stats.get("cooldown", 0))
            _begin_recovery(float(attack_stats["recovery"]))

func _begin_hop() -> void:
    phase = "hop"
    hop_start = global_position
    hop_cooldown = float(stats["hop"]["cooldown"])
    _set_state(State.ACTIVE)
    var hop: Dictionary = stats["hop"]
    _hazard({"fx":"bone_spike_ground", "size":[128,128], "seconds":hop["spike_seconds"], "damage":hop["spike_damage"]}, global_position - Vector2(0,64))
    _play_sfx("bone_spike_pop")

func _hazard(specification: Dictionary, at: Vector2, direction: Vector2 = Vector2.RIGHT) -> CedarHazard:
    var hazard := CedarHazard.new()
    hazard.spec = specification
    hazard.direction = direction
    hazard.position = get_parent().to_local(at)
    get_parent().add_child(hazard)
    return hazard

func get_attack_rect() -> Rect2:
    if phase in ["hop", "fall", "fuse", "shield"]:
        return Rect2()
    var box: Rect2 = super.get_attack_rect()
    if phase == "rear_poke":
        box.position.x = global_position.x - box.size.x if facing > 0 else global_position.x
    return box

func _receive_hit(damage: int, from_pos: Vector2, step: int, shockwave: bool) -> Dictionary:
    if phase == "fuse":
        return {"blocked":false, "damage_dealt":0}
    if enemy_id == "cedar_sentinel":
        var shield: Dictionary = stats["shield"]
        var front: bool = (from_pos.x - global_position.x) * facing >= 0
        if shockwave and step == 4:
            guard_left = 0
            guard_broken_left = float(shield["broken_seconds"])
            var result: Dictionary = super._receive_hit(damage, from_pos, step, shockwave)
            if hp > 0:
                phase = "shield_break_stun"
                _set_state(State.STUN)
                stun_left = float(shield["break_stun"])
                recovery_after_stun = 0
            _play_sfx("sentinel_shield_break")
            return result
        if front and guard_broken_left <= 0 and (guard_left > 0 or _roll() < float(shield["chance"])):
            var result: Dictionary = super._receive_hit(roundi(damage * float(shield["damage_multiplier"])), from_pos, step, shockwave)
            if hp > 0:
                guard_left = float(shield["hold"])
                phase = "shield"
                velocity = Vector2.ZERO
                _set_state(State.WINDUP)
                _play_sfx("sentinel_shield_up")
            return result
    perched = false if enemy_id == "cedar_demon" else perched
    return super._receive_hit(damage, from_pos, step, shockwave)

func _on_hit(seconds: float) -> void:
    if enemy_id == "cedar_sentinel" and phase == "shield_break_stun" and state == State.STUN:
        return
    super._on_hit(seconds)

func _die() -> void:
    if enemy_id == "cedar_wisp":
        _start_fuse()
    else:
        super._die()

func _start_fuse() -> void:
    if phase == "fuse":
        return
    hp = 0
    phase = "fuse"
    collision_layer = 0
    collider.set_deferred("disabled", true)
    velocity = Vector2.ZERO
    _set_state(State.WINDUP)

func _explode_wisp() -> void:
    var explosion: Dictionary = stats["explosion"]
    _hazard({"fx":"blue_flame_explosion", "size":[float(explosion["radius"])*2,float(explosion["radius"])*2], "radius":explosion["radius"], "seconds":explosion["seconds"], "damage":explosion["damage"]}, global_position)
    _play_sfx("wisp_explode")
    phase = ""
    super._die()

func marker_blinks() -> bool:
    return phase == "fuse"

func _update_visual(delta: float) -> void:
    if visual == null:
        return
    if perched:
        display_clock += delta
        _show_clip("perch", display_clock)
    elif state in [State.WINDUP, State.ACTIVE, State.RECOVERY] and not phase.is_empty():
        var name_value: String = phase
        if enemy_id == "cedar_sentinel":
            name_value = "shield_hold" if phase == "shield" and state_clock > .2 else ("shield_up" if phase == "shield" else ("windup" if state == State.WINDUP else phase))
            if state == State.RECOVERY:
                name_value = "attack_recovery"
        elif enemy_id == "cedar_colossus":
            name_value = phase + ("_windup" if state == State.WINDUP else ("_recovery" if state == State.RECOVERY else "")) if phase != "rear_poke" else phase
        elif enemy_id == "cedar_archer":
            name_value = "hop_back" if phase == "hop" else ("windup" if state == State.WINDUP else ("recovery" if state == State.RECOVERY else "shoot"))
        elif enemy_id == "cedar_demon":
            name_value = "claw_windup" if phase == "claws" and state == State.WINDUP else ("recovery" if state == State.RECOVERY else phase)
        _show_clip(name_value, state_clock)
    elif state == State.STUN and phase == "shield_break_stun":
        _show_clip("shield_break_stun", state_clock)
    else:
        super._update_visual(delta)

func _exit_tree() -> void:
    if is_instance_valid(loop_sound):
        get_node("/root/Audio").stop_sfx(loop_sound)
