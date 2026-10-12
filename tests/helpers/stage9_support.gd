extends "res://tests/helpers/stage4_support.gd"
var story_state: Node
var dialogue_node: Node
var cutscene_node: Node
func _start9() -> void:
    await _start()
    story_state = root.get_node("Story")
    dialogue_node = root.get_node("Dialogue")
    cutscene_node = root.get_node("Cutscene")
    dialogue_node.test_timing_scale = .001
    cutscene_node.timing_scale = .03
func _go(id: String, spawn: String = "") -> void:
    if spawn.is_empty():
        spawn = str(manager.levels[id]["spawns"].keys()[0])
    await manager.go_to(id,spawn,{"instant":true})
