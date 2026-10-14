extends Node
var dash_left := 0.0
var dash_cooldown := 0.0
var throw_cooldown := 0.0
var second_jump_used := false
var wall_push_left := 0.0
var crawling := false
var vision := false
var motion_clock := 0.0

func reset_motion() -> void:
    dash_left=0
    dash_cooldown=0
    throw_cooldown=0
    second_jump_used=false
    wall_push_left=0
    crawling=false
    vision=false
    motion_clock=0

func tick(hero: NimrodPlayer,delta: float) -> bool:
    var world: Node = get_parent()
    if not world.active or hero.transition_locked or hero.action!="normal" or Input.is_action_just_pressed("restart"):return false
    var tuning: Dictionary = world.abilities_data.abilities
    dash_cooldown=maxf(0,dash_cooldown-delta)
    throw_cooldown=maxf(0,throw_cooldown-delta)
    wall_push_left=maxf(0,wall_push_left-delta)
    vision=world.has_ability("vision") and Input.is_action_pressed("ability_vision")
    if hero.is_on_floor():second_jump_used=false
    if Input.is_action_just_pressed("skill_light"):throw_light(hero)
    if world.has_ability("dash") and Input.is_action_just_pressed("dash") and dash_cooldown<=0:
        dash_left=float(tuning.dash.seconds)
        dash_cooldown=float(tuning.dash.cooldown)
        motion_clock=0
        AnurLightProjectile.spawn_fx(hero.get_parent(),hero.position-Vector2(0,40),"anur_light_cast")
    var climbable := false
    var wall_dir := 0
    for i in range(hero.get_slide_collision_count()):
        var collision: KinematicCollision2D = hero.get_slide_collision(i)
        var body: Object = collision.get_collider()
        if absf(collision.get_normal().x)>.5 and is_instance_valid(body) and body.get_meta("wall_climbable",false):
            climbable=true
            wall_dir=-1 if collision.get_normal().x>0 else 1
    if not hero.is_on_floor() and Input.is_action_just_pressed("jump"):
        if climbable and world.has_ability("wall_jump"):
            hero.velocity=Vector2(-wall_dir*float(tuning.wall_jump.x_impulse),-float(tuning.wall_jump.y_impulse))
            wall_push_left=.18
            hero._show_clip("wall_jump",0)
            second_jump_used=false
        elif world.has_ability("double_jump") and not second_jump_used:
            hero.velocity.y=-float(tuning.double_jump.impulse)
            second_jump_used=true
            hero.jump_start_left=.12
            AnurLightProjectile.spawn_fx(hero.get_parent(),hero.position-Vector2(0,35),"anur_light_cast")
    if dash_left>0:
        dash_left=maxf(0,dash_left-delta)
        motion_clock+=delta
        hero.velocity.x=hero.facing*float(tuning.dash.speed)
        hero._integrate_vertical(delta)
        hero._move_with_surface_rules(delta)
        hero._show_clip("dash",motion_clock)
        return true
    if hero.is_on_floor() and Input.is_action_pressed("crouch") and Input.is_action_just_pressed("jump"):
        return false # Preserve the existing S+Space one-way platform drop.
    if world.has_ability("crawl") and (hero.is_on_floor() and Input.is_action_pressed("crouch") or crawling and not hero._can_stand()):
        crawling=true
        hero.crouching=true
        var shape: RectangleShape2D = hero.collider.shape
        shape.size=Vector2(36,float(tuning.crawl.height))
        hero.collider.position.y=-float(tuning.crawl.height)*.5
        hero.velocity.x=hero.movement_axis()*float(tuning.crawl.speed)
        hero._integrate_vertical(delta)
        hero._move_with_surface_rules(delta)
        motion_clock+=delta
        hero._show_clip("crawl",motion_clock)
        return true
    if crawling:
        crawling=false
        hero.compact_escape=false
        hero.crouching=false
        hero._set_standing_collider()
    if climbable and world.has_ability("wall_cling") and hero.velocity.y>0 and hero.movement_axis()*wall_dir>0:
        hero.velocity.y=minf(hero.velocity.y,float(tuning.wall_cling.slide_speed))
        hero._move_with_surface_rules(delta)
        motion_clock+=delta
        hero._show_clip("wall_cling",motion_clock)
        return true
    if wall_push_left>0:
        hero._integrate_vertical(delta)
        hero._move_with_surface_rules(delta)
        hero._show_clip("wall_jump",.18-wall_push_left)
        return true
    return false

func throw_light(hero: NimrodPlayer) -> bool:
    var world: Node = get_parent()
    if not world.has_ability("light_throw") or throw_cooldown>0 or hero.action!="normal":return false
    var tuning: Dictionary = world.abilities_data.abilities.light_throw
    var projectile := AnurLightProjectile.new()
    projectile.hero=hero
    projectile.direction=hero.facing
    projectile.damage=int(tuning.damage)
    hero.get_parent().add_child(projectile)
    projectile.global_position=hero.global_position+Vector2(hero.facing*24,-74)
    projectile.settings.speed=tuning.speed
    projectile.settings.range=tuning.range
    projectile.modulate=Color(.85,.7,1)
    throw_cooldown=float(tuning.cooldown)
    return true
