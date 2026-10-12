#!/usr/bin/env python3
"""Isotropically align inconsistent neutral source poses, retaining immutable originals."""
import json,shutil
from pathlib import Path
from types import SimpleNamespace
import numpy as np
from PIL import Image
from pack_sprites import apply_storage_policy
R=Path(__file__).resolve().parents[1]
def original_frames(row,c):
 path=R/'archive'/row['source_archive'] if row.get('source_archive') else R/'archive/stage8_density_before'/row['source'];im=Image.open(path).convert('RGBA');frames=[]
 for i in range(c['frames']):
  if row.get('source_canonical'):f=im.crop((i*c['frame_width'],0,(i+1)*c['frame_width'],c['frame_height']))
  else:
   t=c['trim'];f=Image.new('RGBA',(c['frame_width'],c['frame_height']));f.paste(im.crop((i*t['w'],0,(i+1)*t['w'],t['h'])),(t['x'],t['y']))
  frames.append(f)
 return frames

def main():
 rows={r['path']:r for r in json.loads((R/'data/storage_quality.json').read_text())};catalog=json.loads((R/'data/sprite_trims.json').read_text());fixed=[]
 for mp in (R/'assets/sprites/enemies').glob('*/manifest.json'):
  d=json.loads(mp.read_text());clips=d['clips']
  for c in clips:
   if c['sheet'].endswith('.png') and 'res://assets/'+c['sheet'] not in rows:
    previous=str(Path(c['sheet']).with_suffix('.webp'))
    if 'res://assets/'+previous in rows:c['sheet']=previous
  base=next((c for c in clips if c['name'] in ['idle','perch','float','glide','fly_idle']),None)
  if not base:continue
  frames=original_frames(rows['res://assets/'+base['sheet']],base);first=frames[0].getchannel('A').point(lambda v:255 if v>12 else 0).getbbox();enemy=next(e for e in json.loads((R/'data/enemies.json').read_text())['enemies'] if e['id']==mp.parent.name);target=int(round(enemy.get('art_height_px',first[3]-first[1])))
  for c in clips:
   floating=c['anchor_px'][1]==c['frame_height']//2
   if floating and mp.parent.name in ['sky_beast','wraith_ray']:
    c.setdefault('qa',{})['pose_height_exception']=True;c['qa']['posture_reason']='Wing flapping / smoke silhouette; floating mass-centre is checked separately';continue
   if c['name'] in ['chain_throw','slam_windup','windup','spew','recovery','hurt','death']:
    c.setdefault('qa',{})['pose_height_exception']=True;c['qa']['posture_reason']='Forward bend / raised arms changes silhouette while anatomy remains fixed';continue
   if c['name'] not in ['idle','perch','walk','turn'] or c.get('qa',{}).get('pose_height_exception'):continue
   key='res://assets/'+c['sheet'];source=original_frames(rows[key],c);heights=[f.getchannel('A').point(lambda v:255 if v>12 else 0).getbbox()[3]-f.getchannel('A').point(lambda v:255 if v>12 else 0).getbbox()[1] for f in source]
   if max(abs(h-target) for h in heights)<=target*.025:continue
   output=Image.new('RGBA',(c['frame_width']*len(source),c['frame_height']));anchor=c['anchor_px']
   for i,f in enumerate(source):
    box=f.getchannel('A').getbbox();pose=f.crop(box);scale=target/heights[i];pose=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.LANCZOS)
    x=round(anchor[0]-pose.width/2);y=round(anchor[1]-pose.height if not floating else anchor[1]-pose.height/2)
    if min(x,y)<8 or x+pose.width>c['frame_width']-8 or y+pose.height>c['frame_height']-8:raise ValueError('Canonical frame must be regenerated, protrusion does not fit: '+key)
    output.alpha_composite(pose,(i*c['frame_width']+x,y))
   path=R/'assets'/Path(c['sheet']).with_suffix('.png');output.save(path)
   c['sheet']=str(Path(c['sheet']).with_suffix('.png'));c.setdefault('qa',{});c['qa']['expected_pose_heights']=[target]*len(source);c['qa']['neutral_normalization']='isotropic source scaling, foot/centre anchor preserved';fixed.append((path,c,mp.parent.name))
  mp.write_text(json.dumps(d,indent=2)+'\n')
 for path,c,ident in fixed:
  enemy=next(e for e in json.loads((R/'data/enemies.json').read_text())['enemies'] if e['id']==ident);base=enemy['visual_scale']*enemy.get('size_multiplier',1)
  apply_storage_policy(SimpleNamespace(output=str(path),frames=c['frames'],frame_width=c['frame_width'],frame_height=c['frame_height'],anchor=c['anchor_px'],visual_scale=base,density_class='large_enemy' if ident in ['humbaba','gugalanna','kala_ushumgal'] else 'enemy',canonical_only=False),Image.open(path).convert('RGBA'),True)
 (R/'archive/stage11/normalized_clips.json').write_text(json.dumps([str(p.relative_to(R)) for p,c,i in fixed],indent=2))
 print('NEUTRAL NORMALIZATION',len(fixed),'clips')
if __name__=='__main__':main()
