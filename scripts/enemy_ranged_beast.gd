extends EnemyBase

const FLAME_PATH: String = "res://assets/sprites/enemies/ranged_beast/flame.png"
const FLAME_FRAME_SIZE: Vector2i = Vector2i(512, 256)
const FLAME_FRAMES: int = 6
const FLAME_ANCHOR: Vector2 = Vector2(16.0, 128.0)

var flame_tick_count: int = 0
var flame_next_tick: float = 0.0
var flame_has_damaged: bool = false
var flame_effect: Node2D
var flame_loop_player: Node

func _init() -> void:
    enemy_id = "ranged_beast"

func _update_chase(delta: float) -> void:
    var player: Node2D = _target()
    if not _can_detect(player):
        _brake(delta)
        _set_state(State.IDLE)
        return
    var difference: float = player.global_position.x - global_position.x
    var distance: float = absf(difference)
    var direction: int = 1 if difference >= 0.0 else -1
    if direction != facing:
        _request_turn(direction)
        _brake(delta)
        return
    if distance <= float(attack_stats.get("range", 0.0)) and attack_cooldown_left <= 0.0:
        velocity.x = 0.0
        _begin_attack()
        return
    var preferred: Array = stats.get("preferred_distance", [0.0, 0.0])
    if distance < float(preferred[0]):
        velocity.x = -facing * float(stats.get("move_speed", 0.0))
    elif distance > float(preferred[1]):
        velocity.x = facing * float(stats.get("move_speed", 0.0))
    else:
        _brake(delta)

func _begin_active() -> void:
    super._begin_active()
    flame_tick_count = 0
    flame_next_tick = 0.0
    flame_has_damaged = false
    _play_sfx("beast_ranged_flame_start")
    flame_loop_player = _play_sfx("beast_ranged_flame_loop")
    flame_effect = IMAGE_EFFECT.new()
    flame_effect.configure(FLAME_PATH, FLAME_FRAME_SIZE, FLAME_FRAMES, float(attack_stats.get("flame_animation_seconds", 0.36)), true, FLAME_ANCHOR)
    var box: Dictionary = attack_stats.get("hitbox", {})
    var width: float = float(box.get("width", 0.0))
    var height: float = float(box.get("height", 0.0))
    var art_size: Array = attack_stats.get("flame_art_size", [FLAME_FRAME_SIZE.x, FLAME_FRAME_SIZE.y])
    flame_effect.scale = Vector2(facing * width / float(art_size[0]), height / float(art_size[1]))
    flame_effect.position = Vector2(facing * float(box.get("offset_x", 0.0)), float(box.get("top", 0.0)) + height * 0.5)
    flame_effect.z_index = 3
    add_child(flame_effect)
    _attempt_flame_tick()

func _active_clip() -> String:
    return "flame_loop"

func _update_active(delta: float) -> void:
    _brake(delta)
    var limit: int = int(attack_stats.get("tick_count", 11))
    # Eleven opportunities at 0.00, 0.09, ..., 0.90; never a twelfth tick.
    while flame_tick_count < limit and state_clock >= flame_next_tick:
        _attempt_flame_tick()
    if state_clock >= float(attack_stats.get("active", 0.0)):
        _finish_active()

func _attempt_flame_tick() -> void:
    flame_tick_count += 1
    flame_next_tick = flame_tick_count * float(attack_stats.get("tick_interval", 0.09))
    var player: Node2D = _target()
    if not _player_in_attack(player):
        return
    var first_stagger: bool = not flame_has_damaged and bool(attack_stats.get("first_tick_stagger", true))
    var opts: Dictionary = {
        "stagger": first_stagger,
        "grant_grace": false,
        "stagger_seconds": float(attack_stats.get("first_tick_stagger_seconds", 0.18))
    }
    var accepted: bool = bool(player.call("receive_damage", int(attack_stats.get("damage", 1)), opts))
    if accepted:
        flame_has_damaged = true

func _finish_active() -> void:
    _stop_flame()
    attack_cooldown_left = float(attack_stats.get("cooldown", 1.5))
    super._finish_active()

func _on_hit(seconds: float) -> void:
    if state in [State.WINDUP, State.ACTIVE]:
        _stop_flame()
        attack_cooldown_left = float(attack_stats.get("cooldown", 1.5))
        _apply_stun(float(attack_stats.get("interrupt_stun", 0.4)), true)
    else:
        _apply_stun(seconds)

func _on_death() -> void:
    _stop_flame()
    super._on_death()

func _exit_tree() -> void:
    _stop_flame()

func _stop_flame() -> void:
    if is_instance_valid(flame_effect):
        flame_effect.visible = false
        flame_effect.queue_free()
    flame_effect = null
    if is_instance_valid(flame_loop_player):
        flame_loop_player.call("stop")
        flame_loop_player.queue_free()
    flame_loop_player = null
