extends Node
# A presentation/combat controller, never a second physics body or sprite sheet.
signal transformed
signal transform_resolved(success: bool)
signal ended
var settings: Dictionary = {}
var state := "inactive"
var elapsed := 0.0
var remaining := 0.0
var cooldown_left := 0.0
var breath_cooldown := 0.0
var attack_kind := ""
var attack_phase := 0
var attack_clock := 0.0
var combo_step := 0
var combo_left := 0.0
var buffer_left := 0.0
var next_step := 1
var hit_ids: Dictionary = {}
var ticks := 0
var turn_left := 0.0
var turn_target := 1
var turn_origin := 1
var flash_clock := 0.0
var generation := 0
var clips: Dictionary = {}
var textures: Dictionary = {}
var minimum_density := 0.0
var saved_zoom := Vector2.ONE
var saved_bgm_db := 0.0
var bgm_bus := -1
var audio_ducked := false
var aura: Node2D
var flame: Node2D
var breath_sound: Node
var dying := false
var transform_timer: SceneTreeTimer
var camera_tween: Tween
var pending_checkpoint := ""

func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/humbaba_form.json"))
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/enemies/humbaba/manifest.json"))
    minimum_density = INF
    for spec: Dictionary in manifest["clips"]:
        clips[str(spec["name"])] = spec
        textures[str(spec["name"])] = load("res://assets/" + str(spec["sheet"]))
        var density: Array = spec.get("storage_scale", [1.0,1.0])
        minimum_density = minf(minimum_density, minf(float(density[0]),float(density[1])) / (.3*float(settings["visual_multiplier"])))
    assert(minimum_density >= float(settings["minimum_density"]), "Humbaba form texel density")
    get_node("/root/GameState").run_reset.connect(reset)
    get_node("/root/Cutscene").completed.connect(_cutscene_done)
    get_node("/root/SceneManager").transition_finished.connect(_arrival)

func hero() -> NimrodPlayer:
    return get_node("/root/SceneManager").player as NimrodPlayer

func engaged() -> bool:
    return state != "inactive"

func superarmored() -> bool:
    return state in ["transforming","active"]

func can_enter() -> bool:
    var actor := hero()
    if engaged() or cooldown_left > 0 or not is_instance_valid(actor) or actor.action == "dead" or get_node("/root/GameState").active_character != "nimrod" or get_node("/root/Save").restoring:
        return false
    if get_node("/root/Dialogue").active:
        return false
    var runner: Node = get_node("/root/Cutscene")
    if runner.active:
        return runner.current_id == "utnapishtim_rampage"
    return not actor.transition_locked

func enter() -> bool:
    if not can_enter():
        return false
    generation += 1
    state = "transforming"
    dying = false
    elapsed = 0
    remaining = float(settings["duration"])
    attack_kind = ""
    combo_step = 0
    next_step = 1
    breath_cooldown = 0
    var actor := hero()
    saved_zoom = actor.camera.zoom
    actor._cancel_attack()
    actor._restore_safe_collider()
    actor.pull_left = 0
    actor.velocity = Vector2.ZERO
    # Keep the existing environment collider; never enlarge it with the art.
    get_node("/root/SceneManager").set_player_locked(true)
    bgm_bus=AudioServer.get_bus_index("BGM")
    if bgm_bus>=0:
        saved_bgm_db=AudioServer.get_bus_volume_db(bgm_bus)
        AudioServer.set_bus_volume_db(bgm_bus,saved_bgm_db+float(settings["bgm_duck_db"]))
        audio_ducked=true
    _transform(generation)
    return true

func _transform(token: int) -> void:
    var actor := hero()
    actor.hitstop_left = float(settings["transform_hitstop"])
    await _wait(float(settings["transform_hitstop"]))
    if token != generation:return
    actor.visual.modulate = Color(1.8,.15,.1)
    await _wait(float(settings["transform_flash_seconds"]))
    if token != generation:return
    flash_clock = 0
    render("phase_roar",0)
    aura = _fx("humbaba_ember_aura",Vector2(0,-155),Vector2(360,360),true)
    get_node("/root/Audio").play_sfx("humbaba_roar")
    actor.shake_time = float(settings["roar_seconds"])
    camera_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    camera_tween.tween_property(actor.camera,"zoom",saved_zoom / float(settings["zoom_out_factor"]),_timing_scale())
    await _wait(float(settings["roar_seconds"]))
    if token != generation:return
    state = "active"
    elapsed = 0
    flash_clock = 0
    actor.hitstop_left = 0
    actor.action = "normal"
    if not get_node("/root/Cutscene").active:
        get_node("/root/SceneManager").set_player_locked(false)
    render("idle",0)
    transformed.emit()
    transform_resolved.emit(true)

