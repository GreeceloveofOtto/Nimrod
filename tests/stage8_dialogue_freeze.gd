extends "res://tests/helpers/stage4_support.gd"
func _run() -> void:
    await _start()
    await manager.go_to("DowntownPassage_F4", "Spawn_FromAbove", {"instant": true})
    var beast: EnemyBase = get_nodes_in_group("enemies")[0]
    beast.set_physics_process(true)
    var hazard: Node2D = load("res://scripts/stage5_hazard.gd").new()
    # Use a real time-dependent world node as a projectile/zone freeze witness.
    var effect: Node2D = load("res://scripts/image_effect.gd").new()
    effect.configure("res://assets/sprites/fx/gas_cloud.webp", Vector2i(256,256),6,2,true)
    main.add_child(effect)
    hazard.configure("gas", {"radius":110,"height":160,"seconds":4,"tick_interval":.2,"damage":1})
    hazard.position = Vector2(2000,400)
    main.add_child(hazard)
    var projectile := Stage5Projectile.new()
    var enemy_registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
    for stats: Dictionary in enemy_registry.enemies:
        if stats.id == "explosive_spitter":
            projectile.configure(stats.projectile,Vector2(2100,300))
    projectile.position = Vector2(1900,300)
    main.add_child(projectile)
    var npc := NPC.new()
    npc.npc_id = "gatekeeper"
    npc.position = Vector2(2200,400)
    main.add_child(npc)
    var door: DoorPortal = manager.current_level.doors.values()[0]
    door.open_progress = .25
    door.door_tween = door.create_tween()
    door.door_tween.tween_property(door,"open_progress",1.0,3.0)
    var d: Node = root.get_node("Dialogue")
    hero.set_physics_process(true)
    d.play(["시간 정지 검증"],hero,{"freeze":false,"character_seconds":.01,"hold_seconds":2.2})
    await process_frame
    var pos := beast.global_position
    var clock: float = beast.state_clock
    var cooldown: float = beast.attack_cooldown_left
    var frame: int = beast.current_frame
    var fx_clock: float = effect.clock
    var gas_age: float = hazard.age
    var projectile_position: Vector2 = projectile.global_position
    var player_position: Vector2 = hero.global_position
    var npc_clock: float = npc.clip_clock
    var door_progress: float = door.open_progress
    await create_timer(2,true,false,true).timeout
    _check(paused and beast.global_position == pos and beast.state_clock == clock,"Enemy position and state clock frozen for two seconds")
    _check(beast.attack_cooldown_left == cooldown and beast.current_frame == frame,"Cooldown and animation frozen")
    _check(effect.clock == fx_clock,"Looping gas/effect clock frozen")
    _check(hazard.age == gas_age and projectile.global_position == projectile_position,"Actual gas timer and projectile stay frozen")
    _check(hero.global_position == player_position,"Player physics stays paused")
    _check(npc.clip_clock == npc_clock and door.open_progress == door_progress,"NPC breathing and door tween stay paused")
    projectile.queue_free()
    hazard.queue_free()
    npc.queue_free()
    door.door_tween.kill()
    await d.finished
    effect.queue_free()
    await _finish("STAGE8_DIALOGUE_FREEZE")
