class_name KalaUshumgal
extends EnemyBase

var phase: String = ""
var phase_two: bool = false
var battle_started: bool = false
var battle_finished: bool = false
var pattern_index: int = 0
var swing_number: int = 0
var roar_ticks: int = 0
var roar_effect: Node2D
var roar_sound: Node
var core_sound: Node
var summon_used: Dictionary = {}
var summons: Array[EnemyBase] = []
var summon_cooldown: float = 0.0
var rear_hits: Array[float] = []
var rear_cooldown: float = 0.0
var life_clock: float = 0.0
var dialogue_finished: bool = false
var death_attack_done: bool = false
var hit_contact: Vector2 = Vector2.ZERO
var has_hit_contact: bool = false

func set_hit_contact(point: Vector2) -> void:
    hit_contact = point
    has_hit_contact = true

func _init() -> void:
    enemy_id = "kala_ushumgal"

func _ready() -> void:
    super._ready()
    no_drop = true
    attack_stats = stats["attacks"][0]

func _physics_process(delta: float) -> void:
    life_clock += delta
    rear_cooldown = maxf(0, rear_cooldown - delta)
    _refresh_summons(delta)
    var hero: Node2D = _target()
    if not battle_started:
        if hero != null and hero.global_position.x >= float(stats["start_x"]):
            battle_started = true
            _lock_arrival(true)
            _set_state(State.CHASE)
            core_sound = _play_sfx("boss_core_throb")
        else:
            _show_clip("idle", life_clock)
            return
    super._physics_process(delta)

func _lock_arrival(value: bool) -> void:
    var level: Node = _level()
    if level != null and level.doors.has("boss_arrival"):
        var door: DoorPortal = level.doors["boss_arrival"]
        door.locked = value
        door.locked_message = "전투 중에는 돌아갈 수 없다"

func _time_factor() -> float:
    return float(stats["phase_two"]["time_multiplier"]) if phase_two else 1.0

func _turn_seconds() -> float:
    return float(stats["phase_two"]["turn_delay"]) if phase_two else float(stats["turn_delay"])

func _attack(id: String) -> Dictionary:
    for entry in stats["attacks"]:
        if str(entry["id"]) == id:
            return entry
    return stats["attacks"][0]

func _update_idle(delta: float) -> void:
    _update_chase(delta)

func _update_chase(delta: float) -> void:
    var hero: Node2D = _target()
    if not _player_is_available(hero):
        _brake(delta)
        return
    if hp <= int(stats["phase_two"]["hp"]) and not phase_two:
        _enter_phase_two()
        return
    var dx: float = hero.global_position.x - global_position.x
    var desired: int = -1 if dx < 0 else 1
    if desired != facing:
        _request_turn(desired)
        return
    _brake(delta)
    if absf(dx) > float(stats["pattern_range"]):
        velocity.x = facing * float(stats["move_speed"])
        return
    if _should_summon():
        _start_pattern("summon")
    else:
        var sequence: Array = ["whip", "slam", "roar"] if phase_two else ["whip", "slam"]
        _start_pattern(str(sequence[pattern_index % sequence.size()]))
        pattern_index += 1

func _should_summon() -> bool:
    if not summons.is_empty():
        return false
    for threshold in stats["summon"]["thresholds"]:
        var key: String = str(threshold)
        if hp <= roundi(float(stats["hp"]) * float(threshold)) and not summon_used.get(key, false):
            summon_used[key] = true
            return true
    return summon_used.size() > 0 and summon_cooldown <= 0.0

func _refresh_summons(delta: float) -> void:
    var living: Array[EnemyBase] = []
    for actor in summons:
        if is_instance_valid(actor) and actor.state != State.DEAD and actor.hp > 0:
            living.append(actor)
    if not summons.is_empty() and living.is_empty():
        summon_cooldown = float(stats.get("summon", {}).get("cooldown", 20))
    summons = living
    if summons.is_empty():
        summon_cooldown = maxf(0, summon_cooldown - delta)

