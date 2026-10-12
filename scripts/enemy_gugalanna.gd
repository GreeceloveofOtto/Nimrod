class_name Gugalanna
extends EnemyBase

var battle_started := false
var battle_finished := false
var pattern := ""
var last_pattern := ""
var cooldowns: Dictionary = {"stomp":0.,"charge":0.,"rake":0.}
var charge_origin := Vector2.ZERO
var crashed := false
var life_clock := 0.0
var prompt: Node2D
var drop_created := false

func _init() -> void:
    enemy_id = "gugalanna"

func _ready() -> void:
    super._ready()
    no_drop = true
    prompt = AssetVisual.add_image(self,"res://assets/ui/prompt_e.png",Vector2(-20,-body_size.y-50),Vector2(40,40),60)
    prompt.name = "InteractionPrompt"
    prompt.hide()
    var warning: Node2D = load("res://scripts/boss_warning.gd").new()
    add_child(warning)

func _physics_process(delta: float) -> void:
    life_clock += delta
    for key in cooldowns:
        cooldowns[key] = maxf(0,float(cooldowns[key])-delta)
    if not battle_started and state != State.DEAD:
        var hero: NimrodPlayer = _target() as NimrodPlayer
        battle_started = get_node("/root/Story").is_flag("gugalanna_intro_done")
        prompt.visible = not battle_started and is_instance_valid(hero) and absf(hero.global_position.x-global_position.x)<=400 and not hero.transition_locked and not get_node("/root/Dialogue").input_blocked()
        if prompt.visible and Input.is_action_just_pressed("interact"):
            get_node("/root/Dialogue").play_interaction("gugalanna_intro",{"gugalanna":self,"player":hero})
        if not battle_started:
            _integrate_motion(delta)
            _show_clip("idle",life_clock)
            return
        prompt.hide()
        _set_state(State.CHASE)
    super._physics_process(delta)

func _update_idle(delta: float) -> void:
    _update_chase(delta)

func _update_chase(delta: float) -> void:
    _brake(delta)
    var hero: NimrodPlayer = _target() as NimrodPlayer
    if not _player_is_available(hero):
        return
    var dx: float = hero.global_position.x-global_position.x
    var desired: int = -1 if dx<0 else 1
    if desired != facing:
        _request_turn(desired)
        return
    var options: Array[String] = []
    if float(cooldowns["rake"])<=0:
        options.append("rake")
    if float(cooldowns["stomp"])<=0:
        options.append("stomp")
    if absf(dx)>float(stats["patterns"]["uppercut"]["range"]) and float(cooldowns["charge"])<=0:
        options.append("charge")
    options.append("uppercut")
    for choice in options:
        if choice!=last_pattern:
            start_pattern(choice)
            return
    velocity.x = facing*float(stats["move_speed"])

func start_pattern(id: String) -> void:
    pattern = id
    last_pattern = id
    attack_stats = stats["patterns"][id].duplicate(true)
    crashed = false
    attack_has_hit = false
    charge_origin = global_position
    _set_state(State.WINDUP)
    if cooldowns.has(id):
        cooldowns[id] = float(attack_stats["low_hp_cooldown"] if id=="rake" and hp<=int(stats["hp"])*.5 else attack_stats["cooldown"])
    _play_sfx("gugalanna_roar")

func _update_windup(delta: float) -> void:
    _brake(delta)
    visual.modulate = Color(1.15,.8,.8) if pattern=="charge" else Color.WHITE
    if state_clock >= float(attack_stats["windup"]):
        _set_state(State.ACTIVE)
        _play_sfx("gugalanna_charge_rumble" if pattern=="charge" else "gugalanna_"+pattern)
        if pattern=="stomp":
            var quake: Node2D = load("res://scripts/gugalanna_quake.gd").new()
            quake.spec = attack_stats.duplicate(true)
            quake.position = global_position
            _level().add_child(quake)
        elif pattern in ["rake","uppercut"]:
            var fx: Node2D = get_node("/root/Chapter").spawn_fx(_level(),global_position+Vector2(facing*160,-100),"gugalanna_rake_arc" if pattern=="rake" else "gugalanna_dust")
            fx.scale.x *= facing

