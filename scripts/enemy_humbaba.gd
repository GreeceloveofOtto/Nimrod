class_name Humbaba
extends EnemyBase

var battle_started := false
var battle_finished := false
var phase_two := false
var phase_roaring := false
var pattern := ""
var last_pattern := ""
var tick_count := 0
var breath_cooldown := 0.0
var flame: Node2D
var ember: Node2D
var flame_sound: Node
var life_clock := 0.0
var hurt_flash_left := 0.0

func _init() -> void:
    enemy_id = "humbaba"

func _ready() -> void:
    super._ready()
    no_drop = true

func _physics_process(delta: float) -> void:
    life_clock += delta
    hurt_flash_left = maxf(0,hurt_flash_left-delta)
    _apply_tint()
    breath_cooldown = maxf(0,breath_cooldown-delta)
    if not battle_started:
        var hero: Node2D = _target()
        if hero != null and hero.global_position.x >= float(stats["start_x"]):
            battle_started = true
            _lock_arrival(true)
            _set_state(State.CHASE)
        else:
            _integrate_motion(delta)
            _show_clip("idle",life_clock)
            return
    super._physics_process(delta)

func _lock_arrival(value: bool) -> void:
    var level: LevelBase = _level() as LevelBase
    if level != null and level.doors.has("boss_arrival"):
        level.doors["boss_arrival"].locked = value
        level.doors["boss_arrival"].locked_message = "전투 중에는 돌아갈 수 없다"

func _time_factor() -> float:
    return float(stats["phase_two"]["time_multiplier"]) if phase_two else 1.0

func _turn_seconds() -> float:
    return float(stats["phase_two"]["turn_delay"]) if phase_two else float(stats["turn_delay"])

func _pattern_spec(id: String) -> Dictionary:
    return stats["patterns"][id]

func _start_pattern(id: String) -> void:
    pattern = id
    attack_stats = _pattern_spec(id).duplicate(true)
    last_pattern = id
    tick_count = 0
    attack_has_hit = false
    _set_state(State.WINDUP)

func _update_idle(delta: float) -> void:
    _update_chase(delta)

func _update_chase(delta: float) -> void:
    _brake(delta)
    var hero: Node2D = _target()
    if not _player_is_available(hero):
        return
    if not phase_two and hp <= int(stats["phase_two"]["hp"]):
        phase_roaring = true
        _set_state(State.WINDUP)
        _play_sfx("humbaba_roar")
        return
    var dx: float = hero.global_position.x-global_position.x
    var desired: int = -1 if dx < 0 else 1
    if desired != facing:
        pending_facing = desired
        if last_pattern != "tail" and randf() < float(stats["tail_chance"]):
            _start_pattern("tail")
        else:
            _request_turn(desired)
        return
    var choice: String = "claw" if absf(dx) <= float(stats["claw_range"]) else "bite" if absf(dx) <= float(stats["bite_range"]) else "breath"
    if choice == "breath" and breath_cooldown > 0:
        velocity.x = facing*float(stats["move_speed"])
        return
    if choice == last_pattern:
        choice = "bite" if choice == "claw" else "claw" if choice == "bite" else "bite"
    _start_pattern(choice)

func _update_windup(delta: float) -> void:
    _brake(delta)
    if phase_roaring:
        if state_clock >= float(stats["phase_two"]["roar_seconds"]):
            phase_roaring = false
            phase_two = true
            ember = _effect("humbaba_ember_aura",Vector2(0,-body_size.y*.5),true)
            _set_state(State.CHASE)
        return
    if state_clock >= float(attack_stats["windup"])*_time_factor():
        tick_count = 0
        _set_state(State.ACTIVE)
        if pattern == "breath":
            flame_sound = _play_sfx("humbaba_breath_loop")
        else:
            _play_sfx("humbaba_"+pattern)
        if pattern == "breath":
            breath_cooldown = float(stats["breath_cooldown"])
            flame = _effect("humbaba_flame_cone",Vector2(facing*body_size.x*.35,-body_size.y*.7),true)
            flame.scale.x *= facing

func _update_active(delta: float) -> void:
    var hero: NimrodPlayer = _target() as NimrodPlayer
    var factor: float = _time_factor()
    var seconds: float = float(attack_stats["active"])
    if pattern == "bite":
        velocity.x = facing*float(attack_stats["lunge"])/(seconds*factor)
        if not attack_has_hit and _attack_hits(hero):
            attack_has_hit = hero.receive_damage(int(attack_stats["damage"]))
    elif pattern == "tail":
        _brake(delta)
        if not attack_has_hit and _attack_hits(hero):
            attack_has_hit = hero.receive_damage(int(attack_stats["damage"]))
    elif pattern == "claw":
        _brake(delta)
        var count: int = int(stats["phase_two"]["claw_count"] if phase_two else attack_stats["count"])
        seconds = count*float(attack_stats["interval"])
        while tick_count < count and state_clock >= tick_count*float(attack_stats["interval"])*factor:
            if _attack_hits(hero):
                hero.receive_damage(int(attack_stats["damage"]),{"grant_grace":false})
            tick_count += 1
    elif pattern == "breath":
        _brake(delta)
        var count: int = int(stats["phase_two"]["breath_ticks"] if phase_two else attack_stats["ticks"])
        seconds = count*float(attack_stats["interval"])
        if is_instance_valid(flame) and phase_two:
            flame.rotation = deg_to_rad(sin(state_clock/(seconds*factor)*TAU)*float(stats["phase_two"]["sweep_degrees"])*facing)
        while tick_count < count and state_clock >= tick_count*float(attack_stats["interval"])*factor:
            if _breath_hits(hero,seconds*factor):
                hero.receive_damage(int(attack_stats["damage"]),{"stagger":false,"grant_grace":false,"source_id":get_instance_id()})
            tick_count += 1
    if state_clock >= seconds*factor:
        _stop_flame()
        _begin_recovery(float(attack_stats["recovery"])*factor)