func _start_pattern(id: String) -> void:
    phase = id
    attack_stats = _attack(id)
    attack_has_hit = false
    swing_number = 0
    roar_ticks = 0
    _set_state(State.WINDUP)

func _enter_phase_two() -> void:
    phase = "phase_transition"
    _set_state(State.WINDUP)
    _play_sfx("boss_phase_roar")
    _stop_roar()

func _update_windup(delta: float) -> void:
    _brake(delta)
    if phase == "phase_transition":
        if state_clock >= float(stats["phase_two"]["transition_seconds"]):
            phase_two = true
            phase = ""
            _set_state(State.CHASE)
        return
    var seconds: float = float(attack_stats["windup"])
    if phase == "whip" and swing_number == 1:
        seconds = float(attack_stats["second_windup"])
    if state_clock + TIME_EPSILON >= seconds * _time_factor():
        _begin_active()

func _begin_active() -> void:
    attack_has_hit = false
    _set_state(State.ACTIVE)
    match phase:
        "summon":
            _summon_archers()
            _begin_recovery(float(stats["summon"]["recovery"]) * _time_factor())
        "slam":
            _play_sfx("boss_slam")
            _make_spikes()
        "whip":
            _play_sfx("boss_whip_swing")
        "roar":
            roar_ticks = 0
            var length: float = float(stats["roar"]["range"])
            roar_effect = CedarFX.spawn(self, "soul_flame_cone", global_position + Vector2(facing * length * .5, float(stats["roar"]["origin_y"])), Vector2(length, length * tan(deg_to_rad(float(stats["roar"]["angle"]) * .5)) * 2))
            if roar_effect != null:
                roar_effect.scale.x *= facing
            roar_sound = _play_sfx("boss_roar_loop")
        "spines":
            _play_sfx("boss_spike_rise")

func _update_active(delta: float) -> void:
    _brake(delta)
    var hero: Node2D = _target()
    if phase == "roar":
        _roar_damage(hero)
    elif not attack_has_hit and _player_in_attack(hero):
        attack_has_hit = bool(hero.receive_damage(int(attack_stats["damage"])))
    if state_clock + TIME_EPSILON >= float(attack_stats["active"]) * _time_factor():
        if phase == "whip" and swing_number == 0:
            swing_number = 1
            _set_state(State.WINDUP)
        else:
            _stop_roar()
            _begin_recovery(float(attack_stats["recovery"]) * _time_factor())

func _update_recovery(delta: float) -> void:
    _brake(delta)
    if state_clock >= recovery_duration:
        if phase == "spines":
            phase = ""
            turn_flip_applied = false
            _set_state(State.TURN)
        else:
            phase = ""
            _set_state(State.CHASE)

func _request_turn(direction: int) -> void:
    if direction == facing or state not in [State.CHASE, State.IDLE]:
        return
    pending_facing = direction
    var window: float = float(stats["rear"]["window"])
    var recent: Array[float] = []
    for at in rear_hits:
        if life_clock - at <= window:
            recent.append(at)
    rear_hits = recent
    if phase_two and rear_cooldown <= 0 and rear_hits.size() >= int(stats["rear"]["hits"]):
        rear_hits.clear()
        rear_cooldown = float(stats["rear"]["cooldown"])
        _start_pattern("spines")
    else:
        super._request_turn(direction)

func _roar_damage(hero: Node2D) -> void:
    var spec: Dictionary = stats["roar"]
    while roar_ticks < int(spec["ticks"]) and state_clock + TIME_EPSILON >= roar_ticks * float(spec["interval"]) * _time_factor():
        if _player_is_available(hero):
            var origin: Vector2 = global_position + Vector2(0, float(spec["origin_y"]))
            # Test several points of the player hurtbox against the cone.
            var box: Rect2 = _player_rect(hero)
            var inside: bool = false
            for point in [box.get_center(), box.position, box.end, Vector2(box.position.x, box.end.y), Vector2(box.end.x, box.position.y)]:
                var relative: Vector2 = point - origin
                if relative.x * facing >= 0 and relative.length() <= float(spec["range"]) and absf(atan2(relative.y, absf(relative.x))) <= deg_to_rad(float(spec["angle"]) * .5):
                    inside = true
            if inside:
                hero.receive_damage(int(spec["damage"]), {"stagger":false, "grant_grace":false, "tick_group":"boss_flame", "tick_source":get_instance_id()})
        roar_ticks += 1

