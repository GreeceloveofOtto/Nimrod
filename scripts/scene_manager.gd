extends Node

signal level_changed(level_id: String)
signal transition_finished(level_id: String)

var player: NimrodPlayer
var current_level: Node2D
var level_root: Node2D
var main: Node
var is_transitioning: bool = false
var player_locked: bool = false
var levels: Dictionary = {}
var config: Dictionary = {}
var _overlay: CanvasLayer
var _fade_rect: ColorRect
var _fade_tween: Tween
var _reset_on_arrival: bool = false

func _ready() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/transitions.json"))
    if parsed is Dictionary:
        config = parsed
    _load_levels()
    _overlay = CanvasLayer.new()
    _overlay.name = "LevelTransition"
    _overlay.layer = int(config.get("ui", {}).get("fade_canvas_layer", 100))
    add_child(_overlay)
    _fade_rect = ColorRect.new()
    _fade_rect.color = Color.BLACK
    _fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _fade_rect.modulate.a = 0.0
    _overlay.add_child(_fade_rect)

func _load_levels() -> void:
    levels.clear()
    if not FileAccess.file_exists("res://data/levels.json"):
        return
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
    if not (parsed is Dictionary):
        push_error("Invalid level registry")
        return
    for row: Dictionary in parsed.get("levels", []):
        levels[str(row["id"])] = row

func bind_main(value: Node, root: Node2D, actor: NimrodPlayer) -> void:
    main = value
    level_root = root
    player = actor
    current_level = null
    _load_levels()
    set_player_locked(true)
    _fade_rect.modulate.a = 1.0
    _reset_on_arrival = true
    _start_game.call_deferred()

func unbind_main(value: Node) -> void:
    if main != value:
        return
    if _fade_tween != null and _fade_tween.is_valid():
        _fade_tween.kill()
    main = null
    level_root = null
    player = null
    current_level = null
    is_transitioning = false
    player_locked = false
    _fade_rect.modulate.a = 0.0

func _start_game() -> void:
    if not await get_node("/root/Save").resume(false):
        await go_to(str(config["start_level"]), str(config["start_spawn"]))

# A door locks the actor before its opening animation; this is deliberately
# separate from is_transitioning so that its subsequent go_to call is accepted.
func set_player_locked(locked: bool) -> void:
    player_locked = locked
    if is_instance_valid(player):
        player.set_transition_locked(locked)

func show_toast(text: String, seconds: float = -1.0) -> void:
    if is_instance_valid(main):
        var hud := main.get_node_or_null("HUD")
        if hud != null:
            hud.show_toast(text, seconds)

func go_to(level_id: String, spawn_name: String, options: Dictionary = {}) -> bool:
    if is_transitioning or not is_instance_valid(player) or not is_instance_valid(level_root):
        return false
    if not levels.has(level_id):
        push_warning("Unknown level: " + level_id)
        _cancel_entry()
        return false
    var definition: Dictionary = levels[level_id]
    var packed := load(str(definition["scene"])) as PackedScene
    if packed == null:
        push_warning("Level could not be loaded: " + level_id)
        _cancel_entry()
        return false
    get_node("/root/Dialogue").cancel()
    is_transitioning = true
    set_player_locked(true)
    var instant: bool = bool(options.get("instant", false))
    if not instant:
        await _fade_to(1.0, float(config["fade_out_seconds"]))
    if not is_instance_valid(level_root) or not is_instance_valid(player):
        return false
    if is_instance_valid(current_level):
        var sight: Node = player.get_node_or_null("TiamatSight")
        if sight != null:
            player.remove_child(sight)
            sight.queue_free()
        level_root.remove_child(current_level)
        current_level.queue_free()
    current_level = packed.instantiate() as Node2D
    level_root.add_child(current_level)
    var spawn: Marker2D = current_level.get_spawn(spawn_name)
    if spawn == null:
        push_warning("Missing spawn %s in %s" % [spawn_name, level_id])
        spawn = current_level.get_spawn(str(config["start_spawn"]))
    if _reset_on_arrival:
        player.reset_run_state()
        _reset_on_arrival = false
    if spawn != null:
        player.global_position = spawn.global_position
    player.modulate.a = 1.0
    _update_camera(current_level.camera_limits)
    get_node("/root/Audio").play_bgm(str(current_level.bgm_name), 0.0 if instant else float(config["bgm_fade_seconds"]))
    var hud := main.get_node_or_null("HUD")
    if hud != null:
        hud.set_level_name(str(current_level.display_name))
    level_changed.emit(level_id)
    get_node("/root/Ferry").decorate(current_level)
    current_level.reconcile_presence()
    get_node("/root/Odyssey").decorate(current_level)
    var arrival: Node = current_level.find_arrival_door(spawn_name)
    # An arrival door prepares itself before fade-in, then plays its walking
    # and closing sequence while input and incoming damage remain locked.
    if not instant and arrival != null and arrival.has_method("prepare_arrival"):
        arrival.prepare_arrival(player)
    if not instant:
        await _fade_to(0.0, float(config["fade_in_seconds"]))
    elif not bool(options.get("preserve_fade", false)):
        _fade_rect.modulate.a = 0.0
    if not is_instance_valid(player) or not is_instance_valid(current_level):
        return false
    if not instant and is_instance_valid(arrival) and arrival.has_method("play_arrival"):
        await arrival.play_arrival(player)
    player.end_portal_walk()
    player.modulate.a = 1.0
    set_player_locked(get_node("/root/Cutscene").active)
    is_transitioning = false
    show_toast(str(current_level.display_name))
    if level_id == str(config["start_level"]) and spawn_name == str(config["start_spawn"]) and get_node("/root/GameState").first_time("home_intro"):
        if hud != null:
            hud.show_story()
    transition_finished.emit(level_id)
    if not bool(options.get("debug_reload",false)):
        get_node("/root/Chapter").on_arrival.call_deferred(level_id)
    if level_id == "DowntownPassage_F8" and not bool(options.get("debug_reload",false)):
        _passage_soliloquy.call_deferred()
    return true