func _attack_hits(hero: NimrodPlayer) -> bool:
    if not _player_is_available(hero):
        return false
    return get_attack_rect().intersects(_player_rect(hero))

func get_attack_rect() -> Rect2:
    if state != State.ACTIVE or attack_stats.is_empty():
        return Rect2()
    var box: Array = attack_stats["box"]
    var side: int = -facing if pattern == "tail" else facing
    return Rect2(global_position+Vector2(0 if side>0 else -float(box[0]),-float(box[1])),Vector2(float(box[0]),float(box[1])))

func _breath_hits(hero: NimrodPlayer, seconds: float) -> bool:
    if not _player_is_available(hero):
        return false
    var origin: Vector2 = global_position+Vector2(facing*body_size.x*.35,-body_size.y*.7)
    var offset: Vector2 = _player_rect(hero).get_center()-origin
    var local := Vector2(offset.x*facing,offset.y)
    var angle: float = atan2(local.y,local.x)
    var sweep: float = sin(state_clock/seconds*TAU)*deg_to_rad(float(stats["phase_two"]["sweep_degrees"])) if phase_two else 0
    return local.x >= 0 and offset.length() <= float(attack_stats["range"]) and absf(angle-sweep) <= deg_to_rad(float(attack_stats["cone_degrees"])*.5)

func _update_recovery(delta: float) -> void:
    _brake(delta)
    if state_clock >= recovery_duration:
        if pattern == "tail" and pending_facing != facing:
            _set_state(State.CHASE)
            _request_turn(pending_facing)
        else:
            _set_state(State.CHASE)

func _on_hit(_seconds: float) -> void:
    pass # Superarmor keeps attack and recovery timing; hitstop still applies.

func _receive_hit(damage: int, from_pos: Vector2, step: int, shockwave: bool) -> Dictionary:
    if phase_roaring:
        return {"blocked":false,"damage_dealt":0}
    var front: bool = (from_pos.x-global_position.x)*facing >= 0
    var amount: int = roundi(damage*float(stats["front_armor"])) if front else damage
    if front:
        _effect("humbaba_bite_spark",Vector2(facing*body_size.x*.3,-body_size.y*.6))
    var result: Dictionary = super._receive_hit(amount,from_pos,step,shockwave)
    _flash_hit(result)
    return result

func take_light_hit(damage: int, from_pos: Vector2, _stagger: float) -> Dictionary:
    if phase_roaring:
        return {"blocked":false,"damage_dealt":0}
    var result: Dictionary = super._receive_hit(damage,from_pos,1,false)
    _flash_hit(result)
    return result

func _flash_hit(result: Dictionary) -> void:
    if int(result["damage_dealt"])>0 and hp>0:
        hurt_flash_left=float(stats["hurt_flash"]["seconds"])
        _apply_tint()

func _apply_tint() -> void:
    var tint: Array = stats["hurt_flash"]["color"] if hurt_flash_left>0 else stats["phase_two"]["visual_color"] if phase_two else [1.0,1.0,1.0]
    visual.modulate = Color(float(tint[0]),float(tint[1]),float(tint[2]))

func _die() -> void:
    _stop_flame()
    if is_instance_valid(ember):
        ember.queue_free()
    battle_finished = true
    _lock_arrival(false)
    get_node("/root/Story").set_flag("humbaba_defeated")
    super._die()

func _stop_flame() -> void:
    if is_instance_valid(flame):
        flame.queue_free()
    flame = null
    if is_instance_valid(flame_sound):
        get_node("/root/Audio").stop_sfx(flame_sound)
    flame_sound = null

func _effect(id: String, at: Vector2, loops: bool = false) -> Node2D:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage9_fx.json"))[id]
    var effect: Node2D = IMAGE_EFFECT.new()
    var size: Array = data["frame_size"]
    var coordinates: Array = data.get("emission_anchor",[float(size[0])*.5,float(size[1])*.5])
    var anchor := Vector2(float(coordinates[0]),float(coordinates[1]))
    effect.configure("res://"+str(data["path"]),Vector2i(int(size[0]),int(size[1])),int(data["frames"]),float(data["duration"]),loops,anchor)
    effect.scale = Vector2.ONE*float(data["scale"])
    add_child(effect)
    effect.position = at
    return effect

func _exit_tree() -> void:
    _stop_flame()

func _update_visual(_delta: float) -> void:
    var clip := "idle"
    if phase_roaring:
        clip = "phase_roar"
    elif state == State.TURN:
        clip = "turn"
    elif state == State.CHASE and absf(velocity.x)>1:
        clip = "walk"
    elif state in [State.WINDUP,State.ACTIVE,State.RECOVERY]:
        clip = str(attack_stats["windup_clip"] if state == State.WINDUP else attack_stats["recovery_clip"] if state == State.RECOVERY else attack_stats["active_clip"])
    var clock: float = state_clock/_time_factor() if state in [State.WINDUP,State.ACTIVE,State.RECOVERY] and not phase_roaring else state_clock
    if state == State.ACTIVE and pattern == "claw" and phase_two:
        clock = fmod(clock,float(clip_data["claw_swipe"]["duration_seconds"]))
    # EnemyBase._show_clip already scales turn playback to this phase's delay.
    _show_clip(clip,clock)
    _apply_tint()