func _make_spikes() -> void:
    var spec: Dictionary = stats["spikes"]
    for i in range(spec["distances"].size()):
        var location: Vector2 = global_position + Vector2(facing * float(spec["distances"][i]), -float(spec["size"][1]) * .5)
        var level: Node = _level()
        if level != null:
            location.x = clampf(location.x, 45, level.camera_limits.end.x - 45)
        _hazard({"fx":"bone_spike", "size":spec["size"], "damage":spec["damage"], "seconds":spec["seconds"], "delay":(float(spec["delay"]) + i * float(spec["interval"])) * _time_factor()}, location)
    _play_sfx("boss_spike_rise")

func _hazard(spec: Dictionary, location: Vector2) -> void:
    var actor := CedarHazard.new()
    actor.spec = spec
    actor.position = get_parent().to_local(location)
    get_parent().add_child(actor)

func _summon_archers() -> void:
    if not summons.is_empty():
        return
    for at in stats["summon"]["positions"]:
        if summons.size() >= int(stats["summon"]["max_count"]):
            break
        var archer: CedarEnemy = load("res://scripts/enemy_cedar_archer.gd").new()
        archer.position = Vector2(float(at[0]), float(at[1]))
        archer.patrol_center = archer.position.x
        archer.patrol_range = 60
        archer.no_drop = true
        get_parent().add_child(archer)
        archer.facing = 1 if archer.position.x < global_position.x else -1
        summons.append(archer)
    summon_cooldown = float(stats["summon"]["cooldown"])

func get_attack_rect() -> Rect2:
    if phase in ["roar", "summon", "phase_transition"]:
        return Rect2()
    # Final attack remains lethal after HP reaches zero.
    if state == State.DEAD and phase == "final_active":
        var hitbox: Dictionary = _attack("final")["hitbox"]
        var width: float = float(hitbox["width"])
        return Rect2(global_position + Vector2(0 if facing > 0 else -width, float(hitbox["top"])), Vector2(width, float(hitbox["height"])))
    var box: Rect2 = super.get_attack_rect()
    if phase == "spines":
        box.position.x = global_position.x - box.size.x if facing > 0 else global_position.x
    return box

func _receive_hit(damage: int, from_pos: Vector2, step: int, shockwave: bool) -> Dictionary:
    if state == State.DEAD or phase == "phase_transition":
        return {"blocked":false, "damage_dealt":0}
    var front: bool = (from_pos.x - global_position.x) * facing >= 0
    var hit_y: float = hit_contact.y if has_hit_contact and not shockwave else from_pos.y
    has_hit_contact = false
    var upper: bool = hit_y < global_position.y - body_size.y * float(stats["armor"]["upper_ratio"])
    if front and upper and not shockwave:
        damage = roundi(damage * float(stats["armor"]["multiplier"]))
        CedarFX.spawn(self, "armor_hit_spark", get_hurt_rect().get_center(), Vector2(80,80))
        _play_sfx("armor_hit")
    if not front:
        rear_hits.append(life_clock)
    return super._receive_hit(damage, from_pos, step, shockwave)

func _on_hit(_seconds: float) -> void:
    # Deliberate superarmor. EnemyBase already applies hitstop and 20% knockback.
    pass

func _die() -> void:
    if state == State.DEAD:
        return
    hp = 0
    _stop_roar()
    if is_instance_valid(core_sound):
        get_node("/root/Audio").stop_sfx(core_sound)
    collision_layer = 0
    collision_mask = 0
    collider.set_deferred("disabled", true)
    velocity = Vector2.ZERO
    hitstop_left = 0
    phase = "collapse"
    _set_state(State.DEAD)
    var hero: Node2D = _target()
    pending_facing = facing if hero == null else (-1 if hero.global_position.x < global_position.x else 1)
    turn_flip_applied = pending_facing == facing
    _play_sfx("boss_collapse")
    died.emit(self)

