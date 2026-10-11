#!/usr/bin/env python3
"""Pack the eight saved image-generated Stage 2 environment atlases.

Pillow only crops/resizes existing artwork. All chromakey, alignment, sprite
packing and exact tile wrap correction run through tools/pack_sprites.py.
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

from pack_sprites import chromakey

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
SOURCE = ASSETS / "source_art/stage2_environment"
PACK = ROOT / "tools/pack_sprites.py"
STYLE = "2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark"


def run_pack(kind, source, output, *options):
    subprocess.run([sys.executable, str(PACK), kind, str(source),
                    str(ASSETS / output), *map(str, options)], check=True)


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    sources = {row["id"]: row for row in json.loads((SOURCE / "generation.json").read_text())}
    assets = []
    clips = []
    provenance = []

    def prompt(name, path, size, source_id, purpose, frames=1, opaque=False):
        text = (f"# {name}\n\n목적: {purpose}\n\n파일: `assets/{path}`\n\n"
                f"크기: {size[0]} × {size[1]}px; 프레임: {frames}, 한 줄.\n\n"
                + ("배경: 불투명.\n\n" if opaque else "배경: 생성 원본 #FF00FF → pack_sprites.py 크로마키로 투명 RGBA.\n\n")
                + f"원본: `assets/source_art/stage2_environment/{source_id}.png`\n\n"
                + f"완성 프롬프트:\n\n{sources[source_id]['prompt']}\n")
        (ASSETS / "image_prompts" / f"stage2_{name}.md").write_text(text, encoding="utf-8")

    with tempfile.TemporaryDirectory(prefix="nimrod-stage2-art-") as temporary:
        temporary = Path(temporary)

        def single(name, source_id, crop, path, size, opaque=False, trim=False,
                   floor_y=None, tile=False, ratio=None, map_width=None):
            source = SOURCE / f"{source_id}.png"
            options = ["--size", f"{size[0]},{size[1]}"]
            if floor_y is not None:
                # Move the already-painted walkable ledge to y=620. The two
                # regions remain original pixels, resized independently.
                x, y, width, height = crop
                raw = Image.open(source).convert("RGBA").crop((x, y, x + width, y + height))
                upper = raw.crop((0, 0, width, floor_y)).resize((size[0], 620), Image.Resampling.LANCZOS)
                lower = raw.crop((0, floor_y, width, height)).resize((size[0], 100), Image.Resampling.LANCZOS)
                combined = Image.new("RGBA", size)
                combined.paste(upper, (0, 0))
                combined.paste(lower, (0, 620))
                source = temporary / f"{name}.png"
                combined.save(source)
            else:
                options += ["--crop", ",".join(map(str, crop))]
            if opaque:
                options.append("--opaque")
            if trim:
                options.append("--trim")
            if tile:
                options.append("--tile-x")
            run_pack("image", source, path, *options)
            entry = dict(name=name, path=path, width=size[0], height=size[1], transparent=not opaque)
            if ratio is not None:
                entry.update(scroll_ratio=ratio, map_width=map_width)
            if tile:
                entry["tile_x"] = True
            assets.append(entry)
            provenance.append(dict(path=path, source=source_id + ".png", crop=crop,
                                   floor_y_source=floor_y, floor_y_output=620 if floor_y else None))
            prompt(name, path, size, source_id, "2단계 레벨의 생성 이미지 배경·지형·소품", opaque=opaque)

        for index, (name, width, ratio) in enumerate([
            ("sky", 1536, .05), ("far_city", 2112, .20),
            ("castle_wall", 3136, .45),
        ]):
            top, bottom = round(index * 1254 / 4), round((index + 1) * 1254 / 4)
            single("rear_gate_" + name, "rear_layers", [0, top, 1254, bottom - top],
                   "backgrounds/rear_gate/" + name + ".png", (width, 720),
                   opaque=index == 0, ratio=ratio, map_width=5400)

        # The original symmetric mansion doorway is at its horizontal center.
        # Trim empty magenta margins so its base aligns with the map's floor.
        single("villa_exterior", "villa_exterior", [0, 0, 1774, 887],
               "backgrounds/rear_gate/villa_exterior.webp", (1500, 720), trim=True)

        for name, width, top, bottom, floor in [
            ("castle_f1_hall", 2000, 0, 307, 252),
            ("castle_f2_sanctum", 1800, 307, 629, 576),
            ("castle_f3_kitchen", 1800, 629, 917, 865),
            ("castle_f4_boudoir", 1800, 917, 1254, 1164),
        ]:
            single(name, "castle_interiors", [0, top, 1254, bottom - top],
                   "backgrounds/castle/" + name + ".png", (width, 720),
                   opaque=True, floor_y=floor - top)

        single("villa_f1_hall", "villa_rooftop", [0, 0, 1254, 312],
               "backgrounds/villa/villa_f1_hall.png", (2000, 720), opaque=True, floor_y=250)
        single("castle_f5_sky", "villa_rooftop", [0, 313, 1254, 314],
               "backgrounds/castle/castle_f5_sky.webp", (1536, 720), opaque=True, ratio=.05, map_width=2400)
        single("castle_f5_far", "villa_rooftop", [0, 627, 1254, 314],
               "backgrounds/castle/castle_f5_far.webp", (1664, 720), ratio=.20, map_width=2400)
        single("castle_f5_terrace", "villa_rooftop", [0, 941, 1254, 313],
               "backgrounds/castle/castle_f5_terrace.webp", (2400, 720), floor_y=244)

        for name, crop in [
            ("floor_tile", [12, 88, 1424, 258]),
            ("balcony_floor_tile", [12, 435, 1424, 259]),
            ("villa_floor_tile", [12, 766, 1424, 272]),
        ]:
            single(name, "tiles", crop, "tiles/castle/" + name + ".png", (512, 180), opaque=True, tile=True)

        for name, crop, size, folder in [
            ("castle_pillar", [0, 0, 384, 420], (140, 300), "props"),
            ("castle_banner", [384, 0, 384, 420], (190, 280), "props"),
            ("brazier", [768, 0, 320, 420], (160, 220), "props"),
            ("kitchen_prep_table", [1088, 0, 448, 420], (260, 150), "props"),
            ("kitchen_stove", [0, 420, 384, 330], (230, 180), "props"),
            ("kitchen_dining_table", [384, 420, 420, 330], (300, 150), "props"),
            ("villa_vase", [804, 420, 250, 330], (140, 220), "props"),
            ("villa_rug", [1054, 420, 482, 330], (320, 100), "props"),
            ("healing_vomit", [0, 760, 384, 264], (128, 96), "props"),
            ("prompt_e", [384, 760, 300, 264], (64, 64), "ui"),
        ]:
            single(name, "props_atlas", crop, folder + "/" + name + ".png", size, trim=True)

        def door(name, source_id, crop, columns, frames, size, duration):
            raw = Image.open(SOURCE / (source_id + ".png")).convert("RGBA")
            x, y, width, height = crop
            row = raw.crop((x, y, x + width, y + height))
            # Door architecture is normalized to a common frame extent before
            # packing, preserving every independently generated hinge pose.
            keyed = chromakey(row)
            boxes = [(round(i * width / columns), 0, round((i + 1) * width / columns), height)
                     for i in range(frames)]
            bounds = [keyed.crop(box).getchannel("A").getbbox() for box in boxes]
            max_width = max(bound[2] - bound[0] for bound in bounds)
            max_height = max(bound[3] - bound[1] for bound in bounds)
            scale_x, scale_y = (size[0] - 12) / max_width, (size[1] - 12) / max_height
            normalized = Image.new("RGBA", (frames * size[0], size[1]), (255, 0, 255, 255))
            for index, (box, bound) in enumerate(zip(boxes, bounds)):
                pose = row.crop(box).crop(bound)
                pose = pose.resize((round(pose.width * scale_x), round(pose.height * scale_y)), Image.Resampling.LANCZOS)
                normalized.paste(pose, (index * size[0] + round((size[0] - pose.width) / 2), size[1] - pose.height))
            source = temporary / (name + ".png")
            normalized.save(source)
            path = "props/doors/" + name + ".png"
            run_pack("sheet", source, path, "--grid-cols", frames, "--frames", frames,
                     "--frame-width", size[0], "--frame-height", size[1],
                     "--anchor", f"{size[0] // 2},{size[1]}", "--scale", "1")
            clips.append(dict(name=name, sheet=path, frame_width=size[0], frame_height=size[1],
                              columns=frames, rows=1, frames=frames, duration_seconds=duration,
                              fps=frames / duration, loop=False, anchor_px=[size[0] // 2, size[1]],
                              image_size=[size[0] * frames, size[1]]))
            provenance.append(dict(path=path, source=source_id + ".png", crop=crop, columns=columns,
                                   frames=frames, frame_size=size, artwork_scale_xy=[scale_x, scale_y]))
            prompt(name, path, size, source_id, "문 열림; 첫 프레임 완전 닫힘, 마지막 프레임 완전 열림. 닫힘은 역재생.", frames)

        door("castle_rear_door_exterior", "door_castle", [0, 0, 1254, 410], 6, 6, (320, 420), .6)
        door("castle_interior_door", "door_castle", [0, 410, 1254, 390], 6, 6, (256, 384), .6)
        door("castle_rear_door_interior", "door_castle", [0, 800, 1254, 454], 6, 6, (320, 420), .6)
        door("villa_gate", "door_villa", [0, 0, 1254, 450], 8, 8, (480, 420), 1.)
        door("villa_inner_door", "door_villa", [0, 450, 1254, 320], 8, 6, (256, 384), .6)
        door("castle_front_gate_locked", "door_villa", [0, 780, 320, 474], 1, 1, (320, 420), .6)

    write_json(ASSETS / "props/doors/manifest.json", {"clips": clips})
    write_json(ASSETS / "stage2_environment_manifest.json", {
        "schema_version": 1,
        "source_policy": "All artwork image-generated; only crop/resize/chromakey/anchor/packing/wrap blending postprocess.",
        "sprite_manifests": ["props/doors/manifest.json"], "assets": assets,
        "source_metadata": ["source_art/stage2_environment/generation.json", "source_art/stage2_environment/packing.json"],
    })
    write_json(SOURCE / "packing.json", provenance)
    print(f"Stage 2 environment complete: {len(assets)} static PNGs + {len(clips)} door sheets.")


if __name__ == "__main__":
    main()
