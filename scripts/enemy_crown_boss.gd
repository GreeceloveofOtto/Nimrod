class_name CrownBoss
extends EnemyBase
var pattern:=""
var cooldowns: Dictionary={}
var ghost_clock:=0.0
var weak_stunned:=false
var airborne:=false
var grab_target: NimrodPlayer
var grab_origin:=Vector2.ZERO
var attack_target:=Vector2.ZERO
var tick_count:=0
var active_poison: Stage5Hazard
var ambush_turn_target:=0
var apparition: Node2D
var wing_clock:=0.0
var trail_clock:=0.0
var warning: Line2D
var previous_pattern:=""

func _ready() -> void:
    super._ready()
    no_drop=true
    airborne=enemy_id=="zu"
    attack_cooldown_left=float(stats["cooldown_offset"])
    for key in stats["patterns"]:cooldowns[key]=0.
    warning=Line2D.new()
    warning.width=3
    warning.default_color=Color(1,.08,.08,.65)
    warning.z_index=15
    warning.visible=false
    add_child(warning)

func arena() -> Node:
    return get_meta("arena",null)

func _physics_process(delta: float) -> void:
    if get_node("/root/HumbabaForm").state == "transforming":
        return
    for key in cooldowns:cooldowns[key]=maxf(0,float(cooldowns[key])-delta)
    trail_clock=maxf(0,trail_clock-delta)
    if enemy_id=="lilith" and absf(velocity.x)>50 and trail_clock<=0 and state!=State.DEAD:
        _afterimage()
    ghost_clock+=delta
    wing_clock+=delta
    var coordinator: Node=arena()
    if is_instance_valid(coordinator) and coordinator.opening>0:
        _integrate_motion(delta)
        _show_clip("idle",wing_clock)
        return
    super._physics_process(delta)

func _update_idle(delta: float) -> void:
    _update_chase(delta)

func _update_chase(delta: float) -> void:
    var hero: NimrodPlayer=_target() as NimrodPlayer
    if not _player_is_available(hero):
        _brake(delta)
        return
    var dx: float=hero.global_position.x-global_position.x
    var desired: int=1 if dx>=0 else -1
    if desired!=facing:
        _request_turn(desired)
        return
    var coordinator: Node=arena()
    if attack_cooldown_left>0 or (is_instance_valid(coordinator) and not coordinator.can_attack(self)):
        velocity.x=facing*float(stats["move_speed"])*.25 if absf(dx)>250 else 0.
        return
    var choice:=""
    if enemy_id=="ninazu_mother":
        choice="tail" if absf(dx)<330 else "poison"
    elif enemy_id=="lilith":
        choice="ghost" if ghost_clock>=float(stats["patterns"]["ghost"]["interval"]) else "ambush" if previous_pattern!="ambush" else "charm"
    else:
        choice="grab" if previous_pattern!="grab" else "feathers"
    if float(cooldowns.get(choice,0))>0:
        for key in stats["patterns"]:
            if float(cooldowns[key])<=0 and (key!="ghost" or ghost_clock>=4.5):
                choice=key
                break
    if float(cooldowns.get(choice,0))>0:
        velocity.x=facing*float(stats["move_speed"])*.3
        return
    var major: bool=choice in ["ambush","grab","ghost"]
    if is_instance_valid(coordinator) and major and not coordinator.acquire(self):return
    pattern=choice
    ambush_turn_target=hero.facing if choice=="ambush" else 0
    previous_pattern=choice
    attack_stats=stats["patterns"][choice].duplicate(true)
    attack_target=hero.global_position
    attack_has_hit=false
    tick_count=0
    velocity.x=0
    _set_state(State.WINDUP)
    if pattern=="grab":
        warning.points=PackedVector2Array([Vector2(0,-body_size.y*.5),to_local(attack_target-Vector2(0,60))])
        warning.show()
    _play_sfx("humbaba_claw")

