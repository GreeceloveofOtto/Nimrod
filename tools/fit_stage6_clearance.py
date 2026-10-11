#!/usr/bin/env python3
"""Fit enlarged monsters and their supporting paths without changing combat stats."""
import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def load(p):return json.loads((R/p).read_text())
def save(p,d):(R/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def p(id,x,y,w=300):return dict(id=id,position=[x,y],width=w,art='res://assets/tiles/passage/platform.png',art_height=48)
def chain(l,key,x,bottom,top,w=240):
 a=[];steps=[];y=bottom-90;i=0
 while y>top:
  id=key+str(i);l['platforms'].append(p(id,x+(i%2)*70,y,w));a.append(id);steps.append(id);y-=90;i+=1
 l['reachability']['chains'].append(a)
 return a

def main():
 d=load('data/levels.json')
 for l in d['levels']:
  if l['id'].startswith('CedarForest'):
   for a in l['platforms']:
    if a['id'].startswith('stair_'):
     _,c,r,i=a['id'].split('_');a['position'][0]=int(c)*1200+60+(int(i)%2)*80;a['width']=280
   for e in l['enemies']:
    if e['id']=='cedar_demon':
     import math
     e['position'][1]=128+math.ceil((e['position'][1]-128)/640)*640-320
   continue
  if not l['id'].startswith('DowntownPassage'):continue
  n=int(l['id'][-1]);l['ceiling_y']=-500;l['camera_limits']=[0,-560,3600,1500]
  for bg in l['backgrounds']:
   if bg.get('ratio',1)==1:bg['position'][1]=-560;bg['size']=[3600,1500]
  l['reachability']['chains']=[];l['reachability']['elevation_limits']=[-280,1200];l['reachability']['max_local_platform_elevation']=1200
  if n==1:
   for e in l['enemies']:
    if e['id']=='melee_beast' and e['position'][0]>3000:e['position'][0]=1700
    if e['id']=='explosive_spitter' and e['position'][0]>2000:e['position'][0]=2100
  if n==2:
   roots=[e for e in l['enemies'] if e['id']=='root_spewer']
   l['platforms']=[p('root_left',roots[0]['position'][0]-160,420,320),p('root_right',roots[1]['position'][0]-160,420,320)]
   for e in l['enemies']:
    if e['id']=='ranged_beast':e['position']=[1450 if e['position'][0]<1800 else 2300,420]
  if n==3:
   l['platforms']=[p('middle',800,300,2300),p('upper',2100,-40,1000)]
   chain(l,'left_ascent',420,620,300);chain(l,'right_ascent',3170,620,-40)
   for e in l['enemies']:
    if e['id']=='root_spewer':e['position'][1]=300
    if e['id']=='explosive_spitter':e['position'][1]=-40 if e['position'][0]>2000 else 300
  if n==5:
   l['platforms']=[p('machinery_high',900,300,1600),p('high_left',500,420,300),p('high_right',2820,420,300)]
   chain(l,'machine_left',450,680,300);chain(l,'machine_right',2710,680,300)
   for e in l['enemies']:
    if e['id']=='root_spewer':e['position'][1]=300
  if n==6:
   l['platforms']=[p('alcove_right',1700,300,500)]
   chain(l,'alcove_stairs',1700,520,300)
   for e in l['enemies']:
    if e['id']=='boar_charger':e['position'][0]=900 if e['position'][0]<1800 else 2700;e['patrol_range']=650
   l['clearance_lanes']=[[200,1600],[2000,3400]]
  if n==7:
   l['platforms']=[p('balcony_low',700,230,300),p('balcony_high',900,140,300),p('balcony_exit',1200,230,220)]
   chain(l,'balcony_ascent',1100,620,140,220)
   for e in l['enemies']:
    if e['id']=='shell_scorpion' and e['position'][0]>1800:e['position'][0]=3100
    if e['id']!='wraith_ray':e['patrol_range']=70
  if n==8:
   l['platforms']=[a for a in l['platforms'] if not a['id'].startswith('stage6_upper')]
   chain(l,'stage6_upper_',1200,620,0,240)
   for e in l['enemies']:
    if e['id']=='corpse_bomber' and e['position'][0]>2500:e['position'][0]=3150
  for e in l['enemies']:
   if e['id']=='gas_sac':e['position'][1]=150 if n in [5,6] else 220
   if e['id']=='root_spewer':
    x,y=e['position']
    if not any(a['position'][0]<=x-111 and a['position'][0]+a['width']>=x+111 and a['position'][1]==y for a in l['platforms']):l['platforms'].append(p('root_pad_'+str(x),x-160,y,320))
   e['patrol_center']=e['position'][0]
   if e['id'] not in ['boar_charger','wraith_ray','wall_diver','chain_beastman']:e['patrol_range']=min(100,e.get('patrol_range',100))
 save('data/levels.json',d)
if __name__=='__main__':main()
