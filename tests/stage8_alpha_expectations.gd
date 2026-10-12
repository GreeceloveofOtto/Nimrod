extends "res://tests/helpers/stage4_support.gd"
func _run() -> void:
    var specs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/alpha_expectations.json"))
    _check(specs.size() >= 400,"Every runtime image is classified")
    for path: String in specs:
        _check(FileAccess.file_exists("res://"+path),"Classified image exists: "+path)
        _check(specs[path].mode in ["opaque","transparent"],"Explicit alpha mode")
    print("STAGE8_ALPHA_EXPECTATIONS: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)