func _update_active(delta: float) -> void:
    var hero: NimrodPlayer = _target() as NimrodPlayer
    if pattern=="charge":
        velocity.x = facing*float(attack_stats["speed"])
        var next := Vector2(velocity.x*delta,0)
        var bounds: Vector2 = _ground_roam_bounds()
        if is_on_wall() or test_move(global_transform,next) or global_position.x+next.x<=bounds.x or global_position.x+next.x>=bounds.y:
            crashed = true
            velocity.x = 0
            _play_sfx("gugalanna_charge_crash")
            get_node("/root/Chapter").spawn_fx(_level(),global_position+Vector2(0,-body_size.y*.5),"gugalanna_lightning")
            _set_state(State.STUN)
            stun_left = float(attack_stats["crash_stun"])
            return
    else:
        _brake(delta)
    if pattern!="stomp" and not attack_has_hit and attack_hits(hero):
        attack_has_hit = hero.receive_damage(int(attack_stats["damage"]))
        if attack_has_hit:
            hero.velocity.x = facing*220
    if state_clock>=float(attack_stats["active"]) or (pattern=="charge" and absf(global_position.x-charge_origin.x)>=float(attack_stats["distance"])):
        _begin_recovery(float(attack_stats["recovery"]))

func attack_hits(hero: NimrodPlayer) -> bool:
    if not _player_is_available(hero):
        return false
    if pattern=="charge":
        return get_hurt_rect().intersects(_player_rect(hero))
    if pattern=="rake":
        var delta: Vector2 = _player_rect(hero).get_center()-global_position
        return delta.x*facing>=0 and absf(delta.y)<=float(attack_stats["height"]) and delta.length()<=float(attack_stats["radius"])
    return get_attack_rect().intersects(_player_rect(hero))

func get_attack_rect() -> Rect2:
    if state!=State.ACTIVE or attack_stats.is_empty():
        return Rect2()
    var box: Array = attack_stats["box"]
    return Rect2(global_position+Vector2(0 if facing>0 else -float(box[0]),-float(box[1])),Vector2(float(box[0]),float(box[1])))

func _update_recovery(delta: float) -> void:
    _brake(delta)
    if state_clock>=recovery_duration:
        _set_state(State.CHASE)

func _update_stun(delta: float) -> void:
    _brake(delta)
    stun_left = maxf(0,stun_left-delta)
    if stun_left<=0:
        _begin_recovery(float(stats["patterns"]["charge"]["recovery"]))

func _on_hit(_seconds: float) -> void:
    pass # Normal hits cannot interrupt patterns. Wall crash is an explicit stun.

func _die() -> void:
    battle_finished = true
    _play_sfx("gugalanna_vomit")
    get_node("/root/Story").set_flag("gugalanna_defeated")
    super._die()

func _update_dead(delta: float) -> void:
    if not drop_created and state_clock+delta>=float(clip_data["death"]["duration_seconds"]):
        drop_created = true
        get_node("/root/Chapter").drop(_level(),"helm",global_position)
    super._update_dead(delta)

func _update_visual(_delta: float) -> void:
    var clip := "idle"
    if state==State.TURN:
        clip = "turn"
    elif state==State.STUN:
        clip = "charge_crash"
    elif state==State.CHASE and absf(velocity.x)>1:
        clip = "walk"
    elif state in [State.WINDUP,State.ACTIVE,State.RECOVERY]:
        clip = str(attack_stats["windup_clip"] if state==State.WINDUP else attack_stats["active_clip"] if state==State.ACTIVE else attack_stats["recovery_clip"])
    _show_clip(clip,state_clock)

func _receive_hit(damage: int, from_pos: Vector2, step: int, shockwave: bool) -> Dictionary:
    if not battle_started and not get_node("/root/Story").is_flag("gugalanna_intro_done"):
        return {"blocked":false,"damage_dealt":0}
    return super._receive_hit(damage,from_pos,step,shockwave)
