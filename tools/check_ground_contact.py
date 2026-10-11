#!/usr/bin/env python3
"""Measure painted bottom rows against actual supporting collision surfaces."""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]
def solid_row(im):
 a=np.asarray(im.convert('RGBA'))[:,:,3];rows=np.flatnonzero((a>200).sum(axis=1)>=a.shape[1]*.3)
 return int(rows[-1])+1 if len(rows) else None

def support(level,x,foot):
 floors=[g['y'] for g in level.get('terrain',[]) if g['from']<=x<=g['to']]
 if not floors:floors=[level['floor_y']]
 floors += [p['position'][1] for p in level.get('platforms',[]) if p['position'][0]<=x<=p['position'][0]+p['width']]
 return min(floors,key=lambda y:abs(y-foot))

def check(fix=False):
 path=R/'data/levels.json';data=json.loads(path.read_text());art=json.loads((R/'data/interactions.json').read_text())['door_art'];lines=['접지 기준: alpha>200 픽셀이 폭의 30% 이상인 마지막 행. 허용 ±6px.'];errors=0;count=0
 ground_words=['pillar','statue','lamp_post','fence','house_ruin','market_stall','stump','bone_pile','home_bed','home_table','skeleton_remains','vase','brazier','castle_facade','passage_facade','villa_exterior','nimrod_home_exterior']
 for l in data['levels']:
  for kind in ['backgrounds','decorations','doors']:
   for e in l.get(kind,[]):
    pth=e.get('path',e.get('door_art',''));door=kind=='doors';name=Path(pth).stem
    if fix and not door and e.get('ratio',1)==1 and any(w in name for w in ground_words):e['ground_contact']=True
    if fix and name in ['home_shelf','home_lamp']:e['ground_contact']=False
    if not e.get('ground_contact',door):continue
    if fix and door:e['ground_contact']=True
    p=R/pth.removeprefix('res://')
    if not p.is_file():errors+=1;lines.append('FAIL missing '+pth);continue
    im=Image.open(p).convert('RGBA');x,y=e['position']
    if door:
     cfg=art.get(name,{});w,h=cfg.get('frame_size',[256,384]);im=im.crop((0,0,w,h));left=x-w/2;top=y-h;size=[w,h]
    else:size=e['size'];left=x;top=y
    row=solid_row(im)
    if row is None:lines.append(f'WARNING {l["id"]}/{name}: no >=30% solid bottom row (slender/sparse silhouette)');continue
    bottom=top+row*size[1]/im.height;target=support(l,left+size[0]/2,bottom)
    # Keep the approved building reference at y233: edge stones sit within6px.
    if fix and not door and abs(bottom-target)>6:
     shift=target-bottom;e['position'][1]=round(y+shift,3);bottom+=shift
    count+=1;delta=bottom-target
    if abs(delta)>6:errors+=1
    lines.append(f'{"PASS" if abs(delta)<=6 else "FAIL"} {l["id"]}/{name}: row={row}, placed_bottom={bottom:.1f}, ground={target}, delta={delta:+.1f}px'+(' (door frame anchor retained)' if door else ''))
 if fix:path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 lines.append(f'{count} grounded items; {errors} failures. Wall lamps/shelves, hanging vines and elevated bridge artwork are excluded.');text='\n'.join(lines)+'\n';(R/'docs/STAGE6_GROUND_CONTACT.txt').write_text(text);print(text,end='');return not errors
if __name__=='__main__':p=argparse.ArgumentParser();p.add_argument('--fix',action='store_true');args=p.parse_args();raise SystemExit(not check(args.fix))