func _update_dead(delta: float) -> void:
    state_clock += delta
    var spec: Dictionary = stats["death_sequence"]
    match phase:
        "collapse":
            if pending_facing != facing and not turn_flip_applied:
                _show_clip("turn_p2" if phase_two else "turn", state_clock)
                if state_clock >= _turn_seconds() * 2.0 / 6.0:
                    facing = pending_facing
                    turn_flip_applied = true
            else:
                _show_clip("collapse", state_clock)
            if state_clock >= float(spec["collapse"]):
                phase = "final_windup"
                state_clock = 0
                attack_has_hit = false
        "final_windup":
            _show_clip("final_swing_windup", state_clock)
            visual.modulate = Color(1, .35, .35) if sin(state_clock * 24.0) > 0 else Color.WHITE
            if state_clock >= float(spec["windup"]):
                phase = "final_active"
                state_clock = 0
                visual.modulate = Color.WHITE
                _play_sfx("boss_final_swing")
        "final_active":
            _show_clip("final_swing", state_clock)
            var hero: Node2D = _target()
            if not attack_has_hit and _player_in_attack(hero):
                attack_has_hit = bool(hero.receive_damage(int(spec["damage"])))
            if state_clock >= float(spec["active"]):
                death_attack_done = true
                phase = "death"
                state_clock = 0
                battle_finished = true
                _lock_arrival(false)
                get_node("/root/GameState").run_flags["kala_defeated"] = true
                _death_dialogue()
        "death":
            _show_clip("death", state_clock)
            modulate.a = maxf(0.0, 1.0 - state_clock / float(spec["fade"]))
            if state_clock >= float(spec["fade"]) and dialogue_finished:
                queue_free()

func _death_dialogue() -> void:
    if get_node("/root/GameState").first_time("kala_death_lines"):
        await get_node("/root/Dialogue").play(stats["death_lines"], self, {"freeze":false, "zoom":false, "hold_seconds":1.6})
    dialogue_finished = true

func marker_is_dangerous() -> bool:
    return phase in ["final_windup", "final_active"]

func marker_blinks() -> bool:
    return phase == "final_windup"

func _update_visual(_delta: float) -> void:
    var clip: String = "idle"
    if state == State.TURN:
        clip = "turn"
    elif state == State.CHASE and absf(velocity.x) > 1:
        clip = "walk"
    elif phase == "phase_transition":
        clip = "phase_transition"
    elif state in [State.WINDUP, State.ACTIVE, State.RECOVERY]:
        match phase:
            "whip":
                clip = "whip_windup" if state == State.WINDUP else ("whip_recovery" if state == State.RECOVERY else ("whip_swing" if swing_number == 0 else "whip_swing_back"))
            "slam":
                clip = "slam_windup" if state == State.WINDUP else ("slam_recovery" if state == State.RECOVERY else "slam")
            "roar":
                clip = "roar_windup" if state == State.WINDUP else ("roar_recovery" if state == State.RECOVERY else "roar_loop")
            "summon":
                clip = "summon"
            "spines":
                clip = "spines_back"
    if phase_two and textures.has(clip + "_p2"):
        clip += "_p2"
    _show_clip(clip, state_clock / _time_factor() if state in [State.WINDUP, State.ACTIVE, State.RECOVERY] and phase != "phase_transition" else state_clock)

func _stop_roar() -> void:
    if is_instance_valid(roar_effect):
        roar_effect.queue_free()
    if is_instance_valid(roar_sound):
        get_node("/root/Audio").stop_sfx(roar_sound)
    roar_effect = null
    roar_sound = null

func _exit_tree() -> void:
    _stop_roar()
    if is_instance_valid(core_sound):
        get_node("/root/Audio").stop_sfx(core_sound)