func _update_windup(delta: float) -> void:
    _brake(delta)
    if pattern=="ambush" and ambush_turn_target!=0 and state_clock>=_turn_seconds()*.5:
        facing=ambush_turn_target
    if state_clock>=float(attack_stats["windup"]):
        _set_state(State.ACTIVE)
        cooldowns[pattern]=float(attack_stats["cooldown"])
        var hero: NimrodPlayer=_target() as NimrodPlayer
        if pattern=="ambush" and hero!=null:
            visual.modulate.a=0
            var smoke: Node2D=Stage5FX.spawn(_level(),"gas_cloud",global_position-Vector2(0,90),Vector2(180,150))
            smoke.modulate=Color(.2,.02,.04,.5)
            var fade:=smoke.create_tween()
            fade.tween_property(smoke,"modulate:a",0.,.5)
            fade.tween_callback(smoke.queue_free)
            attack_target=hero.global_position+Vector2(-facing*80,0)
        elif pattern=="ghost":
            ghost_clock=0
            _ghost()
            if hero!=null:hero.apply_stun(float(attack_stats["stagger_seconds"]))
        elif pattern=="poison":
            var hazard:=Stage5Hazard.new()
            hazard.configure("gas",{"radius":attack_stats["radius"],"height":attack_stats["height"],"seconds":attack_stats["seconds"],"tick_interval":attack_stats["tick_interval"],"damage":attack_stats["damage"]})
            hazard.position=Vector2(clampf(attack_target.x,120,3080),880-float(attack_stats["height"])*.5)
            _level().add_child(hazard)
            active_poison=hazard
        elif pattern in ["feathers","charm"]:
            var count: int=int(attack_stats.get("count",1))
            for i in range(count):
                var projectile: Node2D=load("res://scripts/crown_projectile.gd").new()
                projectile.position=global_position+Vector2(0,-body_size.y*.4)
                projectile.speed=float(attack_stats["speed"])
                projectile.damage=float(attack_stats["damage"])
                projectile.charm_seconds=float(attack_stats.get("reverse_seconds",0))
                var direction: Vector2=projectile.position.direction_to(attack_target-Vector2(0,55))
                var angle: float=lerpf(-.5,.5,float(i)/float(maxi(1,count-1)))*deg_to_rad(float(attack_stats.get("spread_degrees",0)))
                projectile.direction=direction.rotated(angle)
                projectile.remaining=float(attack_stats.get("range",1200))
                _level().add_child(projectile)

func _update_active(_delta: float) -> void:
    var hero: NimrodPlayer=_target() as NimrodPlayer
    if pattern=="ambush":
        if state_clock>=float(attack_stats["teleport_seconds"]) and visual.modulate.a==0:
            global_position=Vector2(clampf(attack_target.x,80,3120),attack_target.y)
            visual.modulate.a=1
            # Ambush emerges in the locked original facing; no instant turnaround.
        var strike_time: float=state_clock-float(attack_stats["teleport_seconds"])
        while tick_count<int(attack_stats["count"]) and strike_time>=tick_count*float(attack_stats["interval"]):
            if hero!=null and get_attack_rect().intersects(_player_rect(hero)):
                hero.receive_damage(float(attack_stats["damage"]),{"grant_grace":false})
            tick_count+=1
    elif pattern=="tail":
        if not attack_has_hit and hero!=null and get_attack_rect().intersects(_player_rect(hero)):
            attack_has_hit=hero.receive_damage(float(attack_stats["damage"]),{"stagger_seconds":float(attack_stats["stagger_seconds"])})
    elif pattern=="grab":
        warning.hide()
        if is_instance_valid(grab_target):
            if grab_target.pull_escaped or grab_target.is_roll_invulnerable():
                grab_target=null
                attack_has_hit=true
                return
            var carry: float=float(attack_stats["carry_seconds"])
            grab_target.global_position=global_position+Vector2(0,-20)
            velocity=Vector2(0,-180 if state_clock<carry else 780)
            if state_clock>=carry and global_position.y>=810:
                grab_target.global_position.y=880
                grab_target.pull_left=0
                grab_target.receive_damage(float(attack_stats["damage"]),{"grant_grace":false})
                grab_target=null
                attack_has_hit=true
        elif not attack_has_hit:
            velocity=global_position.direction_to(attack_target)*float(attack_stats["dive_speed"])
            if hero!=null and get_hurt_rect().grow(20).intersects(_player_rect(hero)) and not hero.is_roll_invulnerable() and not get_node("/root/HumbabaForm").superarmored():
                grab_target=hero
                hero.apply_pull(global_position.x,.7)
                state_clock=0
    if state_clock>=float(attack_stats["active"]):
        _release_effects()
        active_poison=null
        _begin_recovery(float(attack_stats["recovery"]))

func _integrate_motion(delta: float) -> void:
    if enemy_id=="zu" and state!=State.STUN and state!=State.DEAD:
        if pattern!="grab" or state!=State.ACTIVE:
            velocity.y=clampf((510-global_position.y)*3,-140,140)
        move_and_slide()
        global_position.x=clampf(global_position.x,body_size.x*.5,3200-body_size.x*.5)
        return
    super._integrate_motion(delta)

func snap_to_ground() -> void:
    if enemy_id!="zu":super.snap_to_ground()

func _update_recovery(delta: float) -> void:
    _brake(delta)
    if state_clock>=recovery_duration:
        if is_instance_valid(arena()):arena().release(self)
        pattern=""
        _set_state(State.CHASE)

