extends Node

# Replace a source file at the same path to upgrade the temporary synthesized audio.
const SFX_TABLE: Dictionary = {
    "jump_a": "res://assets/audio/jump_a.wav",
    "jump_b": "res://assets/audio/jump_b.wav",
    "jump_c": "res://assets/audio/jump_c.wav",
    "land": "res://assets/audio/land.wav",
    "roll": "res://assets/audio/roll.wav",
    "step": "res://assets/audio/step.wav",
    "axe_hit_flesh": "res://assets/audio/sfx/axe_hit_flesh.wav",
    "axe_hit_heavy": "res://assets/audio/sfx/axe_hit_heavy.wav",
    "shockwave": "res://assets/audio/sfx/shockwave.wav",
    "beast_melee_windup": "res://assets/audio/sfx/beast_melee_windup.wav",
    "beast_melee_attack": "res://assets/audio/sfx/beast_melee_attack.wav",
    "beast_melee_hurt": "res://assets/audio/sfx/beast_melee_hurt.wav",
    "beast_melee_death": "res://assets/audio/sfx/beast_melee_death.wav",
    "beast_ranged_windup": "res://assets/audio/sfx/beast_ranged_windup.wav",
    "beast_ranged_flame_start": "res://assets/audio/sfx/beast_ranged_flame_start.wav",
    "beast_ranged_flame_loop": "res://assets/audio/sfx/beast_ranged_flame_loop.wav",
    "beast_ranged_hurt": "res://assets/audio/sfx/beast_ranged_hurt.wav",
    "beast_ranged_death": "res://assets/audio/sfx/beast_ranged_death.wav",
    "player_hurt": "res://assets/audio/sfx/player_hurt.wav",
    "door_open": "res://assets/audio/sfx/door_open.wav",
    "door_close": "res://assets/audio/sfx/door_close.wav",
    "door_locked": "res://assets/audio/sfx/door_locked.wav",
    "portal_whoosh": "res://assets/audio/sfx/portal_whoosh.wav",
    "sky_beast_wingflap_loop": "res://assets/audio/sfx/sky_beast_wingflap_loop.wav",
    "sky_beast_windup_screech": "res://assets/audio/sfx/sky_beast_windup_screech.wav",
    "sky_beast_dive_whoosh": "res://assets/audio/sfx/sky_beast_dive_whoosh.wav",
    "sky_beast_hurt": "res://assets/audio/sfx/sky_beast_hurt.wav",
    "sky_beast_death": "res://assets/audio/sfx/sky_beast_death.wav",
    "great_gate_open": "res://assets/audio/sfx/great_gate_open.wav",
    "great_gate_close": "res://assets/audio/sfx/great_gate_close.wav"
}
const BGM_TABLE: Dictionary = {
    "uruk_rear_gate": "res://assets/audio/bgm/uruk_rear_gate.wav",
    "castle_hall": "res://assets/audio/bgm/castle_hall.wav",
    "uruk_sky": "res://assets/audio/bgm/uruk_sky.wav",
    "villa_calm": "res://assets/audio/bgm/villa_calm.wav",
    "castle_front": "res://assets/audio/bgm/castle_front.wav"
}
const LOOP_SFX: Array[String] = ["beast_ranged_flame_loop", "sky_beast_wingflap_loop"]
const SILENT_DB: float = -60.0

var _streams: Dictionary = {}
var _bgm: AudioStreamPlayer
var _bgm_name: String = ""
var _bgm_tween: Tween

func _ready() -> void:
    _bgm = AudioStreamPlayer.new()
    _bgm.name = "BackgroundMusic"
    _bgm.bus = &"BGM"
    add_child(_bgm)

