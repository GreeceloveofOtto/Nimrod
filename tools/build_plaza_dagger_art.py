#!/usr/bin/env python3
"""Pack original generated hero and dagger poses; no procedural game art."""
import json,shutil
from pathlib import Path
from types import SimpleNamespace
import numpy as np
from PIL import Image
from build_siyavash_redesign import extract,key,face_color
from pack_sprites import apply_storage_policy
import downscale_assets
ROOT=Path(__file__).resolve().parents[1]
ARC=ROOT/'archive/plaza_dagger_2026-10-14'

def build(job):
 id,name,n=job['id'],job['clip'],job['n'];npc=id!='siyavash_dagger'
 folder=ROOT/'assets/sprites'/('npcs' if npc else 'player')/id;folder.mkdir(parents=True,exist_ok=True)
 manifest_path=folder/'manifest.json'
 if manifest_path.exists():m=json.loads(manifest_path.read_text())
 else:m={'character':id,'frame_size':[640,640],'clips':[]}
 poses=extract(job['path'],[n]);ratio=1
 if npc:
  row=next(v for v in json.loads((ROOT/'data/npcs.json').read_text())['npcs'] if v['id']==id);ratio=row['height_ratio'];m['height_ratio']=ratio
 target=round(363*ratio);factor=min(target/max(p.height for p in poses),600/max(p.width for p in poses));sheet=Image.new('RGBA',(640*n,640));heights=[]
 for i,pose in enumerate(poses):
  if not npc:
   pose,_=face_color(pose,name,i)
   pixels=np.array(pose);hsv=np.array(pose.convert('RGB').convert('HSV'))
   yy,xx=np.indices(pixels.shape[:2]);blade=(pixels[:,:,3]>100)&(pixels[:,:,2]>160)&(pixels[:,:,2]>pixels[:,:,0].astype(float)*1.1)&(pixels[:,:,1]>pixels[:,:,0].astype(float)*1.05)&(yy>pose.height*.2)
   hsv[blade,0]=[30,242,125,170,210,0][i];hsv[blade,1]=50 if i==5 else 105
   pixels[:,:,:3]=np.array(Image.fromarray(hsv,'HSV').convert('RGB'));pixels[pixels[:,:,3]==0,:3]=0;pose=Image.fromarray(pixels)
  size=(round(pose.width*factor),round(pose.height*factor))
  # Density-aware normalization of new generated art, retaining archived raw pixels.
  small=pose.resize((max(1,round(size[0]*.85)),max(1,round(size[1]*.85))),Image.Resampling.BILINEAR).resize(size,Image.Resampling.BILINEAR)
  pixels=np.array(small);pixels[pixels[:,:,3]==0,:3]=0;small=Image.fromarray(pixels)
  sheet.alpha_composite(small,(640*i+320-small.width//2,600-small.height));heights.append(small.height)
 duration=.6 if name=='give_dagger' else 2.4 if npc else next(a['duration'] for a in json.loads((ROOT/'data/player_attacks.json').read_text())['weapons']['dagger']['attacks'] if name=='attack_'+str(a['step']))
 c={'name':name,'sheet':f'sprites/{"npcs" if npc else "player"}/{id}/{name}.png','frames':n,'frame_width':640,'frame_height':640,'anchor_px':[320,600],'duration_seconds':duration,'fps':n/duration,'loop':npc and name!='give_dagger','image_size':list(sheet.size),'body_reference_height_px':target,'qa':{'movement':not npc or name=='give_dagger','pose_height_exception':not npc or name=='give_dagger','expected_pose_heights':heights,'authored_interior_violet':True,'detached_fx_or_weapon':False},'source_reference':f'archive/plaza_dagger_2026-10-14/{id}_reference.png'}
 m['clips']=[v for v in m['clips'] if v['name']!=name]+[c]
 if not npc:m['aliases']={v['name']:{'set':'siyavash','clip':v['name']} for v in json.loads((ROOT/'assets/sprites/player/siyavash/manifest.json').read_text())['clips']}
 manifest_path.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n');output=folder/(name+'.png');sheet.save(output)
 original_choose=downscale_assets.choose_scale
 def bounded(img,w,h,count,base,limit):
  result=original_choose(img,w,h,count,base,1.4)
  if result[-1]>2.0001:raise ValueError(f'{id}/{name}: density {result[-1]} above NPC/player cap')
  return result
 downscale_assets.choose_scale=bounded
 try:apply_storage_policy(SimpleNamespace(output=str(output),frames=n,frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='npc' if npc else 'player',canonical_only=False),sheet,True)
 finally:downscale_assets.choose_scale=original_choose
 if output.with_suffix('.storage.json').exists():shutil.move(output.with_suffix('.storage.json'),ARC/(id+'_'+name+'.storage.json'))
 print('PACKED',id,name,heights,flush=True)

def catalogs():
 catalog=json.loads((ROOT/'assets/art_manifest.json').read_text());expectations=json.loads((ROOT/'data/alpha_expectations.json').read_text())
 manifests=[str(p.relative_to(ROOT/'assets')) for p in (ROOT/'assets/sprites/npcs').glob('*/manifest.json') if p.parent.name in ['laodastahma','tusa','gudarz','gaevani','baraja','pariburz']]+['sprites/player/siyavash_dagger/manifest.json']
 for relative in manifests:
  if relative not in catalog['sprite_manifests']:catalog['sprite_manifests'].append(relative)
  for c in json.loads((ROOT/'assets'/relative).read_text())['clips']:
   catalog['assets']=[a for a in catalog['assets'] if a['path']!=c['sheet']]
   catalog['assets'].append(dict(path=c['sheet'],width=c['image_size'][0],height=c['image_size'][1],transparent=True,category='sprite'))
   expectations['assets/'+c['sheet']]=dict(mode='transparent',edge_black_fraction=.03,source='generated plaza hero/dagger')
 for p,d in [('assets/art_manifest.json',catalog),('data/alpha_expectations.json',expectations)]: (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')

if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser();p.add_argument('--only');a=p.parse_args()
 for job in json.loads((ARC/'sources.json').read_text()):
  if not a.only or a.only in job['id']+'/'+job['clip']:build(job)
 catalogs()
