extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    var rage: Node=root.get_node("Rampage")
    var form: Node=root.get_node("HumbabaForm")
    var save: Node=root.get_node("Save")
    story_state.debug_stage(18)
    rage.set_value(91)
    _check(hero.hp==0 and hero.action=="dead" and not form.engaged(),"Unsuspended91 retains instant death")
    hero.reset_run_state()
    rage.set_value(60)
    await _go("HuluppuCrown")
    rage.set_death_suspended(true)
    var original_shape: Vector2=hero.collider.shape.size
    var original_feet: Vector2=hero.global_position
    rage.set_value(100)
    _check(form.state=="transforming" and hero.hp>0 and manager.player_locked,"Suspended100 starts actual transformation")
    _check(not hero.receive_damage(9999,{"grant_grace":false}),"Roar transformation invulnerable")
    var mother: CrownBoss=get_nodes_in_group("enemies")[0]
    var previous_clock: float=mother.ghost_clock
    mother._physics_process(.5)
    _check(mother.ghost_clock==previous_clock,"Boss clocks stop through transformation")
    await form.transformed
    _check(form.state=="active" and not manager.player_locked,"Roar returns control")
    _check(hero.visual.texture==form.textures["idle"],"Player uses actual Humbaba idle texture")
    _check(hero.collider.shape.size==original_shape and hero.global_position==original_feet,"Transform preserves body collider and feet")
    _check(form.minimum_density>=.9 and form.settings["visual_multiplier"]==1,"Stored density limits visual multiplier")
    for clip in form.clips:
        _check(form.textures[clip]==load("res://assets/"+str(form.clips[clip]["sheet"])),"Shared resource cache: "+clip)
    var hp_before: int=hero.hp
    var before_velocity: Vector2=hero.velocity
    hero.receive_damage(10,{"grant_grace":false,"knockback":Vector2(300,-200)})
    _check(hero.hp==hp_before-5 and hero.action=="normal" and hero.velocity==before_velocity,"Damage halved without stun or knockback")
    _check(not hero.apply_stun(.5) and not hero.apply_pull(700,.35),"Apparition stun and grab immune")
    hero.reverse_controls(2.5)
    Input.action_press("move_right")
    _check(hero.movement_axis()==-1,"Charm inversion remains active in form")
    Input.action_release("move_right")
    _check(not hero.cast_anur_light() and not hero.try_devour() and not rage.cure(hero),"Anur/devour/cure disabled during form")
    _check(not save.can_save() and not save._write_snapshot(true),"Manual and automatic save both blocked")
    hero.controls_reversed_left=0
    for step in range(1,5):
        _check(form.request_attack(),"J accepts combo step%d"%step)
        _check(form.combo_step==step and form.attack_kind==("bite" if step==4 else "claw"),"Claw1/2/3 then bite4")
        for phase in range(3):form._attack_tick(form._phase_seconds()+.001)
    _check(form.next_step==1,"Four-hit combo wraps")
    form.request_attack()
    hero.facing=1
    form.request_attack(-1)
    _check(hero.facing==-1 and form.combo_step==2 and hero.velocity.x==0,"Reverse J immediately starts next step with zero old momentum")
    hero.hitstop_left=.05
    form.request_attack(1)
    _check(hero.facing==-1 and hero.pending_cancel_direction==1,"Opposite J during hitstop buffers")
    form.tick_player(.051)
    _check(hero.facing==1 and form.combo_step==3,"Buffered reversal starts after hitstop")
    form.request_tail()
    _check(form.attack_kind=="tail" and not hero.is_roll_invulnerable(),"K is tail with no roll immunity")
    for phase in range(3):form._attack_tick(form._phase_seconds()+.001)
    _check(form.request_breath() and form.attack_kind=="breath" and form.breath_cooldown==6,"R breath uses independent six-second cooldown")
    _check(not form.request_breath(),"Repeated R blocked by cooldown")
    form.attack_phase=1
    form.attack_clock=0
    form.ticks=0
    for i in range(16):form._attack_tick(.1)
    _check(form.ticks==16,"Breath emits exactly16 ticks")
    var bird: CrownBoss=get_nodes_in_group("enemies")[2]
    bird.take_hit(1,hero.global_position,4)
    _check(bird.state!=EnemyBase.State.STUN,"Form cannot trigger air axe-four reaction")
    mother.take_shockwave_hit(1,hero.global_position,4)
    _check(mother.state!=EnemyBase.State.STUN,"Form cannot trigger axe shockwave weakness")
    hero.position=Vector2(1000,880)
    form.elapsed=0
    await _go("CastleF2")
    _check(form.state=="active" and hero.visual.texture==form.textures["idle"] and is_equal_approx(hero.camera.zoom.x,form.saved_zoom.x/1.15),"Form survives level transition and maintains camera")
    form.tick_player(12.5)
    _check(rage.value()==80 and is_equal_approx(form.remaining,12.5),"Gauge drains linearly100 to60 over25s")
    paused=true
    var pause_remaining: float=form.remaining
    await _wait(.05)
    _check(form.remaining==pause_remaining,"Pause does not consume form time")
    paused=false
    form.tick_player(12.5)
    _check(form.state=="exiting" and rage.value()==60 and manager.player_locked,"25s stops attacks, restores human and begins exhaustion")
    var exhausted_hp: int=hero.hp
    hero.damage_grace=0
    hero.receive_damage(10,{"grant_grace":false})
    _check(hero.hp==exhausted_hp-20,"Exhaustion takes double damage")
    form._process(.3)
    form._process(2)
    _check(not form.engaged() and rage.value()==60 and not manager.player_locked,"Two-second exhaustion unlocks at60")
    _check(is_equal_approx(hero.modifiers.multiplier("attack"),1.35+1.8),"Post-form attack modifier recomputed at rage60")
    _check(hero.selected_sprite_set()=="axe_prosthetic_helm_r50","Return renders normal r50 set")
    rage.set_value(100)
    _check(not form.engaged(),"15s cooldown blocks immediate re-entry")
    rage.set_value(60)
    form._process(15.01)
    rage.set_value(100)
    await form.transformed
    _check(form.state=="active","Can re-enter after15s")
    await _go("HuluppuCrown")
    hero.debug_hp_floor=false
    hero.receive_damage(float(hero.get_max_hp())*3,{"stagger":false,"grant_grace":false})
    _check(hero.action=="dead" and hero.hp==0,"HP-zero still kills the form")
    form.tick_player(.01)
    _check(hero.displayed_clip=="death" and hero.visual.texture==form.textures["death"],"Form death uses shared Humbaba death clip")
    await manager.handle_death()
    _check(not form.engaged() and rage.value()==0 and hero.hp==hero.get_max_hp() and manager.current_level.level_id=="HuluppuCrown","Actual form death respawns at crown, HP full, form off and rage0")
    await _go("CastleF2")
    rage.set_value(60)
    _check(save.save_game(),"Save succeeds when human form is inactive")
    var legacy: Dictionary=save.migrate_save({"version":1,"level":"DeathSea","position":[800,880],"hp":100,"run_flags":{"deathsea_arrived":true,"rampage":100,"weapon":"axe"}})
    _check(legacy["rampage"]==60 and legacy["run_flags"]["deathsea_arrived"],"Legacy suspended100 save migrates safely without deleting progress")
    await save.resume()
    _check(not form.engaged() and hero.hp>0,"Loaded save always starts human")
    root.get_node("GameState").switch_character("siyavash")
    rage.death_suspended=true
    rage.set_value(100)
    _check(not form.engaged() and not rage.unlocked() and hero.get_max_hp()==100,"Siyavash cannot enter form")
    await _finish("HUMBABA_FORM")