func restart_run(reset_flags: bool = true) -> void:
    if get_node("/root/Cutscene").active or get_node("/root/Dialogue").active:
        return
    if is_transitioning or not is_instance_valid(player):
        return
    if reset_flags:
        get_node("/root/GameState").reset_run(false)
    _reset_on_arrival = true
    await go_to(str(config["start_level"]), str(config["start_spawn"]))

func full_reset_run() -> void:
    if get_tree().paused or is_transitioning or player_locked or get_node("/root/Cutscene").active or get_node("/root/Dialogue").active:
        if is_instance_valid(player):
            player._restart_requested = false
        return
    if not get_node("/root/Save").erase_save():
        player._restart_requested = false
        show_toast("저장 파일을 지우지 못했다")
        return
    get_node("/root/Ferry").boarding_requested = false
    player.debug_hp_floor = false
    await restart_run()

func _cancel_entry() -> void:
    if is_instance_valid(player):
        player.end_portal_walk()
        player.modulate.a = 1.0
    set_player_locked(false)

func _update_camera(limits: Rect2) -> void:
    player.camera.limit_left = roundi(limits.position.x)
    player.camera.limit_top = roundi(limits.position.y)
    player.camera.limit_right = roundi(limits.end.x)
    player.camera.limit_bottom = roundi(limits.end.y)
    player.camera.reset_smoothing()
    player.camera.force_update_scroll()

func _fade_to(alpha: float, seconds: float) -> void:
    if _fade_tween != null and _fade_tween.is_valid() and _fade_tween.is_running():
        _fade_tween.kill()
    _fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _fade_tween.tween_property(_fade_rect, "modulate:a", alpha, seconds)
    await _fade_tween.finished

func _passage_soliloquy() -> void:
    var dialogue: Node = get_node("/root/Dialogue")
    await get_tree().create_timer(float(dialogue.settings["soliloquy_delay"]), false).timeout
    if is_instance_valid(current_level) and is_instance_valid(player) and str(current_level.level_id) == "DowntownPassage_F8" and not is_transitioning and dialogue.interaction_available("passage_soliloquy"):
        dialogue.play_interaction("passage_soliloquy", {"player": player})

func handle_death() -> void:
    if is_instance_valid(current_level) and current_level.level_id == "HuluppuCrown":
        get_node("/root/Rampage").reset_value()
        player.reset_run_state()
        get_node("/root/Rampage").set_death_suspended(true)
        await go_to("HuluppuCrown","Spawn_Entrance")
        return
    if str(get_node("/root/Save").settings.get("death_respawn", "last_save")) == "last_save" and await get_node("/root/Save").resume(true):
        return
    await restart_run()
