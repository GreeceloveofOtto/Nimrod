#!/usr/bin/env python3
"""Repack the checked-in image-generated beast atlases without drawing art.

The image model emitted seven melee bands instead of eight. Recovery uses the
generated lowering poses in reverse, yielding a rising motion. Every other
clip uses its own generated poses. Connected-component extraction retains
each existing painted creature when adjacent poses overlap horizontally.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

if __package__:
    from .pack_sprites import chromakey, component_poses, foreground
else:
    from pack_sprites import chromakey, component_poses, foreground


ROOT = Path(__file__).resolve().parents[1]
SPECS = {
    "melee_beast": {
        "source": "melee_atlas.png",
        "fit": [460, 300],
        "bands": [
            ["idle", 0, 160, 6, False],
            ["walk", 160, 175, 8, False],
            ["windup", 335, 153, 4, False],
            ["attack", 488, 154, 3, False],
            ["recovery", 335, 153, 4, True],
            ["turn", 642, 155, 4, False],
            ["hurt", 797, 188, 2, False],
            ["death", 985, 147, 6, False],
        ],
    },
    "ranged_beast": {
        "source": "ranged_atlas.png",
        "fit": [440, 600],
        "bands": [
            ["idle", 0, 194, 6, False],
            ["walk", 194, 168, 8, False],
            ["windup", 362, 185, 4, False],
            ["flame_loop", 0, 455, 4, False],
            ["recovery", 655, 163, 4, False],
            ["turn", 818, 165, 4, False],
            ["hurt", 978, 152, 2, False],
            ["death", 455, 338, 6, False],
        ],
        "boxes": {
            "hurt": [[435, 978, 140, 152], [621, 978, 160, 152]],
        },
        "sources": {"flame_loop": "ranged_compact_atlas.png", "death": "ranged_compact_atlas.png"},
        # Alternate source was generated at larger raw resolution. Normalize
        # its torso/leg scale once for the whole source, not frame by frame.
        "source_scales": {"ranged_compact_atlas.png": 0.56},
        "flip_frames": {"turn": [1]},
    },
}


def pose_candidates(image, spec, clip, y, height, frames):
    boxes = spec.get("boxes", {}).get(clip)
    if boxes:
        return [foreground(chromakey(image.crop((x, top, x + width, top + high))))[0]
                for x, top, width, high in boxes]
    band = chromakey(image.crop((0, y, image.width, y + height)))
    return component_poses(band, frames)


def source_for(spec, clip):
    filename = spec.get("sources", {}).get(clip, spec["source"])
    return ROOT / "assets/source_art" / filename, spec.get("source_scales", {}).get(filename, 1.0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--beast", choices=list(SPECS), help="Build only one beast; default both")
    parser.add_argument("--skip-clips", type=lambda value: set(value.split(",")), default=set(),
                        help="Temporary partial build; excluded clips do not affect shared scale")
    args = parser.parse_args()
    for name, spec in SPECS.items():
        if args.beast and args.beast != name:
            continue
        source = ROOT / "assets/source_art" / spec["source"]
        if not source.is_file():
            raise SystemExit(f"Missing original image-generated source: {source}")
        with Image.open(source) as image:
            width = image.width
            _, y, height, frames, _ = spec["bands"][0]
            idle_poses = pose_candidates(image, spec, "idle", y, height, frames)
            all_pose_bounds = []
            for clip, band_y, band_height, band_frames, _ in spec["bands"]:
                if clip in args.skip_clips:
                    continue
                clip_source, source_scale = source_for(spec, clip)
                with Image.open(clip_source) as clip_image:
                    all_pose_bounds.extend((pose.width * source_scale, pose.height * source_scale)
                                           for pose in pose_candidates(clip_image, spec, clip, band_y, band_height, band_frames))
        reference, _ = foreground(idle_poses[0])
        reference_scale = min(spec["fit"][0] / reference.width, spec["fit"][1] / reference.height)
        # Keep one uniform scale even when a generated hurt/attack pose extends
        # farther than idle. Never clip a horn/neck or shrink individual poses.
        scale = min(reference_scale, 620 / max(size[0] for size in all_pose_bounds),
                    600 / max(size[1] for size in all_pose_bounds))
        print(json.dumps({"beast": name, "shared_scale": scale, "reference_scale": reference_scale,
                          "reference_bounds": list(reference.size)}), flush=True)
        for clip, y, height, frames, reverse in spec["bands"]:
            if clip in args.skip_clips:
                continue
            output = ROOT / "assets/sprites/enemies" / name / f"{clip}.png"
            clip_source, source_scale = source_for(spec, clip)
            with Image.open(clip_source) as clip_image:
                clip_width = clip_image.width
            command = [sys.executable, str(ROOT / "tools/pack_sprites.py"), "sheet", str(clip_source), str(output),
                       "--frames", str(frames), "--fit", ",".join(map(str, spec["fit"])), "--scale", str(scale * source_scale)]
            boxes = spec.get("boxes", {}).get(clip)
            if boxes:
                command.extend(["--boxes", json.dumps(boxes)])
            else:
                command.extend(["--crop", f"0,{y},{clip_width},{height}", "--components"])
            if reverse:
                command.append("--reverse")
            flip_frames = spec.get("flip_frames", {}).get(clip)
            if flip_frames:
                command.extend(["--flip-frames", ",".join(map(str, flip_frames))])
            subprocess.run(command, check=True, cwd=ROOT)


if __name__ == "__main__":
    main()
