extends Node

# Replace a source file at the same path to upgrade the temporary synthesized audio.
const SFX_TABLE: Dictionary = {
    "melammu_heartbeat": "res://assets/audio/sfx/melammu_heartbeat.ogg",
    "sob_loop": "res://assets/audio/sfx/sob_loop.ogg",
    "arm_cut": "res://assets/audio/sfx/arm_cut.ogg",
    "gugalanna_stomp": "res://assets/audio/sfx/gugalanna_stomp.ogg",
    "gugalanna_quake": "res://assets/audio/sfx/gugalanna_quake.ogg",
    "gugalanna_charge_rumble": "res://assets/audio/sfx/gugalanna_charge_rumble.ogg",
    "gugalanna_charge_crash": "res://assets/audio/sfx/gugalanna_charge_crash.ogg",
    "gugalanna_uppercut": "res://assets/audio/sfx/gugalanna_uppercut.ogg",
    "gugalanna_rake": "res://assets/audio/sfx/gugalanna_rake.ogg",
    "gugalanna_roar": "res://assets/audio/sfx/gugalanna_roar.ogg",
    "gugalanna_vomit": "res://assets/audio/sfx/gugalanna_vomit.ogg",
    "gugalanna_death": "res://assets/audio/sfx/gugalanna_death.ogg",

    "anur_cast": "res://assets/audio/sfx/anur_cast.ogg",
    "anur_hit": "res://assets/audio/sfx/anur_hit.ogg",
    "humbaba_bite": "res://assets/audio/sfx/humbaba_bite.ogg",
    "humbaba_claw": "res://assets/audio/sfx/humbaba_claw.ogg",
    "humbaba_breath_loop": "res://assets/audio/sfx/humbaba_breath_loop.ogg",
    "humbaba_tail": "res://assets/audio/sfx/humbaba_tail.ogg",
    "humbaba_roar": "res://assets/audio/sfx/humbaba_roar.ogg",
    "humbaba_hurt": "res://assets/audio/sfx/humbaba_hurt.ogg",
    "humbaba_death": "res://assets/audio/sfx/humbaba_death.ogg",

    "cedar_sentinel_windup": "res://assets/audio/sfx/cedar_sentinel_windup.ogg",
    "cedar_sentinel_attack": "res://assets/audio/sfx/cedar_sentinel_attack.ogg",
    "cedar_sentinel_hurt": "res://assets/audio/sfx/cedar_sentinel_hurt.ogg",
    "cedar_sentinel_death": "res://assets/audio/sfx/cedar_sentinel_death.ogg",
    "cedar_colossus_windup": "res://assets/audio/sfx/cedar_colossus_windup.ogg",
    "cedar_colossus_attack": "res://assets/audio/sfx/cedar_colossus_attack.ogg",
    "cedar_colossus_hurt": "res://assets/audio/sfx/cedar_colossus_hurt.ogg",
    "cedar_colossus_death": "res://assets/audio/sfx/cedar_colossus_death.ogg",
    "cedar_archer_windup": "res://assets/audio/sfx/cedar_archer_windup.ogg",
    "cedar_archer_attack": "res://assets/audio/sfx/cedar_archer_attack.ogg",
    "cedar_archer_hurt": "res://assets/audio/sfx/cedar_archer_hurt.ogg",
    "cedar_archer_death": "res://assets/audio/sfx/cedar_archer_death.ogg",
    "cedar_wisp_windup": "res://assets/audio/sfx/cedar_wisp_windup.ogg",
    "cedar_wisp_attack": "res://assets/audio/sfx/cedar_wisp_attack.ogg",
    "cedar_wisp_hurt": "res://assets/audio/sfx/cedar_wisp_hurt.ogg",
    "cedar_wisp_death": "res://assets/audio/sfx/cedar_wisp_death.ogg",
    "cedar_demon_windup": "res://assets/audio/sfx/cedar_demon_windup.ogg",
    "cedar_demon_attack": "res://assets/audio/sfx/cedar_demon_attack.ogg",
    "cedar_demon_hurt": "res://assets/audio/sfx/cedar_demon_hurt.ogg",
    "cedar_demon_death": "res://assets/audio/sfx/cedar_demon_death.ogg",
    "kala_ushumgal_windup": "res://assets/audio/sfx/kala_ushumgal_windup.ogg",
    "kala_ushumgal_attack": "res://assets/audio/sfx/kala_ushumgal_attack.ogg",
    "kala_ushumgal_hurt": "res://assets/audio/sfx/kala_ushumgal_hurt.ogg",
    "kala_ushumgal_death": "res://assets/audio/sfx/kala_ushumgal_death.ogg",
    "sentinel_shield_up": "res://assets/audio/sfx/sentinel_shield_up.ogg",
    "sentinel_shield_break": "res://assets/audio/sfx/sentinel_shield_break.ogg",
    "colossus_slam": "res://assets/audio/sfx/colossus_slam.ogg",
    "colossus_shockwave": "res://assets/audio/sfx/colossus_shockwave.ogg",
    "archer_shot": "res://assets/audio/sfx/archer_shot.ogg",
    "bone_spike_pop": "res://assets/audio/sfx/bone_spike_pop.ogg",
    "wisp_wail_loop": "res://assets/audio/sfx/wisp_wail_loop.ogg",
    "wisp_explode": "res://assets/audio/sfx/wisp_explode.ogg",
    "demon_screech": "res://assets/audio/sfx/demon_screech.ogg",
    "boss_whip_swing": "res://assets/audio/sfx/boss_whip_swing.ogg",
    "boss_slam": "res://assets/audio/sfx/boss_slam.ogg",
    "boss_spike_rise": "res://assets/audio/sfx/boss_spike_rise.ogg",
    "boss_roar_loop": "res://assets/audio/sfx/boss_roar_loop.ogg",
    "boss_phase_roar": "res://assets/audio/sfx/boss_phase_roar.ogg",
    "boss_core_throb": "res://assets/audio/sfx/boss_core_throb.ogg",
    "boss_collapse": "res://assets/audio/sfx/boss_collapse.ogg",
    "boss_final_swing": "res://assets/audio/sfx/boss_final_swing.ogg",
    "armor_hit": "res://assets/audio/sfx/armor_hit.ogg",
    "speech_blip": "res://assets/audio/sfx/speech_blip.ogg",
    "buff_chime": "res://assets/audio/sfx/buff_chime.ogg",

    "explosive_spitter_windup": "res://assets/audio/sfx/explosive_spitter_windup.ogg",
    "explosive_spitter_attack": "res://assets/audio/sfx/explosive_spitter_attack.ogg",
    "explosive_spitter_hurt": "res://assets/audio/sfx/explosive_spitter_hurt.ogg",
    "explosive_spitter_death": "res://assets/audio/sfx/explosive_spitter_death.ogg",
    "wall_diver_windup": "res://assets/audio/sfx/wall_diver_windup.ogg",
    "wall_diver_attack": "res://assets/audio/sfx/wall_diver_attack.ogg",
    "wall_diver_hurt": "res://assets/audio/sfx/wall_diver_hurt.ogg",
    "wall_diver_death": "res://assets/audio/sfx/wall_diver_death.ogg",
    "root_spewer_windup": "res://assets/audio/sfx/root_spewer_windup.ogg",
    "root_spewer_attack": "res://assets/audio/sfx/root_spewer_attack.ogg",
    "root_spewer_hurt": "res://assets/audio/sfx/root_spewer_hurt.ogg",
    "root_spewer_death": "res://assets/audio/sfx/root_spewer_death.ogg",
    "boar_charger_windup": "res://assets/audio/sfx/boar_charger_windup.ogg",
    "boar_charger_attack": "res://assets/audio/sfx/boar_charger_attack.ogg",
    "boar_charger_hurt": "res://assets/audio/sfx/boar_charger_hurt.ogg",
    "boar_charger_death": "res://assets/audio/sfx/boar_charger_death.ogg",
    "gas_sac_windup": "res://assets/audio/sfx/gas_sac_windup.ogg",
    "gas_sac_attack": "res://assets/audio/sfx/gas_sac_attack.ogg",
    "gas_sac_hurt": "res://assets/audio/sfx/gas_sac_hurt.ogg",
    "gas_sac_death": "res://assets/audio/sfx/gas_sac_death.ogg",
    "wraith_ray_windup": "res://assets/audio/sfx/wraith_ray_windup.ogg",
    "wraith_ray_attack": "res://assets/audio/sfx/wraith_ray_attack.ogg",
    "wraith_ray_hurt": "res://assets/audio/sfx/wraith_ray_hurt.ogg",
    "wraith_ray_death": "res://assets/audio/sfx/wraith_ray_death.ogg",
    "shell_scorpion_windup": "res://assets/audio/sfx/shell_scorpion_windup.ogg",
    "shell_scorpion_attack": "res://assets/audio/sfx/shell_scorpion_attack.ogg",
    "shell_scorpion_hurt": "res://assets/audio/sfx/shell_scorpion_hurt.ogg",
    "shell_scorpion_death": "res://assets/audio/sfx/shell_scorpion_death.ogg",
    "corpse_bomber_windup": "res://assets/audio/sfx/corpse_bomber_windup.ogg",
    "corpse_bomber_attack": "res://assets/audio/sfx/corpse_bomber_attack.ogg",
    "corpse_bomber_hurt": "res://assets/audio/sfx/corpse_bomber_hurt.ogg",
    "corpse_bomber_death": "res://assets/audio/sfx/corpse_bomber_death.ogg",
    "chain_beastman_windup": "res://assets/audio/sfx/chain_beastman_windup.ogg",
    "chain_beastman_attack": "res://assets/audio/sfx/chain_beastman_attack.ogg",
    "chain_beastman_hurt": "res://assets/audio/sfx/chain_beastman_hurt.ogg",
    "chain_beastman_death": "res://assets/audio/sfx/chain_beastman_death.ogg",
    "spit_launch": "res://assets/audio/sfx/spit_launch.ogg",
    "explosion_boom": "res://assets/audio/sfx/explosion_boom.ogg",
    "gas_burst": "res://assets/audio/sfx/gas_burst.ogg",
    "gas_loop": "res://assets/audio/sfx/gas_loop.ogg",
    "chain_launch": "res://assets/audio/sfx/chain_launch.ogg",
    "chain_pull": "res://assets/audio/sfx/chain_pull.ogg",
    "guard_block": "res://assets/audio/sfx/guard_block.ogg",
    "corpse_scream": "res://assets/audio/sfx/corpse_scream.ogg",
    "corpse_fuse_beep": "res://assets/audio/sfx/corpse_fuse_beep.ogg",
    "boar_charge_rumble": "res://assets/audio/sfx/boar_charge_rumble.ogg",
    "wraith_wail_loop": "res://assets/audio/sfx/wraith_wail_loop.ogg",
    "wall_diver_screech": "res://assets/audio/sfx/wall_diver_screech.ogg",

    "jump_a": "res://assets/audio/jump_a.ogg",
    "jump_b": "res://assets/audio/jump_b.ogg",
    "jump_c": "res://assets/audio/jump_c.ogg",
    "land": "res://assets/audio/land.ogg",
    "roll": "res://assets/audio/roll.ogg",
    "step": "res://assets/audio/step.ogg",
    "axe_hit_flesh": "res://assets/audio/sfx/axe_hit_flesh.ogg",
    "axe_hit_heavy": "res://assets/audio/sfx/axe_hit_heavy.ogg",
    "shockwave": "res://assets/audio/sfx/shockwave.ogg",
    "beast_melee_windup": "res://assets/audio/sfx/beast_melee_windup.ogg",
    "beast_melee_attack": "res://assets/audio/sfx/beast_melee_attack.ogg",
    "beast_melee_hurt": "res://assets/audio/sfx/beast_melee_hurt.ogg",
    "beast_melee_death": "res://assets/audio/sfx/beast_melee_death.ogg",
    "beast_ranged_windup": "res://assets/audio/sfx/beast_ranged_windup.ogg",
    "beast_ranged_flame_start": "res://assets/audio/sfx/beast_ranged_flame_start.ogg",
    "beast_ranged_flame_loop": "res://assets/audio/sfx/beast_ranged_flame_loop.ogg",
    "beast_ranged_hurt": "res://assets/audio/sfx/beast_ranged_hurt.ogg",
    "beast_ranged_death": "res://assets/audio/sfx/beast_ranged_death.ogg",
    "player_hurt": "res://assets/audio/sfx/player_hurt.ogg",
    "door_open": "res://assets/audio/sfx/door_open.ogg",
    "door_close": "res://assets/audio/sfx/door_close.ogg",
    "door_locked": "res://assets/audio/sfx/door_locked.ogg",
    "portal_whoosh": "res://assets/audio/sfx/portal_whoosh.ogg",
    "sky_beast_wingflap_loop": "res://assets/audio/sfx/sky_beast_wingflap_loop.ogg",
    "sky_beast_windup_screech": "res://assets/audio/sfx/sky_beast_windup_screech.ogg",
    "sky_beast_dive_whoosh": "res://assets/audio/sfx/sky_beast_dive_whoosh.ogg",
    "sky_beast_hurt": "res://assets/audio/sfx/sky_beast_hurt.ogg",
    "sky_beast_death": "res://assets/audio/sfx/sky_beast_death.ogg",
    "great_gate_open": "res://assets/audio/sfx/great_gate_open.ogg",
    "great_gate_close": "res://assets/audio/sfx/great_gate_close.ogg"
}
const BGM_TABLE: Dictionary = {
    "home_sorrow": "res://assets/audio/bgm/home_sorrow.ogg",
    "dilmun_wind": "res://assets/audio/bgm/dilmun_wind.ogg",
    "nimrod_home": "res://assets/audio/bgm/nimrod_home.ogg",
    "cedar_forest": "res://assets/audio/bgm/cedar_forest.ogg",
    "cedar_boss": "res://assets/audio/bgm/cedar_boss.ogg",

    "passage_descent": "res://assets/audio/bgm/passage_descent.ogg",
    "uruk_home_road": "res://assets/audio/bgm/uruk_home_road.ogg",

    "uruk_rear_gate": "res://assets/audio/bgm/uruk_rear_gate.ogg",
    "castle_hall": "res://assets/audio/bgm/castle_hall.ogg",
    "uruk_sky": "res://assets/audio/bgm/uruk_sky.ogg",
    "villa_calm": "res://assets/audio/bgm/villa_calm.ogg",
    "castle_front": "res://assets/audio/bgm/castle_front.ogg",
    "uruk_wasteland": "res://assets/audio/bgm/uruk_wasteland.ogg"
}
const LOOP_SFX: Array[String] = ["beast_ranged_flame_loop", "sky_beast_wingflap_loop", "gas_loop", "wraith_wail_loop", "wisp_wail_loop", "boss_roar_loop", "boss_core_throb", "humbaba_breath_loop", "sob_loop"]
const SILENT_DB: float = -60.0

