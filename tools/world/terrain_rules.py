#!/usr/bin/env python3
"""Structural measurements for the carved terrain; no geometry is generated here."""
from pathlib import Path
import argparse, collections, json
import numpy as np
from scipy.ndimage import label, minimum_filter

ROOT = Path(__file__).resolve().parents[2]
SOLID = '#W^F'
TARGETS = {'landing': (40, 50), 'forest': (50, 60), 'marsh': (55, 65),
           'mine': (55, 65), 'fortress': (45, 55), 'village': (40, 50),
           'ridge': (30, 45), 'skywalk': (25, 40), 'deep': (60, 70), 'crystal': (50, 60)}


def decode(row):
    if isinstance(row, list):
        return ''.join(c * n for c, n in row)
    import re
    parts = re.findall(r'(\d+)([.#W=:\^F~])', row)
    assert ''.join(str(n) + c for n, c in parts) == row, row
    return ''.join(c * int(n) for n, c in parts)


def load_world(base=ROOT / 'data/world/zabulistan'):
    w = json.loads((base / 'world_v2.json').read_text())
    entities, pieces, decor = [], [], []
    rows = [list('#' * w['width']) for _ in range(w['height'])]
    for path in w['chunks'].values():
        data = json.loads((ROOT / path.removeprefix('res://')).read_text())
        x, y = data['coord'][0] * 64, data['coord'][1] * 36
        for dy, runs in enumerate(data['rle']):
            rows[y + dy][x:x + 64] = decode(runs)
        entities.extend(data['entities'])
        pieces.extend(data['landmarks'])
        decor.extend(data.get('decor', []))
    w['navigation'] = [''.join(row) for row in rows]
    return w, entities, pieces, decor


def window_counts(mask, width=40, height=22):
    sums = np.pad(mask.astype(np.int32), ((1, 0), (1, 0))).cumsum(0).cumsum(1)
    return sums[height:, width:] - sums[:-height, width:] - sums[height:, :-width] + sums[:-height, :-width]


