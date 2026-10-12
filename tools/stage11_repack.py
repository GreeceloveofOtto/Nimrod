#!/usr/bin/env python3
"""Repack immutable canonical pixels once; uphold density floor and two transparent storage pixels."""
import json,shutil,io,argparse,math
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import numpy as np
from PIL import Image
from downscale_assets import ROOT,choose_scale
from stage10_optimize_density import encoded

def pad_sheet(inner,iw,ih,count,pad=2):
 out=Image.new('RGBA',((iw+pad*2)*count,ih+pad*2))
 for i in range(count):out.paste(inner.crop((i*iw,0,(i+1)*iw,ih)),(i*(iw+pad*2)+pad,pad))
 return out

def pad_spec(spec,iw,ih,count,pad=2):
 t=spec['trim'];sx,sy=spec['storage_scale'];spec.update(stored_content_size=[iw,ih],stored_padding=pad,stored_cell=[iw+pad*2,ih+pad*2],stored_gutter=pad,storage_trim={'x':t['x']*sx-pad,'y':t['y']*sy-pad,'w':iw+pad*2,'h':ih+pad*2},image_size=[(iw+pad*2)*count,ih+pad*2])

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--only-low',action='store_true');parser.add_argument('--prefix',default='');parser.add_argument('--paths');args=parser.parse_args();selected=set(json.loads(Path(args.paths).read_text())) if args.paths else None
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());rows=json.loads((ROOT/'data/storage_quality.json').read_text());enemies={e['id']:e for e in json.loads((ROOT/'data/enemies.json').read_text())['enemies']};npcs=json.loads((ROOT/'data/npcs.json').read_text());npcscales={e['sheet_dir']:.3*e.get('visual_scale_multiplier',1) for e in npcs['npcs']};results=[]
 def worker(row):
  path=ROOT/row['path'].removeprefix('res://')
  if selected is not None and row['path'] not in selected:return None
  if not path.exists() or '/axe_prosthetic/' in row['path'] or (args.prefix and args.prefix not in row['path']):return None
  spec=registry[row['path']];trim=spec['trim'];n=spec['frames'];base=.3;floor=.8
  if '/enemies/' in row['path']:
   e=enemies[path.parent.name];base=e['visual_scale']*e.get('size_multiplier',1);floor=.9 if path.parent.name in ['gugalanna','humbaba','kala_ushumgal'] else .8
  elif '/npcs/' in row['path']:base=npcscales.get(str(path.parent.relative_to(ROOT)),.3)
  elif '/props/doors/' in row['path']:base=1;floor=.75
  elif '/fx/' in row['path']:floor=0 # Same size; these are not character density targets.
  before=path.stat().st_size;old_density=spec['storage_scale'][1]/base
  if args.only_low and (floor<=0 or old_density>=floor):return None
  source_path=ROOT/'archive'/row['source_archive'] if row.get('source_archive') else ROOT/'archive/stage8_density_before'/row['source'];source=Image.open(source_path).convert('RGBA');w,h=trim['w'],trim['h'];packed=Image.new('RGBA',(w*n,h))
  for i in range(n):
   rect=(i*spec['frame_width']+trim['x'],trim['y'],i*spec['frame_width']+trim['x']+w,trim['y']+h) if row.get('source_canonical') else (i*w,0,(i+1)*w,h)
   packed.paste(source.crop(rect),(i*w,0))
  # Store true source -> target scale; never multiply an old storage scale again.
  if floor>0:
   scale,iw,ih,score,density=choose_scale(packed,w,h,n,base,floor)
  else:
   iw,ih=spec.get('stored_content_size',[spec['storage_trim']['w'],spec['storage_trim']['h']]);score=spec['ssim'];density=row.get('density',1)
  if floor>0:
   iw=max(iw,math.ceil(w*base*floor));ih=max(ih,math.ceil(h*base*floor))
  inner=Image.new('RGBA',(iw*n,ih))
  for i in range(n):inner.paste(packed.crop((i*w,0,(i+1)*w,h)).resize((iw,ih),Image.Resampling.LANCZOS),(i*iw,0))
  # Keep the existing logical frame map, including merged loops.
  mapping=spec.get('frame_map',list(range(n)));count=max(mapping)+1;unique=Image.new('RGBA',(iw*count,ih));seen=set()
  for i,k in enumerate(mapping):
   if k not in seen:unique.paste(inner.crop((i*iw,0,(i+1)*iw,ih)),(k*iw,0));seen.add(k)
  sheet=pad_sheet(unique,iw,ih,count);content,metrics=encoded(sheet);backup=ROOT/'archive/stage11_before_repack'/path.relative_to(ROOT);backup.parent.mkdir(parents=True,exist_ok=True)
  if not backup.exists():shutil.copy2(path,backup)
  path.write_bytes(content);spec.update(storage_scale=[iw/w,ih/h],ssim=score,effective_density=density,stored_frame_size=[round(spec['frame_width']*iw/w),round(spec['frame_height']*ih/h)],stored_anchor_px=[spec['anchor_px'][0]*iw/w,spec['anchor_px'][1]*ih/h]);pad_spec(spec,iw,ih,count);row.update(output_bytes=len(content),storage_scale=spec['storage_scale'],density=density,ssim=score,**metrics)
  return {'path':row['path'],'before':before,'after':len(content),'density_before':old_density,'density_after':ih/h/base,'ssim':score}
 with ThreadPoolExecutor(max_workers=2 if args.only_low else 4) as pool:
  for future in as_completed([pool.submit(worker,row) for row in rows]):
   result=future.result()
   if result:
    results.append(result);print(result['path'],result['density_before'],'->',result['density_after'],result['before'],'->',result['after'],flush=True)
 for mp in (ROOT/'assets').rglob('*manifest.json'):
  d=json.loads(mp.read_text())
  for c in d.get('clips',[])+d.get('effects',[]):
   s=c['sheet'];p=ROOT/s.removeprefix('res://') if s.startswith('res://') else ROOT/'assets'/s if s.startswith(('sprites/','props/','fx/')) else mp.parent/s;k='res://'+str(p.relative_to(ROOT))
   if k in registry:c.update(registry[k])
  mp.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':'))+'\n')
 for p,d in [('data/sprite_trims.json',registry),('data/storage_quality.json',rows),('archive/stage11/rounding_results.json' if args.only_low else 'archive/stage11/repack_results.json',results)]: (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
if __name__=='__main__':main()
