#!/usr/bin/env python3
"""Validate generated PNG sheets, NPC proportions and level art manifests.

Missing assets fail by default. --allow-missing reports them as SKIPPED and
returns success only when every present asset is valid; it does not certify
that the project has complete final art.
"""

import argparse
import json
import math
from pathlib import Path

from PIL import Image


class Validator:
    def __init__(self, root, allow_missing):
        self.root = root
        self.assets = root / "assets"
        self.allow_missing = allow_missing
        self.errors = []
        self.missing = []
        self.checked = 0
        self.npc_data = {}
        self.player_height = None

    def fail(self, path, message):
        self.errors.append(f"{path}: {message}")

    def read_json(self, relative):
        path = self.assets / relative
        if not path.is_file():
            self.fail(relative, "manifest missing")
            return None
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            self.fail(relative, f"invalid manifest: {error}")
            return None

    def open_png(self, relative, size, transparent):
        path = self.assets / relative
        if not path.is_file():
            self.missing.append(relative)
            if not self.allow_missing:
                self.fail(relative, "required generated PNG missing")
            return None
        try:
            image = Image.open(path)
            image.load()
        except OSError as error:
            self.fail(relative, f"cannot load PNG: {error}")
            return None
        self.checked += 1
        if image.format != "PNG":
            self.fail(relative, f"format must be PNG, found {image.format}")
        if image.size != tuple(size):
            self.fail(relative, f"size {image.size}, expected {tuple(size)}")
        if image.mode != "RGBA":
            self.fail(relative, f"RGBA required, found {image.mode}")
            return None
        alpha_min, alpha_max = image.getchannel("A").getextrema()
        if alpha_max == 0:
            self.fail(relative, "image has no visible pixels")
        if transparent and alpha_min == 255:
            self.fail(relative, "transparent background required but alpha is fully opaque")
        if not transparent and alpha_min != 255:
            self.fail(relative, "opaque image required but nonopaque pixels found")
        return image

    def validate_clip(self, clip, enemy=False, sky=False, npc=None):
        required = {"name", "sheet", "frame_width", "frame_height", "columns", "rows", "frames",
                    "duration_seconds", "fps", "loop", "anchor_px", "image_size"}
        if required - clip.keys():
            self.fail(str(clip.get("name", "unnamed clip")), f"missing fields {sorted(required - clip.keys())}")
            return
        path = clip["sheet"]
        width, height = clip["frame_width"], clip["frame_height"]
        frames, columns, rows = clip["frames"], clip["columns"], clip["rows"]
        if not all(isinstance(value, int) and value > 0 for value in (width, height, frames, columns, rows)):
            self.fail(path, "frame dimensions/counts must be positive integers")
            return
        if rows != 1 or columns != frames:
            self.fail(path, "one horizontal row with columns == frames required")
        expected_size = [width * columns, height * rows]
        if clip["image_size"] != expected_size:
            self.fail(path, f"manifest image_size must equal {expected_size}")
        duration = clip["duration_seconds"]
        if duration <= 0 or not math.isclose(clip["fps"], frames / duration, rel_tol=1e-7):
            self.fail(path, "fps must equal frames / duration_seconds")
        anchor = clip["anchor_px"]
        if len(anchor) != 2 or not (0 <= anchor[0] <= width and 0 <= anchor[1] <= height):
            self.fail(path, "anchor must lie inside frame")
        if sky:
            if (width, height, anchor) != (768, 640, [384, 320]):
                self.fail(path, "sky-beast frame must be 768x640 with center anchor [384,320]")
        elif (enemy or npc is not None) and (width != 640 or height != 640 or anchor != [320, 600]):
            self.fail(path, "ground enemy/NPC frame must be 640x640 with anchor [320,600]")
        if clip["name"] == "turn" and (frames < 3 or clip["loop"]):
            self.fail(path, "turn requires at least 3 frames and must not loop")
        image = self.open_png(path, expected_size, True)
        if image is None or image.size != tuple(expected_size):
            return
        previous = None
        for index in range(frames):
            frame = image.crop((index * width, 0, (index + 1) * width, height))
            alpha = frame.getchannel("A")
            bounds = alpha.point(lambda value: 255 if value > 12 else 0).getbbox()
            if bounds is None:
                self.fail(path, f"frame {index + 1} is empty")
            elif sky:
                center_x = (bounds[0] + bounds[2]) / 2
                center_y = (bounds[1] + bounds[3]) / 2
                if abs(center_x - anchor[0]) > 4 or abs(center_y - anchor[1]) > 4:
                    self.fail(path, f"frame {index + 1} not aligned to center anchor: {bounds}")
                if bounds[2] - bounds[0] > 700:
                    self.fail(path, f"frame {index + 1} exceeds 700px maximum wing span")
            elif enemy or npc is not None:
                center_x = (bounds[0] + bounds[2]) / 2
                if abs(center_x - anchor[0]) > 4 or abs(bounds[3] - anchor[1]) > 4:
                    self.fail(path, f"frame {index + 1} not aligned to bottom-center anchor: {bounds}")
            if bounds is not None and npc is not None and self.player_height is not None:
                measured_height = bounds[3] - bounds[1]
                expected_height = self.player_height * npc["height_ratio"]
                if abs(measured_height - expected_height) > expected_height * 0.03:
                    self.fail(path, f"frame {index + 1} NPC height {measured_height}px outside ±3% of "
                              f"{self.player_height} × {npc['height_ratio']} = {expected_height:.2f}px")
            current = frame.tobytes()
            if previous is not None and current == previous:
                self.fail(path, f"frame {index + 1} duplicates previous frame; animation poses required")
            previous = current

    def run(self):
        manifest = self.read_json("art_manifest.json")
        if manifest is None:
            return
        npc_path = self.root / "data/npcs.json"
        if npc_path.is_file():
            npc_config = json.loads(npc_path.read_text(encoding="utf-8"))
            self.npc_data = {entry["id"]: entry for entry in npc_config["npcs"]}
            player = Image.open(self.assets / "sprites/idle.png").convert("RGBA")
            player_frame = player.crop((0, 0, 640, 640))
            bounds = player_frame.getchannel("A").point(lambda value: 255 if value > 12 else 0).getbbox()
            if bounds is None:
                self.fail("sprites/idle.png", "player reference frame is empty")
            else:
                self.player_height = bounds[3] - bounds[1]
                print(f"NPC height reference: player idle frame 0, alpha > 12, H_p={self.player_height}px; every frame ±3%.")
        for relative in manifest["sprite_manifests"]:
            sprite = self.read_json(relative)
            if sprite is None:
                continue
            enemy = "/enemies/" in relative
            sky = "/sky_beast/" in relative
            npc = None
            if "/npcs/" in relative:
                npc_id = sprite.get("character", Path(relative).parent.name)
                npc = self.npc_data.get(npc_id)
                if npc is None:
                    self.fail(relative, f"NPC {npc_id} not registered in data/npcs.json")
                elif not math.isclose(sprite.get("height_ratio", -1), npc["height_ratio"]):
                    self.fail(relative, "height_ratio differs from data/npcs.json")
                else:
                    expected_clips = {item["name"]: item for item in npc["clips"]}
                    actual_clips = {item["name"]: item for item in sprite.get("clips", [])}
                    if expected_clips.keys() != actual_clips.keys():
                        self.fail(relative, "clip names differ from data/npcs.json")
                    for name, expected in expected_clips.items():
                        actual = actual_clips.get(name)
                        if actual and (actual["frames"] != expected["frames"] or
                                       actual["loop"] != expected["loop"] or
                                       not math.isclose(actual["duration_seconds"], expected["duration"])):
                            self.fail(relative, f"clip {name} count/loop/duration differs from data/npcs.json")
            for clip in sprite.get("clips", []):
                self.validate_clip(clip, enemy, sky, npc)
            for effect in sprite.get("effects", []):
                self.validate_clip(effect)
        for entry in manifest["assets"]:
            image = self.open_png(entry["path"], [entry["width"], entry["height"]], entry["transparent"])
            if image is not None and entry.get("tile_x"):
                first = image.crop((0, 0, 1, image.height)).tobytes()
                last = image.crop((image.width - 1, 0, image.width, image.height)).tobytes()
                if first != last:
                    self.fail(entry["path"], "tile_x requires matching first/last RGBA columns; repack with --tile-x")
            ratio = entry.get("scroll_ratio")
            map_width = entry.get("map_width", 3600)
            if ratio is not None and entry["width"] < 1280 + max(0, map_width - 1280) * ratio:
                self.fail(entry["path"], f"image width insufficient for {map_width}px map parallax travel")
        for relative in self.missing:
            if self.allow_missing:
                print(f"SKIPPED (MISSING_TEXTURE fallback required): assets/{relative}")
        for error in self.errors:
            print(f"ERROR: {error}")
        print(f"Checked {self.checked} PNG files; missing {len(self.missing)}; errors {len(self.errors)}.")
        if not self.errors and not self.missing:
            print("PASS: all required sheets and map assets match their manifests.")
        elif not self.errors and self.allow_missing:
            print("PARTIAL PASS: present assets valid; missing assets are not final art.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--allow-missing", action="store_true")
    args = parser.parse_args()
    validator = Validator(args.root.resolve(), args.allow_missing)
    try:
        validator.run()
    except (KeyError, TypeError, ValueError) as error:
        validator.fail("manifest", str(error))
        print(f"ERROR: malformed manifest: {error}")
    return 1 if validator.errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
