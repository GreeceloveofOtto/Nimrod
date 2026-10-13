extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(18)
    var rage: Node=root.get_node("Rampage")
    var form: Node=root.get_node("HumbabaForm")
    await _go("HuluppuCrown")
    hero.global_position=Vector2(250,880)
    rage.set_value(100)
    await form.transformed
    var axis_before: Vector2=hero.collider.shape.size
    # Real low, one-way ceiling; the art may overlap it, the physics body never grows.
    var branch:=StaticBody2D.new()
    branch.collision_layer=2
    branch.position=hero.position-Vector2(0,52)
    branch.set_meta("one_way",true)
    var shape:=CollisionShape2D.new()
    var rect:=RectangleShape2D.new()
    rect.size=Vector2(200,12)
    shape.shape=rect
    shape.one_way_collision=true
    branch.add_child(shape)
    manager.current_level.add_child(branch)
    await physics_frame
    _check(hero._can_stand() and hero.collider.shape.size==axis_before,"Low one-way ceiling does not expand/block form collider")
    Input.action_press("move_right")
    hero._physics_process(.02)
    _check(hero.velocity.x>0 and hero.collider.shape.size==axis_before,"Form walks out of low platform space")
    Input.action_release("move_right")
    await process_frame
    Input.action_press("attack")
    hero._physics_process(.02)
    _check(form.attack_kind=="claw","Actual J action routes to claw (state=%s kind=%s locked=%s just=%s)"%[form.state,form.attack_kind,manager.player_locked,Input.is_action_just_pressed("attack")])
    Input.action_release("attack")
    await process_frame
    Input.action_press("roll")
    hero._physics_process(.02)
    _check(form.attack_kind=="tail" and not hero.is_roll_invulnerable(),"Actual K action cancels to tail, no i-frames")
    Input.action_release("roll")
    for phase in range(3):form._attack_tick(form._phase_seconds()+.001)
    await process_frame
    Input.action_press("skill_light")
    hero._physics_process(.02)
    _check(form.attack_kind=="breath","Actual R action routes to breath")
    Input.action_release("skill_light")
    form.exit(true)
    manager.set_player_locked(false)
    # Damage fractional accumulator preserves the strengthened16.5/49.5 values.
    hero.action="normal"
    hero.damage_grace=0
    hero.damage_fraction=0
    var before_hp: int=hero.hp
    hero.receive_damage(16.5,{"stagger":false,"grant_grace":false})
    hero.receive_damage(16.5,{"stagger":false,"grant_grace":false})
    _check(before_hp-hero.hp==33 and is_zero_approx(hero.damage_fraction),"Two strengthened feathers deal exactly33")
    before_hp=hero.hp
    hero.receive_damage(49.5,{"stagger":false,"grant_grace":false})
    hero.receive_damage(49.5,{"stagger":false,"grant_grace":false})
    _check(before_hp-hero.hp==99,"Two strengthened grabs deal exactly99")
    # Form damage does not use the enormous rage attack multiplier.
    form.cooldown_left=0
    rage.set_value(100)
    await form.transformed
    var mother: CrownBoss=get_nodes_in_group("enemies")[0]
    mother.global_position=hero.global_position+Vector2(120,0)
    var before_enemy: int=mother.hp
    hero.facing=1
    form.request_attack()
    form.attack_phase=1
    form._hit_targets()
    _check(before_enemy-mother.hp==22,"One claw deals22 independent of rage/stat multipliers")
    form.exit(true)
    manager.set_player_locked(false)
    await _finish("HUMBABA_FORM_PHYSICS")
