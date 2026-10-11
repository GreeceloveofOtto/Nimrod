#!/usr/bin/env python3
"""Audit physical spawn bodies against actual floor, ceiling and platform rectangles."""
import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def rect_intersects(a,b):return a[0]<b[0]+b[2]-.01 and a[0]+a[2]>b[0]+.01 and a[1]<b[1]+b[3]-.01 and a[1]+a[3]>b[1]+.01
def check(level,stats):
 errors=[]
 for e in level['enemies']:
  s=stats[e['id']];factor=s.get('size_multiplier',1);w,h=[v*factor for v in s['body_size']];x,y=e['position'];center=s.get('body_offset_y',-s['body_size'][1]/2)*factor
  box=[x-w/2,y+center-h/2,w,h]
  if e['id'] in ['wraith_ray','cedar_wisp']:continue
  if e['id']=='wall_diver':continue # Perches intentionally overlap the wall/ceiling anchor.
  for o in level.get('obstacles',[])+level.get('ceilings',[]):
   if rect_intersects(box,o['rect']):errors.append(f"{e['id']}@{x}: body overlaps solid {o['rect']}")
  for p in level.get('platforms',[]):
   px,py=p['position']
   if rect_intersects(box,[px,py,p['width'],16]):errors.append(f"{e['id']}@{x}: body overlaps platform {p['id']}")
  # Check the entire configured patrol corridor, not only its spawn point.
  if e['id'] not in ['root_spewer','cedar_demon']:
   corridor=[e.get('patrol_center',x)-w/2-e.get('patrol_range',0),box[1],w+e.get('patrol_range',0)*2,h]
   for o in level.get('obstacles',[])+level.get('ceilings',[]):
    if rect_intersects(corridor,o['rect']):errors.append(f"{e['id']}@{x}: patrol corridor overlaps solid {o['rect']}")
   for p in level.get('platforms',[]):
    if rect_intersects(corridor,[*p['position'],p['width'],16]):errors.append(f"{e['id']}@{x}: patrol corridor overlaps platform {p['id']}")
  ceiling=level.get('ceiling_y',0)
  if level.get('ceiling') and box[1]<ceiling+h*.05:errors.append(f"{e['id']}@{x}: ceiling clearance below {h*1.05:.1f}")
  if e['id']=='root_spewer':
   if not any(p['position'][0]<=x-w/2 and p['position'][0]+p['width']>=x+w/2 and abs(p['position'][1]-y)<2 and p['width']>=w+60 for p in level.get('platforms',[])):
    errors.append(f"{e['id']}@{x}: no {w+60:g}px supported root platform")
  if e['id']=='boar_charger' and level['id']=='DowntownPassage_F6':
   if not any(b-a>=w+800 for a,b in level.get('clearance_lanes',[])):errors.append(f"Boar straight lane <{w+800}px")
 print(f"CLEARANCE {level['id']}: {len(level['enemies'])} actors, {len(errors)} failures")
 for e in errors:print('FAIL',e)
 return not errors
if __name__=='__main__':
 levels=json.loads((R/'data/levels.json').read_text())['levels'];stats={e['id']:e for e in json.loads((R/'data/enemies.json').read_text())['enemies']};results=[check(l,stats) for l in levels if l['id'].startswith('DowntownPassage') or l['id'].startswith('Cedar')];raise SystemExit(not all(results))