def measure(w, entities, decor, region_id=None):
    rows = w['navigation']; a = np.array([list(r) for r in rows]); solid = np.isin(a, list(SOLID))
    samples, errors = {}, []
    for region in w['regions']:
        if region_id and region['id'] != region_id:
            continue
        x0, y0, width, height = region['bounds']; x1, y1 = x0 + width, y0 + height
        ar = a[y0:y1, x0:x1]; mask = solid[y0:y1, x0:x1]
        errors_here = []
        def require(ok, message):
            if not ok: errors_here.append(message)
        counts = collections.Counter(''.join(''.join(r) for r in ar))
        ratio = 100 * float(mask.mean()); platforms = 100 * counts['='] / mask.size
        low, high = TARGETS[region['id']]; require(low <= ratio <= high, 'region_solid_ratio')
        require(platforms <= (8 if region['id'] == 'skywalk' else 4), 'platform_ratio')
        view = window_counts(mask); required_min = 20 if region['id'] in ['ridge', 'skywalk'] else 35
        minimum = float(view.min()) / 880 * 100
        exterior_view = window_counts(ar == ':') > 0
        limits = np.where(exterior_view, 20, required_min)
        require(bool(np.all(view / 880 * 100 + 1e-8 >= limits)), 'viewport_solid_ratio')
        # A cell must belong to a 2x2 solid block; this also rejects one-tile rods.
        squares = mask[:-1, :-1] & mask[1:, :-1] & mask[:-1, 1:] & mask[1:, 1:]
        thick = np.zeros_like(mask)
        for yy in [0, 1]:
            for xx in [0, 1]:thick[yy:yy + height - 1, xx:xx + width - 1] |= squares
        thin = int((mask & ~thick).sum()); require(thin == 0, 'one_tile_solid')
        labels, num = label(mask); floating = []
        for idx in range(1, num + 1):
            yy, xx = np.where(labels == idx)
            if len(xx) < 12 and not (0 in xx or width - 1 in xx or 0 in yy or height - 1 in yy):floating.append([int(xx[0] + x0), int(yy[0] + y0), len(xx)])
        require(not floating, 'small_floating_rock')
        unsupported = []; lines = 0
        for y in range(y0, y1):
            x = x0
            while x < x1:
                if rows[y][x] != '=':x += 1; continue
                start = x
                while x < x1 and rows[y][x] == '=':x += 1
                lines += 1
                wall = (start > 0 and rows[y][start - 1] in SOLID) or (x < w['width'] and rows[y][x] in SOLID)
                has_decor = any(d[0] in [0, 1, 2] and start <= d[1] <= x and abs(d[2] - y) <= 20 for d in decor)
                if not wall and not has_decor:unsupported.append([start, y, x - start])
        require(not unsupported, 'unsupported_platform')
        gate_heights = {}; bad_gates = []
        for e in entities:
            if e['region'] != region['id'] or e['type'] != 'gate':continue
            x, foot = (round(v / 32) for v in e['position']); top = foot - 1
            while top >= y0 and rows[top][x] not in '#W^':top -= 1
            clearance = foot - top - 1; gate_heights[e['uid']] = clearance
            if clearance != 5:bad_gates.append(e['uid'])
        require(not bad_gates, 'gate_corridor_not_5')
        bad_enemy_floor = []
        for e in entities:
            if e['region'] != region['id'] or e['type'] != 'enemy':continue
            x, foot = (round(v / 32) for v in e['position'])
            if e['id'] == 'cedar_wisp':foot += 2
            if not (4 <= x < w['width'] - 4 and 0 <= foot < w['height'] and all(c in '#W' for c in rows[foot][x - 4:x + 4])):bad_enemy_floor.append(e['uid'])
        require(not bad_enemy_floor, 'enemy_flat_floor_below_8')
        # Clearance is checked at two-cell-wide possible feet, not arbitrary wall corners.
        stuck = []
        for y in range(y0 + 1, y1):
            for x in range(x0 + 1, x1 - 1):
                if not (solid[y, x] and solid[y, x + 1]) or a[y - 1, x] not in '.:~=':continue
                free = 0
                # One-way shelves do not block a head rising from underneath.
                # Treating '=' as a ceiling incorrectly reports 1/3-tile traps.
                while y - free - 1 >= y0 and a[y - free - 1, x] in '.:~=' and a[y - free - 1, x + 1] in '.:~=':free += 1
                if free in [1, 3]:stuck.append([x, y, free])
        require(not stuck, 'standing_clearance_below_4')
        # Long vertical empty runs are only legal in explicitly authored drop shafts.
        drops = w.get('drop_shafts', []); long_runs = []
        for x in range(x0, x1):
            start = y0
            for y in range(y0, y1 + 1):
                if y < y1 and a[y, x] in '.:~':continue
                if y - start > 30 and not any(dx <= x < dx + dw and dy <= start and y <= dy + dh for dx, dy, dw, dh in drops):long_runs.append([x, start, y - start])
                start = y + 1
        require(not long_runs, 'empty_vertical_run_over_30')
        samples[region['id']] = {'solid_percent': ratio, 'platform_percent': platforms,
            'glyph_counts': dict(counts), 'minimum_viewport_solid_percent': minimum,
            'minimum_viewport_at': [int(view.argmin() % view.shape[1]) + x0, int(view.argmin() // view.shape[1]) + y0],
            'one_tile_cells': thin, 'small_floating_components': floating[:30],
            'platform_lines': lines, 'unsupported_platforms': unsupported[:30],
            'unsupported_platform_count': len(unsupported), 'gate_clearance': gate_heights,
            'bad_enemy_floor': bad_enemy_floor, 'stuck_standing': stuck[:30],
            'long_empty_columns': long_runs[:30], 'errors': errors_here}
        errors += [region['id'] + ': ' + error for error in errors_here]
    return {'passed': not errors, 'scope': region_id or 'all', 'regions': samples,
            'global_solid_percent': float(solid.mean() * 100), 'global_platform_percent': float((a == '=').mean() * 100), 'errors': errors}


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--region'); parser.add_argument('--output', default='archive/stage15_map/terrain.json'); args = parser.parse_args()
    w, entities, _, decor = load_world(); report = measure(w, entities, decor, args.region)
    out = ROOT / args.output; out.parent.mkdir(parents=True, exist_ok=True); out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(report, ensure_ascii=False, indent=2)); return 0 if report['passed'] else 1


if __name__ == '__main__':raise SystemExit(main())
