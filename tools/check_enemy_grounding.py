#!/usr/bin/env python3
"""Find actual collision support under ground spawns and authored branch perches."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def check():
 errors=[];rows=[]
 for l in json.loads((ROOT/'data/levels.json').read_text())['levels']:
  surfaces=[(t['from'],t['to'],t['y']) for t in l.get('terrain',[])] or [(0,l['width'],l['floor_y'])]
  surfaces += [(p['position'][0],p['position'][0]+p['width'],p['position'][1]+(p.get('art_height',48)*37/120 if p.get('perch_support') else 0)) for p in l.get('platforms',[])]
  surfaces += [(o['rect'][0],o['rect'][0]+o['rect'][2],o['rect'][1]) for o in l.get('obstacles',[])]
  for e in l.get('enemies',[]):
   if e['id'] in ['sky_beast','gas_sac','wraith_ray','cedar_wisp','wall_diver']:continue
   x,y=e['position'];support=[z for a,b,z in surfaces if a<=x<=b and y-8<=z<=y+600];ok=bool(support)
   if e['id']=='cedar_demon':ok=ok and any(p.get('perch_support') and p['position'][0]<=x<=p['position'][0]+p['width'] and abs(p['position'][1]+p['art_height']*37/120-y)<1 for p in l.get('platforms',[]))
   rows.append(f"{l['id']} / {e['id']} {x},{y}: {'PASS' if ok else 'FAIL'}")
   if not ok:errors.append(rows[-1])
 out=ROOT/'docs/STAGE8_GROUNDING_REPORT.txt';out.write_text(f'STATIC: {len(rows)} spawns, {len(errors)} failures\n'+'\n'.join(rows)+'\n');print(f'GROUNDING: {len(rows)} spawns, {len(errors)} failures');print('\n'.join(errors));return int(bool(errors))
if __name__=='__main__':raise SystemExit(check())
