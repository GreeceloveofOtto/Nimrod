#!/usr/bin/env python3
"""Try channel-aware bounded color quantization. Alpha stays byte-exact."""
import json,io,shutil,argparse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import numpy as np
from PIL import Image
from build_image_parity_fixtures import reference
from downscale_assets import ssim
R=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser();p.add_argument('--paths',required=True);a=p.parse_args();chosen=set(json.loads(Path(a.paths).read_text()));rows=json.loads((R/'data/storage_quality.json').read_text());specs=json.loads((R/'data/sprite_trims.json').read_text());results=[]
 def worker(row):
  if row['path'] not in chosen:return None
  path=R/row['path'].removeprefix('res://');source=reference(row,specs[row['path']]);a=np.array(source);mask=a[:,:,3]>12;before=path.stat().st_size;best=None;trials=[]
  variants=[(13,13,13),(14,12,10),(14,10,12),(12,14,10),(10,14,12),(12,10,14),(10,12,14),(16,10,10),(10,16,10),(10,10,16)]
  for steps in variants:
   b=a.copy()
   for channel,step in enumerate(steps):b[:,:,channel]=np.minimum(255,np.floor(b[:,:,channel].astype(float)/step+.5)*step).astype('uint8')
   rgb=float(np.abs(a[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean())
   if rgb>3:
    trials.append({'steps':steps,'rgb_mae':rgb,'rejected':'rgb gate'});continue
   im=Image.fromarray(b);score=ssim(source,im)
   if score<.93:continue
   buf=io.BytesIO();im.save(buf,'WEBP',lossless=True,method=6,exact=True);content=buf.getvalue();trials.append({'steps':steps,'rgb_mae':rgb,'ssim':score,'bytes':len(content)})
   if len(content)<before and (best is None or len(content)<len(best[0])):best=(content,trials[-1])
  if best:
   backup=R/'archive/stage13/before_quantize'/path.relative_to(R);backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,backup);path.write_bytes(best[0])
  return {'path':row['path'],'before':before,'after':len(best[0]) if best else before,'accepted':bool(best),'metrics':best[1] if best else {},'trials':trials}
 with ThreadPoolExecutor(max_workers=3) as pool:
  for future in as_completed([pool.submit(worker,row) for row in rows]):
   result=future.result()
   if result:results.append(result);print(result['path'],result['before'],'->',result['after'],flush=True)
 for result in results:
  if result['accepted']:
   for row in rows:
    if row['path']==result['path']:row.update(output_bytes=result['after'],encoder='channel-aware bounded RGB',rgb_mae=result['metrics']['rgb_mae'],alpha_mae=0.,bbox_same=True,quantization_steps=result['metrics']['steps'])
 for name,data in [('data/storage_quality.json',rows),('archive/stage13/quantize_trials.json',results)]: (R/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 print('QUANTIZE saved',sum(r['before']-r['after'] for r in results)/1048576,'MiB')
if __name__=='__main__':main()
