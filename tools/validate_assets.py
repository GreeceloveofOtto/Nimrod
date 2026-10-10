#!/usr/bin/env python3
"""Validate generated PNG sheets and rear-gate art against their manifests.

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

    def validate_clip(self, clip, enemy=False):
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
        if enemy and (width != 640 or height != 640 or anchor != [320, 600]):
            self.fail(path, "enemy frame must be 640x640 with anchor [320,600]")
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
            elif enemy:
                center_x = (bounds[0] + bounds[2]) / 2
                if abs(center_x - anchor[0]) > 4 or abs(bounds[3] - anchor[1]) > 4:
                    self.fail(path, f"frame {index + 1} not aligned to bottom-center anchor: {bounds}")
            current = frame.tobytes()
            if previous is not None and current == previous:
                self.fail(path, f"frame {index + 1} duplicates previous frame; animation poses required")
            previous = current

    def run(self):
        manifest = self.read_json("art_manifest.json")
        if manifest is None:
            return
        for relative in manifest["sprite_manifests"]:
            sprite = self.read_json(relative)
            if sprite is None:
                continue
            enemy = "/enemies/" in relative
            for clip in sprite.get("clips", []):
                self.validate_clip(clip, enemy)
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
            if ratio is not None and entry["width"] < 1280 + 2320 * ratio:
                self.fail(entry["path"], "image width insufficient for 3600px map parallax travel")
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
