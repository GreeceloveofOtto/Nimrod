extends "res://tests/helpers/stage4_support.gd"

func _run() -> void:
    await _start()
    await manager.go_to("CastleOutskirts","Spawn_Debug")
    var accents: Array[Node] = get_nodes_in_group("surface_accents")
    var solid: int=0
    var one_way: int=0
    var ground: int=0
    for accent: SurfaceAccent in accents:
        _check(accent.get_parent() is StaticBody2D,"Accent attaches only to collision surface")
        _check(accent.z_index==-2,"Accent above terrain and below actors")
        if accent.one_way:one_way+=1
        else:solid+=1
        if accent.ground_floor:ground+=1
    _check(solid>0 and one_way>0 and ground>0,"Solid floors, one-way ledges and ground present")
    Input.action_press("surface_accents")
    accents[0]._process(0)
    Input.action_release("surface_accents")
    _check(not SurfaceAccent.globally_enabled and not accents[0].visible,"F3 hides visibility aid")
    SurfaceAccent.globally_enabled=true
    await _finish("STAGE6_SURFACE_ACCENT")
