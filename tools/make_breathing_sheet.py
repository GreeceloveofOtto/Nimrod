#!/usr/bin/env python3
"""Derive subtle breathing from one image-generated pose; never paint new art.

The feet/lower body stay untouched. A chest band stretches vertically by at
most 2%; the generated head/shoulders move up by 1–2 px with that band.
"""

import argparse
from pathlib import Path

from PIL import Image


def breathing_sheet(source, output, frame_count=6):
    original = Image.open(source).convert("RGBA")
    if original.size != (640, 640):
        raise ValueError("A packed 640x640 reference pose is required")
    bounds = original.getchannel("A").point(lambda value: 255 if value > 12 else 0).getbbox()
    if not bounds:
        raise ValueError("Reference pose is empty")
    height = bounds[3] - bounds[1]
    shoulder = bounds[1] + round(height * 0.19)
    waist = bounds[1] + round(height * 0.53)
    band_height = waist - shoulder
    # Nonidentical subpixel chest motion also survives small Toin silhouettes.
    phases = (0.0, 0.35, 0.85, 1.0, 0.65, 0.2)
    if frame_count != len(phases):
        raise ValueError("The specified breathing clip has six frames")
    result = Image.new("RGBA", (640 * frame_count, 640))
    for index, amount in enumerate(phases):
        scale = 1.0 + 0.02 * amount
        rise = min(2.0, band_height * (scale - 1.0))
        frame = Image.new("RGBA", (640, 640))
        # Affine sampling moves only the original painted pixels; the lower
        # body remains byte-identical, with feet fixed at [320,600].
        upper = original.crop((0, 0, 640, shoulder))
        upper = upper.transform((640, shoulder), Image.Transform.AFFINE,
                                (1, 0, 0, 0, 1, rise), Image.Resampling.BICUBIC)
        frame.alpha_composite(upper, (0, 0))
        chest = original.transform((640, waist), Image.Transform.AFFINE,
                                   (1, 0, 0, 0, 1 / scale, waist * (1 - 1 / scale)),
                                   Image.Resampling.BICUBIC)
        # The chest selection includes the shifted shoulder edge so there
        # is no transparent seam between the moving head and torso.
        top = max(0, shoulder - 3)
        frame.alpha_composite(chest.crop((0, top, 640, waist)), (0, top))
        frame.alpha_composite(original.crop((0, waist, 640, 640)), (0, waist))
        result.alpha_composite(frame, (640 * index, 0))
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    result.save(output, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    breathing_sheet(args.source, args.output)


if __name__ == "__main__":
    main()