func get_attack_rect() -> Rect2:
    if state!=State.ACTIVE or attack_stats.is_empty():return Rect2()
    var box: Array=attack_stats["box"]
    if pattern=="ambush":
        return Rect2(global_position-Vector2(float(box[0])*.5,float(box[1])),Vector2(float(box[0]),float(box[1])))
    return Rect2(global_position+Vector2(0 if facing>0 else -float(box[0]),-float(box[1])),Vector2(float(box[0]),float(box[1])))

func _receive_hit(damage: int, source: Vector2, step: int, shockwave: bool) -> Dictionary:
    var hero: NimrodPlayer=_target() as NimrodPlayer
    var human_axe: bool=not get_node("/root/HumbabaForm").superarmored()
    var air_four: bool=human_axe and enemy_id=="zu" and not shockwave and step==4 and hero!=null and hero.weapon=="axe" and not hero.is_on_floor()
    var result: Dictionary=super._receive_hit(damage,source,step,shockwave)
    if hp>0 and int(result["damage_dealt"])>0:
        if human_axe and enemy_id=="ninazu_mother" and shockwave and step==4:
            weak_stun(float(stats["shockwave_stun"]))
        elif air_four:
            weak_stun(float(stats["air_fourth_stun"]))
    return result

func _on_hit(_seconds: float) -> void:
    pass # Large bosses keep recovery unless their specified weak reaction is struck.

func weak_stun(seconds: float) -> void:
    if pattern=="poison" and is_instance_valid(active_poison):active_poison.queue_free()
    active_poison=null
    if enemy_id=="zu":set_collision_mask_value(2,false)
    _release_effects()
    if is_instance_valid(arena()):arena().release(self)
    pattern=""
    recovery_after_stun=0
    attack_cooldown_left=maxf(attack_cooldown_left,1.5)
    weak_stunned=true
    stun_left=seconds
    _set_state(State.STUN)
    velocity=Vector2.ZERO

func _update_stun(delta: float) -> void:
    if enemy_id=="zu" and not is_on_floor():return
    stun_left=maxf(0,stun_left-delta)
    if stun_left<=0:
        weak_stunned=false
        if enemy_id=="zu":set_collision_mask_value(2,true)
        _set_state(State.CHASE)

func _ghost() -> void:
    var npc_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/npcs/enkidua/manifest.json"))
    var clip: Dictionary=npc_data["clips"][0]
    apparition=Node2D.new()
    add_child(apparition)
    var sprite:=Sprite2D.new()
    sprite.region_enabled=true
    sprite.texture=load("res://assets/"+str(clip["sheet"]))
    sprite.set_meta("canonical_scale",Vector2.ONE*.3)
    apparition.add_child(sprite)
    AssetVisual.apply_frame(sprite,clip,0)
    sprite.modulate=Color(1,.1,.15,.65)
    visual.modulate.a=.15

func _release_effects() -> void:
    visual.modulate.a=1
    warning.hide()
    if is_instance_valid(apparition):apparition.queue_free()
    apparition=null
    if is_instance_valid(grab_target):
        grab_target.pull_left=0
    grab_target=null

func _die() -> void:
    if pattern=="poison" and is_instance_valid(active_poison):active_poison.queue_free()
    active_poison=null
    _release_effects()
    super._die()

func _update_visual(delta: float) -> void:
    var clip:="idle"
    if state==State.DEAD:clip="death"
    elif state==State.STUN:clip="hurt"
    elif state==State.TURN:clip="turn"
    elif state==State.CHASE and absf(velocity.x)>1:clip="move"
    elif state in [State.WINDUP,State.ACTIVE]:
        var visual_pattern: String=pattern if not pattern.is_empty() else str(attack_stats.get("id",stats["patterns"].keys()[0]))
        clip=visual_pattern+"_windup" if state==State.WINDUP else visual_pattern+"_attack"
    display_clock+=delta
    var seconds: float=state_clock if state not in [State.IDLE,State.CHASE] else display_clock
    if state==State.STUN:seconds=fmod(seconds,float(clip_data["hurt"]["duration_seconds"]))
    if pattern=="ambush" and state==State.WINDUP and state_clock<_turn_seconds():
        clip="turn"
    _show_clip(clip,seconds)
    # Generated final turn pose faces the opposite basis; the third frame still switches facing.
    if state==State.TURN and current_frame==int(clip_data["turn"]["frames"])-1:
        visual.flip_h=facing>0

func _afterimage() -> void:
    trail_clock=.08
    var clone:=visual.duplicate() as Sprite2D
    _level().add_child(clone)
    clone.global_position=visual.global_position
    clone.modulate=Color(1,.06,.08,.45)
    clone.z_index=z_index-1
    var tween:=clone.create_tween()
    tween.tween_property(clone,"modulate:a",0.,.25)
    tween.tween_callback(clone.queue_free)