func _exit_tree() -> void:
    _cancel_bgm_tween()
    _bgm_tween = null
    for child in get_children():
        if child is AudioStreamPlayer:
            var player: AudioStreamPlayer = child as AudioStreamPlayer
            player.stop()
            player.stream = null
        elif child is AudioStreamPlayer2D:
            var spatial: AudioStreamPlayer2D = child as AudioStreamPlayer2D
            spatial.stop()
            spatial.stream = null
    _streams.clear()
    _bgm_name = ""
    _bgm = null

func _load_stream(path: String, looping: bool) -> AudioStream:
    var cache_key: String = path + (":loop" if looping else ":once")
    if _streams.has(cache_key):
        return _streams[cache_key] as AudioStream
    if not ResourceLoader.exists(path):
        push_warning("Audio file missing: " + path)
        return null
    var source: AudioStream = load(path) as AudioStream
    if source == null:
        push_warning("Audio file could not be loaded: " + path)
        return null
    var stream: AudioStream = source.duplicate() as AudioStream
    if stream is AudioStreamWAV:
        var wav: AudioStreamWAV = stream as AudioStreamWAV
        wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
        wav.loop_begin = 0
        wav.loop_end = roundi(wav.get_length() * wav.mix_rate)
    elif stream is AudioStreamOggVorbis:
        (stream as AudioStreamOggVorbis).loop = looping
    _streams[cache_key] = stream
    return stream

# Returns a stoppable handle for sustained sounds such as the ranged beast's flame.
func play_sfx(name: String, position: Variant = null, pitch_jitter: float = 0.04) -> Node:
    if not SFX_TABLE.has(name):
        push_warning("Unknown SFX: " + name)
        return null
    var looping: bool = LOOP_SFX.has(name)
    var stream: AudioStream = _load_stream(str(SFX_TABLE[name]), looping)
    if stream == null:
        return null
    var pitch: float = randf_range(1.0 - absf(pitch_jitter), 1.0 + absf(pitch_jitter))
    if position is Vector2:
        var spatial: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
        spatial.stream = stream
        spatial.bus = &"SFX"
        spatial.pitch_scale = maxf(0.01, pitch)
        spatial.max_distance = 1100.0
        add_child(spatial)
        spatial.global_position = position
        if not looping:
            spatial.finished.connect(spatial.queue_free)
        spatial.play()
        return spatial
    var player: AudioStreamPlayer = AudioStreamPlayer.new()
    player.stream = stream
    player.bus = &"SFX"
    player.pitch_scale = maxf(0.01, pitch)
    add_child(player)
    if not looping:
        player.finished.connect(player.queue_free)
    player.play()
    return player

func stop_sfx(handle: Node) -> void:
    if not is_instance_valid(handle):
        return
    if handle.has_method("stop"):
        handle.call("stop")
    handle.queue_free()

func play_bgm(name: String, fade: float = 1.0) -> void:
    if not BGM_TABLE.has(name):
        push_warning("Unknown BGM: " + name)
        return
    if _bgm.playing and _bgm_name == name:
        return
    var stream: AudioStream = _load_stream(str(BGM_TABLE[name]), true)
    if stream == null:
        return
    _cancel_bgm_tween()
    _bgm.stream = stream
    _bgm_name = name
    _bgm.volume_db = SILENT_DB if fade > 0.0 else 0.0
    _bgm.play()
    if fade > 0.0:
        _bgm_tween = create_tween()
        _bgm_tween.tween_property(_bgm, "volume_db", 0.0, fade)

func stop_bgm(fade: float = 1.0) -> void:
    _cancel_bgm_tween()
    if not _bgm.playing:
        return
    if fade <= 0.0:
        _bgm.stop()
        _bgm_name = ""
        return
    _bgm_tween = create_tween()
    _bgm_tween.tween_property(_bgm, "volume_db", SILENT_DB, fade)
    _bgm_tween.tween_callback(_finish_bgm_stop)

func _cancel_bgm_tween() -> void:
    if _bgm_tween != null and _bgm_tween.is_valid():
        _bgm_tween.kill()

func _finish_bgm_stop() -> void:
    _bgm.stop()
    _bgm_name = ""