func _timing_scale() -> float:
    if get_node("/root/Cutscene").active:
        return float(get_node("/root/Cutscene").timing_scale)
    return 1.0

func _wait(seconds: float) -> void:
    transform_timer=get_tree().create_timer(maxf(.001,seconds*_timing_scale()),true)
    await transform_timer.timeout
    transform_timer=null

func _process(delta: float) -> void:
    # Dialogue pauses timers and animation, even though this controller must be
    # ALWAYS to render a scripted form inside a paused cutscene.
    if get_node("/root/Dialogue").active or (get_tree().paused and not get_node("/root/Cutscene").active):return
    if not engaged():
        if not get_node("/root/Cutscene").active:cooldown_left = maxf(0,cooldown_left-delta)
        return
    if not is_instance_valid(hero()):return
    if state in ["exiting","exhausted"] and hero().action=="dead":
        state="inactive"
        get_node("/root/SceneManager").set_player_locked(false)
        return
    flash_clock += delta / _timing_scale()
    if state == "transforming":
        if flash_clock < float(settings["transform_hitstop"])+float(settings["transform_flash_seconds"]):
            hero().visual.modulate=Color(1.8,.15,.1)
        else:
            render("phase_roar",flash_clock-float(settings["transform_hitstop"])-float(settings["transform_flash_seconds"]))
        hero()._update_camera_shake(delta)
    elif state == "exiting":
        hero().visual.modulate=Color(1.5,.35,.25)
        if flash_clock >= float(settings["exit_flash_seconds"]):
            state="exhausted"
            flash_clock=0
            hero().action="hurt"
            hero().hurt_clock=0
    elif state == "exhausted":
        hero()._show_clip("hurt",flash_clock)
        if flash_clock >= float(settings["exhaust_seconds"]):
            get_node("/root/Rampage").set_form_gauge(int(settings["exit_rampage_value"]))
            state="inactive"
            hero().action="normal"
            hero().sync_story_state()
            if not get_node("/root/SceneManager").is_transitioning and not get_node("/root/Odyssey").busy:
                get_node("/root/SceneManager").set_player_locked(false)
            ended.emit()
            _flush_checkpoint()
    elif dying:
        render("death",hero().death_clock)
    elif get_node("/root/Cutscene").active or hero().transition_locked:
        if not get_node("/root/Cutscene").active and not _advance_life(delta):return
        var clip: String=hero().cinematic_clip
        if not clips.has(clip):clip="idle"
        render(clip,hero().cinematic_clock)
    if state in ["transforming","active"]:
        var mat: ShaderMaterial=get_node("/root/Chapter").vignette.material
        mat.set_shader_parameter("tint",Vector3(.55,0,0))
        mat.set_shader_parameter("strength",.18)

func tick_exhausted(delta: float) -> void:
    var actor := hero()
    actor.damage_grace=maxf(0,actor.damage_grace-delta)
    actor.damage_tick_clock+=delta
    actor.velocity.x=move_toward(actor.velocity.x,0,actor.GROUND_ACCEL*delta)
    actor._integrate_vertical(delta)
    actor._move_with_surface_rules(delta)
    actor._update_camera_shake(delta)

