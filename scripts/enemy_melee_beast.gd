extends EnemyBase

func _update_chase(delta: float) -> void:
    var player: Node2D = _target()
    if not _can_detect(player):
        _brake(delta)
        _set_state(State.IDLE)
        return
    var difference: float = player.global_position.x - global_position.x
    var direction: int = 1 if difference >= 0.0 else -1
    if direction != facing:
        _request_turn(direction)
        _brake(delta)
        return
    if absf(difference) <= float(attack_stats.get("range", 0.0)):
        velocity.x = 0.0
        _begin_attack()
    else:
        velocity.x = facing * float(stats.get("move_speed", 0.0))

func _begin_active() -> void:
    super._begin_active()
    _play_sfx("beast_melee_attack")

func _update_active(_delta: float) -> void:
    velocity.x = facing * float(attack_stats.get("lunge_speed", 0.0))
    var player: Node2D = _target()
    if not attack_has_hit and _player_in_attack(player):
        var accepted: bool = bool(player.call("receive_damage", int(attack_stats.get("damage", 0))))
        if accepted:
            attack_has_hit = true
    if state_clock >= float(attack_stats.get("active", 0.0)):
        velocity.x = 0.0
        _finish_active()

func _on_hit(seconds: float) -> void:
    if state == State.WINDUP and bool(attack_stats.get("windup_stun_immune", true)):
        return
    _apply_stun(seconds)
