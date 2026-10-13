extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(18)
    root.get_node("Rampage").set_death_suspended(true)
    root.get_node("Rampage").set_value(60)
    await _go("HuluppuCrown")
    var bosses: Dictionary={}
    for enemy: EnemyBase in get_nodes_in_group("enemies"):bosses[enemy.enemy_id]=enemy
    var mother: CrownBoss=bosses["ninazu_mother"]
    var lilith: CrownBoss=bosses["lilith"]
    var bird: CrownBoss=bosses["zu"]
    for pair in [[mother,19300,.5],[lilith,20500,.2],[bird,18800,.35]]:
        _check(pair[0].hp==pair[1] and is_equal_approx(pair[0]._turn_seconds(),pair[2]),"User HP/Turn Delay")
    _check(mother.hp+lilith.hp+bird.hp==58600,"Total HP 58600")
    _check(mother.stats["patterns"]["tail"]["damage"]==27 and is_equal_approx(mother.stats["patterns"]["tail"]["stagger_seconds"],.3),"Tail 18/0.3s")
    var poison: Dictionary=mother.stats["patterns"]["poison"]
    _check(poison["seconds"]==5 and poison["damage"]/poison["tick_interval"]==12,"Poison 5 seconds, DPS 8")
    mother._set_state(EnemyBase.State.WINDUP)
    mother.pattern="poison"
    mother.take_shockwave_hit(1,hero.global_position,4)
    _check(mother.state==EnemyBase.State.STUN and is_equal_approx(mother.stun_left,1) and mother.pattern.is_empty(),"Shockwave interrupts and stuns 1s")
    _check(lilith.stats["patterns"]["ambush"]["count"]==3 and lilith.stats["patterns"]["ambush"]["damage"]==15 and lilith.stats["patterns"]["ambush"]["teleport_seconds"]==.1,"Ambush 0.1 seconds and 3x10")
    _check(lilith.stats["patterns"]["ghost"]["interval"]==4.5 and lilith.stats["patterns"]["ghost"]["stagger_seconds"]==.5,"Enkidua apparition every 4.5s, stun .5")
    hero.reverse_controls(2.5)
    Input.action_press("move_right")
    _check(hero.movement_axis()==-1,"A/D reversed")
    hero.controls_reversed_left=.01
    hero._physics_process(.02)
    _check(hero.movement_axis()==1,"Reverse expires with gameplay time")
    Input.action_release("move_right")
    hero.weapon="axe"
    bird.take_hit(1,hero.global_position,4)
    _check(bird.state==EnemyBase.State.STUN and bird.stun_left==2,"Air axe fourth knocks bird down for 2s")
    _check(bird.stats["patterns"]["feathers"]["count"]==5 and bird.stats["patterns"]["feathers"]["damage"]==16.5 and bird.stats["patterns"]["grab"]["damage"]==49.5,"Bird 5x11 feathers /33 grab")
    var timer_arena: Node=manager.current_level.get_node("Arena")
    timer_arena.opening=0
    lilith.global_position=hero.global_position-Vector2(150,0)
    lilith.facing=1
    lilith.state=EnemyBase.State.CHASE
    lilith.attack_cooldown_left=.05
    lilith.ghost_clock=4.49
    lilith._physics_process(.005)
    _check(lilith.pattern!="ghost","Ghost does not run before4.5 seconds")
    lilith.attack_cooldown_left=0
    lilith._physics_process(.01)
    _check(lilith.pattern=="ghost" and lilith.state==EnemyBase.State.WINDUP,"Ghost becomes due after4.5 seconds")
    timer_arena.release(lilith)
    lilith.pattern="ambush"
    lilith.attack_stats=lilith.stats["patterns"]["ambush"]
    lilith.state=EnemyBase.State.ACTIVE
    lilith.state_clock=.2
    lilith.ghost_clock=4.5
    lilith._physics_process(.01)
    _check(lilith.pattern=="ambush","Due ghost defers instead of overlapping ambush")
    _check(not bird.get_collision_mask_value(2),"Stunned bird passes branch platforms to main ground")
    var arena: Node=manager.current_level.get_node("Arena")
    arena.opening=0
    arena.major_gap=0
    _check(arena.acquire(lilith) and not arena.can_attack(mother) and not arena.acquire(bird),"Major attacks mutually exclusive")
    arena.release(lilith)
    _check(arena.can_attack(mother),"Other minor patterns resume")
    _check(get_nodes_in_group("healing_pickups").size()==4,"Four healing points")
    hero.debug_hp_floor=false
    hero.damage_grace=0
    hero.action="normal"
    hero.receive_damage(hero.get_max_hp()+10,{"stagger":false,"grant_grace":false})
    _check(hero.hp==0 and hero.action=="dead","Rage suspension does not block ordinary HP death")
    await manager.handle_death()
    var sum:=0
    for enemy: EnemyBase in get_nodes_in_group("enemies"):sum+=enemy.hp
    _check(manager.current_level.level_id=="HuluppuCrown" and sum==58600 and hero.hp==hero.get_max_hp(),"Death restores arena checkpoint and all boss HP")
    await _finish("STAGE13_BOSSES")
