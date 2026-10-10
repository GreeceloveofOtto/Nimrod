extends SceneTree

const BASE = preload("res://scripts/enemy_base.gd")
const MELEE = preload("res://scripts/enemy_melee_beast.gd")
const SKY = preload("res://scripts/enemy_sky_beast.gd")
const PICKUP = preload("res://scripts/healing_pickup.gd")

class TestLevel:
    extends Node2D
    var floor_y: float = 620.0
    var safe_enabled: bool = false
    func is_point_safe(point: Vector2) -> bool:
        return safe_enabled and (point.x <= 350.0 or point.x >= 4950.0)
    func get_enemy_roam_bounds(_point: Vector2, size: Vector2) -> Vector2:
        return Vector2(350.0 + size.x * 0.5, 4950.0 - size.x * 0.5)
    func get_flight_bounds() -> Rect2:
        return Rect2(0.0, 80.0, 2400.0, 500.0)

var world: Node2D
var level: TestLevel
var player: NimrodPlayer
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
    run.call_deferred()

func expect(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("FAIL: " + message)

func close(actual: float, expected: float, message: String) -> void:
    expect(absf(actual - expected) <= 0.001, message + " (%s != %s)" % [actual, expected])

func spawn_sky(at: Vector2 = Vector2(1400.0, 400.0)) -> EnemyBase:
    var enemy: EnemyBase = SKY.new()
    enemy.position = at
    level.add_child(enemy)
    enemy.set_physics_process(false)
    return enemy

func destroy_enemy(enemy: Node) -> void:
    enemy.free()

func run() -> void:
    world = Node2D.new()
    root.add_child(world)
    current_scene = world
    level = TestLevel.new()
    level.add_to_group("current_level")
    world.add_child(level)
    player = load("res://scenes/Player.tscn").instantiate() as NimrodPlayer
    world.add_child(player)
    player.set_physics_process(false)
    player.position = Vector2(1550.0, 620.0)
    await physics_frame
    test_stats_and_damage()
    test_dive_and_interrupt()
    test_turn_and_recovery()
    test_bounds_and_safe_zones()
    test_drops_and_healing()
    await test_actual_overshoot()
    await test_wall_collision()
    await test_death_fall()
    world.queue_free()
    await process_frame
    var audio: Node = root.get_node_or_null("Audio")
    if audio != null:
        for child in audio.get_children():
            if child.has_method("stop"):
                child.call("stop")
    await create_timer(0.1).timeout
    print("Stage 2 sky/safe-zone checks: %d; failures: %d" % [checks, failures])
    quit(0 if failures == 0 else 1)

func test_stats_and_damage() -> void:
    var enemy: EnemyBase = spawn_sky()
    expect(enemy.hp == 110, "sky starts with 110 HP")
    close(enemy.stats["turn_delay"], 0.25, "sky turn delay")
    close(enemy.stats["detect_range"], 700.0, "sky detection range")
    close(enemy.visual.scale.x, 0.45, "sky visual scale")
    expect(enemy.collision_layer == 4 and enemy.collision_mask == 3, "sky collision layer/mask preserve attacks and terrain")
    close(enemy.collider.position.y, 0.0, "airborne hurtbox uses center anchor")
    expect(is_instance_valid(enemy.wing_loop), "hover starts the wing loop")
    if is_instance_valid(enemy.wing_loop):
        close(enemy.wing_loop.get("volume_db"), -16.0, "wing loop stays at low volume")
    enemy.take_hit(20, enemy.position - Vector2(100.0, 0.0), 1)
    close(enemy.velocity.x, 56.0, "sky knockback is 40 percent of first strike")
    close(enemy.stun_left, 0.25, "sky hit stuns for 0.25 seconds")
    close(enemy.hitstop_left, 0.05, "sky hitstop lasts 0.05 seconds")
    var before: Vector2 = enemy.position
    var previous_frame: int = enemy.current_frame
    enemy._physics_process(0.02)
    expect(enemy.position == before and enemy.current_frame == previous_frame, "hitstop freezes movement and animation")
    for step in [2, 3, 4]:
        enemy.take_hit(22 if step == 4 else 20, enemy.position - Vector2(100.0, 0.0), step)
    expect(enemy.hp == 28, "one full combo deals 82")
    enemy.take_hit(20, enemy.position - Vector2(100.0, 0.0), 1)
    expect(enemy.hp == 8 and enemy.state != BASE.State.DEAD, "fifth hit leaves eight HP")
    enemy.take_hit(20, enemy.position - Vector2(100.0, 0.0), 2)
    expect(enemy.hp == 0 and enemy.state == BASE.State.DEAD, "sixth axe hit kills sky beast")
    expect(enemy.collision_layer == 0 and enemy.collision_mask == 0, "death disables damage and collision immediately")
    expect(not is_instance_valid(enemy.wing_loop), "death stops wing loop immediately")
    destroy_enemy(enemy)

func test_dive_and_interrupt() -> void:
    var enemy: EnemyBase = spawn_sky()
    player.position = Vector2(1560.0, 620.0)
    enemy._begin_attack()
    var locked_target: Vector2 = enemy.dive_target
    player.position.x += 180.0
    enemy.state_clock = 0.4
    enemy._update_windup(0.4)
    expect(enemy.state == BASE.State.ACTIVE, "windup enters dive after 0.4 seconds")
    expect(enemy.dive_target == locked_target, "dive target stays fixed after player moves")
    close(enemy.velocity.length(), 520.0, "dive speed is 520 pixels per second")
    close(enemy.dive_distance, enemy.position.distance_to(locked_target) + 200.0, "dive plans 200 pixels beyond locked target")
    enemy.state_clock = 0.9
    enemy._update_active(0.9)
    expect(enemy.state == BASE.State.RECOVERY, "dive stops at 0.9 second cap")
    close(enemy.recovery_duration, 0.6, "dive pays 0.6 seconds recovery")
    close(enemy.attack_cooldown_left, 1.2, "completed dive starts 1.2 second cooldown")
    destroy_enemy(enemy)
    for attack_state in [BASE.State.WINDUP, BASE.State.ACTIVE]:
        enemy = spawn_sky()
        enemy._set_state(attack_state)
        enemy.take_hit(20, enemy.position - Vector2(100.0, 0.0), 1)
        expect(enemy.state == BASE.State.STUN, "windup/active axe cancels dive")
        close(enemy.stun_left, 0.25, "interrupted dive staggers for 0.25")
        close(enemy.recovery_after_stun, 0.0, "cancelled dive returns to hover after stun")
        close(enemy.attack_cooldown_left, 1.2, "cancelled dive starts cooldown")
        destroy_enemy(enemy)
    enemy = spawn_sky()
    player.reset_run_state()
    player.position = enemy.position + Vector2(0.0, 62.0)
    enemy.dive_direction = Vector2.RIGHT
    enemy._set_state(BASE.State.ACTIVE)
    enemy._update_active(0.01)
    expect(player.hp == 172, "dive contact damages player by eight")
    player.damage_grace = 0.0
    enemy._update_active(0.01)
    expect(player.hp == 172, "one dive cannot hit twice even after grace clears")
    enemy.attack_has_hit = false
    player.set_transition_locked(true)
    enemy._update_active(0.01)
    expect(player.hp == 172, "transition lock rejects dive damage")
    player.set_transition_locked(false)
    player.reset_run_state()
    player.action = "roll"
    player.roll_clock = 0.1
    enemy._update_active(0.01)
    expect(player.hp == 180, "roll invulnerability rejects dive contact")
    destroy_enemy(enemy)
    enemy = spawn_sky()
    enemy._set_state(BASE.State.ACTIVE)
    enemy.take_shockwave_hit(22, enemy.position - Vector2(100.0, 0.0), 4)
    expect(enemy.state == BASE.State.STUN and enemy.dive_direction == Vector2.ZERO, "shockwave also interrupts a dive")
    close(enemy.velocity.x, 36.0, "sky shockwave knockback uses forty percent")
    destroy_enemy(enemy)

func test_turn_and_recovery() -> void:
    var enemy: EnemyBase = spawn_sky()
    enemy.clip_data["turn"] = {"frames": 4, "duration_seconds": 0.25, "loop": false}
    enemy._request_turn(-1)
    enemy.state_clock = 0.124
    enemy._update_turn(0.01)
    enemy._update_visual(0.0)
    expect(enemy.facing == 1 and enemy.current_frame == 1, "turn second frame keeps original facing")
    enemy.state_clock = 0.125
    enemy._update_turn(0.001)
    enemy._update_visual(0.0)
    expect(enemy.facing == -1 and enemy.current_frame == 2, "turn switches flip at third frame")
    enemy.state_clock = 0.249
    enemy._update_turn(0.001)
    expect(enemy.state == BASE.State.TURN, "turn continues for full delay")
    enemy.state_clock = 0.25
    enemy._update_turn(0.001)
    expect(enemy.state != BASE.State.TURN, "turn ends at delay boundary")
    for attack_state in [BASE.State.WINDUP, BASE.State.ACTIVE, BASE.State.RECOVERY]:
        enemy.facing = 1
        enemy._set_state(attack_state)
        enemy._request_turn(-1)
        expect(enemy.facing == 1 and enemy.state == attack_state, "attack and recovery cannot turn")
    enemy._begin_recovery(0.6)
    enemy.state_clock = 0.59
    enemy._update_recovery(0.01)
    expect(enemy.state == BASE.State.RECOVERY and enemy.velocity.y < 0.0, "recovery rises while retaining its full duration")
    destroy_enemy(enemy)

func test_bounds_and_safe_zones() -> void:
    var enemy: EnemyBase = spawn_sky()
    enemy.position = Vector2(-100.0, -100.0)
    enemy._enforce_bounds()
    expect(enemy.get_hurt_rect().position.x >= 0.0 and enemy.get_hurt_rect().position.y >= 80.0, "sky full hurtbox stays above and inside left boundary")
    enemy.position = Vector2(3000.0, 900.0)
    enemy._enforce_bounds()
    expect(enemy.get_hurt_rect().end.x <= 2400.0 and enemy.position.y <= 580.0, "sky stays inside right and lower flight boundaries")
    destroy_enemy(enemy)
    level.safe_enabled = true
    var melee: EnemyBase = MELEE.new()
    melee.position = Vector2(400.0, 620.0)
    melee.patrol_center = 400.0
    melee.patrol_range = 250.0
    level.add_child(melee)
    melee.set_physics_process(false)
    melee.position.x = 290.0
    melee.velocity.x = -260.0
    melee._enforce_bounds()
    expect(melee.get_hurt_rect().position.x >= 350.0, "knockback cannot push body into left safe zone")
    close(melee.velocity.x, 0.0, "safe-zone clamp stops outward knockback")
    var roam: Vector2 = melee._ground_roam_bounds()
    expect(roam.x - melee.body_size.x * 0.5 >= 350.0, "patrol range excludes safe zone")
    melee.position.x = 600.0
    melee.facing = -1
    player.position = Vector2(340.0, 620.0)
    melee._set_state(BASE.State.CHASE)
    melee._update_chase(0.01)
    expect(melee.state == BASE.State.IDLE and not melee._can_detect(player), "safe player makes enemy abandon chase")
    melee._update_idle(0.01)
    expect(melee.velocity.x < 0.0, "enemy returns toward patrol home after losing safe player")
    melee._set_state(BASE.State.ACTIVE)
    melee.position.x = 400.0
    expect(not melee._player_in_attack(player), "attack cannot reach player inside safe zone")
    melee.patrol_center = 4750.0
    melee.patrol_range = 150.0
    melee.position.x = 5050.0
    melee.velocity.x = 260.0
    melee._enforce_bounds()
    expect(melee.get_hurt_rect().end.x <= 4950.0, "knockback cannot push body into right safe zone")
    destroy_enemy(melee)
    level.safe_enabled = false

func test_drops_and_healing() -> void:
    var enemy: EnemyBase = spawn_sky()
    close(enemy.flight["drop_chance"], 0.05, "healing drop chance is five percent")
    enemy.flight = enemy.flight.duplicate(true)
    enemy.flight["drop_chance"] = 1.0
    enemy._roll_drop()
    enemy._roll_drop()
    var drops: Array[Node] = get_nodes_in_group("healing_pickups")
    expect(drops.size() == 1, "a successful death roll creates exactly one pickup")
    if not drops.is_empty():
        var pickup: Node = drops[0]
        player.reset_run_state()
        player.hp = 165
        pickup.interact(player)
        expect(player.hp == 180, "healing pickup caps player HP at 180")
    var second: Node2D = PICKUP.new()
    level.add_child(second)
    player.hp = 100
    second.interact(player)
    expect(player.hp == 130, "healing pickup restores exactly thirty HP")
    var third: Node2D = PICKUP.new()
    level.add_child(third)
    player.hp = 180
    third.interact(player)
    expect(not third.is_queued_for_deletion(), "full-health player can leave pickup for later")
    third.free()
    destroy_enemy(enemy)

func test_actual_overshoot() -> void:
    player.reset_run_state()
    player.position = Vector2(1100.0, 362.0)
    var enemy: EnemyBase = spawn_sky(Vector2(1000.0, 300.0))
    enemy._begin_attack()
    enemy._begin_active()
    enemy.set_physics_process(true)
    await create_timer(0.6).timeout
    expect(enemy.position.x >= 1300.0 and enemy.position.x < 1320.0, "real dive travels target plus about two hundred pixels")
    expect(enemy.state == BASE.State.RECOVERY, "completed overshoot enters recovery before max duration")
    enemy.set_physics_process(false)
    destroy_enemy(enemy)

func test_wall_collision() -> void:
    var wall := StaticBody2D.new()
    wall.collision_layer = 1
    wall.position = Vector2(1120.0, 330.0)
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(40.0, 580.0)
    shape.shape = rectangle
    wall.add_child(shape)
    level.add_child(wall)
    var enemy: EnemyBase = spawn_sky(Vector2(1000.0, 300.0))
    enemy.dive_direction = Vector2.RIGHT
    enemy.dive_distance = 1000.0
    enemy._set_state(BASE.State.ACTIVE)
    enemy.set_physics_process(true)
    await create_timer(0.2).timeout
    expect(enemy.get_hurt_rect().end.x <= 1100.1, "real physics dive cannot pass solid terrain")
    expect(enemy.state == BASE.State.RECOVERY, "terrain contact ends dive into recovery")
    enemy.set_physics_process(false)
    destroy_enemy(enemy)
    wall.queue_free()

func test_death_fall() -> void:
    var enemy: EnemyBase = spawn_sky(Vector2(1400.0, 240.0))
    enemy.flight = enemy.flight.duplicate(true)
    enemy.flight["drop_chance"] = 0.0
    enemy.take_hit(110, enemy.position - Vector2(100.0, 0.0), 4)
    enemy.set_physics_process(true)
    await create_timer(0.15).timeout
    expect(is_instance_valid(enemy) and enemy.position.y > 240.0, "dead sky beast falls instead of floating")
    await create_timer(1.7).timeout
    expect(not is_instance_valid(enemy), "dead sky beast disappears after landing and fade")
