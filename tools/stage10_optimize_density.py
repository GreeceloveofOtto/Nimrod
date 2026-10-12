#!/usr/bin/env python3
"""Try smaller densities against immutable authored pixels; reject failed quality/size gates."""
import argparse,json,io,shutil
from pathlib import Path
import numpy as np
from PIL import Image
from downscale_assets import ROOT,choose_scale

def encoded(image):
 original=np.array(image);mask=original[:,:,3]>12;best=None
 for mode,value in [('yuv',80),('quantized',12),('quantized',10)]:
  data=original.copy()
  if mode=='quantized':data[:,:,:3]=np.minimum(255,np.floor(data[:,:,:3].astype(float)/value+.5)*value).astype(np.uint8)
  buf=io.BytesIO();Image.fromarray(data).save(buf,'WEBP',lossless=mode=='quantized',quality=value if mode=='yuv' else 100,alpha_quality=90,method=6,exact=True)
  actual=Image.open(io.BytesIO(buf.getvalue())).convert('RGBA');pixels=np.array(actual);rgb=float(np.abs(original[:,:,:3][mask].astype(float)-pixels[:,:,:3][mask]).mean());alpha=float(np.abs(original[:,:,3].astype(float)-pixels[:,:,3]).mean());bbox=image.getchannel('A').getbbox()==actual.getchannel('A').getbbox()
  if rgb<=3 and alpha<=.5 and bbox and (best is None or len(buf.getvalue())<len(best[0])):best=(buf.getvalue(),{'mode':'lossy','quality':value if mode=='yuv' else 100,'encoder':'YUV WebP' if mode=='yuv' else 'bounded RGB quantization','rgb_step':value if mode=='quantized' else None,'rgb_mae':rgb,'alpha_mae':alpha,'bbox_same':True})
 if best is None:
  buf=io.BytesIO();image.save(buf,'WEBP',lossless=True,method=6,exact=True);best=(buf.getvalue(),{'mode':'lossless','quality':100,'rgb_mae':0.,'alpha_mae':0.,'bbox_same':True})
 return best

def spec_count_mismatch(spec):return spec.get('stored_columns',spec['frames'])!=spec['frames']

def main():
 p=argparse.ArgumentParser();p.add_argument('--limit',type=int,default=0);p.add_argument('--people',action='store_true');p.add_argument('--doors',action='store_true');p.add_argument('--clips',help='Comma-separated clip names');a=p.parse_args();rows=json.loads((ROOT/'data/storage_quality.json').read_text());registry=json.loads((ROOT/'data/sprite_trims.json').read_text());enemies={e['id']:e for e in json.loads((ROOT/'data/enemies.json').read_text())['enemies']};policy=json.loads((ROOT/'data/image_policy.json').read_text());results=[];count=0
 for row in rows:
  path=ROOT/row['path'].removeprefix('res://')
  eligible='/props/doors/' in row['path'] if a.doors else any('/'+k+'/' in row['path'] for k in ['player','npcs']) if a.people else '/enemies/' in row['path']
  if a.clips and path.stem not in a.clips.split(','):continue
  if not eligible or not path.exists() or spec_count_mismatch(registry[row['path']]):continue
  if a.limit and count>=a.limit:break
  count+=1;spec=registry[row['path']];before=path.stat().st_size;original=Image.open(ROOT/'archive'/row['source_archive'] if row.get('source_archive') else ROOT/'archive/stage8_density_before'/row['source']).convert('RGBA');t=spec['trim'];w,h=t['w'],t['h'];n=spec['frames'];packed=Image.new('RGBA',(w*n,h))
  for i in range(n):
   box=(i*spec['frame_width']+t['x'],t['y'],i*spec['frame_width']+t['x']+w,t['y']+h) if row.get('source_canonical') else (i*w,0,(i+1)*w,h)
   packed.paste(original.crop(box),(i*w,0))
  if a.doors:
   base=1;limit=.75
  elif a.people:
   npc=json.loads((ROOT/'data/npcs.json').read_text());entry=next((v for v in npc['npcs'] if v['sheet_dir']==str(path.parent.relative_to(ROOT))),{});base=.3*entry.get('visual_scale_multiplier',1);limit=1.2
  else:
   enemy=enemies[path.parent.name];base=enemy['visual_scale']*enemy.get('size_multiplier',1);limit=.4 if path.parent.name in ['gugalanna','humbaba','kala_ushumgal','chain_beastman','cedar_colossus','boar_charger'] else 1.2
  scale,sw,sh,score,density=choose_scale(packed,w,h,n,base,limit);sheet=Image.new('RGBA',(sw*n,sh))
  for i in range(n):sheet.paste(packed.crop((i*w,0,(i+1)*w,h)).resize((sw,sh),Image.Resampling.LANCZOS),(i*sw,0))
  content,metrics=encoded(sheet);accepted=len(content)<before
  results.append({'path':row['path'],'before':before,'candidate':len(content),'accepted':accepted,'density':density,'ssim':score,**metrics})
  if accepted:
   archive=ROOT/'archive/stage10_before_compression'/path.relative_to(ROOT);archive.parent.mkdir(parents=True,exist_ok=True)
   if not archive.exists():shutil.copy2(path,archive)
   path.write_bytes(content);spec.update(storage_scale=[sw/w,sh/h],stored_frame_size=[round(spec['frame_width']*sw/w),round(spec['frame_height']*sh/h)],stored_anchor_px=[spec['anchor_px'][0]*sw/w,spec['anchor_px'][1]*sh/h],storage_trim={'x':t['x']*sw/w,'y':t['y']*sh/h,'w':sw,'h':sh},stored_columns=n,frame_map=list(range(n)),image_size=list(sheet.size),ssim=score,effective_density=density)
   row.update(output_bytes=len(content),storage_scale=spec['storage_scale'],stored_frames=n,density=density,ssim=score,**metrics)
   policy.setdefault('overrides',{})[str(path.relative_to(ROOT))]=metrics
  print(f'DENSITY10 {path.parent.name}/{path.stem} {density:.1f} SSIM {score:.4f} {before}->{len(content)} '+('APPLY' if accepted else 'KEEP'),flush=True)
 for mp in (ROOT/'assets').rglob('*manifest.json'):
  data=json.loads(mp.read_text());dirty=False
  for c in data.get('clips',[])+data.get('effects',[]):
   s=c['sheet'];path=ROOT/s.removeprefix('res://') if s.startswith('res://') else ROOT/'assets'/s if s.startswith(('sprites/','props/','fx/')) else mp.parent/s;key='res://'+str(path.relative_to(ROOT))
   if key in registry:
    c.update(registry[key]);dirty=True
  if dirty:mp.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 for p,d in [('data/storage_quality.json',rows),('data/sprite_trims.json',registry),('data/image_policy.json',policy),('archive/stage10/door_density_attempts.json' if a.doors else 'archive/stage10/people_density_attempts.json' if a.people else 'archive/stage10/density_attempts.json',results)]: (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
 print('STAGE10_DENSITY saved MiB',sum(v['before']-v['candidate'] for v in results if v['accepted'])/1048576)
if __name__=='__main__':main()