func tick_player(delta: float) -> void:
    var actor := hero()
    if actor.action == "dead":
        dying=true
        actor.death_clock += delta
        actor.velocity.y += actor.GRAVITY*delta
        actor.velocity.x=move_toward(actor.velocity.x,0,actor.GROUND_ACCEL*delta)
        actor._move_with_surface_rules(delta)
        render("death",actor.death_clock)
        if actor.death_clock >= GameConstants.PLAYER_DEATH_RESTART_SECONDS:actor._request_run_restart(true)
        return
    if not _advance_life(delta):return
    actor.controls_reversed_left=maxf(0,actor.controls_reversed_left-delta)
    actor.damage_grace=maxf(0,actor.damage_grace-delta)
    actor.damage_tick_clock+=delta
    actor.flash_time=maxf(0,actor.flash_time-delta)
    breath_cooldown=maxf(0,breath_cooldown-delta)
    combo_left=maxf(0,combo_left-delta)
    buffer_left=maxf(0,buffer_left-delta)
    if combo_left<=0 and attack_kind.is_empty():next_step=1
    if actor.is_on_floor():actor.air_direction_cancels=0
    var axis: float=actor.movement_axis()
    if actor.hitstop_left>0:
        if Input.is_action_just_pressed("attack"):request_attack(axis)
        actor.hitstop_left=maxf(0,actor.hitstop_left-delta)
        actor.direction_cancel_buffer_left=maxf(0,actor.direction_cancel_buffer_left-delta)
        if actor.hitstop_left<=0 and actor.pending_cancel_direction!=0:
            var direction: int=actor.pending_cancel_direction
            actor.pending_cancel_direction=0
            if actor.direction_cancel_buffer_left>0:request_attack(float(direction))
        return
    if Input.is_action_just_pressed("attack"):request_attack(axis)
    if Input.is_action_just_pressed("skill_light"):request_breath()
    if Input.is_action_just_pressed("roll"):request_tail(axis)
    if attack_kind.is_empty() and absf(axis)>.01 and (1 if axis>0 else -1)!=actor.facing and turn_left<=0:
        _begin_turn(1 if axis>0 else -1)
    if turn_left>0:
        turn_left=maxf(0,turn_left-delta)
        if turn_left<=float(settings["turn_delay"])/3:actor.facing=turn_target
    if Input.is_action_just_pressed("jump") and actor.is_on_floor() and attack_kind.is_empty():
        actor.velocity.y=actor.JUMP_IMPULSE*sqrt(float(settings["jump_multiplier"]))
    var speed: float=axis*actor.RUN_SPEED*float(settings["move_speed_multiplier"])
    if not attack_kind.is_empty():speed*=.25
    actor.velocity.x=move_toward(actor.velocity.x,speed,actor.GROUND_ACCEL*delta)
    if attack_kind=="tail" and attack_phase==1 and attack_clock<float(settings["attacks"]["tail"]["retreat_seconds"]):
        actor.velocity.x=-actor.facing*float(settings["attacks"]["tail"]["retreat_speed"])
    actor._integrate_vertical(delta)
    actor._move_with_surface_rules(delta)
    actor._recover_solid_overlap()
    if actor.crouching and actor._can_stand():
        actor._set_standing_collider()
        actor.crouching=false
        actor.compact_escape=false
    if not attack_kind.is_empty():_attack_tick(delta)
    elif turn_left>0:
        render("turn",(1-turn_left/float(settings["turn_delay"]))*float(clips["turn"]["duration_seconds"])*.5)
    else:render("walk" if absf(actor.velocity.x)>10 else "idle",elapsed)
    actor._update_camera_shake(delta)
    _move_fx()

func _advance_life(delta: float) -> bool:
    elapsed += delta
    remaining = maxf(0,float(settings["duration"])-elapsed)
    get_node("/root/Rampage").set_form_gauge(roundi(lerpf(100,float(settings["exit_rampage_value"]),clampf(elapsed/float(settings["duration"]),0,1))))
    if remaining <= 0:
        exit(false)
        return false
    return true

func _begin_turn(direction: int) -> void:
    turn_origin=hero().facing
    turn_target=direction
    turn_left=float(settings["turn_delay"])

func request_attack(axis: float=0) -> bool:
    if state!="active" or dying:return false
    var actor:=hero()
    if not attack_kind.is_empty():
        if attack_kind not in ["claw","bite"]:return false
        if actor._can_direction_cancel(axis):
            if actor.hitstop_left>0:
                actor.pending_cancel_direction=1 if axis>0 else -1
                actor.direction_cancel_buffer_left=.12
                return true
            var step: int=(combo_step%4)+1
            if not actor.is_on_floor():actor.air_direction_cancels+=1
            actor.facing=1 if axis>0 else -1
            actor.visual.flip_h=actor.facing<0
            actor.velocity.x=0
            _begin_turn(actor.facing)
            _start_attack("bite" if step==4 else "claw",step)
        else:buffer_left=float(settings["combo_buffer_seconds"])
    else:_start_attack("bite" if next_step==4 else "claw",next_step)
    return true

func request_breath() -> bool:
    if state!="active" or dying or not attack_kind.is_empty() or breath_cooldown>0:return false
    breath_cooldown=float(settings["attacks"]["breath"]["cooldown"])
    _start_attack("breath",0)
    return true

func request_tail(axis: float=0) -> bool:
    if state!="active" or dying:return false
    if absf(axis)>.01:hero().facing=1 if axis>0 else -1
    _start_attack("tail",0)
    return true

