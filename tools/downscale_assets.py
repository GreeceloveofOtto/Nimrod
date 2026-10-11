#!/usr/bin/env python3
"""Density-limited sprite storage; canonical frame geometry remains in game units.
Archives source bytes, checks resampling SSIM, stores frame maps and reversible
storage geometry. AssetVisual compensates storage scale exactly once.
"""
import argparse,json,shutil,io
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter
ROOT=Path(__file__).resolve().parents[1]

def ssim(a,b):
 a=np.asarray(a.convert('RGBA'),dtype=float);b=np.asarray(b.convert('RGBA'),dtype=float)
 # Premultiplied RGB includes edge shape without hidden transparent RGB noise.
 a=a[:,:,:3]*a[:,:,3:4]/255;b=b[:,:,:3]*b[:,:,3:4]/255
 x=a@np.array([.2126,.7152,.0722]);y=b@np.array([.2126,.7152,.0722]);ux=gaussian_filter(x,1.5);uy=gaussian_filter(y,1.5);vx=gaussian_filter(x*x,1.5)-ux*ux;vy=gaussian_filter(y*y,1.5)-uy*uy;cov=gaussian_filter(x*y,1.5)-ux*uy
 v=((2*ux*uy+6.5025)*(2*cov+58.5225))/((ux*ux+uy*uy+6.5025)*(vx+vy+58.5225));return float(v.mean())

def choose_scale(image,w,h,count,base_scale,limit):
 density=limit
 while True:
  s=min(1,density*base_scale);sw=max(1,round(w*s));sh=max(1,round(h*s));scores=[]
  # Check every frame, avoiding a favorable idle-only sample.
  for i in range(count):
   frame=image.crop((i*w,0,(i+1)*w,h));small=frame.resize((sw,sh),Image.Resampling.LANCZOS);scores.append(ssim(frame,small.resize((w,h),Image.Resampling.LANCZOS)))
  if min(scores)>=.93 or s==1:return s,sw,sh,min(scores),density
  density=round(density+.2,5)

