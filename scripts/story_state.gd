extends Node

signal changed
var settings: Dictionary = {}

func _ready() -> void:
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/story.json"))
    get_node("/root/GameState").run_reset.connect(func() -> void: changed.emit())

func is_flag(flag: String) -> bool:
    if flag == "night":
        return is_flag("kala_first_defeat") and not is_flag("time_skipped")
    return bool(get_node("/root/GameState").run_flags.get(flag, false))

func set_flag(flag: String, value: bool = true) -> void:
    if flag.is_empty():
        return
    get_node("/root/GameState").run_flags[flag] = value
    if flag == "dilmun_arrived" and value:
        get_node("/root/Rampage").unlock()
    changed.emit()

func matches(condition: Dictionary) -> bool:
    for flag in condition.get("all", []):
        if not is_flag(str(flag)):
            return false
    for flag in condition.get("none", []):
        if is_flag(str(flag)):
            return false
    if condition.has("any"):
        for alternative: Dictionary in condition["any"]:
            if matches(alternative):
                return true
        return false
    return true

func stage() -> int:
    var current := 0
    for entry: Dictionary in settings.get("stages", []):
        if matches({"all": entry["flags"]}):
            current = int(entry["stage"])
    return current

func debug_stage(target: int) -> void:
    target = clampi(target, 0, int(settings["stages"][-1]["stage"]))
    for entry: Dictionary in settings["stages"]:
        for flag in entry["flags"]:
            get_node("/root/GameState").run_flags[str(flag)] = int(entry["stage"]) <= target
    get_node("/root/GameState").run_flags["skill_anur_light"] = target >= 7
    get_node("/root/GameState").run_flags["gugalanna_helm"] = target >= 13
    get_node("/root/GameState").run_flags["melammu"] = target >= 9
    if target >= 18:
        get_node("/root/GameState").run_flags["death_sea_paper"] = false
    get_node("/root/GameState").run_flags.erase("bed_blood")
    if target >= 8:
        get_node("/root/GameState").set_weapon("axe")
    for key in get_node("/root/GameState").run_flags.keys():
        if str(key).begins_with("story_dialogue_"):
            get_node("/root/GameState").run_flags.erase(key)
    get_node("/root/Rampage").reset_value()
    changed.emit()
