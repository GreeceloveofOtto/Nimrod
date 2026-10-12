class_name PlayerModifiers
extends RefCounted

var modifiers: Dictionary = {}
var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/player_modifiers.json"))

func add_modifier(id: String, values: Dictionary) -> void:
    modifiers[id] = values.duplicate(true)

func total(key: String) -> float:
    var result := 0.0
    for modifier in modifiers.values():
        result += float(modifier.get(key, 0.0))
    return result

func clear() -> void:
    modifiers.clear()

func multiplier(key: String) -> float:
    var result: float = 1.0
    for modifier in modifiers.values():
        result += float(modifier.get(key, 0.0))
    if key == "attack_speed":
        result = minf(result, float(settings["attack_speed_cap"]))
    return maxf(0.0, result)
