extends SceneTree

# Mirrors ProjectDialog's native ZIP extraction: only directory entries create folders.
func _initialize() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    if args.size() != 2:
        push_error("Usage: --script tools/check_zip_import.gd -- ZIP DESTINATION")
        quit(1)
        return
    var archive := ZIPReader.new()
    if archive.open(args[0]) != OK:
        push_error("Cannot open ZIP")
        quit(1)
        return
    var files: PackedStringArray = archive.get_files()
    var root := ""
    for entry in files:
        if entry.get_file() == "project.godot":
            root = entry.get_base_dir()
            break
    DirAccess.make_dir_recursive_absolute(args[1])
    var failed: Array[String] = []
    var written := 0
    for entry in files:
        var relative: String = entry.trim_prefix(root).trim_prefix("/")
        if relative.is_empty():
            continue
        var destination: String = args[1].path_join(relative)
        if entry.ends_with("/"):
            DirAccess.make_dir_absolute(destination)
        else:
            var output := FileAccess.open(destination, FileAccess.WRITE)
            if output == null:
                failed.append(relative)
            else:
                output.store_buffer(archive.read_file(entry))
                output.close()
                written += 1
    archive.close()
    print("GODOT_ZIP_IMPORT: ", written, " files; ", failed.size(), " failures")
    if not failed.is_empty():
        push_error(str(failed))
    quit(0 if failed.is_empty() else 1)
