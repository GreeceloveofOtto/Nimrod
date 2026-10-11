#!/usr/bin/env python3
"""Author JSON level placement and collisions; all visuals reference PNG art."""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def save(name, value):
    (DATA / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def prop(name, x, y, width, height, z=-2):
    return dict(path="res://assets/props/" + name + ".png", position=[x, y], size=[width, height], z=z)


def door(id, x, y, target, spawn, arrival="", art="villa_inner_door", **extra):
    return dict(door_id=id, position=[x, y], door_art="res://assets/props/doors/" + art + ".png",
                target_level=target, target_spawn=spawn, arrival_spawn=arrival, **extra)


def npc(id, x, y=620, **extra):
    return dict(id=id, position=[x, y], **extra)


def interior(id, width, name, background):
    return dict(id=id, scene="res://scenes/" + id + ".tscn", width=width, bgm="villa_calm",
                display_name=name, floor_y=620, camera_limits=[0, 0, width, 720], safe_zones=[],
                backgrounds=[dict(name="Interior", path="res://assets/backgrounds/villa/" + background + ".png",
                                  size=[width, 720], ratio=1, z=-20, position=[0, 0])],
                spawns={}, doors=[], npcs=[], enemies=[], decorations=[], steps=[], platforms=[],
                ceiling=True, floor_art="res://assets/tiles/castle/villa_floor_tile.webp",
                floor_art_size=[512, 180], bg_dim=[.80, .80, .84])


def main():
    registry = json.loads((DATA / "levels.json").read_text())
    levels = {e["id"]: e for e in registry["levels"]}
    registry["world"].update(underground_art="res://assets/tiles/underground_fill.webp", underground_size=[512, 512])
    for level in levels.values():
        level["backgrounds"] = [b for b in level["backgrounds"] if "foreground" not in b["path"].lower()]
    front = levels["CastleFront"]
    front.update(width=2600, camera_limits=[0, 0, 2600, 1120], safe_zones=[[0, -200, 2600, 1520]],
                 spawns={"Spawn_FromCastle": [2100, 880], "Spawn_FromGate": [760, 880]},
                 enemies=[], steps=[], platforms=[], floor_sections=[],
                 floor_art="res://assets/tiles/castle_front/courtyard_tile.webp")
    front["backgrounds"] = [b for b in front["backgrounds"] if "facade" not in b["path"]]
    front["backgrounds"].append(dict(name="CastleFacade", path="res://assets/backgrounds/castle_front/castle_facade.webp",
                                       position=[1100, 160], size=[1500, 720], ratio=1, z=-10))
    front["doors"] = [door("castle_front_exterior", 2200, 880, "CastleF1", "Spawn_FromFront", "Spawn_FromCastle", "castle_front_door_exterior", exit_direction=-1),
                      door("castle_great_gate", 600, 880, "CastleOutskirts", "Spawn_FromGate", "Spawn_FromGate", "castle_great_gate",
                           kind="great_gate", inner_gatekeeper_id="castle_gatekeeper_inner", gate_settings_key="great_gate",
                           gate_open_seconds=1.2, gate_close_seconds=1.0, auto_transition_level="CastleOutskirts",
                           auto_transition_spawn="Spawn_FromGate", exit_direction=1)]
    front["npcs"] = [npc("castle_gatekeeper_inner", 880, 880, kind="gatekeeper", initial_facing=-1,
                          face_player=False, gesture_face_player=False)]
    front["decorations"] = [prop("castle_gate_wall_left", -140, 280, 420, 600), prop("castle_gate_wall_right", 920, 280, 420, 600),
                            prop("castle_front_brazier", 1450, 680, 180, 200), prop("castle_front_statue", 1750, 560, 230, 320),
                            prop("castle_front_lamp_post", 2340, 620, 150, 260)]

    outside = dict(id="CastleOutskirts", scene="res://scenes/CastleOutskirts.tscn", width=10000, floor_y=880,
                   display_name="루갈성 대문 밖", bgm="uruk_wasteland", bg_dim=[.88, .88, .92],
                   camera_limits=[0, 0, 10000, 1240], safe_zones=[[8850, -200, 1150, 1800]],
                   spawns={"Spawn_FromGate": [9440, 760], "Spawn_Debug": [1200, 680]}, steps=[], floor_sections=[],
                   floor_art="res://assets/tiles/outskirts/ground_tile.webp", floor_art_size=[512, 200], ceiling=False)
    outside["backgrounds"] = [dict(name=name, path="res://assets/backgrounds/outskirts/"+file+".png", size=[width,720], ratio=ratio,
                                        z=z, position=[0,0], **({"repeat_size":[2048,0],"repeat_times":6} if repeat else {}))
                              for name,file,width,ratio,z,repeat in [("Sky","sky",1792,.05,-40,False),("FarCity","far_city_tile",2048,.20,-30,True),
                                  ("MidRuins","mid_ruins_tile",2048,.45,-20,True),("Landmark","far_landmark",900,.20,-25,False)]]
    outside["backgrounds"].append(dict(name="DowntownFacade",path="res://assets/backgrounds/castle_front/downtown_passage_facade.webp",
                                         position=[0,-40],size=[1100,720],ratio=1,z=-10))
    outside["doors"] = [door("castle_great_gate",9600,760,"CastleFront","Spawn_FromGate","Spawn_FromGate","castle_great_gate",
                             kind="great_gate",opens_without_keeper=True,gate_settings_key="great_gate",gate_open_seconds=1.2,gate_close_seconds=1.0,
                             auto_transition_level="CastleFront",auto_transition_spawn="Spawn_FromGate",exit_direction=-1),
                        door("downtown_passage_entrance",520,680,"DowntownPassage_F1","Spawn_FromGate",art="downtown_passage_door",
                             locked=True,locked_message="아직 들어갈 수 없다")]
    outside["npcs"] = [npc("castle_gatekeeper_outer",9140,760,face_player=True,interactable=False)]
    segments=[(0,1500,200),(1500,1780,200),(1780,2060,140),(2060,2340,90),(2340,2620,40),(2620,2900,-10),(2900,3200,-60),
              (3200,5000,-60),(5000,5200,-60),(5200,6480,-40),(6480,6600,-60),(6600,6800,-60),(6800,7950,-120),(7950,8050,-60),
              (8050,8250,-15),(8250,8450,30),(8450,8650,75),(8650,8850,120),(8850,10000,120)]
    outside["terrain"]=[dict(id="ground_"+str(a),**{"from":a,"to":b},y=880-e,elevation=e,
                               art="res://assets/tiles/outskirts/"+("plaza_tile" if a>=8850 or b<=1500 else "ground_tile")+".png") for a,b,e in segments]
    outside["regions"]=[dict(id=i,span=[a,b],label=name) for i,a,b,name in [(1,8850,10000,"대문 광장"),(2,8050,8850,"내리막 계단"),
                            (3,6600,8050,"균열 협곡"),(4,5000,6600,"폐허 성벽"),(5,3200,5000,"황무지 잔해"),(6,1500,3200,"오르막 테라스"),(7,0,1500,"통로 광장")]]
    outside["platforms"]=[]
    def platform(id,x,e,width,art="ruin_platform"):
        outside["platforms"].append(dict(id=id,position=[x,880-e],width=width,art="res://assets/tiles/outskirts/"+art+".png",elevation=e))
    for id,x,e,w in [("bridge_left_low",6640,-10,180),("bridge_left_high",6820,60,180),("bridge",6900,60,900),
                     ("bridge_right_high",7780,60,180),("bridge_right_low",7960,-10,180),
                     ("wall_left_low",5000,50,180),("wall_left_high",5200,140,180),("upper",5300,140,1000),
                     ("wall_right_high",6300,140,180),("wall_right_low",6500,50,180),
                     ("rubble_low_left",3980,30,180),("rubble_high",4160,90,340),("rubble_low_right",4500,30,180)]:
        platform(id,x,e,w,"bridge_platform" if id.startswith("bridge") else "ruin_platform")
    outside["obstacles"]=[dict(rect=[x,940-h,220 if i==0 else 160,h],art="res://assets/props/large_rubble_"+("a" if i==0 else "b")+".png")
                           for i,(x,h) in enumerate([(3600,60),(4100,90),(4600,75)])]
    for a,b,e in segments:
        if 1500<=a<3200:
            outside["obstacles"].append(dict(rect=[a+100,880-e-20,60,20],art="res://assets/tiles/outskirts/ruin_ledge.webp"))
    def floor(x):
        return next(880-e for a,b,e in segments if a<=x<b)
    melee=[8350,7000,7450,5400,6200,3400,3900,4600,2800,1100]
    outside["enemies"]=[dict(id="melee_beast",position=[x,820 if x==7450 else 865 if x==4600 else floor(x)],patrol_center=x,
                              patrol_range=100 if x==8350 else 150 if x in [7450,1100] else 200) for x in melee]
    outside["enemies"] += [dict(id="ranged_beast",position=[x,740 if x==5800 else 790 if x==4200 else floor(x)],patrol_center=x,patrol_range=150)
                            for x in [7300,5800,4200,2300,1900]]
    outside["decorations"]=[prop("castle_gate_wall_left",8860,160,420,600),prop("castle_gate_wall_right",9920,160,420,600),
        prop("ruin_wall_a",5120,520,600,420),prop("ruin_wall_b",5970,580,480,360),prop("broken_tower",4660,380,360,560),
        prop("chasm_edge_left",6530,820,300,260),prop("chasm_edge_right",7850,820,300,260),
        prop("collapsed_bridge",6900,820,900,180),prop("upper_walkway",5300,740,1000,120),
        prop("dead_tree",3490,560,240,380),prop("crashed_pod_wreck",4570,700,420,240),prop("outskirts_lamp",8780,500,100,260)]
    outside["reachability"]={"max_rise":110,"max_gap":200,"max_local_platform_elevation":180,"player_jump_height":138.0,
                              "required_ground_route":[0,10000],"chains":[["bridge_left_low","bridge_left_high","bridge"],
                                 ["bridge","bridge_right_high","bridge_right_low"],["wall_left_low","wall_left_high","upper"],
                                 ["upper","wall_right_high","wall_right_low"],["rubble_low_left","rubble_high","rubble_low_right"]]}
    levels["CastleOutskirts"]=outside

    villa=levels["VillaF1"]
    villa["spawns"]["Spawn_FromAbove"]=[1000,620]
    villa["doors"]=[villa["doors"][0],door("door_up",1000,620,"VillaF2","Spawn_FromBelow","Spawn_FromAbove"),
                     door("villa_back_door",1850,620,"","",art="villa_back_door",locked=True,locked_message="후문은 아직 열 수 없다")]
    villa["npcs"][0]["position"]=[520,620];villa["npcs"][1]["position"]=[1480,620]
    villa["decorations"]=[prop("villa_vase",300,420,150,200),prop("villa_rug",1200,590,500,30)]
    f2=interior("VillaF2",2200,"샤마쉬와 아야의 별장 2층","villa_f2_dining")
    f2["spawns"]={"Spawn_FromBelow":[200,620],"Spawn_FromAbove":[2040,620]}
    f2["doors"]=[door("door_down",200,620,"VillaF1","Spawn_FromAbove","Spawn_FromBelow",exit_direction=1),
                   door("door_up",2040,620,"VillaF3","Spawn_FromBelow","Spawn_FromAbove",exit_direction=-1)]
    f2["npcs"]=[npc("cook_a",500,idle_clip="chop"),npc("cook_b",720,idle_clip="stir"),
                npc("cook_c",930,idle_clip="arrange",instance_id="cook_c_left",initial_facing=1),
                npc("cook_c",1870,idle_clip="arrange",instance_id="cook_c_right",initial_facing=-1)]
    f2["decorations"]=[prop("kitchen_prep_table",460,520,260,100),prop("kitchen_stove",650,535,190,85),
                           prop("villa_chairs",1120,470,520,150,-3),prop("villa_dining_table_wide",950,530,900,90)]
    levels["VillaF2"]=f2
    f3=interior("VillaF3",2000,"샤마쉬와 아야의 별장 3층","villa_f3_chamber")
    f3["spawns"]={"Spawn_FromBelow":[200,620]}
    f3["doors"]=[door("door_down",200,620,"VillaF2","Spawn_FromAbove","Spawn_FromBelow",exit_direction=1),
                   door("villa_up_locked",1800,620,"","",locked=True,locked_message="아직 갈 수 없다")]
    f3["npcs"]=[npc("shamash",900),npc("aya",1070)]
    f3["decorations"]=[prop("villa_sofa",1240,470,360,150),prop("villa_side_table",590,520,160,100)]
    levels["VillaF3"]=f3
    registry["levels"]=list(levels.values());save("levels.json",registry)
    stats=json.loads((DATA/"npcs.json").read_text())
    stats["common"]["three_way"]={"front_distance":140,"side_distance":220,"fade_seconds":.12,"look_distance":700,"look_min":4,"look_max":8,"look_min_hold":2}
    for entry in stats["npcs"]:
        if entry["id"] in ["lugalbanda","ninsun","shamhat","inanna","papsukkal"]:
            entry.update(three_way=True,initial_pose="right" if entry["id"]=="lugalbanda" else "left" if entry["id"]=="ninsun" else "front")
            if not any(c["name"]=="idle_front" for c in entry["clips"]):entry["clips"].append(dict(name="idle_front",frames=6,duration=2.4,loop=True))
    for id,name,ratio in [("shamash","샤마쉬",1.04),("aya","아야",.98)]:
        if not any(n["id"]==id for n in stats["npcs"]):
            stats["npcs"].append(dict(id=id,display_name=name,height_ratio=ratio,sheet_dir="assets/sprites/npcs/"+id,
                                     clips=[dict(name=clip,frames=6,duration=2.4,loop=True) for clip in ["idle","idle_front"]],
                                     face_player=True,three_way=True,initial_pose="front",random_start=False))
    for entry in stats["npcs"]:
        if not entry.get("three_way"):
            entry["source_reference_height_px"] = 359
    save("npcs.json",stats)
    enemies=json.loads((DATA/"enemies.json").read_text())
    for e in enemies["enemies"]:
        if e["id"] in ["melee_beast","ranged_beast"]:e.update(drop_chance=.05,drop_id="healing_vomit")
    save("enemies.json",enemies)
    interactions=json.loads((DATA/"interactions.json").read_text())
    interactions["door_art"]["villa_back_door"]={"frame_size":[320,420],"frames":6}
    save("interactions.json",interactions)
    for id in ["CastleOutskirts","VillaF2","VillaF3"]:
        (ROOT/"scenes"/(id+".tscn")).write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/level_base.gd" id="1"]\n\n[node name="'+id+'" type="Node2D"]\nscript = ExtResource("1")\nlevel_id = "'+id+'"\n')


if __name__ == "__main__":
    main()
