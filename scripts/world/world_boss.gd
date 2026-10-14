extends EnemyBase
# Reuse existing boss textures and numerical patterns without Nimrod story events.
func _init() -> void:set_meta("world_boss",true)
var pattern_index := 0
var battle_started := true
var battle_finished := false
func _on_death() -> void:
    battle_finished=true
    super._on_death()
func _update_chase(delta: float) -> void:
    var hero: Node2D = _target()
    if not _player_is_available(hero):
        _brake(delta)
        return
    var axis: float = hero.position.x-position.x
    var direction := 1 if axis>0 else -1
    if direction!=facing:
        _request_turn(direction)
        return
    if absf(axis)<float(attack_stats.get("range",320)) and attack_cooldown_left<=0:
        _begin_attack()
    else:velocity.x=direction*float(stats.get("move_speed",95))
func _begin_attack() -> void:
    var attacks: Array = stats.attacks
    attack_stats=attacks[pattern_index%attacks.size()]
    pattern_index+=1
    super._begin_attack()
func _active_clip() -> String:
    var id: String = str(attack_stats.get("id",""))
    var phase_name := "idle"
    match state:
        State.CHASE:phase_name="walk"
        State.TURN:phase_name="turn"
        State.WINDUP:phase_name=id+"_windup"
        State.ACTIVE:phase_name=id
        State.RECOVERY:phase_name=id+"_recovery"
        State.STUN:phase_name="idle"
        State.DEAD:phase_name="death"
    var key: String = "windup_clip" if state==State.WINDUP else "active_clip" if state==State.ACTIVE else "recovery_clip"
    if attack_stats.has(key):return str(attack_stats[key])
    if clip_data.has(phase_name):return phase_name
    if enemy_id=="humbaba":
        if state==State.ACTIVE:return "claw_swipe" if id=="claw" else "breath_loop" if id=="breath" else "tail_strike" if id=="tail" else "bite"
    return "idle" if state!=State.DEAD else "death"

func get_attack_rect() -> Rect2:
    if state!=State.ACTIVE:return Rect2()
    if attack_stats.has("hitbox"):return super.get_attack_rect()
    var box: Array = attack_stats.get("box",[260,150])
    var width: float = minf(float(box[0]),600)
    var height: float = minf(float(box[1]),180)
    return Rect2(global_position+Vector2(0 if facing>0 else -width,-height),Vector2(width,height))
func _update_active(delta: float) -> void:
    var hero: Node2D = _target()
    if not attack_has_hit and _player_in_attack(hero):attack_has_hit=hero.receive_damage(int(attack_stats.get("damage",20)))
    super._update_active(delta)
