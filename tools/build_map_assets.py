#!/usr/bin/env python3
"""Repack saved image-generated backgrounds, terrain, props and effects.

No artwork is synthesized here: every output comes from a generated PNG.
Run from any directory: python tools/build_map_assets.py
"""
import json
import subprocess
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "tools/pack_sprites.py"
SOURCE = ROOT / "assets/source_art"


def pack(kind, source, output, *options):
    command = [sys.executable, str(PACK), kind, str(SOURCE / source),
               str(ROOT / "assets" / output), *options]
    subprocess.run(command, check=True)


def main():
    for name, size in [("sky", "1536,720"), ("far_city", "1920,720"),
                       ("castle_wall", "2560,720"), ("foreground", "3328,720")]:
        options = ["--size", size]
        if name == "sky":
            options.append("--opaque")
        pack("image", name + "_source.png", "backgrounds/rear_gate/" + name + ".png", *options)
    pack("image", "terrain_source.png", "tiles/rear_gate/ground_tile.png",
         "--crop", "24,92,1800,215", "--size", "512,220", "--opaque", "--tile-x")
    pack("image", "terrain_source.png", "tiles/rear_gate/step_block.png",
         "--crop", "0,418,1855,218", "--trim", "--size", "512,90")
    pack("image", "terrain_source.png", "tiles/rear_gate/platform.png",
         "--crop", "560,696,740,132", "--trim", "--size", "256,48")
    props = [
        ("rear_gate_door", "25,20,575,745", "320,420"),
        ("exit_signpost", "672,365,215,400", "160,240"),
        ("ruin_pillar_a", "905,115,265,650", "160,300"),
        ("ruin_pillar_b", "1220,305,220,460", "140,220"),
        ("rubble", "1470,535,495,230", "240,100"),
    ]
    for name, crop, size in props:
        pack("image", "props_source.png", "props/" + name + ".png",
             "--crop", crop, "--trim", "--size", size)
    pack("sheet", "fx_source.png", "sprites/enemies/ranged_beast/flame.png",
         "--crop", "0,110,1774,225", "--frames", "6", "--grid-cols", "6",
         "--frame-width", "512", "--frame-height", "256", "--anchor", "16,128",
         "--alignment", "left-center", "--fit", "480,200", "--scale-xy", "1.65,1.05")
    # Spark source poses expand and fade; retain their size variation.
    pack("sheet", "fx_source.png", "sprites/fx/hit_spark.png",
         "--crop", "0,445,1774,420", "--frames", "5", "--grid-cols", "5",
         "--frame-width", "256", "--frame-height", "256", "--anchor", "128,128",
         "--alignment", "center", "--fit", "220,220", "--scale", "0.60")
    flame = Image.open(ROOT / "assets/sprites/enemies/ranged_beast/flame.png")
    boxes = [flame.crop((i * 512, 0, (i + 1) * 512, 256)).getchannel("A").getbbox()
             for i in range(6)]
    art_size = [max(b[2] - b[0] for b in boxes), max(b[3] - b[1] for b in boxes)]
    stats_path = ROOT / "data/enemies.json"
    stats = json.loads(stats_path.read_text(encoding="utf-8"))
    for enemy in stats["enemies"]:
        if enemy["id"] == "ranged_beast":
            enemy["attacks"][0]["flame_art_size"] = art_size
    stats_path.write_text(json.dumps(stats, indent=2) + "\n", encoding="utf-8")
    provenance = {
        "generator": "image_gen.imagegen",
        "postprocess": "tools/pack_sprites.py: chromakey/crop/resize/anchor/edge-pixel blend only",
        "backgrounds": ["sky_source.png", "far_city_source.png", "castle_wall_source.png", "foreground_source.png"],
        "terrain": "terrain_source.png",
        "props": "props_source.png",
        "effects": "fx_source.png",
    }
    (SOURCE / "map_provenance.json").write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
