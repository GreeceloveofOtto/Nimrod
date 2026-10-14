extends "res://tests/helpers/stage4_support.gd"
func _run() -> void:
    var unarmed: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/player/unarmed/manifest.json"))
    var siya: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/player/siyavash/manifest.json"))
    var specifications: Dictionary={}
    for row: Dictionary in unarmed["clips"]:specifications[row["name"]]=row
    _check(siya["clips"].size()==21,"Seventeen base clips plus four world movement clips generated")
    for row: Dictionary in siya["clips"]:
        if row["name"] in ["dash","wall_cling","wall_jump","crawl"]:
            var expected: Dictionary={"dash":4,"wall_cling":4,"wall_jump":3,"crawl":6}
            _check(row["frames"]==expected[row["name"]],"World movement frame count "+str(row["name"]))
            continue
        _check(row["frames"]==specifications[row["name"]]["frames"] and is_equal_approx(row["duration_seconds"],specifications[row["name"]]["duration_seconds"]),"Match unarmed frames and duration "+str(row["name"]))
        var texture: Texture2D=load("res://assets/"+str(row["sheet"]))
        _check(texture!=null,"Generated texture loads")
    for ident in ["ninazu_mother","lilith","zu"]:
        var dir:=DirAccess.open("res://assets/sprites/enemies/"+ident)
        var bytes:=0
        for file_name in dir.get_files():
            if file_name.ends_with(".webp"):bytes+=FileAccess.get_file_as_bytes("res://assets/sprites/enemies/"+ident+"/"+file_name).size()
        _check(bytes<=int(1.2*1048576),"Boss image budget "+ident)
    root.get_node("Audio").release_streams()
    print("STAGE13_ART_CONTRACT: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)
