#!/usr/bin/env python3
"""Try bounded RGB quantization against immutable authored pixels; adopt only all-gate passes."""
from pathlib import Path
import json,sys,io,shutil
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import numpy as np
from PIL import Image
from build_image_parity_fixtures import reference
from downscale_assets import ssim,ROOT

def trial(item):
 row,spec=item;p=ROOT/row['path'].removeprefix('res://');im=reference(row,spec);a=np.asarray(im);mask=a[:,:,3]>12;best=None;outcomes=[]
 for step in [16,14,12]:
  b=a.copy();b[:,:,:3]=np.minimum(255,np.round(b[:,:,:3].astype(float)/step)*step).astype('uint8');candidate=Image.fromarray(b);rgb=float(np.abs(a[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean())
  if rgb>3:outcomes.append({'step':step,'rgb':rgb,'pass':False});continue
  score=ssim(im,candidate)
  if score<.93:outcomes.append({'step':step,'rgb':rgb,'ssim':score,'pass':False});continue
  buf=io.BytesIO();candidate.save(buf,'WEBP',lossless=True,method=6,exact=True);content=buf.getvalue();outcomes.append({'step':step,'rgb':rgb,'ssim':score,'bytes':len(content),'pass':True})
  if len(content)<p.stat().st_size and (best is None or len(content)<len(best[0])):best=(content,{'mode':'lossy','encoder':'bounded RGB quantization','rgb_step':step,'quality':100,'rgb_mae':rgb,'alpha_mae':0,'bbox_same':True,'encoding_ssim':score})
 return row,spec,p,best,outcomes

def main():
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());rows=json.loads((ROOT/'data/storage_quality.json').read_text());policy=json.loads((ROOT/'data/image_policy.json').read_text());selected=sorted(rows,key=lambda r:(ROOT/r['path'].removeprefix('res://')).stat().st_size,reverse=True)[:30];results=[]
 with ThreadPoolExecutor(max_workers=3) as pool:
  for row,spec,p,best,tries in pool.map(trial,[(r,registry[r['path']]) for r in selected]):
   record={'path':row['path'],'before':p.stat().st_size,'trials':tries,'accepted':best is not None}
   if best:
    backup=ROOT/'archive/stage14_rework/optimization_before'/p.relative_to(ROOT);backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup);p.write_bytes(best[0]);row.update(best[1],output_bytes=len(best[0]));spec['encoding']=best[1];policy.setdefault('overrides',{})[str(p.relative_to(ROOT))]=best[1];record['after']=len(best[0])
   results.append(record);print(p.parent.name,p.stem,record['before'],record.get('after','KEEP'),flush=True)
 for name,data in [('data/storage_quality.json',rows),('data/sprite_trims.json',registry),('data/image_policy.json',policy),('archive/stage14_rework/optimization.json',results)]: (ROOT/name).write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
 print('Saved bytes',sum(r['before']-r.get('after',r['before']) for r in results))
if __name__=='__main__':main()
