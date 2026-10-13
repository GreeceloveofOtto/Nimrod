extends Node

signal changed
var settings: Dictionary = {}
var death_suspended: bool = false
var death_queued: bool = false
var heartbeat: AudioStreamPlayer
var counted_kills: Dictionary = {}

func _ready() -> void:
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/rampage.json"))
    get_node("/root/GameState").run_reset.connect(reset_value)

func value() -> int:
    return clampi(int(get_node("/root/GameState").run_flags.get("rampage", 0)), 0, int(settings["max"]))

func unlocked() -> bool:
    return get_node("/root/GameState").active_character == "nimrod" and bool(get_node("/root/GameState").run_flags.get("rampage_unlocked", false))

func unlock() -> void:
    var flags: Dictionary = get_node("/root/GameState").run_flags
    if not unlocked():
        flags["rampage_unlocked"] = true
        flags["rampage"] = 0
        get_node("/root/SceneManager").show_toast("포식을 얻었다 (L)")
        changed.emit()

func reset_value() -> void:
    get_node("/root/GameState").run_flags["rampage"] = 0
    death_suspended = false
    death_queued = false
    counted_kills.clear()
    _update_heartbeat()
    changed.emit()

func tier() -> int:
    var result := 0
    if unlocked():
        for row: Dictionary in settings["tiers"]:
            if value() > int(row["over"]):
                result += 1
    return result

func tier_data() -> Dictionary:
    return settings["tiers"][tier() - 1] if tier() > 0 else {"damage":1.0,"reach":1.0,"set":"axe_prosthetic_helm"}

func sprite_set() -> String:
    return str(tier_data()["set"])

func damage_multiplier() -> float:
    return float(tier_data()["damage"]) if unlocked() else 1.0

func reach_multiplier() -> float:
    return float(tier_data()["reach"]) if unlocked() else 1.0

func set_value(amount: int) -> void:
    var before: int = tier()
    get_node("/root/GameState").run_flags["rampage"] = clampi(amount, 0, int(settings["max"]))
    changed.emit()
    get_node("/root/Story").changed.emit()
    var hero: NimrodPlayer = get_tree().get_first_node_in_group("player") as NimrodPlayer
    if hero != null and before != tier() and get_node("/root/Story").is_flag("prosthetic_equipped"):
        hero.rampage_flash_left = float(settings["tier_flash_seconds"])
    _update_heartbeat()
    if unlocked() and not death_suspended and (value() >= int(settings["death_at_max"]) or value() > int(settings["death_threshold"])):
        if hero != null and not death_queued:
            death_queued = true
            get_node("/root/SceneManager").show_toast("폭주를 이기지 못했다")
            hero.force_rampage_death()

func add(amount: int) -> void:
    set_value(value() + amount)

func set_death_suspended(enabled: bool) -> void:
    death_suspended = enabled
    set_value(value())

func basic_kill(enemy: EnemyBase) -> void:
    if not unlocked() or value() < int(settings["kill_threshold"]) or not is_instance_valid(enemy):
        return
    var id: int = enemy.get_instance_id()
    if counted_kills.has(id):
        return
    counted_kills[id] = true
    add(1)

func cure(hero: NimrodPlayer) -> bool:
    if not unlocked() or hero == null:
        return false
    var cost: Dictionary = settings["cure"]["cost"]
    if str(cost["type"]) != "hp" or hero.hp <= int(cost["amount"]):
        get_node("/root/SceneManager").show_toast("대가를 치를 수 없다")
        return false
    hero.hp -= int(cost["amount"])
    add(-int(settings["cure"]["amount"]))
    hero.damage_received.emit(0, hero.hp)
    get_node("/root/SceneManager").show_toast("폭주가 가라앉았다 (-11)")
    get_node("/root/Audio").play_sfx("rampage_cure")
    return true

func _update_heartbeat() -> void:
    if value() > 90 and unlocked():
        if not is_instance_valid(heartbeat):
            heartbeat = get_node("/root/Audio").play_sfx("rampage_heartbeat_loop") as AudioStreamPlayer
        if is_instance_valid(heartbeat):
            heartbeat.pitch_scale = lerpf(1.0, 1.4, float(value() - 91) / 9.0)
    elif is_instance_valid(heartbeat):
        get_node("/root/Audio").stop_sfx(heartbeat)
        heartbeat = null
