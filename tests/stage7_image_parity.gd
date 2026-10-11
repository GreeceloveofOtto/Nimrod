extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/image_mapping.json"))
    _check(not mapping.is_empty(), "Image conversion mapping exists")
    for old_path: String in mapping:
        var replacement: String = str(mapping[old_path])
        _check(replacement.ends_with(".webp"), "Converted images use WebP")
        _check(not FileAccess.file_exists("res://" + old_path), "Original PNG is outside runtime assets")
        var image := Image.new()
        _check(image.load_webp_from_buffer(FileAccess.get_file_as_bytes("res://" + replacement)) == OK, "Native WebP buffer decoding succeeds")
        _check(image != null and not image.is_empty(), "Godot 4.3 decodes converted image")
    var fixtures: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/image_parity_samples.json"))
    _check(fixtures["samples"].size() >= 20, "At least 20 original images have preserved pixel samples")
    for sample: Dictionary in fixtures["samples"]:
        var original_path: String = str(sample["path"])
        var path: String = "res://" + str(mapping.get(original_path.trim_prefix("res://"), original_path.trim_prefix("res://")))
        var image := Image.new()
        var encoded: PackedByteArray = FileAccess.get_file_as_bytes(path)
        var decoded: Error = image.load_webp_from_buffer(encoded) if path.ends_with(".webp") else image.load_png_from_buffer(encoded)
        _check(decoded == OK, "Native image decoder succeeds for preserved pixel sample")
        image.convert(Image.FORMAT_RGBA8)
        _check(image.get_size() == Vector2i(int(sample["size"][0]), int(sample["size"][1])), "Converted dimensions are unchanged")
        for patch: Dictionary in sample["patches"]:
            var values: Array = patch["rect"]
            var actual: PackedByteArray = image.get_region(Rect2i(int(values[0]), int(values[1]), int(values[2]), int(values[3]))).get_data()
            var expected: PackedByteArray = Marshalls.base64_to_raw(str(patch["rgba"]))
            var alpha_same: bool = true
            var difference: float = 0.0
            var channels: int = 0
            for offset in range(0, expected.size(), 4):
                if actual[offset+3] != expected[offset+3]: alpha_same = false
                if expected[offset+3] > 0:
                    for channel in range(3):
                        difference += abs(int(actual[offset+channel])-int(expected[offset+channel]))
                        channels += 1
            _check(alpha_same, "Original alpha pixels are identical: " + path)
            _check(channels == 0 or difference / channels <= 2.0, "Mean visible RGB error <= 2/255: " + path)
    print("STAGE7_IMAGE_PARITY: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
