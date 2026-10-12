extends Node2D
var spec: Dictionary = {}
var radius := 0.0
var hit := false
var left: Node2D
var right: Node2D
func _ready() -> void:
    left = get_node("/root/Chapter").spawn_fx(self,global_position+Vector2(0,-25),"gugalanna_shockwave")
    right = get_node("/root/Chapter").spawn_fx(self,global_position+Vector2(0,-25),"gugalanna_shockwave")
    left.looped = true
    right.looped = true
    get_node("/root/Audio").play_sfx("gugalanna_quake")
func eligible(hero: NimrodPlayer) -> bool:
    return is_instance_valid(hero) and hero.is_on_floor() and absf(hero.global_position.y-global_position.y)<float(spec["height"]) and not hero.is_roll_invulnerable()
func _physics_process(delta: float) -> void:
    var previous: float = radius
    radius += float(spec["speed"])*delta
    left.position.x = -radius
    right.position.x = radius
    var hero: NimrodPlayer = get_node("/root/SceneManager").player
    if eligible(hero) and not hit:
        var distance: float = absf(hero.global_position.x-global_position.x)
        if distance>=previous-hero.STAND_BOX.x and distance<=radius+hero.STAND_BOX.x:
            hit = hero.receive_damage(int(spec["damage"]),{"stagger_seconds":float(spec["stun"])})
    if radius>2600:
        queue_free()
