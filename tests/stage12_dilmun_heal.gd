extends "res://tests/helpers/stage9_support.gd"
var before_fade_hp := 0
func _run() -> void:
    await _start9()
    story_state.debug_stage(15)
    root.get_node("Rampage").set_value(42)
    hero.sync_story_state()
    hero.apply_shamhat_blessing()
    var expected_hp: int = hero.get_max_hp()
    hero.hp=1
    var gauge: int = root.get_node("Rampage").value()
    hero.damage_received.connect(func(_amount: int,current_hp: int) -> void:
        if manager.current_level.level_id=="Dilmun" and before_fade_hp==0:
            before_fade_hp=current_hp
            _check(manager._fade_rect.modulate.a==1.,"Healing is applied while fully black")
    )
    await cutscene_node.play("skip_to_dilmun")
    _check(hero.hp==expected_hp and before_fade_hp==expected_hp,"Dilmun completely heals current modified maximum")
    _check(root.get_node("Rampage").value()==gauge,"Arrival does not alter existing rage")
    var save: Node = root.get_node("Save")
    save.save_path="user://stage12_heal.json"
    save.erase_save()
    # Exercise the real serializer at Dilmun arrival without adding a UI save point.
    var snapshot: Dictionary=save.snapshot_data()
    var file:=FileAccess.open(save.save_path,FileAccess.WRITE)
    file.store_string(JSON.stringify(snapshot))
    file.close()
    _check(snapshot["level"]=="Dilmun" and snapshot["hp"]==expected_hp,"Arrival snapshot contains the full modified HP")
    hero.hp=1
    _check(await save.resume(false) and hero.hp==hero.get_max_hp(),"Healed HP persists through load")
    save.erase_save()
    await _finish("STAGE12_DILMUN_HEAL")
