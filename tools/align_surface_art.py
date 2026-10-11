#!/usr/bin/env python3
"""Align existing generated art by cropping its support span; never draw new art.

The original PNG is retained so the operation is repeatable after asset rebuilds.
Run --check to check that the deployed images match the preserved source crops.
"""
import argparse
import json
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    config = json.loads((ROOT / 'data/surface_art_alignment.json').read_text())
    for entry in config['assets']:
        target = ROOT / entry['path']
        source = ROOT / 'assets/source_art/surface_alignment' / Path(entry['path']).relative_to('assets')
        if not source.exists():
            assert not args.check, f'Missing preserved source: {source}'
            source.parent.mkdir(parents=True, exist_ok=True)
            source.write_bytes(target.read_bytes())
        original = Image.open(source).convert('RGBA')
        x, y, width, height = entry['source_region']
        aligned = original.crop((x, y, x + width, y + height)).resize(original.size, Image.Resampling.LANCZOS)
        if entry.get('tile_x'):
            pixels = np.asarray(aligned, dtype=np.float32).copy()
            band = int(entry['tile_x'])
            left, right = pixels[:, :band].copy(), pixels[:, -band:][:, ::-1].copy()
            weights = np.linspace(1, 0, band, dtype=np.float32)[None, :, None]
            shared = (left + right) / 2
            pixels[:, :band] = left * (1 - weights) + shared * weights
            pixels[:, -band:] = (right * (1 - weights) + shared * weights)[:, ::-1]
            pixels = np.rint(pixels).astype(np.uint8)
            pixels[:, -1] = pixels[:, 0]
            aligned = Image.fromarray(pixels)
        if args.check:
            actual = Image.open(target).convert('RGBA')
            assert actual.size == original.size and actual.tobytes() == aligned.tobytes(), entry['path']
        else:
            aligned.save(target)
        alpha = aligned.getchannel('A')
        coverage = sum(v > config['alpha_threshold'] for v in alpha.crop((0, aligned.height - 1 if entry.get("edge") == "bottom" else 0, aligned.width, aligned.height if entry.get("edge") == "bottom" else 1)).tobytes()) / aligned.width
        assert coverage >= entry.get('minimum_edge_coverage', config['minimum_top_coverage']), (entry['path'], coverage)
        print(f"SURFACE_ART {entry['path']}: support span {coverage:.1%}, original size retained")

if __name__ == '__main__':
    main()
