#!/usr/bin/env python3
"""Stage/QA generated FX; apply only a fully valid batch and preserve prior sheets."""
import argparse,json,shutil
from pathlib import Path
from PIL import Image
from slice_strip import pack
from check_sprite_frames import check
from trim_sprites import trim
R=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');a=p.parse_args();jobs=json.loads((R/'archive/fx_regen_jobs.json').read_text());results=[];ready=[]
 for j in jobs:
  c=j['clip'];c.pop('trim',None);c['qa']={'height_tol':.35,'height_reason':'FX flow changes extent while retaining uniform scale','detached_fx_or_weapon':True}
  source=Path(j['dest'])
  if j['name']=='chain_segment':
   im=Image.open(source).convert('RGBA');segment=source.with_name('chain_segment_crop.png');im.crop((im.width//3,0,2*im.width//3,im.height)).save(segment);source=segment
  out=R/'archive/packed_fx'/(j['name']+'.png')
  try:
   target=c['frame_height']*.7
   if j['name']=='bone_arrow':target=c['frame_height']*.55
   if j['name']=='chain_segment':target=c['frame_height']*.4
   pack(source,c,out,target,center=c['anchor_px'][1]==c['frame_height']//2,fit=True)
   errors,warnings,metrics=check(out,c)
  except (OSError,ValueError) as e:errors=[str(e)];warnings=[];metrics={}
  results.append({'clip':c['name'],'errors':errors,'warnings':warnings,'metrics':metrics});print('FX_QA',c['name'],errors,warnings,flush=True)
  if not errors:ready.append((j,c,out))
 (R/'archive/fx_qa_final.json').write_text(json.dumps(results,indent=2))
 if len(ready)!=len(jobs):return 1
 if a.apply:
  registry_path=R/'data/sprite_trims.json';registry=json.loads(registry_path.read_text());art_path=R/'assets/art_manifest.json';art=json.loads(art_path.read_text());mapping=json.loads((R/'data/image_mapping.json').read_text());inverse={v:k for k,v in mapping.items()}
  for j,c,out in ready:
   destination=R/'assets'/c['sheet'];old_relative=inverse.get(str(destination.relative_to(R)),str(destination.relative_to(R)))
   backup=R/'archive/fx_before_stage7'/destination.name;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(destination,backup)
   original=R/'archive/untrimmed'/old_relative;original.parent.mkdir(parents=True,exist_ok=True)
   if original.exists():shutil.copy2(original,backup.with_name(original.stem+'_untrimmed.png'))
   shutil.copy2(out,original)
   cropped,crop=trim(Image.open(out).convert('RGBA'),c);c['trim']=crop;c['image_size']=list(cropped.size)
   if destination.suffix=='.webp':cropped.save(destination,'WEBP',lossless=True,quality=100,method=6,exact=True)
   else:cropped.save(destination,optimize=True)
   registry['res://'+str(destination.relative_to(R))]=c
   m=R/j['manifest'];data=json.loads(m.read_text());data['clips']=[c if clip['name']==c['name'] else clip for clip in data['clips']];m.write_text(json.dumps(data,indent=2)+'\n')
   for entry in art['assets']:
    if entry['path']==str(destination.relative_to(R/'assets')):entry['width'],entry['height']=c['image_size']
  registry_path.write_text(json.dumps(registry,indent=2)+'\n');art_path.write_text(json.dumps(art,ensure_ascii=False,indent=2)+'\n')
 print('FX_BATCH:',len(ready),'passed; apply=',a.apply);return 0
if __name__=='__main__':raise SystemExit(main())
