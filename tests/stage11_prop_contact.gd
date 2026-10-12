extends "res://tests/helpers/stage9_support.gd"
func _run() -> void:
    await _start9()
    story_state.debug_stage(10)
    await _go("NimrodHome")
    var contact: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prop_contacts.json"))
    var bed: NPC=manager.current_level.get_node("enkidua_bed")
    _check(absf(bed.position.x-float(contact["bed_center_x"]))<=3,"Bed actor centres on mattress")
    for name in ["bed_awake","bed_asleep"]:
        var c: Dictionary=bed.clip_data[name]
        var image: Image=bed.textures[name].get_image()
        var cell: Vector2i=Vector2i(int(c["storage_trim"]["w"]),int(c["storage_trim"]["h"]))
        var box: Rect2i=image.get_region(Rect2i(Vector2i.ZERO,cell)).get_used_rect()
        var bottom: float=(float(c["storage_trim"]["y"])+box.end.y-float(c["anchor_px"][1])*float(c["storage_scale"][1]))*.3/float(c["storage_scale"][1])
        _check(absf(bed.position.y+bottom-float(contact["bed_surface_y"]))<=3,"Painted bed body contact "+name)
    for row: Dictionary in contact.get("chair_contacts",[]):
        var chair: Image=(load("res://"+row["prop_path"]) as Texture2D).get_image()
        var top_y: float=row["prop_position"][1]+row["seat_row_px"]*row["prop_size"][1]/chair.get_height()
        var actor_y: float=row["actor_y"]+(row["actor_seat_y_px"]-row["anchor_y"])*row["visual_scale"]
        _check(absf(actor_y-top_y)<=3,"Chair/actor contact "+row["actor"])
    story_state.debug_stage(16)
    await _go("DeathSea")
    var old: NPC=manager.current_level.npcs["urshanabi"]
    var rock: Dictionary={}
    for decoration: Dictionary in manager.current_level.config["decorations"]:
        if "small_rock" in decoration["path"]:
            rock=decoration
    var image: Image=(load(rock["path"]) as Texture2D).get_image()
    var row: int=-1
    for y in range(image.get_height()):
        var count: int=0
        for x in range(image.get_width()):
            if image.get_pixel(x,y).a>.78:
                count+=1
        if count>=image.get_width()*.3:
            row=y
            break
    var top: float=float(rock["position"][1])+row*float(rock["size"][1])/image.get_height()
    _check(absf(old.position.y+float(old.clip_data["dice_loop"]["seat_contact_offset_y"])-top)<=3,"Ferryman sits on painted rock surface")
    await _finish("STAGE11_PROP_CONTACT")