var _streams: Dictionary = {}
var sfx_volumes: Dictionary = {}
var _bgm: AudioStreamPlayer
var _bgm_name: String = ""
var _bgm_tween: Tween

func _ready() -> void:
    # Music and dialogue sounds continue while the game world is paused.
    process_mode = Node.PROCESS_MODE_ALWAYS
    for file in ["res://data/audio_stage5.json", "res://data/audio_stage6.json", "res://data/audio_stage9.json", "res://data/audio_stage10.json"]:
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
    release_streams()
    _bgm = null

func release_streams() -> void:
    # Stop and detach streams while the mixer is still running. Test runners
    # call this before shutdown; normal node removal uses the same cleanup.
    _cancel_bgm_tween()
    _bgm_tween = null
    for child in get_children():
        if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
            child.stop()
            child.stream = null
    _streams.clear()
    _bgm_name = ""
# Let Vorbis reach EOF while its player is still in the tree. Godot 4.3's
# mixer owns a native voice until it processes the final packet.
func drain_streams() -> void:
    _cancel_bgm_tween()
    for child in get_children():
        if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
            _retire_player(child)
    await get_tree().create_timer(0.15, true, false, true).timeout
    release_streams()

func _retire_player(player: Node) -> void:
    if not is_instance_valid(player):
        return
    if player.stream is AudioStreamOggVorbis and player.playing:
        (player.stream as AudioStreamOggVorbis).loop = false
        player.volume_db = SILENT_DB
        player.seek(maxf(0.0, player.stream.get_length() - 0.01))
        if not player.finished.is_connected(player.queue_free):
            player.finished.connect(player.queue_free)
    else:
        player.stop()
        player.queue_free()

