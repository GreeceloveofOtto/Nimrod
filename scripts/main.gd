extends Node2D

@onready var hero: NimrodPlayer = $Player
@onready var level_root: Node2D = $LevelRoot
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
    hud.bind_player(hero)
    get_node("/root/SceneManager").bind_main(self, level_root, hero)

func _exit_tree() -> void:
    var manager := get_node_or_null("/root/SceneManager")
    if manager != null:
        manager.unbind_main(self)
