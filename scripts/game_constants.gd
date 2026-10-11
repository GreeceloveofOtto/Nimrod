extends RefCounted
class_name GameConstants

# Preserve the original motion prototype's tuning in one place.
const PLAYER_MAX_HP: int = 180
const PLAYER_RUN_SPEED: float = 360.0
const PLAYER_GROUND_ACCEL: float = 3400.0
const PLAYER_AIR_ACCEL: float = 2200.0
const GRAVITY: float = 1750.0
const PLAYER_JUMP_IMPULSE: float = -695.0
const PLAYER_JUMP_CUT_GRAVITY: float = 2400.0
const PLAYER_JUMP_CUT_THRESHOLD: float = -150.0
const PLAYER_MAX_FALL_SPEED: float = 1100.0
const PLAYER_COYOTE_SECONDS: float = 0.11
const PLAYER_JUMP_BUFFER_SECONDS: float = 0.12
const PLAYER_JUMP_START_SECONDS: float = 0.13
const PLAYER_JUMP_PITCH_MIN: float = 0.96
const PLAYER_JUMP_PITCH_MAX: float = 1.04
const PLAYER_COMBO_RESET_SECONDS: float = 0.8
const PLAYER_ROLL_STARTUP: float = 0.03
const PLAYER_ROLL_INVULNERABLE: float = 0.25
const PLAYER_ROLL_RECOVERY: float = 0.20
const PLAYER_ROLL_DURATION: float = PLAYER_ROLL_STARTUP + PLAYER_ROLL_INVULNERABLE + PLAYER_ROLL_RECOVERY
const PLAYER_ROLL_SPEED: float = 780.0
const PLAYER_ROLL_DECEL: float = 5100.0
const PLAYER_DROP_MASK_SECONDS: float = 0.26
const PLAYER_DROP_OFFSET: float = 21.0
const PLAYER_DROP_SPEED: float = 135.0
const PLAYER_VISUAL_SCALE: float = 0.30
const PLAYER_STAND_BOX: Vector2 = Vector2(36.0, 124.0)
const PLAYER_CROUCH_BOX: Vector2 = Vector2(36.0, 90.0)
const PLAYER_ROLL_BOX: Vector2 = Vector2(46.0, 48.0)
const PLAYER_STAND_CENTER_Y: float = -62.0
const PLAYER_CROUCH_CENTER_Y: float = -45.0
const PLAYER_ROLL_CENTER_Y: float = -24.0
const PLAYER_CROUCH_ENTER_SECONDS: float = 0.14
const PLAYER_CROUCH_EXIT_SECONDS: float = 0.13
const PLAYER_LANDING_SOFT_SECONDS: float = 0.10
const PLAYER_LANDING_HARD_SECONDS: float = 0.20
const PLAYER_LANDING_HARD_THRESHOLD: float = 330.0
const PLAYER_LANDING_CLIP_SECONDS: float = 0.24
const PLAYER_HURT_SECONDS: float = 0.45
const PLAYER_DAMAGE_GRACE_SECONDS: float = 0.45
const PLAYER_FLAME_FIRST_STAGGER_SECONDS: float = 0.18
const PLAYER_DEATH_RESTART_SECONDS: float = 1.6
const PLAYER_DAMAGE_FLASH_SECONDS: float = 0.17
const PLAYER_DAMAGE_SHAKE_SECONDS: float = 0.14
const PLAYER_ATTACK_MOVE_SCALE: float = 0.32
const PLAYER_IDLE_SPEED_THRESHOLD: float = 35.0
const PLAYER_STEP_SPEED_THRESHOLD: float = 45.0
const PLAYER_STEP_RUN_THRESHOLD: float = 0.55
const PLAYER_RUN_STEP_SECONDS: float = 0.28
const PLAYER_WALK_STEP_SECONDS: float = 0.34
const PLAYER_INPUT_DEADZONE: float = 0.01
const PLAYER_COLLISION_MASK: int = 3
const ENEMY_COLLISION_LAYER: int = 4
const ATTACK_QUERY_LIMIT: int = 16
const HITSTOP_SECONDS: float = 0.05
const PLAYER_SHAKE_SPEED: Vector2 = Vector2(53.0, 41.0)
const PLAYER_SHAKE_STRENGTH: float = 2.2
const PLAYER_ATTACK_SOUND_PATHS: Array[String] = [
    "",
    "res://assets/audio/attack1.ogg",
    "res://assets/audio/attack2.ogg",
    "res://assets/audio/attack3.ogg",
    "res://assets/audio/attack4.ogg"
]

const START_LEVEL: String = "NimrodHome"
const START_SPAWN: String = "Spawn_Start"
const ENABLE_DEBUG_TELEPORT: bool = true
const DEBUG_SURFACE: bool = true
