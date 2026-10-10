extends SceneTree

# Run with Godot 4.3: --headless --path . --script tests/regression.gd
# These tests execute production methods and physics queries in real scenes.
const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const ENEMY_BASE = preload("res://scripts/enemy_base.gd")

var checks: int = 0
var failures: int = 0
var fixture: Node2D
var player: Variant

func _initialize() -> void:
    _run.call_deferred()

func _expect(condition: bool, description: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error("FAIL: " + description)

func _close(actual: float, expected: float, description: String) -> void:
    _expect(absf(actual - expected) < 0.0001, description + " (got %s, expected %s)" % [actual, expected])

func _section_result(name: String, failures_before: int) -> void:
    print(("PASS" if failures == failures_before else "FAIL") + " section: " + name)

func _release_inputs() -> void:
    for action: String in ["move_left", "move_right", "crouch", "roll", "attack", "jump", "restart", "debug_hitbox"]:
        Input.action_release(action)

func _reset_player() -> void:
    _release_inputs()
    player._cancel_attack()
    player.hp = 180
    player.action = "normal"
    player.facing = 1
    player.crouching = false
    player.velocity = Vector2.ZERO
    player.damage_grace = 0.0
    player.hurt_clock = 0.0
    player.hurt_duration = 0.45
    player.hitstop_left = 0.0
    player.position = Vector2(1000, 500)
    player._set_standing_collider()

func _new_fixture() -> void:
    fixture = Node2D.new()
    root.add_child(fixture)
    var ground := StaticBody2D.new()
    ground.collision_layer = 1
    ground.collision_mask = 0
    ground.position = Vector2(2000, 550)
    var ground_shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(5000, 100)
    ground_shape.shape = rectangle
    ground.add_child(ground_shape)
    fixture.add_child(ground)
    player = PLAYER_SCENE.instantiate()
    fixture.add_child(player)
    player.set_physics_process(false)
    player.camera.enabled = false
    _reset_player()

func _run() -> void:
    _new_fixture()
    await physics_frame
    await physics_frame
    await process_frame
    _test_roll_cancels()
    _test_damage_paths()
    # Clear this frame's synthetic just-pressed K before advancing AI scenarios.
    await process_frame
    await _test_jump_and_land()
    await _test_enemies()
    await _test_debug_toggle()
    fixture.queue_free()
    player = null
    fixture = null
    await process_frame
    await _test_rear_gate()
    _release_inputs()
    _stop_audio(root)
    # Let the audio mixer release playback references before this short test exits.
    await create_timer(0.1).timeout
    print("NIMROD REGRESSION: %d checks, %d failures" % [checks, failures])
    quit(1 if failures > 0 else 0)

func _stop_audio(node: Node) -> void:
    if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
        node.stop()
    for child: Node in node.get_children():
        _stop_audio(child)

func _test_roll_cancels() -> void:
    var failures_before: int = failures
    # The same real K dispatch path must work before, during and after axe active frames.
    for timing: float in [0.02, 0.12, 0.26]:
        _reset_player()
        player._begin_attack(1)
        player.attack_clock = timing
        player.buffered_attack = true
        player.attack_already_hit[123] = true
        player.debug_rect = Rect2(1, 1, 10, 10)
        player.shockwave_rect = Rect2(2, 2, 20, 20)
        player.combo_next = 3
        Input.action_press("move_left")
        Input.action_press("roll")
        player._physics_process(0.01)
        _expect(player.action == "roll" and player.roll_direction == -1 and player.facing == -1 and player.visual.flip_h, "K reads opposite held direction at attack t=%s" % timing)
        _expect(not player.buffered_attack and player.attack_already_hit.is_empty() and player.debug_rect == Rect2() and player.shockwave_rect == Rect2(), "roll cancel clears all attack remnants at t=%s" % timing)
        _expect(player.attack_step == 0 and player.combo_next == 1, "roll cancel resets combo at t=%s" % timing)
        _release_inputs()

    _reset_player()
    player._begin_attack(4)
    player.velocity.y = -300.0
    Input.action_press("move_left")
    player._begin_roll()
    _expect(player.action == "roll" and player.roll_direction == -1 and player.velocity.y == -300.0, "airborne fourth attack rolls toward held axis and keeps vertical motion")

    _reset_player()
    player.facing = -1
    player._begin_attack(2)
    player._begin_roll()
    _expect(player.roll_direction == -1 and player.visual.flip_h, "no axis retains current facing")

    _reset_player()
    player.facing = -1
    player.crouching = true
    player._set_crouching_collider()
    Input.action_press("crouch")
    Input.action_press("move_right")
    player._begin_roll()
    _expect(player.roll_direction == 1 and player.facing == 1 and not player.crouching and not player.visual.flip_h, "normal crouch plus right axis rolls right")

    _reset_player()
    player._begin_attack(3)
    Input.action_press("crouch")
    Input.action_press("move_left")
    player._begin_roll()
    _expect(player.roll_direction == -1, "held crouch does not hide directional attack cancel")

    _reset_player()
    player.facing = -1
    Input.action_press("move_right", 0.005)
    player._begin_roll()
    _expect(player.roll_direction == -1, "axis below 0.01 retains facing")
    _section_result("directional rolls and cancel cleanup", failures_before)

func _test_damage_paths() -> void:
    var failures_before: int = failures
    _reset_player()
    _expect(player.receive_damage(9), "ordinary damage accepted")
    _expect(player.hp == 171 and player.action == "hurt", "ordinary hit removes 9 HP and staggers")
    _close(player.hurt_duration, 0.45, "ordinary hurt duration remains 0.45")
    _close(player.damage_grace, 0.45, "ordinary damage grace remains 0.45")
    _expect(not player.receive_damage(9) and player.hp == 171, "ordinary grace blocks a repeated ordinary hit")
    player.hurt_clock = 0.11
    _expect(player.receive_damage(1, {"stagger": false, "grant_grace": false}), "flame tick works while ordinary grace exists")
    _expect(player.hp == 170 and player.action == "hurt", "tick removes only 1 HP without replacing current action")
    _close(player.hurt_clock, 0.11, "tick never restarts stagger")

    _reset_player()
    _expect(player.receive_damage(1, {"stagger": true, "grant_grace": false, "stagger_seconds": 0.18}), "first flame tick accepted")
    _close(player.hurt_duration, 0.18, "first flame tick has short 0.18 stagger")
    _close(player.damage_grace, 0.0, "first flame tick grants no grace")
    player._physics_process(0.17)
    player.receive_damage(1, {"stagger": false, "grant_grace": false})
    _close(player.hurt_clock, 0.17, "second tick preserves first short stagger clock")
    player._physics_process(0.02)
    _expect(player.action == "normal" and player.hp == 178, "first flame stagger ends after 0.18 seconds")

    _reset_player()
    player._begin_roll()
    player.roll_clock = 0.04
    _expect(not player.receive_damage(1, {"stagger": false, "grant_grace": false}) and player.hp == 180, "roll invulnerability blocks flame despite no grace")
    player.roll_clock = 0.29
    _expect(player.receive_damage(1, {"stagger": false, "grant_grace": false}) and player.hp == 179, "roll recovery receives flame ticks")

    _reset_player()
    player.receive_damage(3, {"knockback": Vector2(-70, -10)})
    _expect(player.velocity == Vector2(-70, -10), "optional knockback reaches player motion")
    _section_result("normal damage, flame grace, roll immunity, short stagger", failures_before)

func _test_jump_and_land() -> void:
    var failures_before: int = failures
    _reset_player()
    var randomizer: AudioStreamRandomizer = player.sfx_jump.stream as AudioStreamRandomizer
    _expect(randomizer != null and randomizer.get_streams_count() == 3, "jump SFX uses a three-stream AudioStreamRandomizer")
    if randomizer != null:
        for index: int in range(3):
            _expect(randomizer.get_stream(index).resource_path.ends_with("jump_" + ["a", "b", "c"][index] + ".wav"), "jump variant %d uses its generated WAV" % (index + 1))
    player._physics_process(0.01)
    _expect(player.is_on_floor(), "jump scenario starts on physical ground")
    Input.action_press("jump")
    player._physics_process(0.01)
    _expect(player.velocity.y < 0.0 and player.sfx_jump.playing, "grounded jump produces upward motion and starts randomized sound")
    _expect(player.sfx_jump.pitch_scale >= 0.96 and player.sfx_jump.pitch_scale <= 1.04, "jump playback pitch stays in exact 0.96 to 1.04 interval")
    _release_inputs()
    await process_frame
    var frames: int = 0
    while not player.is_on_floor() and frames < 120:
        player._physics_process(1.0 / 60.0)
        frames += 1
        if not player.is_on_floor():
            await process_frame
    _expect(player.is_on_floor() and player.landing_left > 0.0 and player.sfx_land.playing, "actual jump landing sets landing timer and plays land WAV")
    _section_result("jump randomization and physical landing audio", failures_before)

func _test_debug_toggle() -> void:
    var failures_before: int = failures
    _reset_player()
    var enemy: Variant = _new_enemy("melee_beast", Vector2(600, 500))
    await process_frame
    Input.action_press("debug_hitbox")
    player._physics_process(0.001)
    enemy._physics_process(0.001)
    _expect(player.debug_hitboxes and enemy.debug_hitboxes, "same F1 action enables player and enemy debug hitboxes")
    _release_inputs()
    await process_frame
    Input.action_press("debug_hitbox")
    player._physics_process(0.001)
    enemy._physics_process(0.001)
    _expect(not player.debug_hitboxes and not enemy.debug_hitboxes, "second F1 action hides both debug displays")
    _release_inputs()
    enemy.queue_free()
    await process_frame
    _section_result("shared F1 debug toggle", failures_before)

func _test_enemies() -> void:
    var failures_before: int = failures
    _reset_player()
    var melee: Variant = _new_enemy("melee_beast", Vector2(600, 500))
    var ranged: Variant = _new_enemy("ranged_beast", Vector2(1800, 500))
    _expect(melee.collision_layer == 4 and melee.collision_mask == 3 and player.collision_mask == 3, "enemy hurtbox and surface masks match player attack query")
    _expect(melee.hp == 95 and ranged.hp == 63, "JSON stats initialize both beast health pools")
    var deaths: Array[int] = [0]
    melee.died.connect(func(_enemy: Node) -> void: deaths[0] += 1)
    for step: int in range(1, 5):
        melee.take_hit(22 if step == 4 else 20, Vector2(500, 500), step)
    _expect(melee.hp == 13 and melee.state != ENEMY_BASE.State.DEAD, "melee survives four strikes totaling 82")
    melee.take_hit(20, Vector2(500, 500), 1)
    _expect(melee.hp == 0 and melee.state == ENEMY_BASE.State.DEAD and deaths[0] == 1, "fifth strike kills melee and emits died once")
    _expect(melee.collision_layer == 0 and melee.collision_mask == 0, "death immediately removes enemy collision")
    melee.take_hit(20, Vector2(500, 500), 1)
    _expect(deaths[0] == 1, "further hits do not repeat a dead enemy's death signal")
    for step: int in range(1, 4):
        ranged.take_hit(20, Vector2(1700, 500), step)
    _expect(ranged.hp == 3 and ranged.state != ENEMY_BASE.State.DEAD, "ranged remains at 3 HP after three strikes")
    ranged.take_hit(22, Vector2(1700, 500), 4)
    _expect(ranged.hp == 0 and ranged.state == ENEMY_BASE.State.DEAD, "fourth strike kills ranged")

    melee = _new_enemy("melee_beast", Vector2(600, 500))
    melee.take_hit(20, Vector2(500, 500), 1)
    _close(melee.velocity.x, 140.0, "first strike delivers configured knockback")
    _close(melee.stun_left, 0.18, "first strike delivers configured stagger")
    _close(melee.hitstop_left, 0.05, "enemy hitstop lasts 0.05")
    var frozen_position: Vector2 = melee.position
    var frozen_clock: float = melee.state_clock
    var frozen_display: float = melee.display_clock
    melee._physics_process(0.02)
    melee._physics_process(0.02)
    melee._physics_process(0.01)
    _expect(melee.position == frozen_position and melee.state_clock == frozen_clock and melee.display_clock == frozen_display, "hitstop freezes enemy motion and animation for full 0.05")
    melee._physics_process(0.01)
    _expect(melee.state_clock > frozen_clock, "enemy resumes after hitstop")
    _close(melee.velocity.x, 116.0, "stun knockback decays with 2400 friction")
    melee.queue_free()

    melee = _new_enemy("melee_beast", Vector2(600, 500))
    melee.take_shockwave_hit(22, Vector2(500, 500), 4)
    _close(melee.velocity.x, 90.0, "shockwave has separate 90 knockback")
    _close(melee.stun_left, 0.15, "shockwave uses fixed 0.15 stagger")
    melee.queue_free()

    for kind: String in ["melee_beast", "ranged_beast"]:
        _test_turn_and_recovery(kind)
    _test_stun_cap()
    _test_melee_attack()
    _test_flame_ticks()
    _test_flame_interrupts()
    await _test_real_hit_queries()
    _section_result("enemy damage, hitstop, delayed turns, attacks and interrupts", failures_before)

func _new_enemy(kind: String, at: Vector2) -> Variant:
    var script_path: String = "res://scripts/enemy_" + ("melee" if kind == "melee_beast" else "ranged") + "_beast.gd"
    var enemy: Variant = load(script_path).new()
    enemy.enemy_id = kind
    enemy.position = at
    fixture.add_child(enemy)
    enemy.set_physics_process(false)
    return enemy

func _test_turn_and_recovery(kind: String) -> void:
    _reset_player()
    var enemy: Variant = _new_enemy(kind, Vector2(1600, 500))
    player.position = Vector2(1300, 500)
    var delay: float = 0.45 if kind == "melee_beast" else 0.25
    enemy._request_turn(-1)
    enemy._physics_process(0.0)
    _expect(enemy.state == ENEMY_BASE.State.TURN and enemy.current_frame == 0 and enemy.facing == 1, kind + " starts TURN with original first frame")
    enemy._physics_process(delay * 0.25)
    _expect(enemy.current_frame == 1 and enemy.facing == 1 and not enemy.visual.flip_h, kind + " second turn frame keeps original facing")
    enemy._physics_process(delay * 0.249)
    _expect(enemy.current_frame == 1 and enemy.facing == 1, kind + " does not flip just before third frame")
    enemy._physics_process(delay * 0.0011)
    _expect(enemy.current_frame == 2 and enemy.facing == -1 and enemy.visual.flip_h, kind + " flips at beginning of third turn frame")
    enemy._physics_process(delay * 0.25)
    _expect(enemy.current_frame == 3 and enemy.state == ENEMY_BASE.State.TURN, kind + " fourth turn frame remains part of TURN")
    enemy._physics_process(delay * 0.25)
    _expect(enemy.state != ENEMY_BASE.State.TURN, kind + " finishes after full turn delay")

    enemy.facing = 1
    enemy._begin_attack()
    enemy._request_turn(-1)
    _expect(enemy.state == ENEMY_BASE.State.WINDUP and enemy.facing == 1, kind + " windup refuses direction reversal")
    enemy._physics_process(float(enemy.attack_stats["windup"]))
    _expect(enemy.state == ENEMY_BASE.State.ACTIVE and enemy.facing == 1, kind + " completes windup without turning toward rear player")
    enemy._request_turn(-1)
    _expect(enemy.state == ENEMY_BASE.State.ACTIVE and enemy.facing == 1, kind + " active refuses direction reversal")
    enemy._physics_process(float(enemy.attack_stats["active"]))
    _expect(enemy.state == ENEMY_BASE.State.RECOVERY and enemy.facing == 1, kind + " pays attack recovery before turning")
    var recovery: float = float(enemy.attack_stats["recovery"])
    enemy._physics_process(recovery * 0.5)
    enemy._request_turn(-1)
    _expect(enemy.state == ENEMY_BASE.State.RECOVERY and enemy.facing == 1, kind + " recovery refuses direction reversal")
    enemy._physics_process(recovery * 0.5)
    enemy._physics_process(0.001)
    _expect(enemy.state == ENEMY_BASE.State.TURN and enemy.facing == 1, kind + " rear player triggers delayed turn only after recovery")
    enemy.queue_free()

func _test_stun_cap() -> void:
    var enemy: Variant = _new_enemy("melee_beast", Vector2(1600, 500))
    enemy._apply_stun(0.3)
    enemy._physics_process(0.2)
    enemy._apply_stun(0.3)
    enemy._physics_process(0.2)
    enemy._apply_stun(0.3)
    enemy._physics_process(0.2)
    _expect(enemy.state != ENEMY_BASE.State.STUN, "repeated stagger refreshes cannot exceed 0.6 second episode")
    enemy._apply_stun(0.3)
    _expect(enemy.state != ENEMY_BASE.State.STUN, "stun cap allows a brief AI escape before another stagger")
    enemy.queue_free()

func _test_melee_attack() -> void:
    _reset_player()
    var enemy: Variant = _new_enemy("melee_beast", Vector2(600, 500))
    player.position = Vector2(675, 500)
    enemy._begin_attack()
    enemy.take_hit(20, Vector2(500, 500), 1)
    _expect(enemy.state == ENEMY_BASE.State.WINDUP and enemy.hp == 75, "melee windup takes damage while resisting ordinary stagger")
    enemy.hitstop_left = 0.0
    enemy._begin_active()
    enemy.state_clock = 0.02
    enemy._update_active(0.02)
    _expect(player.hp == 171, "headbutt overlap deals 9")
    player.damage_grace = 0.0
    player.action = "normal"
    enemy.state_clock = 0.06
    enemy._update_active(0.04)
    _expect(player.hp == 171, "same headbutt never hits player a second time even without grace")
    enemy.take_hit(20, Vector2(500, 500), 3)
    _expect(enemy.state == ENEMY_BASE.State.STUN, "melee active is interrupted by ordinary stagger")
    enemy.queue_free()

func _test_flame_ticks() -> void:
    _reset_player()
    var enemy: Variant = _new_enemy("ranged_beast", Vector2(600, 500))
    player.position = Vector2(720, 500)
    var hits: Array[int] = [0]
    var count_hit: Callable = func(_amount: int, _remaining_hp: int) -> void: hits[0] += 1
    player.damage_received.connect(count_hit)
    enemy._begin_active()
    _expect(player.hp == 179 and player.action == "hurt", "flame first tick hits and staggers once")
    _close(player.hurt_duration, 0.18, "flame production path selects short first stagger")
    for index: int in range(1, 11):
        player._physics_process(0.09)
        player.position = Vector2(720, 500)
        player.velocity = Vector2.ZERO
        enemy.state_clock = index * 0.09 + 0.000001
        enemy._update_active(0.09)
        if index >= 2:
            _expect(player.action == "normal", "flame tick %d does not repeat stagger" % (index + 1))
    enemy.state_clock = 1.0
    enemy._update_active(0.10)
    _expect(player.hp == 169 and hits[0] == 11 and enemy.flame_tick_count == 11, "full flame cycle deals exactly eleven 1 HP ticks")
    _expect(enemy.state == ENEMY_BASE.State.RECOVERY and enemy.flame_effect == null and enemy.flame_loop_player == null, "flame end stops visuals and loop before recovery")
    player.damage_received.disconnect(count_hit)
    enemy.queue_free()

    _reset_player()
    enemy = _new_enemy("ranged_beast", Vector2(600, 500))
    player.position = Vector2(720, 500)
    player._begin_roll()
    player.roll_clock = 0.04
    enemy._begin_active()
    for index: int in range(1, 11):
        enemy.state_clock = index * 0.09 + 0.000001
        enemy._update_active(0.09)
    _expect(player.hp == 180 and not enemy.flame_has_damaged, "all flame ticks honor player roll invulnerability")
    enemy.queue_free()

func _test_flame_interrupts() -> void:
    for phase: String in ["windup", "active", "shockwave"]:
        _reset_player()
        player.position = Vector2(300, 500)
        var enemy: Variant = _new_enemy("ranged_beast", Vector2(600, 500))
        enemy._begin_attack()
        if phase != "windup":
            enemy._begin_active()
        var old_loop: Variant = enemy.flame_loop_player
        var old_effect: Variant = enemy.flame_effect
        if phase == "shockwave":
            enemy.take_shockwave_hit(22, Vector2(500, 500), 4)
        else:
            enemy.take_hit(20, Vector2(500, 500), 1)
        _expect(enemy.state == ENEMY_BASE.State.STUN and not enemy.get_attack_rect().has_area(), phase + " axe interruption immediately removes flame hitbox")
        _close(enemy.stun_left, 0.4, phase + " interruption staggers for 0.4")
        _close(enemy.attack_cooldown_left, 1.5, phase + " interruption begins 1.5 cooldown")
        _expect(enemy.flame_loop_player == null and enemy.flame_effect == null, phase + " interruption clears flame sound and sprite")
        if old_loop != null:
            _expect(not old_loop.playing and old_loop.is_queued_for_deletion(), phase + " old audio loop has stopped immediately")
        if old_effect != null:
            _expect(not old_effect.visible, phase + " old flame sprite is hidden immediately")
        enemy._physics_process(0.05)
        enemy._physics_process(0.4)
        _expect(enemy.state == ENEMY_BASE.State.RECOVERY and enemy.facing == 1, phase + " interruption preserves recovery before rear turn")
        enemy.queue_free()

func _test_real_hit_queries() -> void:
    _reset_player()
    player.position = Vector2(600, 500)
    var enemy: Variant = _new_enemy("melee_beast", Vector2(670, 500))
    await physics_frame
    await physics_frame
    player._begin_attack(4)
    player._resolve_axe_hit()
    _expect(enemy.hp == 73, "real axe physics query hits enemy layer 4 for fourth strike 22")
    player._resolve_shockwave()
    _expect(enemy.hp == 73 and player.attack_already_hit.size() == 1, "fourth strike direct and shockwave share hit set and never duplicate damage")
    player._resolve_axe_hit()
    _expect(enemy.hp == 73, "repeated active query cannot damage same enemy twice")
    enemy.queue_free()
    await process_frame

    _reset_player()
    player.position = Vector2(600, 500)
    enemy = _new_enemy("melee_beast", Vector2(770, 500))
    await physics_frame
    await physics_frame
    player._begin_attack(4)
    player._resolve_axe_hit()
    _expect(enemy.hp == 95, "enemy beyond direct fourth hitbox remains unharmed")
    player._resolve_shockwave()
    _expect(enemy.hp == 73, "shockwave physics query hits an enemy outside direct hitbox")
    _close(enemy.stun_left, 0.15, "real shockwave query dispatches distinct stagger path")
    enemy.queue_free()
    await process_frame

    _reset_player()
    player.position = Vector2(720, 500)
    enemy = _new_enemy("melee_beast", Vector2(600, 500))
    await physics_frame
    await physics_frame
    var collision: Variant = enemy.move_and_collide(Vector2(200, 0))
    _expect(collision == null and enemy.position.x > player.position.x, "enemy and player physically cross without body collision")
    enemy.queue_free()
    await process_frame

    # The impact point lies ahead of a nearby enemy's center. Knockback must
    # still push away from the attacker, for both facing directions.
    for direction: int in [1, -1]:
        _reset_player()
        player.position = Vector2(900, 500)
        player.facing = direction
        enemy = _new_enemy("melee_beast", Vector2(900 + direction * 50, 500))
        await physics_frame
        await physics_frame
        player._begin_attack(1)
        player._resolve_axe_hit()
        _expect(enemy.hp == 75, "close-range axe physics query connects while facing %d" % direction)
        _expect(enemy.velocity.x * direction > 0.0, "close-range axe knocks enemy away from player while facing %d (velocity=%s)" % [direction, enemy.velocity.x])
        enemy.queue_free()
        await process_frame

func _test_rear_gate() -> void:
    var failures_before: int = failures
    var scene: Variant = load("res://scenes/RearGate.tscn").instantiate()
    root.add_child(scene)
    current_scene = scene
    scene.set_process(false)
    var hero: Variant = scene.get_node("Player")
    hero.set_physics_process(false)
    var enemies: Array = get_nodes_in_group("enemies")
    for enemy: Node in enemies:
        enemy.set_physics_process(false)
    _expect(hero.position == Vector2(260, 880), "rear gate player spawns at x260 on floor")
    _expect(enemies.size() == 5, "rear gate spawns three melee and two ranged beasts")
    var expected_spawn_x: Array[float] = [400.0, 1300.0, 1900.0, 2800.0, 2920.0]
    var actual_spawn_x: Array[float] = []
    for enemy: Variant in enemies:
        actual_spawn_x.append(enemy.position.x)
        _close(enemy.patrol_range, 250.0, "spawn has 250 pixel patrol radius")
        enemy.position.x = 0.0
        enemy._enforce_bounds()
        _expect(enemy.get_hurt_rect().position.x >= 200.0, "enemy bounds keep its entire hurtbox outside rear gate safe zone")
        enemy.position.x = enemy.patrol_center
    actual_spawn_x.sort()
    _expect(actual_spawn_x == expected_spawn_x, "rear gate enemies occupy requested encounters")

    var found_steps: Array[float] = []
    var platforms: int = 0
    for child: Node in scene.get_children():
        if child is StaticBody2D:
            var shape_node: CollisionShape2D = child.get_child(0) as CollisionShape2D
            var size_px: Vector2 = (shape_node.shape as RectangleShape2D).size
            var top_left: Vector2 = child.position - size_px * 0.5
            if shape_node.one_way_collision:
                platforms += 1
                _expect(top_left.y == 700.0 and size_px == Vector2(240, 16) and child.collision_layer == 2, "one-way platform collision aligns y700 top and 16 thickness")
            elif top_left.x == 900.0 or top_left.x == 2400.0:
                found_steps.append(size_px.y)
    found_steps.sort()
    _expect(found_steps == [60.0, 90.0] and platforms == 2, "rear gate has both required step heights and two one-way platforms")
    _expect(hero.camera.limit_left == 0 and hero.camera.limit_right == 3600, "camera uses full 3600 pixel map limits")
    _expect(InputMap.has_action("interact"), "E interaction has an input action for the rear gate prompt")
    hero.position = Vector2(100, 880)
    scene._process(0.01)
    _expect(scene.door_prompt.visible and scene.door_prompt.text == "E", "rear door displays E while player is nearby")
    hero.position = Vector2(500, 880)
    scene._process(0.01)
    _expect(not scene.door_prompt.visible, "rear door prompt hides outside interaction distance")

    var layers: Array[String] = ["Sky", "FarCity", "CastleWall"]
    var ratios: Array[float] = [0.05, 0.2, 0.45]
    var widths: Array[float] = [1536.0, 1920.0, 2560.0]
    for index: int in range(layers.size()):
        var layer: Parallax2D = scene.get_node(layers[index]) as Parallax2D
        _close(layer.scroll_scale.x, ratios[index], layers[index] + " parallax ratio")
        _expect(widths[index] > 1280.0 + 2320.0 * ratios[index], layers[index] + " art is wider than full camera travel requirement")
    _expect(not scene.has_node("Foreground"), "removed foreground layer is absent from rear gate")
    hero.camera.position_smoothing_enabled = false
    hero.position = Vector2(260, 880)
    hero.camera.force_update_scroll()
    await process_frame
    var original_offsets: Array[float] = []
    for name: String in layers:
        original_offsets.append(scene.get_node(name).get_global_transform_with_canvas().origin.x)
    hero.position = Vector2(3340, 880)
    hero.camera.force_update_scroll()
    await process_frame
    for index: int in range(layers.size()):
        var actual: float = scene.get_node(layers[index]).get_global_transform_with_canvas().origin.x - original_offsets[index]
        _expect(absf(actual + 2320.0 * ratios[index]) < 1.0, layers[index] + " actually scrolls according to ratio across map (delta=%s)" % actual)

    hero.position = Vector2(3450, 880)
    await physics_frame
    await physics_frame
    await physics_frame
    await process_frame
    var exit_area: Area2D = scene.get_node("VillaDirectionExit") as Area2D
    _expect(exit_area.get_overlapping_bodies().has(hero), "player physically enters villa direction exit trigger")
    _expect(scene.exit_label.text.contains("별장 방향"), "exit retains villa direction label")

    # Exercise the actual delayed restart, with this scene set as current_scene.
    hero.position = Vector2(260, 880)
    hero._cancel_attack()
    hero.action = "normal"
    hero.hp = 180
    hero.damage_grace = 0.0
    hero.receive_damage(180)
    _expect(hero.action == "dead", "lethal hit enters player death state")
    var old_scene_id: int = scene.get_instance_id()
    hero._physics_process(1.59)
    _expect(current_scene.get_instance_id() == old_scene_id, "death keeps scene until 1.6 second restart delay")
    hero._physics_process(0.02)
    hero = null
    scene = null
    await process_frame
    await process_frame
    _expect(current_scene != null and current_scene.get_instance_id() != old_scene_id, "player death reloads rear gate after 1.6 seconds")
    if current_scene != null:
        var respawn: Variant = current_scene.get_node("Player")
        _expect(respawn.hp == 180 and respawn.position.x == 260.0, "scene restart restores full HP at rear gate spawn")
        current_scene.queue_free()
        current_scene = null
    await process_frame
    _section_result("map physics, actual parallax, prompts, exit and death restart", failures_before)