func _load_stream(path: String, looping: bool) -> AudioStream:
    var preferred: String = path.get_basename() + ".ogg"
    if ResourceLoader.exists(preferred):
        path = preferred
    elif not ResourceLoader.exists(path):
        path = path.get_basename() + ".wav"
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
    # Godot 4.3 OGG playback owns a packet-sequence reference. Reuse its
    # imported stream instead of duplicating that shared sequence for each bus.
    var stream: AudioStream = source if source is AudioStreamOggVorbis else source.duplicate() as AudioStream
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
func play_sfx(clip_or_sound_name: String, position: Variant = null, pitch_jitter: float = 0.04) -> Node:
    if not SFX_TABLE.has(clip_or_sound_name):
        push_warning("Unknown SFX: " + clip_or_sound_name)
        return null
    var looping: bool = LOOP_SFX.has(clip_or_sound_name)
    var stream: AudioStream = _load_stream(str(SFX_TABLE[clip_or_sound_name]), looping)
    if stream == null:
        return null
    stream = stream.duplicate() as AudioStream
    var pitch: float = randf_range(1.0 - absf(pitch_jitter), 1.0 + absf(pitch_jitter))
    if position is Vector2:
        var spatial: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
        spatial.volume_db = float(sfx_volumes.get(clip_or_sound_name, 0.0))
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
    player.volume_db = float(sfx_volumes.get(clip_or_sound_name, 0.0))
    player.stream = stream
    player.bus = &"SFX"
    player.pitch_scale = maxf(0.01, pitch)
    add_child(player)
    if not looping:
        player.finished.connect(player.queue_free)
    player.play()
    return player

