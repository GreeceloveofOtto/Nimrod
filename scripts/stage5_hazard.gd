class_name Stage5Hazard
extends Node2D

var spec: Dictionary = {}
var kind: String = "explosion"
var age: float = 0.0
var next_tick: float = 0.0
var detonated: bool = false
var effect: Node2D

func configure(type: String, settings: Dictionary) -> void:
    kind = type
    spec = settings.duplicate(true)

func _ready() -> void:
    add_to_group("stage5_hazards")
    if kind == "gas":
        effect = Stage5FX.spawn(self, "gas_cloud", global_position, Vector2(float(spec["radius"]) * 2.0, float(spec["height"])))
        _sound("gas_loop", true)
    elif float(spec.get("fuse", 0.0)) <= 0.0:
        _detonate()
    else:
        effect = Stage5FX.spawn(self, "spit_projectile", global_position, Vector2.ONE * 24.0)

func _physics_process(delta: float) -> void:
    age += delta
    if kind == "gas":
        while next_tick + 0.000001 < float(spec["seconds"]) and age + 0.000001 >= next_tick:
            _tick()
            next_tick += float(spec["tick_interval"])
        if age >= float(spec["seconds"]):
            queue_free()
    elif not detonated and age + 0.000001 >= float(spec.get("fuse", 0.0)):
        _detonate()
    elif detonated and age + 0.000001 >= float(spec.get("fuse", 0.0)) + float(spec.get("visual_seconds", 0.35)):
        queue_free()

func _player() -> NimrodPlayer:
    return get_tree().get_first_node_in_group("player") as NimrodPlayer

func _detonate() -> void:
    if detonated:
        return
    detonated = true
    var radius: float = float(spec["radius"])
    if is_instance_valid(effect):
        effect.queue_free()
    effect = Stage5FX.spawn(self, "explosion", global_position, Vector2.ONE * radius * 2.0)
    _sound("explosion_boom")
    var player := _player()
    if player == null:
        return
    var body: Rect2 = Rect2(player.collider.global_position - (player.collider.shape as RectangleShape2D).size * 0.5, (player.collider.shape as RectangleShape2D).size)
    var nearest := Vector2(clampf(global_position.x, body.position.x, body.end.x), clampf(global_position.y, body.position.y, body.end.y))
    if nearest.distance_to(global_position) <= radius:
        var direction: float = 1.0 if player.global_position.x >= global_position.x else -1.0
        player.receive_damage(int(spec["damage"]), {"grant_grace": false, "stagger": true, "knockback": Vector2(direction * float(spec.get("knockback", 0.0)), 0.0)})

func _tick() -> void:
    var player := _player()
    if player == null:
        return
    var bounds := Rect2(global_position - Vector2(float(spec["radius"]), float(spec["height"]) * 0.5), Vector2(float(spec["radius"]) * 2.0, float(spec["height"])))
    var body: Rect2 = Rect2(player.collider.global_position - (player.collider.shape as RectangleShape2D).size * 0.5, (player.collider.shape as RectangleShape2D).size)
    if bounds.intersects(body):
        player.receive_damage(int(spec["damage"]), {"stagger": false, "grant_grace": false, "tick_group": "gas", "tick_source": get_instance_id(), "overlap_interval": float(spec.get("overlap_interval", 0.2))})

func _sound(clip_or_sound_name: String, looped: bool = false) -> void:
    var audio := get_node_or_null("/root/Audio")
    if audio == null:
        return
    var sound: Node = audio.play_sfx(clip_or_sound_name, global_position)
    if looped and sound != null:
        tree_exiting.connect(audio.stop_sfx.bind(sound), CONNECT_ONE_SHOT)