func _start_attack(kind: String, step: int) -> void:
    _stop_breath()
    hero()._cancel_attack()
    hero().action="attack"
    hero().attack_step=step
    hero().attack_clock=0
    attack_kind=kind
    attack_phase=0
    attack_clock=0
    combo_step=step
    hit_ids.clear()
    ticks=0
    buffer_left=0
    render(str(settings["attacks"][kind]["clips"][0]),0)
    get_node("/root/Audio").play_sfx("humbaba_"+("claw" if kind=="claw" else "bite" if kind=="bite" else "tail" if kind=="tail" else "hurt"))

func _phase_seconds() -> float:
    var spec: Dictionary=settings["attacks"][attack_kind]
    var key: String=["windup","active","recovery"][attack_phase]
    var length: float=float(spec[key])
    if attack_kind in ["claw","bite"]:length*=float(settings["combo_time_multiplier"])
    return length

func _attack_tick(delta: float) -> void:
    attack_clock+=delta
    hero().attack_clock+=delta
    if attack_phase==1:
        if attack_kind=="breath":
            while ticks<int(settings["attacks"]["breath"]["ticks"]) and attack_clock>=ticks*float(settings["attacks"]["breath"]["tick_interval"]):
                hit_ids.clear()
                _hit_targets()
                ticks+=1
        else:_hit_targets()
    if hero().action=="dead":return
    if attack_clock>=_phase_seconds():
        attack_clock=0
        attack_phase+=1
        if attack_phase==1 and attack_kind=="breath":
            flame=_fx("humbaba_flame_cone",Vector2(hero().facing*300,-155),Vector2(600,300),true)
            breath_sound=get_node("/root/Audio").play_sfx("humbaba_breath_loop")
        if attack_phase==2:_stop_breath()
        if attack_phase>=3:
            var buffered: bool=buffer_left>0 and attack_kind in ["claw","bite"]
            next_step=(combo_step%4)+1
            combo_left=float(settings["combo_reset_seconds"])
            attack_kind=""
            hero().action="normal"
            hero().attack_step=0
            if buffered:request_attack()
            return
    var clip: String=settings["attacks"][attack_kind]["clips"][attack_phase]
    var animation_clock: float=attack_clock/_phase_seconds()*float(clips[clip]["duration_seconds"])
    if attack_kind=="breath" and attack_phase==1:animation_clock=attack_clock
    render(clip,animation_clock)

func _hit_targets() -> void:
    var actor:=hero()
    var spec: Dictionary=settings["attacks"][attack_kind]
    for target in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(target) or target.hp<=0 or hit_ids.has(target.get_instance_id()):continue
        var rect: Rect2=target.get_hurt_rect()
        var hit:=false
        if attack_kind=="breath":
            var mouth:=actor.global_position-Vector2(0,155)
            var to: Vector2=rect.get_center()-mouth
            hit=to.length()<=float(spec["range"])+rect.size.length()*.5 and to.dot(Vector2(actor.facing,0))>0 and absf(to.angle_to(Vector2(actor.facing,0)))<=deg_to_rad(float(spec["cone_degrees"])*.5)
        else:
            var size_px:=Vector2(float(spec["box"][0]),float(spec["box"][1]))
            var x: float=0 if actor.facing>0 else -size_px.x
            var area:=Rect2(actor.global_position+Vector2(x,-size_px.y-55),size_px)
            hit=area.intersects(rect)
            if attack_kind=="tail":hit=hit or Rect2(actor.global_position+Vector2(-size_px.x if actor.facing>0 else 0,-size_px.y-30),size_px).intersects(rect)
        if not hit:continue
        hit_ids[target.get_instance_id()]=true
        var result: Dictionary=target.take_hit(int(spec["damage"]),actor.global_position,0)
        if bool(result.get("blocked",false)):
            Stage5FX.spawn(target.get_parent(),"guard_spark",rect.get_center(),Vector2(80,80))
            get_node("/root/Audio").play_sfx("guard_block")
            actor._guard_recoil()
        elif int(result.get("damage_dealt",0))>0:
            actor.hitstop_left=.05
            actor.shake_time=.12
            actor.attack_connected.emit(int(spec["damage"]),0)
            if target.hp<=0:get_node("/root/Rampage").basic_kill(target)

func render(clip: String, seconds: float) -> void:
    var actor:=hero()
    if not is_instance_valid(actor) or not clips.has(clip):return
    actor.visual.texture=textures[clip]
    actor.visual.flip_h=actor.facing<0
    actor.visual.set_meta("canonical_scale",Vector2.ONE*.3*float(settings["visual_multiplier"]))
    var spec: Dictionary=clips[clip]
    var duration: float=float(spec["duration_seconds"])
    var phase: float=minf(seconds,duration)
    if bool(spec.get("loop",false)):phase=fmod(seconds,duration)
    var frame: int=clampi(floori(phase/duration*float(spec["frames"])),0,int(spec["frames"])-1)
    AssetVisual.apply_frame(actor.visual,spec,frame)
    actor.visual.modulate=Color(1.18,.86,.8)
    actor.displayed_clip=clip
    actor.display_clock=seconds

