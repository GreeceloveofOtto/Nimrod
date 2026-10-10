#!/usr/bin/env python3
"""Join generated panorama sections by crossfading existing overlap pixels.

This utility never synthesizes artwork. Input panels must already be generated
PNG images, ordered left to right. Optional chromakey uses pack_sprites.py.
"""
import argparse
from pathlib import Path

from PIL import Image

from pack_sprites import chromakey


def stitch(paths, overlap, key=False):
    images = [Image.open(path).convert("RGBA") for path in paths]
    if key:
        images = [chromakey(image) for image in images]
    if not images or len({image.height for image in images}) != 1:
        raise ValueError("At least one PNG is required; panels must have the same height")
    if overlap < 0 or any(overlap >= image.width for image in images):
        raise ValueError("Overlap must be nonnegative and narrower than every panel")
    result = images[0]
    for panel in images[1:]:
        merged = Image.new("RGBA", (result.width + panel.width - overlap, result.height))
        merged.paste(result, (0, 0))
        merged.paste(panel, (result.width - overlap, 0))
        for index in range(overlap):
            left = result.crop((result.width - overlap + index, 0, result.width - overlap + index + 1, result.height))
            right = panel.crop((index, 0, index + 1, panel.height))
            mixed = Image.blend(left, right, (index + 1) / (overlap + 1))
            merged.paste(mixed, (result.width - overlap + index, 0))
        result = merged
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("inputs", nargs="+", type=Path)
    parser.add_argument("--overlap", type=int, default=64)
    parser.add_argument("--chromakey", action="store_true")
    args = parser.parse_args()
    result = stitch(args.inputs, args.overlap, args.chromakey)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    result.save(args.output, optimize=True)
    print(f"Saved {args.output}: {result.width}x{result.height}")


if __name__ == "__main__":
    main()
