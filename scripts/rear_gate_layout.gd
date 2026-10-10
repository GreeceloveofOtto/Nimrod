extends RefCounted
class_name RearGateLayout

# All world coordinates are measured from the player's feet.
const MAP_LEFT: float = 0.0
const MAP_RIGHT: float = 3600.0
const FLOOR_Y: float = 880.0
const GROUND_HEIGHT: float = 220.0
const WALL_THICKNESS: float = 64.0
const OUTSIDE_MARGIN: float = 200.0
const PLAYER_START: Vector2 = Vector2(260.0, FLOOR_Y)
const SAFE_ZONE_END: float = 200.0
const EXIT_START: float = 3400.0
const PATROL_RANGE: float = 250.0
const PLATFORM_Y: float = 700.0
const PLATFORM_WIDTH: float = 240.0
const PLATFORM_COLLISION_HEIGHT: float = 16.0
const PLATFORM_ART_HEIGHT: float = 48.0
const PLATFORM_X := [1120.0, 1480.0]
const STEPS := [
    {"x": 900.0, "width": 180.0, "height": 60.0},
    {"x": 2400.0, "width": 200.0, "height": 90.0},
]
const SPAWNS := [
    {"id": "melee_beast", "x": 400.0},
    {"id": "ranged_beast", "x": 1300.0},
    {"id": "melee_beast", "x": 1900.0},
    {"id": "ranged_beast", "x": 2800.0},
    {"id": "melee_beast", "x": 2920.0},
]
const PARALLAX_LAYERS := [
    {"name": "Sky", "file": "sky.png", "size": Vector2(1536.0, 720.0), "ratio": 0.05, "z": -40},
    {"name": "FarCity", "file": "far_city.png", "size": Vector2(1920.0, 720.0), "ratio": 0.20, "z": -30},
    {"name": "CastleWall", "file": "castle_wall.png", "size": Vector2(2560.0, 720.0), "ratio": 0.45, "z": -20},
]
const DOOR_CENTER: Vector2 = Vector2(100.0, FLOOR_Y)
const DOOR_SIZE: Vector2 = Vector2(320.0, 420.0)
const DOOR_INTERACT_DISTANCE: float = 145.0
const DOOR_INTERACT_VERTICAL_RANGE: float = 160.0
const DOOR_PROMPT_POSITION: Vector2 = Vector2(DOOR_CENTER.x - 20.0, FLOOR_Y - DOOR_SIZE.y - 38.0)
const DOOR_PROMPT_SIZE: Vector2 = Vector2(40.0, 36.0)
const EXIT_SIGN_CENTER: Vector2 = Vector2(3470.0, FLOOR_Y)
const EXIT_SIGN_SIZE: Vector2 = Vector2(160.0, 240.0)
const EXIT_HEIGHT: float = 500.0
const EXIT_LABEL_POSITION: Vector2 = Vector2(EXIT_START - 45.0, FLOOR_Y - 280.0)
const EXIT_LABEL_SIZE: Vector2 = Vector2(235.0, 38.0)
const DECORATIONS := [
    {"file": "ruin_pillar_a.png", "position": Vector2(690.0, FLOOR_Y - 280.0), "size": Vector2(150.0, 280.0), "z": -8},
    {"file": "ruin_pillar_b.png", "position": Vector2(2240.0, FLOOR_Y - 240.0), "size": Vector2(140.0, 240.0), "z": -8},
    {"file": "rubble.png", "position": Vector2(1730.0, FLOOR_Y - 110.0), "size": Vector2(220.0, 110.0), "z": -2},
]
const GROUND_TILE_SIZE: Vector2 = Vector2(512.0, GROUND_HEIGHT)
const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const CAMERA_BOTTOM: int = 1060
const STORY_SECONDS: float = 7.0
const ONE_WAY_MARGIN: float = 8.0
const HUD_BORDER_POSITION: Vector2 = Vector2(18.0, 18.0)
const HUD_BORDER_SIZE: Vector2 = Vector2(246.0, 30.0)
const HUD_HP_BACKGROUND_POSITION: Vector2 = Vector2(21.0, 21.0)
const HUD_HP_BACKGROUND_SIZE: Vector2 = Vector2(240.0, 24.0)
const HUD_HP_FILL_POSITION: Vector2 = Vector2(24.0, 24.0)
const HUD_HP_FILL_SIZE: Vector2 = Vector2(234.0, 18.0)
const HUD_HP_LABEL_POSITION: Vector2 = Vector2(28.0, 18.0)
const HUD_HP_LABEL_SIZE: Vector2 = Vector2(230.0, 28.0)
const HUD_TITLE_POSITION: Vector2 = Vector2(18.0, 57.0)
const HUD_TITLE_SIZE: Vector2 = Vector2(520.0, 34.0)
const HUD_CONTROLS_POSITION: Vector2 = Vector2(18.0, 675.0)
const HUD_CONTROLS_SIZE: Vector2 = Vector2(1240.0, 30.0)
const HUD_STORY_POSITION: Vector2 = Vector2(305.0, 32.0)
const HUD_STORY_SIZE: Vector2 = Vector2(730.0, 65.0)
