extends Node

signal restored
var settings: Dictionary = {}
var save_path: String = "user://save.json"
var last_diagnostic: String = ""

func _ready() -> void:
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/save_settings.json"))
    save_path = str(settings["file"])

func migrate_save(input: Dictionary) -> Dictionary:
    var data: Dictionary = input.duplicate(true)
    if not data.has("level") or not data.has("position") or not data.get("run_flags") is Dictionary:
        return {}
    var manager: Node = get_node("/root/SceneManager")
    if not manager.levels.has(str(data["level"])) or not data["position"] is Array or data["position"].size() != 2:
        return {}
    for coordinate in data["position"]:
        if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)):
            return {}
    var flags: Dictionary = data["run_flags"]
    if flags.get("prosthetic_equipped",false) or flags.get("gugalanna_helm",false):
        flags["helmet_equipped"] = true
    if flags.get("dilmun_arrived",false):
        flags["rampage_unlocked"] = true
    if str(flags.get("weapon","none")) not in ["none","staff","axe"]:
        flags["weapon"] = "none"
    for field in ["hp","facing","version","rampage"]:
        if data.has(field) and not (data[field] is float or data[field] is int):
            return {}
    if not (data.get("rampage",flags.get("rampage",0)) is float or data.get("rampage",flags.get("rampage",0)) is int):
        return {}
    data["version"] = 1
    data["facing"] = -1 if int(data.get("facing", 1)) < 0 else 1
    data["hp"] = maxi(1, int(data.get("hp", 180)))
    data["rampage"] = clampi(int(data.get("rampage", data["run_flags"].get("rampage", 0))),0,100)
    data["cooldowns"] = {"anur_light":0.0,"devour":0.0}
    return data

func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(path)) != OK:
        return {}
    var parsed: Variant = parser.data
    return migrate_save(parsed) if parsed is Dictionary else {}

func read_save() -> Dictionary:
    var result: Dictionary = _read(save_path)
    if not result.is_empty():
        return result
    if FileAccess.file_exists(save_path):
        last_diagnostic = "SAVE 경고 — 손상된 저장 파일"
        print(last_diagnostic)
    result = _read(save_path + ".bak")
    if not result.is_empty():
        last_diagnostic = "SAVE RECOVERY — 백업에서 복구"
        print(last_diagnostic)
        var recovered := FileAccess.open(save_path+".recovery.tmp",FileAccess.WRITE)
        if recovered != null:
            recovered.store_string(JSON.stringify(result))
            recovered.flush()
            recovered.close()
            DirAccess.rename_absolute(save_path+".recovery.tmp",save_path)
    return result

func can_save() -> bool:
    var manager: Node = get_node("/root/SceneManager")
    return is_instance_valid(manager.player) and is_instance_valid(manager.current_level) and manager.current_level.level_id == "CastleF2" and manager.player.action != "dead" and not manager.is_transitioning and not manager.player_locked and not get_node("/root/Dialogue").active and not get_node("/root/Cutscene").active and not _boss_active()

func _boss_active() -> bool:
    var manager: Node = get_node("/root/SceneManager")
    return is_instance_valid(manager.main) and manager.main.get_node("HUD").boss_panel.visible

func save_game() -> bool:
    if not can_save():
        return false
    var manager: Node = get_node("/root/SceneManager")
    var hero: NimrodPlayer = manager.player
    var data: Dictionary = {"version":1,"level":manager.current_level.level_id,"position":[hero.global_position.x,hero.global_position.y],"facing":hero.facing,"hp":hero.hp,"run_flags":get_node("/root/GameState").run_flags.duplicate(true),"rampage":get_node("/root/Rampage").value(),"cooldowns":{"anur_light":0,"devour":0},"timestamp":Time.get_unix_time_from_system()}
    var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
    if file == null:
        return _failed()
    file.store_string(JSON.stringify(data))
    file.flush()
    file.close()
    var directory := DirAccess.open(save_path.get_base_dir())
    if directory == null:
        return _failed()
    if not _read(save_path).is_empty() and directory.copy(save_path,save_path + ".bak") != OK:
        return _failed()
    if directory.rename(save_path + ".tmp", save_path) != OK:
        return _failed()
    hero.skill_cooldown_left = 0
    hero.devour_cooldown_left = 0
    get_node("/root/SceneManager").show_toast("저장되었다",float(settings["toast_seconds"]))
    get_node("/root/Audio").play_sfx("save_chime")
    return true

func _failed() -> bool:
    last_diagnostic = "SAVE ERROR — 저장하지 못했다"
    print(last_diagnostic)
    get_node("/root/SceneManager").show_toast("저장하지 못했다")
    return false

func resume(full_health: bool = false) -> bool:
    var data: Dictionary = read_save()
    if data.is_empty():
        return false
    var manager: Node = get_node("/root/SceneManager")
    get_node("/root/GameState").reset_run(false)
    manager.player.reset_run_state()
    get_node("/root/GameState").run_flags = data["run_flags"].duplicate(true)
    get_node("/root/GameState").run_flags["rampage"] = data["rampage"]
    get_node("/root/GameState").set_weapon(str(data["run_flags"].get("weapon","none")))
    get_node("/root/Story").changed.emit()
    manager._reset_on_arrival = false
    var spawn_name: String = str(manager.levels[str(data["level"])]["spawns"].keys()[0])
    if not await manager.go_to(str(data["level"]), spawn_name, {"instant":true}):
        return false
    manager.player.global_position = Vector2(float(data["position"][0]),float(data["position"][1]))
    manager.player.camera.reset_smoothing()
    manager.player.camera.force_update_scroll()
    manager.player.facing = int(data["facing"])
    manager.player._show_clip(manager.player.displayed_clip,manager.player.display_clock)
    manager.player.hp = manager.player.get_max_hp() if full_health else clampi(int(data["hp"]),1,manager.player.get_max_hp())
    manager.player.skill_cooldown_left = 0
    manager.player.devour_cooldown_left = 0
    manager.player._show_clip("idle",0)
    get_node("/root/Rampage")._update_heartbeat()
    manager.show_toast("이어서 시작")
    restored.emit()
    return true
