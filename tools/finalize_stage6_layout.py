#!/usr/bin/env python3
"""Finalize physical maze separators and patrol clearance after the Stage6 builder."""
import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
p=R/'data/levels.json';d=json.loads(p.read_text());stats={e['id']:e for e in json.loads((R/'data/enemies.json').read_text())['enemies']};lays=json.loads((R/'data/cedar_forest_layout.json').read_text())['layouts']
for lay in lays:
 l=next(x for x in d['levels'] if x['id']==lay['level_id'])
 for plat in l['platforms']:
  if not plat['id'].startswith('room_'):continue
  _,c,row=plat['id'].split('_');c=int(c);row=int(row);plat['one_way']=False
  if any(set(edge)=={f'{c}_{row}',f'{c}_{row+1}'} for edge in lay['connections']):plat['position'][0]=c*1200+440;plat['width']=720
 l['decorations']=[{'path':'res://assets/props/cedar_stump.png','position':[1000,3128],'size':[240,200],'z':-2,'ground_contact':True},{'path':'res://assets/props/skeleton_remains.png','position':[1600,2568],'size':[280,120],'z':-2,'ground_contact':True}]
 for e in l['enemies']:
  c=int(e['position'][0]//1200);e['position'][0]=c*1200+800;e['patrol_center']=e['position'][0];e['patrol_range']=120 if e['id']=='cedar_colossus' else 180;y=e['position'][1];row=min(4,int((y-129)//640));e['room_bounds']=[c*1200+440,128+row*640,720,640]
  if e['id']=='cedar_demon':l['decorations'].append({'path':'res://assets/props/cedar_branch_perch.png','position':[e['position'][0]-180,y-120],'size':[360,120],'z':-2})
l=next(x for x in d['levels'] if x['id']=='DowntownPassage_F8')
for plat in l['platforms']:
 if plat['id'].startswith('stage6_upper'):plat['position'][0]=840+70*(int(plat['id'].rsplit('_',1)[1])%2)
 if plat['id']=='wall_l270':plat['position'][0]=1320;plat['width']=600
 if plat['id'].startswith('wall_r'):plat['position'][0]=2750 if plat['id']=='wall_r180' else 2580
for e in l['enemies']:
 if e['id']=='chain_beastman':e['patrol_range']=350
 if e['id']=='corpse_bomber' and 1000<=e['position'][0]<1300:e['position']=[700,620];e['patrol_center']=700;e['patrol_range']=40
 if e['id']=='corpse_bomber' and 3100<=e['position'][0]<3300:e['position'][0]=3200;e['patrol_center']=3200;e['patrol_range']=50
 if e['id']=='shell_scorpion' and 800<=e['position'][0]<1000:e['position']=[550,620];e['patrol_center']=550;e['patrol_range']=70
 if e['id']=='shell_scorpion' and e['position'][0]>=3000:e['position'][0]=2200;e['patrol_center']=2200;e['patrol_range']=100
changes=[]
for l in d['levels']:
 for e in l['enemies']:
  if e['id']=='kala_ushumgal':e['patrol_center']=800;e['patrol_range']=200
 if not (l['id'].startswith('DowntownPassage') or l['id'].startswith('CedarForest')):continue
 for e in l['enemies']:
  if e['id'] in ['root_spewer','wall_diver','wraith_ray','cedar_wisp','cedar_demon']:continue
  st=stats[e['id']];mult=st.get('size_multiplier',1);w,h=[v*mult for v in st['body_size']];x,y=e['position'];top=y+st.get('body_offset_y',-st['body_size'][1]/2)*mult-h/2;radius=e['patrol_range'];low=x-radius;high=x+radius
  if e.get('room_bounds'):left,_,ww,_=e['room_bounds'];low=max(low,left+w/2);high=min(high,left+ww-w/2)
  blocks=[o['rect'] for o in l.get('obstacles',[])+l.get('ceilings',[])]+[[*pl['position'],pl['width'],16] for pl in l['platforms']]
  for bx,by,bw,bh in blocks:
   if top<by+bh-.01 and top+h>by+.01:
    if bx+bw<=x-w/2:low=max(low,bx+bw+w/2+1)
    elif bx>=x+w/2:high=min(high,bx-w/2-1)
  new=max(0,min(x-low,high-x))
  if new<radius:changes.append(f"{l['id']}/{e['id']}@{x}: patrol±{radius}→±{new}");e['patrol_range']=new
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
print('Finalized20-room mazes, sealed floor separators, clear F8 battle room, patrol widths.')
