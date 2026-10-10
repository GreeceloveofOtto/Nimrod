class_name RearGateLayout
extends RefCounted

# Compatibility accessor; all tuning and placements now live in levels.json.
static func get_config() -> Dictionary:
    var file := FileAccess.open("res://data/levels.json", FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        for entry in parsed.get("levels", []):
            if str(entry.get("id", "")) == "RearGate":
                return entry
    return {}
