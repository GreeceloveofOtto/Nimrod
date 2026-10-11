extends "res://tests/helpers/stage4_support.gd"
func _save(name_value: String) -> void:
    hero.camera.position_smoothing_enabled = false
    hero.camera.reset_smoothing()
    hero.camera.force_update_scroll()
    await create_timer(.15).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_jpg("res://docs/screenshots/stage8_"+name_value+".jpg",.8)
func _run() -> void:
    root.size = Vector2i(1280,720)
    await _start(false)
    main.get_node("HUD").story.hide()
    await manager.go_to("CedarForest_F1","Spawn_FromVilla",{"instant":true})
    hero.global_position = Vector2(1160,300)
    await _save("trunk_after")
    await manager.go_to("CedarForest_F2","Spawn_FromBelow",{"instant":true})
    hero.global_position = Vector2(3100,1088)
    await _save("perches")
    await manager.go_to("CastleF1","Spawn_Debug",{"instant":true})
    var d: Node = root.get_node("Dialogue")
    d.play([{"speaker":"lugalbanda","text":"니므롯, 사랑하는 내 아들, 누군가의 수칼루가 되는 것을 내가 얼마나 기다렸는지 모른다."}],manager.current_level.npcs.lugalbanda,{"participants":d.find_speakers(),"character_seconds":.001,"hold_seconds":3})
    await create_timer(.8,true,false,true).timeout
    await _save("dialogue")
    d.cancel()
    await manager.go_to("CastleOutskirts","Spawn_FromGate",{"instant":true})
    hero.global_position = Vector2(9200,760)
    await _save("castle_gate")
    await manager.go_to("RearGate","Spawn_FromVilla",{"instant":true})
    hero.global_position = Vector2(5060,880)
    await _save("villa_gate")
    await _finish("STAGE8_SCREENS")
