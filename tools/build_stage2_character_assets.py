#!/usr/bin/env python3
"""Repack preserved image-generation outputs for stage 2 character art.

All non-idle animation poses were painted by the image-generation tool.
Only NPC breathing is derived from one painted still, as explicitly allowed.
"""

import json
import tempfile
from pathlib import Path
from types import SimpleNamespace

from PIL import Image

from make_breathing_sheet import breathing_sheet
from pack_sprites import chromakey, component_poses, foreground, pack_sheet

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source_art/stage2_characters"
ASSETS = ROOT / "assets"
PREFIX = ("2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, "
          "hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, "
          "no text, no watermark")
NPCS = [
    ("lugalbanda", 1.06, "idle", 6, 2.4, "royals", 0),
    ("ninsun", 0.98, "idle", 6, 2.4, "royals", 1),
    ("shamhat", 0.96, "idle", 6, 2.4, "royals", 2),
    ("inanna", 1.00, "idle", 6, 2.4, "royals", 3),
    ("papsukkal", 1.02, "idle", 6, 2.4, "royals", 4),
    ("cook_a", 0.70, "chop", 6, 1.2, "cooks", 0),
    ("cook_b", 0.72, "stir", 6, 1.6, "cooks", 1),
    ("cook_c", 0.74, "arrange", 6, 2.0, "cooks", 2),
    ("servant_a", 0.70, "sweep", 8, 1.6, "servants_upright", 0),
    ("servant_b", 0.72, "sweep", 8, 1.6, "servants_upright", 1),
    ("gatekeeper", 0.74, "idle", 6, 2.4, "workers", 2),
]
SKY = [
    ("fly_idle", 6, 0.9, True, "sky_flight", (0, 0, 1536, 286)),
    ("windup", 4, 0.4, False, "sky_flight", (0, 289, 1536, 574)),
    ("dive", 3, 0.25, True, "sky_flight", (0, 574, 1536, 751)),
    ("recovery", 4, 0.6, False, "sky_flight", (0, 751, 1536, 1024)),
    ("turn", 4, 0.25, False, "sky_turn_death", (0, 0, 1536, 378)),
    ("hurt", 2, 0.2, False, "sky_turn_death", (0, 378, 610, 667)),
    ("death", 6, 0.8, False, "sky_turn_death", None),
]


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def clip(name, sheet, frames, duration, loop, sky=False):
    width, height = (768, 640) if sky else (640, 640)
    return {"name": name, "sheet": sheet, "frame_width": width, "frame_height": height,
            "columns": frames, "rows": 1, "frames": frames, "duration_seconds": duration,
            "fps": frames / duration, "loop": loop, "anchor_px": [384, 320] if sky else [320, 600],
            "image_size": [width * frames, height]}


def pack(poses, output, scale, sky=False):
    """Feed a normalized extraction atlas through the common PNG packer."""
    cell_width = max(pose.width for pose in poses) + 16
    cell_height = max(pose.height for pose in poses) + 16
    atlas = Image.new("RGBA", (cell_width * len(poses), cell_height))
    for index, pose in enumerate(poses):
        atlas.alpha_composite(pose, (cell_width * index + 8, 8))
    with tempfile.TemporaryDirectory(prefix="nimrod-stage2-") as temporary:
        source = Path(temporary) / "extracted.png"
        atlas.save(source)
        args = SimpleNamespace(source=source, output=output, crop=None, frames=len(poses),
                               grid_cols=len(poses), grid_rows=1, column=0, row=0,
                               reference_column=0, reference_row=0, auto_cells=False, boxes=None,
                               components=False, fit=(700, 580) if sky else (600, 590),
                               scale=scale, scale_xy=None, frame_width=768 if sky else 640,
                               frame_height=640, anchor=(384, 320) if sky else (320, 600),
                               alignment="center" if sky else "bottom-center", reverse=False,
                               flip_frames=[], cell_gap=3)
        pack_sheet(args)


def prompt(npc_id, animation, frames, duration, source, sky=False):
    text = json.loads((SOURCE / "generation_prompts.json").read_text(encoding="utf-8"))
    source_key = {"cooks": "cooks_aligned", "workers": "workers_aligned"}.get(source, source)
    folder = f"sprites/enemies/{npc_id}" if sky else f"sprites/npcs/{npc_id}"
    width, anchor = (768, "[384,320]") if sky else (640, "[320,600]")
    note = ("The generated still is packed then six subtle breathing frames are derived by "
            "tools/make_breathing_sheet.py; feet stay fixed." if animation == "idle" and not sky else
            "Every pose is painted by the image-generation tool; no cloned action frames.")
    path = ASSETS / f"image_prompts/stage2_{npc_id}_{animation}.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"# {npc_id} / {animation}\n\nPurpose: stage 2 character animation.\n\n"
                    f"Output: `assets/{folder}/{animation}.png`\n\n"
                    f"Frames: {frames} × {width}x640, one horizontal row; duration {duration}s; anchor {anchor}.\n\n"
                    "Background: request flat #FF00FF, chromakey with tools/pack_sprites.py to RGBA.\n\n"
                    f"{note}\n\nComplete generation prompt:\n\n{text[source_key]}\n", encoding="utf-8")