func hurt_rect() -> Rect2:
    var size_px:=Vector2(float(settings["body_size"][0]),float(settings["body_size"][1]))*float(settings["visual_multiplier"])*float(settings["hurtbox_ratio"])
    return Rect2(hero().global_position+Vector2(-size_px.x*.5,-size_px.y),size_px)

func incoming_multiplier() -> float:
    if state in ["exiting","exhausted"]:return 2.0
    if superarmored():return float(settings["damage_taken_multiplier"])
    return 1.0

func exit(cutscene_exit: bool=false) -> void:
    if not engaged():return
    var was_transforming: bool=state=="transforming"
    generation+=1
    if transform_timer!=null:
        transform_timer.timeout.emit()
        transform_timer=null
    _stop_breath()
    attack_kind=""
    buffer_left=0
    dying=false
    _restore_presentation()
    cooldown_left=float(settings["reentry_cooldown"])
    state="inactive" if cutscene_exit else "exiting"
    flash_clock=0
    var actor:=hero()
    actor.cinematic_clip=""
    actor._cancel_attack()
    get_node("/root/Rampage").set_form_gauge(int(settings["exit_rampage_value"]))
    actor.sync_story_state()
    actor.visual.set_meta("canonical_scale",Vector2.ONE*.3)
    actor.displayed_clip=""
    actor._show_clip("idle",0)
    if not cutscene_exit:
        get_node("/root/SceneManager").set_player_locked(true)
    else:
        ended.emit()
    if was_transforming:transform_resolved.emit(false)

func reset() -> void:
    var was_transforming: bool=state=="transforming"
    generation+=1
    if transform_timer!=null:
        transform_timer.timeout.emit()
        transform_timer=null
    _stop_breath()
    _restore_presentation()
    state="inactive"
    dying=false
    cooldown_left=0
    remaining=0
    attack_kind=""
    pending_checkpoint=""
    if is_instance_valid(hero()):
        hero().visual.set_meta("canonical_scale",Vector2.ONE*.3)
        hero().displayed_clip=""
    if was_transforming:transform_resolved.emit(false)

func _restore_presentation() -> void:
    if camera_tween!=null and camera_tween.is_valid():camera_tween.kill()
    if is_instance_valid(aura):aura.queue_free()
    aura=null
    if is_instance_valid(hero()):hero().camera.zoom=saved_zoom
    if audio_ducked and bgm_bus>=0:AudioServer.set_bus_volume_db(bgm_bus,saved_bgm_db)
    audio_ducked=false
    get_node("/root/Chapter").vignette.material.set_shader_parameter("strength",0)

func _stop_breath() -> void:
    if is_instance_valid(flame):flame.queue_free()
    flame=null
    if is_instance_valid(breath_sound):get_node("/root/Audio").stop_sfx(breath_sound)
    breath_sound=null

func _fx(id: String, offset: Vector2, size_px: Vector2, repeats: bool) -> Node2D:
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/stage9_fx.json"))[id]
    var effect: Node2D=load("res://scripts/image_effect.gd").new()
    var size: Array=spec["frame_size"]
    effect.configure("res://"+str(spec["path"]),Vector2i(int(size[0]),int(size[1])),int(spec["frames"]),float(spec["duration"]),repeats,Vector2(float(size[0])*.5,float(size[1])*.5))
    effect.scale=size_px/Vector2(float(size[0]),float(size[1]))
    hero().add_child(effect)
    effect.position=offset
    return effect

func _move_fx() -> void:
    if is_instance_valid(flame):
        flame.position.x=hero().facing*300
        flame.scale.x=absf(flame.scale.x)*hero().facing

func _arrival(_level_id: String = "") -> void:
    if state in ["transforming","active"]:
        hero().camera.zoom=saved_zoom/float(settings["zoom_out_factor"])
        render("idle",0)

func _cutscene_done(id: String) -> void:
    if state=="transforming" or (id=="utnapishtim_rampage" and engaged()):exit(true) # cancellation restores the original actor
    if state=="active":_arrival()
    if engaged() and id=="huluppu_victory":pending_checkpoint="victory"

func _flush_checkpoint() -> void:
    if not pending_checkpoint.is_empty():
        get_node("/root/Save").save_checkpoint(pending_checkpoint)
        pending_checkpoint=""
