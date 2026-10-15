extends Node

signal restored
var settings: Dictionary = {}
var save_path: String = "user://save.json"
var indicator: CanvasLayer
var indicator_label: Label
var indicator_tween: Tween
var last_diagnostic: String = ""
var restoring := false

func _ready() -> void:
    settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/save_settings.json"))
    save_path = str(settings["file"])
    indicator=CanvasLayer.new()
    indicator.layer=125
    indicator.process_mode=PROCESS_MODE_ALWAYS
    add_child(indicator)
    indicator_label=Label.new()
    indicator_label.text="저장"
    indicator_label.add_theme_font_override("font",load("res://assets/fonts/NimrodUIKorean-Regular.otf"))
    indicator_label.add_theme_font_size_override("font_size",16)
    var background:=StyleBoxFlat.new()
    background.bg_color=Color(.04,.05,.07,.8)
    background.border_color=Color(.8,.65,.35)
    background.set_border_width_all(1)
    background.content_margin_left=8
    background.content_margin_right=8
    indicator_label.add_theme_stylebox_override("normal",background)
    indicator.add_child(indicator_label)
    indicator_label.modulate.a=0

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
    data["active_character"] = str(data.get("active_character","nimrod"))
    if data["active_character"] not in ["nimrod","siyavash"]:
        return {}
    for field in ["siyavash_progress","nimrod_status"]:
        data[field] = data.get(field,{}) if data.get(field,{}) is Dictionary else {}
    if str(data["siyavash_progress"].get("weapon", "none")) not in ["none", "dagger"]:
        data["siyavash_progress"]["weapon"] = "none"
    data["choice_pending"] = bool(data.get("choice_pending",flags.get("choice_pending",false)))
    data["selected_system"] = str(data.get("selected_system",flags.get("selected_system","")))
    var combined: Dictionary=flags.duplicate(true)
    combined.merge(data["siyavash_progress"],true)
    var stage_value:=0
    for row: Dictionary in get_node("/root/Story").settings["stages"]:
        var complete:=true
        for key in row["flags"]:complete=complete and bool(combined.get(str(key),false))
        if complete:stage_value=int(row["stage"])
    data["story_stage"]=stage_value
    data["version"] = 2
    data["zabulistan"] = data.get("zabulistan",{}) if data.get("zabulistan",{}) is Dictionary else {}
    if not (data.get("deaths_total",0) is int or data.get("deaths_total",0) is float):data["deaths_total"]=0
    data["deaths_total"] = maxi(0,int(data.get("deaths_total",0)))
    for key in ["abilities","life_fragments","opened_doors","defeated_bosses"]:
        if not data["zabulistan"].get(key,{}) is Dictionary:data["zabulistan"][key]={}
    if not data["zabulistan"].get("map_bitmap","") is String:data["zabulistan"]["map_bitmap"]=""
    if not (data["zabulistan"].get("deaths_zabulistan",0) is int or data["zabulistan"].get("deaths_zabulistan",0) is float):data["zabulistan"]["deaths_zabulistan"]=0
    data["facing"] = -1 if int(data.get("facing", 1)) < 0 else 1
    data["hp"] = maxi(1, int(data.get("hp", 180)))
    data["rampage"] = clampi(int(data.get("rampage", data["run_flags"].get("rampage", 0))),0,100)
    if int(data["rampage"]) >= 100:
        data["rampage"] = 60
        data["run_flags"]["rampage"] = 60
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
        if not get_node("/root/World").saving_allowed():return result
        var recovered := FileAccess.open(save_path+".recovery.tmp",FileAccess.WRITE)
        if recovered != null:
            recovered.store_string(JSON.stringify(result))
            recovered.flush()
            recovered.close()
            DirAccess.rename_absolute(save_path+".recovery.tmp",save_path)
    return result

func can_save() -> bool:
    if not get_node("/root/World").saving_allowed():return false
    if get_node("/root/HumbabaForm").engaged():return false
    var manager: Node = get_node("/root/SceneManager")
    return is_instance_valid(manager.player) and is_instance_valid(manager.current_level) and manager.current_level.level_id == "CastleF2" and manager.player.action != "dead" and not manager.is_transitioning and not manager.player_locked and not get_node("/root/Dialogue").active and not get_node("/root/Cutscene").active and not _boss_active()

func _boss_active() -> bool:
    var manager: Node = get_node("/root/SceneManager")
    return is_instance_valid(manager.main) and manager.main.get_node("HUD").boss_panel.visible

func snapshot_data() -> Dictionary:
    var manager: Node = get_node("/root/SceneManager")
    var hero: NimrodPlayer = manager.player
    return {"story_stage":get_node("/root/Story").stage(),"active_character":get_node("/root/GameState").active_character,"siyavash_progress":get_node("/root/GameState").siyavash_progress.duplicate(true),"nimrod_status":get_node("/root/GameState").nimrod_status.duplicate(true),"choice_pending":bool(get_node("/root/GameState").run_flags.get("choice_pending",false)),"selected_system":str(get_node("/root/GameState").run_flags.get("selected_system","")),"version":2,"zabulistan":get_node("/root/World").persistent_data(),"deaths_total":get_node("/root/World").deaths_total,"level":manager.current_level.level_id,"position":[hero.global_position.x,hero.global_position.y],"facing":hero.facing,"hp":hero.hp,"run_flags":get_node("/root/GameState").run_flags.duplicate(true),"rampage":get_node("/root/Rampage").value(),"cooldowns":{"anur_light":0,"devour":0},"timestamp":Time.get_unix_time_from_system()}