def main():
    images = {name: chromakey(Image.open(SOURCE / f"{name}.png")) for name in
              ("royals", "cooks", "workers", "servants_upright", "sky_flight", "sky_turn_death")}
    player = Image.open(ASSETS / "sprites/idle.png").convert("RGBA")
    player_frame = player.crop((0, 0, 640, 640))
    bounds = player_frame.getchannel("A").point(lambda value: 255 if value > 12 else 0).getbbox()
    player_height = bounds[3] - bounds[1]
    manifests = []
    provenance = {"player_height_px": player_height, "player_height_method": "idle frame 0, alpha > 12",
                  "processing": "Image-generated poses, common chromakey packer, shared scale within each action clip; NPC breathing only derived.",
                  "npcs": {}, "sky_beast": {}}
    for npc_id, ratio, animation, count, duration, source, index in NPCS:
        if source == "royals" and (ASSETS / "source_art/stage3/npc_stills_atlas.png").is_file():
            manifests.append(f"sprites/npcs/{npc_id}/manifest.json")
            continue
        if source == "royals":
            column, row = index % 3, index // 3
            bounds = (column * 418, 0 if row == 0 else 610, (column + 1) * 418, 610 if row == 0 else 1254)
            poses = [foreground(images[source].crop(bounds))[0]]
        elif source == "servants_upright":
            image = images[source]
            split = image.height // 2
            poses = component_poses(image.crop((0, index * split, image.width,
                                                image.height if index == 1 else split)), count)
        else:
            rows = [(0, 365), (365, 684), (684, 1024)] if source == "cooks" else [(0, 345), (345, 670), (670, 1024)]
            top, bottom = rows[index]
            poses = component_poses(images[source].crop((0, top, 1536, bottom)), 5 if npc_id == "gatekeeper" else count)
        target_height = round(player_height * ratio)
        scale = target_height / max(pose.height for pose in poses)
        folder = ASSETS / f"sprites/npcs/{npc_id}"
        folder.mkdir(parents=True, exist_ok=True)
        if animation == "idle":
            with tempfile.TemporaryDirectory(prefix="nimrod-idle-") as temporary:
                still = Path(temporary) / "still.png"
                pack([poses[0]], still, scale)
                breathing_sheet(still, folder / "idle.png")
        else:
            pack(poses, folder / f"{animation}.png", scale)
        clips = [clip(animation, f"sprites/npcs/{npc_id}/{animation}.png", count, duration, True)]
        prompt(npc_id, animation, count, duration, source)
        if npc_id == "gatekeeper":
            pack(poses, folder / "open_gate.png", scale)
            clips.append(clip("open_gate", f"sprites/npcs/{npc_id}/open_gate.png", 5, 0.8, False))
            prompt(npc_id, "open_gate", 5, 0.8, source)
        manifests.append(f"sprites/npcs/{npc_id}/manifest.json")
        write_json(folder / "manifest.json", {"character": npc_id, "frame_size": [640, 640],
                   "orientation": "right-facing; flip_h for left", "height_ratio": ratio,
                   "height_reference_px": player_height, "height_reference_method": "idle frame 0 alpha > 12",
                   "height_validation": "every frame alpha>12 bbox height within 3 percent of player height times height_ratio",
                   "clips": clips})
        provenance["npcs"][npc_id] = {"source": f"{source}.png", "source_row_or_cell": index,
                                      "ratio": ratio, "target_height": target_height, "shared_scale": scale}
    sky_clips = []
    for animation, count, duration, loop, source, bounds in SKY:
        if animation == "death":
            poses = component_poses(images[source].crop((0, 668, 1080, 1024)), 4)
            poses += component_poses(images[source].crop((1080, 630, 1536, 1024)), 2)
        else:
            poses = component_poses(images[source].crop(bounds), count)
        scale = min(690 / max(pose.width for pose in poses), 560 / max(pose.height for pose in poses))
        pack(poses, ASSETS / f"sprites/enemies/sky_beast/{animation}.png", scale, True)
        sky_clips.append(clip(animation, f"sprites/enemies/sky_beast/{animation}.png", count, duration, loop, True))
        prompt("sky_beast", animation, count, duration, source, True)
        provenance["sky_beast"][animation] = {"source": f"{source}.png", "crop": bounds, "shared_scale": scale}
    write_json(ASSETS / "sprites/enemies/sky_beast/manifest.json", {"character": "sky_beast",
               "frame_size": [768, 640], "orientation": "right-facing; turn frame 3 is near-symmetric frontal",
               "render": "Image-generated animation poses; chromakey, shared per-clip scale and center packing only",
               "clips": sky_clips})
    manifests.append("sprites/enemies/sky_beast/manifest.json")
    write_json(ASSETS / "stage2_character_manifest.json", {"sprite_manifests": manifests, "assets": []})
    write_json(SOURCE / "provenance.json", provenance)
    print(f"Packed 12 NPC sheets + 7 sky-beast sheets; player reference height={player_height}px")


if __name__ == "__main__":
    main()
