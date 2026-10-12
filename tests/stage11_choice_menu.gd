extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    await _go("CastleF2")
    var menu: Node = root.get_node("Choice")
    var npc: NPC = manager.current_level.npcs["shamhat"]
    _check(not menu.menu_available(),"First interaction remains story dialogue")
    await dialogue_node.play_interaction("shamhat")
    _check(menu.menu_available() and not story_state.is_flag("shamhat_blessing"),"First conversation unlocks menu without blessing")
    menu.open(npc)
    await process_frame
    _check(menu.active and paused and menu.items==["대화하기","저장하기"],"Choice menu pauses world")
    await menu.choose(0)
    _check(hero.modifiers.modifiers.has("shamhat_blessing"),"Talk repeat gives blessing once")
    _check(not npc._interaction_complete(),"Conversation remains available after blessing")
    root.get_node("Rampage").unlock()
    menu.open(npc)
    await process_frame
    _check(menu.items.size()==3,"Unlocked rage adds cure")
    menu.input_delay=0
    var key := InputEventKey.new()
    key.physical_keycode=KEY_UP
    key.pressed=true
    menu._unhandled_input(key)
    _check(menu.selected==2,"Up wraps to cure")
    root.get_node("Rampage").set_value(20)
    hero.hp=30
    await menu.choose(2)
    _check(hero.hp==30 and root.get_node("Rampage").value()==20,"Insufficient HP never charges cost")
    menu.open(npc)
    await process_frame
    menu.input_delay=0
    key.physical_keycode=KEY_ESCAPE
    menu._unhandled_input(key)
    _check(not menu.active and not paused,"Escape restores world")
    await _finish("STAGE11_CHOICE_MENU")
