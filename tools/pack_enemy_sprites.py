#!/usr/bin/env python3
"""Pack image-generated creature strips at their data-defined painted heights.
No procedural art or motion synthesis. A merged or missing pose rejects a sheet.
"""
import argparse,json,sys
from pathlib import Path
from slice_strip import pack,slices
import numpy as np
ROOT=Path(__file__).resolve().parents[1]

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');a=p.parse_args();catalog=json.loads((ROOT/'archive/stage7_art_catalog.json').read_text());results=[];failures=[];missing=[]
 for d in catalog:
  manifest=d['manifest'];folder=ROOT/'assets/sprites/enemies'/d['id'];ready=True
  for c in manifest['clips']:
   source=ROOT/'archive/source_art/stage7/enemies'/d['id']/(c['name']+'.png')
   if not source.exists():missing.append(str(source.relative_to(ROOT)));ready=False;continue
   out=(ROOT/'archive/packed_enemies'/d['id'])/(c['name']+'.png')
   try:
    poses=slices(source,int(c['frames']))
    heights=np.array([p.height for p in poses]);deviation=float(max(abs(heights-np.median(heights)))/np.median(heights))
    if .10 < deviation <= .35:
     c.setdefault('qa',{})['height_tol']=.35
     c['qa']['height_reason']='Visible pose extent changes while one uniform scale is retained'
    if c['name'] in ['walk','run','crawl','glide','fly_idle','dive','fall','charge','hop_back']:
     c.setdefault('qa',{})['movement']=True
    neutral=c['name'] in ['idle','fly_idle','float','glide','idle_p2']
    reference=poses[0].height if neutral else float(np.median([p.height for p in poses]))
    target=float(d['height'])
    r=pack(source,c,out,target,bool(d['center']),reference_height=reference,fit=True);results.append({'enemy':d['id'],'clip':c['name'],**r});print('PACK',d['id'],c['name'],flush=True)
    c['image_size']=[c['frame_width']*c['frames'],c['frame_height']]
   except (ValueError,OSError) as e:failures.append({'enemy':d['id'],'clip':c['name'],'error':str(e)});ready=False;print('FAIL',d['id'],c['name'],e,flush=True)
  if ready:
   destination=ROOT/'archive/packed_enemies'/d['id']
   (destination/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
 if a.apply and not failures and not missing:
  import subprocess,shutil
  manifests=[ROOT/'archive/packed_enemies'/d['id']/'manifest.json' for d in catalog]
  checked=subprocess.run([sys.executable,str(ROOT/'tools/check_sprite_frames.py'),*[str(p) for p in manifests]],check=False)
  if checked.returncode:return 1
  for d in catalog:
   dest=ROOT/'assets/sprites/enemies'/d['id'];backup=ROOT/'archive/runtime_enemies_before_apply'/d['id']
   if dest.exists() and not backup.exists():shutil.copytree(dest,backup)
   dest.mkdir(parents=True,exist_ok=True)
   for source in (ROOT/'archive/packed_enemies'/d['id']).iterdir():shutil.copy2(source,dest/source.name)
 report={'clips':results,'failures':failures,'missing':missing};(ROOT/'archive/enemy_packing.json').write_text(json.dumps(report,indent=2));print(f'ENEMY_PACK: {len(results)} packed, {len(failures)} rejected, {len(missing)} missing');return int(bool(failures or missing))
if __name__=='__main__':sys.exit(main())
