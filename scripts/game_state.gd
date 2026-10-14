extends Node

signal run_reset
signal weapon_changed(weapon: String)

var active_character: String = "nimrod"
var siyavash_progress: Dictionary = {}
var nimrod_status: Dictionary = {}
var siyavash_settings: Dictionary = {}

func _ready() -> void:
    siyavash_settings=JSON.parse_string(FileAccess.get_file_as_string("res://data/siyavash.json"))

var run_flags: Dictionary = {"weapon": "none"}

func first_time(key: String) -> bool:
    if run_flags.has(key):
        return false
    run_flags[key] = true
    return true

func reset_run(restart_world: bool = true) -> void:
    active_character = "nimrod"
    siyavash_progress.clear()
    nimrod_status.clear()
    run_flags.clear()
    set_weapon("none")
    run_reset.emit()
    if restart_world:
        var manager: Node = get_node_or_null("/root/SceneManager")
        if manager != null and is_instance_valid(manager.player):
            await manager.restart_run(false)

func get_weapon() -> String:
    return str(siyavash_progress.get("weapon",siyavash_settings.get("weapon","none"))) if active_character == "siyavash" else str(run_flags.get("weapon", "none"))

func set_weapon(value: String) -> void:
    if active_character == "siyavash":
        if value not in ["none", "dagger"]:
            return
        siyavash_progress["weapon"] = value
        weapon_changed.emit(value)
        return
    if value not in ["none", "staff", "axe"]:
        return
    if bool(run_flags.get("arm_lost", false)):
        value = "axe"
    run_flags["weapon"] = value
    weapon_changed.emit(value)

func visit_count(key: String, increment: bool = false) -> int:
    var flag: String = "visits_" + key
    if increment:
        run_flags[flag] = int(run_flags.get(flag, 0)) + 1
    return int(run_flags.get(flag, 0))

func switch_character(id: String) -> void:
    if id not in ["nimrod","siyavash"] or id==active_character:
        return
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    if active_character=="nimrod" and is_instance_valid(hero):
        nimrod_status={"hp":hero.hp,"weapon":run_flags.get("weapon","none"),"level":get_node("/root/SceneManager").current_level.level_id,"position":[hero.position.x,hero.position.y],"facing":hero.facing,"rampage":get_node("/root/Rampage").value()}
    if active_character=="siyavash" and is_instance_valid(hero):
        siyavash_progress.merge({"hp":hero.hp,"level":get_node("/root/SceneManager").current_level.level_id,"position":[hero.position.x,hero.position.y],"facing":hero.facing},true)
    active_character=id
    weapon_changed.emit(get_weapon())
    if is_instance_valid(hero):hero.reset_run_state()
    get_node("/root/Story").changed.emit()
    if is_instance_valid(hero):
        hero.hp=clampi(int(siyavash_progress.get("hp",hero.get_max_hp())) if id=="siyavash" else int(nimrod_status.get("hp",hero.get_max_hp())),1,hero.get_max_hp())