func stop_sfx(handle: Variant) -> void:
    if not is_instance_valid(handle):
        return
    _retire_player(handle)

func play_bgm(clip_or_sound_name: String, fade: float = 1.0) -> void:
    if not BGM_TABLE.has(clip_or_sound_name):
        push_warning("Unknown BGM: " + clip_or_sound_name)
        return
    if _bgm.playing and _bgm_name == clip_or_sound_name:
        return
    var stream: AudioStream = _load_stream(str(BGM_TABLE[clip_or_sound_name]), true)
    if stream == null:
        return
    _cancel_bgm_tween()
    # Retire the old player before attaching another looping Vorbis playback.
    # Godot 4.3 can retain native voices when a live player is reused rapidly.
    _retire_player(_bgm)
    _bgm = AudioStreamPlayer.new()
    _bgm.name = "BackgroundMusic"
    _bgm.bus = &"BGM"
    add_child(_bgm)
    _bgm.stream = stream.duplicate() as AudioStream
    _bgm_name = clip_or_sound_name
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
        _finish_bgm_stop()
        return
    _bgm_tween = create_tween()
    _bgm_tween.tween_property(_bgm, "volume_db", SILENT_DB, fade)
    _bgm_tween.tween_callback(_finish_bgm_stop)

func _cancel_bgm_tween() -> void:
    if _bgm_tween != null and _bgm_tween.is_valid():
        _bgm_tween.kill()

func _finish_bgm_stop() -> void:
    _retire_player(_bgm)
    _bgm = AudioStreamPlayer.new()
    _bgm.name = "BackgroundMusic"
    _bgm.bus = &"BGM"
    add_child(_bgm)
    _bgm_name = ""

func pause_world_sfx() -> Dictionary:
    var states: Dictionary = {}
    for child in get_children():
        if (child is AudioStreamPlayer or child is AudioStreamPlayer2D) and child != _bgm:
            states[child] = child.stream_paused
            child.stream_paused = true
    return states

func restore_world_sfx(states: Dictionary) -> void:
    for child in states:
        if is_instance_valid(child):
            child.stream_paused = bool(states[child])