func save_game(arrival_checkpoint: bool = false) -> bool:
    if not get_node("/root/World").saving_allowed():return false
    var destination_ok: bool = arrival_checkpoint and get_node("/root/Story").is_flag("tiamat_arrived") and get_node("/root/SceneManager").current_level.level_id == "TiamatZone" and not get_node("/root/Cutscene").active and not get_node("/root/Dialogue").active and not get_node("/root/SceneManager").is_transitioning and not get_node("/root/SceneManager").player_locked
    if not can_save() and not destination_ok:
        return false
    return _write_snapshot(arrival_checkpoint)

func _write_snapshot(quiet: bool) -> bool:
    if not get_node("/root/World").saving_allowed():return false
    if get_node("/root/HumbabaForm").engaged():return false
    var manager: Node = get_node("/root/SceneManager")
    var hero: NimrodPlayer = manager.player
    var data: Dictionary = snapshot_data()
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
    indicator_label.position=get_viewport().get_visible_rect().size-Vector2(82,52)
    indicator_label.modulate.a=1
    if indicator_tween!=null and indicator_tween.is_valid():indicator_tween.kill()
    indicator_tween=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    indicator_tween.tween_interval(.3)
    indicator_tween.tween_property(indicator_label,"modulate:a",0.,.3)
    if not quiet:
        get_node("/root/SceneManager").show_toast("저장되었다",float(settings["toast_seconds"]))
        get_node("/root/Audio").play_sfx("save_chime")
    return true

func erase_save() -> bool:
    for suffix in ["", ".bak", ".tmp", ".recovery.tmp"]:
        var path: String = save_path + str(suffix)
        if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
            return false
    last_diagnostic = ""
    if indicator_tween!=null and indicator_tween.is_valid():indicator_tween.kill()
    indicator_label.modulate.a=0
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
    restoring = true
    get_node("/root/GameState").reset_run(false)
    manager.player.reset_run_state()
    get_node("/root/World").restore_persistent(data["zabulistan"],int(data["deaths_total"]))
    get_node("/root/GameState").active_character = data["active_character"]
    get_node("/root/GameState").siyavash_progress = data["siyavash_progress"].duplicate(true)
    get_node("/root/GameState").nimrod_status = data["nimrod_status"].duplicate(true)
    get_node("/root/GameState").run_flags = data["run_flags"].duplicate(true)
    get_node("/root/GameState").run_flags["choice_pending"] = data["choice_pending"]
    get_node("/root/GameState").run_flags["selected_system"] = data["selected_system"]
    get_node("/root/GameState").run_flags["rampage"] = data["rampage"]
    get_node("/root/GameState").set_weapon(get_node("/root/GameState").get_weapon())
    get_node("/root/Story").changed.emit()
    manager._reset_on_arrival = false
    var spawn_name: String = str(manager.levels[str(data["level"])]["spawns"].keys()[0])
    if not await manager.go_to(str(data["level"]), spawn_name, {"instant":true}):
        restoring = false
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
    manager.current_level.reconcile_presence()
    if bool(data["choice_pending"]):
        manager._fade_rect.modulate.a = 1
        get_node("/root/Choice").open_systems.call_deferred()
    manager.show_toast("이어서 시작")
    restoring = false
    restored.emit()
    return true

func save_checkpoint(reason: String) -> bool:
    if not get_node("/root/World").saving_allowed():return false
    var manager: Node = get_node("/root/SceneManager")
    if not is_instance_valid(manager.current_level) or manager.is_transitioning or get_node("/root/Dialogue").active or get_node("/root/Cutscene").active:
        return false
    var level_id: String = manager.current_level.level_id
    var valid: bool = reason=="choice" and level_id=="TiamatCollapsed" and get_node("/root/Story").is_flag("tiamat_talk_done") and manager._fade_rect.modulate.a>=.99
    valid = valid or (reason=="character" and level_id=="HwaniraPlaza" and get_node("/root/GameState").active_character=="siyavash")
    valid = valid or (reason=="rampage" and level_id=="TiamatZone" and get_node("/root/Story").is_flag("utnapishtim_done"))
    valid = valid or (reason=="victory" and level_id=="TiamatCollapsed" and get_node("/root/Story").is_flag("huluppu_boss_done"))
    return _write_snapshot(true) if valid else false

func persist_death_counters() -> bool:
    # Metadata update retains the saved level, position, inventory and story verbatim.
    if not get_node("/root/World").saving_allowed():return false
    var data: Dictionary=read_save()
    if data.is_empty():return false
    data.deaths_total=get_node("/root/World").deaths_total
    data.zabulistan["deaths_zabulistan"]=get_node("/root/World").deaths_zabulistan
    var file:=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
    if file==null:return false
    file.store_string(JSON.stringify(data))
    file.flush()
    file.close()
    return DirAccess.rename_absolute(save_path+".tmp",save_path)==OK