def encode(image,path,quality=86):
 a=np.asarray(image.convert('RGBA'));transparent=a[:,:,3].min()<255;buffer=io.BytesIO();image.save(buffer,'WEBP',quality=quality,alpha_quality=95,method=6,exact=True)
 b=np.asarray(Image.open(io.BytesIO(buffer.getvalue())).convert('RGBA'));mask=a[:,:,3]>12
 alpha=float(np.abs(a[:,:,3].astype(float)-b[:,:,3]).mean());rgb=float(np.abs(a[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean()) if mask.any() else 0
 bbox=Image.fromarray(a[:,:,3]).getbbox()==Image.fromarray(b[:,:,3]).getbbox();lossless=not(bbox and alpha<=1.5 and rgb<=3)
 if lossless:
  buffer=io.BytesIO();image.save(buffer,'WEBP',lossless=True,method=6,exact=True);alpha=0;rgb=0
 path.write_bytes(buffer.getvalue());return {'mode':'lossless' if lossless else 'lossy','quality':quality,'alpha_mae':alpha,'rgb_mae':rgb,'bbox_same':True,'transparent':bool(transparent)}

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--apply',action='store_true');parser.add_argument('--dry-run',action='store_true');a=parser.parse_args()
 if a.apply and a.dry_run:parser.error('Choose --apply or --dry-run')
 limits={'player':2,'npc':2,'enemy':2,'large_enemy':1.4,'fx':1.4,'props':2,'doors':2,'sky_far':1,'ssim_min':.93};limits.update(json.loads((ROOT/'data/density_limits.json').read_text()) if (ROOT/'data/density_limits.json').exists() else {})
 if a.apply:(ROOT/'data/density_limits.json').write_text(json.dumps(limits,indent=2)+'\n')
 policy={'assets/sprites':{'mode':'lossy','quality':86,'alpha_quality':95,'method':6},'assets/props':{'mode':'lossy','quality':86},'assets/backgrounds':{'mode':'lossy','quality':82},'assets/tiles':{'mode':'keep'},'assets/ui':{'mode':'keep'}};policy.update(json.loads((ROOT/'data/image_policy.json').read_text()) if (ROOT/'data/image_policy.json').exists() else {})
 if a.apply:(ROOT/'data/image_policy.json').write_text(json.dumps(policy,indent=2)+'\n')
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());enemies={v['id']:v for v in json.loads((ROOT/'data/enemies.json').read_text())['enemies']};npcs=json.loads((ROOT/'data/npcs.json').read_text());scales={v['sheet_dir']:npcs['common']['visual_scale']*v.get('visual_scale_multiplier',1) for v in npcs['npcs']};records=[];replacements={};new_registry={}
 previous={r['path']:r['source'] for r in json.loads((ROOT/'data/storage_quality.json').read_text())} if (ROOT/'data/storage_quality.json').exists() else {}
 for path,spec in registry.items():
  file=ROOT/path.removeprefix('res://');rel=str(file.relative_to(ROOT));archive=ROOT/'archive/stage8_density_before'/previous.get(path,rel);archive.parent.mkdir(parents=True,exist_ok=True)
  if spec.get('storage_scale') and not archive.exists():raise RuntimeError('Original density archive is required; never downscale an already normalized runtime image: '+rel)
  if a.apply and not archive.exists():shutil.copy2(file,archive)
  image=Image.open(archive if archive.exists() else file).convert('RGBA');trim=spec['trim'];w,h=trim['w'],trim['h'];count=spec['frames'];base=.3;limit=limits['player']
  if '/props/' in path:base=1;limit=limits['doors']
  if '/enemies/' in path:
   id=file.parent.name;v=enemies[id];base=v.get('visual_scale',.3)*v.get('size_multiplier',1);limit=limits['large_enemy'] if id in ['kala_ushumgal','chain_beastman','cedar_colossus','boar_charger'] else limits['enemy']
  elif '/npcs/' in path:base=scales.get(str(file.parent.relative_to(ROOT)),.3);limit=limits['npc']
  elif '/fx/' in path:base=.3;limit=limits['fx']
  s,sw,sh,score,density=choose_scale(image,w,h,count,base,limit)
  unique=[];frame_map=[]
  for i in range(count):
   frame=image.crop((i*w,0,(i+1)*w,h)).resize((sw,sh),Image.Resampling.LANCZOS)
   if unique and np.abs(np.array(frame,dtype=float)-np.array(unique[-1],dtype=float)).mean()<=.3:frame_map.append(len(unique)-1)
   else:frame_map.append(len(unique));unique.append(frame)
  sheet=Image.new('RGBA',(sw*len(unique),sh))
  for i,frame in enumerate(unique):sheet.paste(frame,(i*sw,0))
  out=file.with_suffix('.webp');spec.update(storage_scale=[sw/w,sh/h],stored_frame_size=[round(spec['frame_width']*sw/w),round(spec['frame_height']*sh/h)],stored_anchor_px=[spec['anchor_px'][0]*sw/w,spec['anchor_px'][1]*sh/h],storage_trim={'x':trim['x']*sw/w,'y':trim['y']*sh/h,'w':sw,'h':sh},stored_columns=len(unique),frame_map=frame_map,image_size=list(sheet.size),effective_density=density,ssim=score)
  metrics=encode(sheet,out) if a.apply else {'mode':'dry-run'}
  if a.apply and file!=out:file.unlink()
  newpath='res://'+str(out.relative_to(ROOT));new_registry[newpath]=spec
  if path!=newpath:replacements[path.removeprefix('res://')]=newpath.removeprefix('res://')
  records.append({'path':newpath,'source':rel,'source_bytes':archive.stat().st_size if archive.exists() else file.stat().st_size,'output_bytes':out.stat().st_size if a.apply else None,'density':density,'ssim':score,'storage_scale':spec['storage_scale'],'stored_frames':len(unique),'frames':count,**metrics})
  print(f"DENSITY {rel}: {s:.3f}, SSIM {score:.4f}, {len(unique)}/{count}, {metrics['mode']}",flush=True)
 if a.apply:
  (ROOT/'data/sprite_trims.json').write_text(json.dumps(new_registry,indent=2)+'\n')
  for manifest in (ROOT/'assets').rglob('*manifest.json'):
   data=json.loads(manifest.read_text());dirty=False
   for clip in data.get('clips',[]):
    sheet=clip['sheet'];p=ROOT/sheet.removeprefix('res://') if sheet.startswith('res://') else ROOT/'assets'/sheet if sheet.startswith(('sprites/','props/','fx/')) else manifest.parent/sheet
    key='res://'+str(p.with_suffix('.webp').relative_to(ROOT))
    if key in new_registry:
     clip.update(new_registry[key]);clip['sheet']=str(Path(sheet).with_suffix('.webp'));dirty=True
   if dirty:manifest.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
  rewrite_paths(replacements)
  (ROOT/'data/storage_quality.json').write_text(json.dumps(records,indent=2)+'\n')
 print(f'DENSITY: {len(records)} sheets, before {sum(v["source_bytes"] for v in records)/1048576:.2f}MiB, after {sum(v["output_bytes"] or 0 for v in records)/1048576:.2f}MiB')

def rewrite_paths(mapping):
 import re
 if not mapping:return
 replacements={**mapping,**{k.removeprefix('assets/'):v.removeprefix('assets/') for k,v in mapping.items()}}
 pattern=re.compile('|'.join(re.escape(k) for k in sorted(replacements,key=len,reverse=True)))
 for folder in ['scripts','scenes','data','assets','tools','tests']:
  for p in (ROOT/folder).rglob('*'):
   if p.suffix not in ['.gd','.py','.json','.tscn','.tres','.txt','.md']:continue
   old=p.read_text();new=pattern.sub(lambda m:replacements[m.group()],old)
   if new!=old:p.write_text(new)
 p=ROOT/'data/image_mapping.json';d=json.loads(p.read_text());d.update(mapping);p.write_text(json.dumps(d,indent=2)+'\n')
if __name__=='__main__':main()
