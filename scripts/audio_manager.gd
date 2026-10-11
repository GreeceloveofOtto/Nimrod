extends Node

# Replace a source file at the same path to upgrade the temporary synthesized audio.
const SFX_TABLE: Dictionary = {
    "cedar_sentinel_windup": "res://assets/audio/sfx/cedar_sentinel_windup.wav",
    "cedar_sentinel_attack": "res://assets/audio/sfx/cedar_sentinel_attack.wav",
    "cedar_sentinel_hurt": "res://assets/audio/sfx/cedar_sentinel_hurt.wav",
    "cedar_sentinel_death": "res://assets/audio/sfx/cedar_sentinel_death.wav",
    "cedar_colossus_windup": "res://assets/audio/sfx/cedar_colossus_windup.wav",
    "cedar_colossus_attack": "res://assets/audio/sfx/cedar_colossus_attack.wav",
    "cedar_colossus_hurt": "res://assets/audio/sfx/cedar_colossus_hurt.wav",
    "cedar_colossus_death": "res://assets/audio/sfx/cedar_colossus_death.wav",
    "cedar_archer_windup": "res://assets/audio/sfx/cedar_archer_windup.wav",
    "cedar_archer_attack": "res://assets/audio/sfx/cedar_archer_attack.wav",
    "cedar_archer_hurt": "res://assets/audio/sfx/cedar_archer_hurt.wav",
    "cedar_archer_death": "res://assets/audio/sfx/cedar_archer_death.wav",
    "cedar_wisp_windup": "res://assets/audio/sfx/cedar_wisp_windup.wav",
    "cedar_wisp_attack": "res://assets/audio/sfx/cedar_wisp_attack.wav",
    "cedar_wisp_hurt": "res://assets/audio/sfx/cedar_wisp_hurt.wav",
    "cedar_wisp_death": "res://assets/audio/sfx/cedar_wisp_death.wav",
    "cedar_demon_windup": "res://assets/audio/sfx/cedar_demon_windup.wav",
    "cedar_demon_attack": "res://assets/audio/sfx/cedar_demon_attack.wav",
    "cedar_demon_hurt": "res://assets/audio/sfx/cedar_demon_hurt.wav",
    "cedar_demon_death": "res://assets/audio/sfx/cedar_demon_death.wav",
    "kala_ushumgal_windup": "res://assets/audio/sfx/kala_ushumgal_windup.wav",
    "kala_ushumgal_attack": "res://assets/audio/sfx/kala_ushumgal_attack.wav",
    "kala_ushumgal_hurt": "res://assets/audio/sfx/kala_ushumgal_hurt.wav",
    "kala_ushumgal_death": "res://assets/audio/sfx/kala_ushumgal_death.wav",
    "sentinel_shield_up": "res://assets/audio/sfx/sentinel_shield_up.wav",
    "sentinel_shield_break": "res://assets/audio/sfx/sentinel_shield_break.wav",
    "colossus_slam": "res://assets/audio/sfx/colossus_slam.wav",
    "colossus_shockwave": "res://assets/audio/sfx/colossus_shockwave.wav",
    "archer_shot": "res://assets/audio/sfx/archer_shot.wav",
    "bone_spike_pop": "res://assets/audio/sfx/bone_spike_pop.wav",
    "wisp_wail_loop": "res://assets/audio/sfx/wisp_wail_loop.wav",
    "wisp_explode": "res://assets/audio/sfx/wisp_explode.wav",
    "demon_screech": "res://assets/audio/sfx/demon_screech.wav",
    "boss_whip_swing": "res://assets/audio/sfx/boss_whip_swing.wav",
    "boss_slam": "res://assets/audio/sfx/boss_slam.wav",
    "boss_spike_rise": "res://assets/audio/sfx/boss_spike_rise.wav",
    "boss_roar_loop": "res://assets/audio/sfx/boss_roar_loop.wav",
    "boss_phase_roar": "res://assets/audio/sfx/boss_phase_roar.wav",
    "boss_core_throb": "res://assets/audio/sfx/boss_core_throb.wav",
    "boss_collapse": "res://assets/audio/sfx/boss_collapse.wav",
    "boss_final_swing": "res://assets/audio/sfx/boss_final_swing.wav",
    "armor_hit": "res://assets/audio/sfx/armor_hit.wav",
    "speech_blip": "res://assets/audio/sfx/speech_blip.wav",
    "buff_chime": "res://assets/audio/sfx/buff_chime.wav",

    "explosive_spitter_windup": "res://assets/audio/sfx/explosive_spitter_windup.wav",
    "explosive_spitter_attack": "res://assets/audio/sfx/explosive_spitter_attack.wav",
    "explosive_spitter_hurt": "res://assets/audio/sfx/explosive_spitter_hurt.wav",
    "explosive_spitter_death": "res://assets/audio/sfx/explosive_spitter_death.wav",
    "wall_diver_windup": "res://assets/audio/sfx/wall_diver_windup.wav",
    "wall_diver_attack": "res://assets/audio/sfx/wall_diver_attack.wav",
    "wall_diver_hurt": "res://assets/audio/sfx/wall_diver_hurt.wav",
    "wall_diver_death": "res://assets/audio/sfx/wall_diver_death.wav",
    "root_spewer_windup": "res://assets/audio/sfx/root_spewer_windup.wav",
    "root_spewer_attack": "res://assets/audio/sfx/root_spewer_attack.wav",
    "root_spewer_hurt": "res://assets/audio/sfx/root_spewer_hurt.wav",
    "root_spewer_death": "res://assets/audio/sfx/root_spewer_death.wav",
    "boar_charger_windup": "res://assets/audio/sfx/boar_charger_windup.wav",
    "boar_charger_attack": "res://assets/audio/sfx/boar_charger_attack.wav",
    "boar_charger_hurt": "res://assets/audio/sfx/boar_charger_hurt.wav",
    "boar_charger_death": "res://assets/audio/sfx/boar_charger_death.wav",
    "gas_sac_windup": "res://assets/audio/sfx/gas_sac_windup.wav",
    "gas_sac_attack": "res://assets/audio/sfx/gas_sac_attack.wav",
    "gas_sac_hurt": "res://assets/audio/sfx/gas_sac_hurt.wav",
    "gas_sac_death": "res://assets/audio/sfx/gas_sac_death.wav",
    "wraith_ray_windup": "res://assets/audio/sfx/wraith_ray_windup.wav",
    "wraith_ray_attack": "res://assets/audio/sfx/wraith_ray_attack.wav",
    "wraith_ray_hurt": "res://assets/audio/sfx/wraith_ray_hurt.wav",
    "wraith_ray_death": "res://assets/audio/sfx/wraith_ray_death.wav",
    "shell_scorpion_windup": "res://assets/audio/sfx/shell_scorpion_windup.wav",
    "shell_scorpion_attack": "res://assets/audio/sfx/shell_scorpion_attack.wav",
    "shell_scorpion_hurt": "res://assets/audio/sfx/shell_scorpion_hurt.wav",
    "shell_scorpion_death": "res://assets/audio/sfx/shell_scorpion_death.wav",
    "corpse_bomber_windup": "res://assets/audio/sfx/corpse_bomber_windup.wav",
    "corpse_bomber_attack": "res://assets/audio/sfx/corpse_bomber_attack.wav",
    "corpse_bomber_hurt": "res://assets/audio/sfx/corpse_bomber_hurt.wav",
    "corpse_bomber_death": "res://assets/audio/sfx/corpse_bomber_death.wav",
    "chain_beastman_windup": "res://assets/audio/sfx/chain_beastman_windup.wav",
    "chain_beastman_attack": "res://assets/audio/sfx/chain_beastman_attack.wav",
    "chain_beastman_hurt": "res://assets/audio/sfx/chain_beastman_hurt.wav",
    "chain_beastman_death": "res://assets/audio/sfx/chain_beastman_death.wav",
    "spit_launch": "res://assets/audio/sfx/spit_launch.wav",
    "explosion_boom": "res://assets/audio/sfx/explosion_boom.wav",
    "gas_burst": "res://assets/audio/sfx/gas_burst.wav",
    "gas_loop": "res://assets/audio/sfx/gas_loop.wav",
    "chain_launch": "res://assets/audio/sfx/chain_launch.wav",
    "chain_pull": "res://assets/audio/sfx/chain_pull.wav",
    "guard_block": "res://assets/audio/sfx/guard_block.wav",
    "corpse_scream": "res://assets/audio/sfx/corpse_scream.wav",
    "corpse_fuse_beep": "res://assets/audio/sfx/corpse_fuse_beep.wav",
    "boar_charge_rumble": "res://assets/audio/sfx/boar_charge_rumble.wav",
    "wraith_wail_loop": "res://assets/audio/sfx/wraith_wail_loop.wav",
    "wall_diver_screech": "res://assets/audio/sfx/wall_diver_screech.wav",

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
    "nimrod_home": "res://assets/audio/bgm/nimrod_home.wav",
    "cedar_forest": "res://assets/audio/bgm/cedar_forest.wav",
    "cedar_boss": "res://assets/audio/bgm/cedar_boss.wav",

    "passage_descent": "res://assets/audio/bgm/passage_descent.wav",
    "uruk_home_road": "res://assets/audio/bgm/uruk_home_road.wav",

    "uruk_rear_gate": "res://assets/audio/bgm/uruk_rear_gate.wav",
    "castle_hall": "res://assets/audio/bgm/castle_hall.wav",
    "uruk_sky": "res://assets/audio/bgm/uruk_sky.wav",
    "villa_calm": "res://assets/audio/bgm/villa_calm.wav",
    "castle_front": "res://assets/audio/bgm/castle_front.wav",
    "uruk_wasteland": "res://assets/audio/bgm/uruk_wasteland.wav"
}
const LOOP_SFX: Array[String] = ["beast_ranged_flame_loop", "sky_beast_wingflap_loop", "gas_loop", "wraith_wail_loop", "wisp_wail_loop", "boss_roar_loop", "boss_core_throb"]
const SILENT_DB: float = -60.0

var _streams: Dictionary = {}
var sfx_volumes: Dictionary = {}
var _bgm: AudioStreamPlayer
var _bgm_name: String = ""
var _bgm_tween: Tween

func _ready() -> void:
    for file in ["res://data/audio_stage5.json", "res://data/audio_stage6.json"]:
        var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
        for item in spec.get("sfx", []):
            sfx_volumes[str(item["name"])] = float(item.get("volume_db", 0.0))
    var spec: Dictionary = {}
    for item in spec.get("sfx", []):
        sfx_volumes[str(item["name"])] = float(item.get("volume_db", 0.0))
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
        spatial.volume_db = float(sfx_volumes.get(name, 0.0))
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
    player.volume_db = float(sfx_volumes.get(name, 0.0))
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
