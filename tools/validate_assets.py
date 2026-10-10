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
                measured_height *= npc.get("visual_scale_multiplier", 1.0)
                if abs(measured_height - expected_height) > expected_height * 0.03:
                    self.fail(path, f"frame {index + 1} NPC height {measured_height}px outside ±3% of "
                              f"{self.player_height} × {npc['height_ratio']} = {expected_height:.2f}px (render multiplier applied)")
            current = frame.tobytes()
            if previous is not None and current == previous:
                self.fail(path, f"frame {index + 1} duplicates previous frame; animation poses required")
            previous = current

    def check_npc_contrast(self):
        """Warn on average sprite/background luminance difference below 30.

        This estimates the local background after bg_dim; it excludes props,
        shadow/light-pool and proximity highlight so warnings remain conservative.
        """
        import numpy as np
        registry = json.loads((self.root / "data/levels.json").read_text())
        warnings = 0
        for level in registry["levels"]:
            for placement in level.get("npcs", []):
                npc = self.npc_data.get(placement["id"])
                if npc is None:
                    continue
                folder = self.root / npc["sheet_dir"]
                sheet = folder / (placement.get("idle_clip", npc["clips"][0]["name"]) + ".png")
                if not sheet.is_file():
                    continue
                frame = Image.open(sheet).convert("RGBA").crop((0, 0, 640, 640))
                pixels = np.asarray(frame)
                mask = pixels[..., 3] > 128
                if not mask.any():
                    continue
                npc_luma = float((pixels[..., :3] @ np.array([0.2126, 0.7152, 0.0722]))[mask].mean())
                bounds = frame.getchannel("A").point(lambda a: 255 if a > 12 else 0).getbbox()
                scale = registry.get("npc_visual_scale", 0.30) * npc.get("visual_scale_multiplier", 1.0)
                width, height = (bounds[2]-bounds[0])*scale, (bounds[3]-bounds[1])*scale
                x, y = placement["position"]
                camera_x = max(0, min(x-640, level["width"]-1280))
                background = None
                bg_entries = sorted(level["backgrounds"], key=lambda b: b.get("z", 0), reverse=True)
                for entry in bg_entries:
                    if entry.get("z", 0) >= 0:
                        continue
                    ratio = entry.get("ratio", 1)
                    left = x-camera_x+camera_x*ratio-entry["position"][0]-width/2
                    camera_y = max(0, level["camera_limits"][3]-720) if ratio != 1 else 0
                    top = y-camera_y-entry["position"][1]-height
                    if 0 <= left and left+width <= entry["size"][0] and 0 <= top and top+height <= entry["size"][1]:
                        path = self.root / entry["path"].replace("res://", "")
                        if not path.is_file():
                            continue
                        image = Image.open(path).convert("RGBA").resize(tuple(entry["size"]))
                        crop = np.asarray(image.crop((round(left),round(top),round(left+width),round(top+height))))
                        visible = crop[...,3] > 128
                        if visible.any():
                            background = crop[...,:3][visible].astype(float)
                            break
                if background is None:
                    continue
                dim = np.array(level.get("bg_dim", [0.80,0.80,0.84]))
                bg_luma = float((background*dim @ np.array([0.2126,0.7152,0.0722])).mean())
                difference = abs(npc_luma-bg_luma)
                print(f"CONTRAST {level['id']}/{npc['id']}: NPC {npc_luma:.1f}, BG {bg_luma:.1f}, difference {difference:.1f}")
                if difference < 30:
                    warnings += 1
                    print(f"WARNING: NPC contrast below 30: {level['id']}/{npc['id']}")
        print(f"NPC contrast warnings: {warnings} (non-failing; light pools/highlights excluded)")

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
                elif not math.isclose(sprite.get("height_ratio", -1), npc.get("source_height_ratio", npc["height_ratio"])):
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
                import numpy as np
                pixels = np.asarray(image)
                key_color = (pixels[..., 0] > 220) & (pixels[..., 1] < 60) & (pixels[..., 2] > 220)
                if key_color.any():
                    self.fail(entry["path"], "opaque tile contains magenta key-color margins; crop the generated source")
                first = image.crop((0, 0, 1, image.height)).tobytes()
                last = image.crop((image.width - 1, 0, image.width, image.height)).tobytes()
                if first != last:
                    self.fail(entry["path"], "tile_x requires matching first/last RGBA columns; repack with --tile-x")
            ratio = entry.get("scroll_ratio")
            map_width = entry.get("map_width", 3600)
            if ratio is not None and entry["width"] < 1280 + max(0, map_width - 1280) * ratio:
                self.fail(entry["path"], f"image width insufficient for {map_width}px map parallax travel")
        self.check_npc_contrast()
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
