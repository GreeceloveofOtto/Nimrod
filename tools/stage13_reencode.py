#!/usr/bin/env python3
"""Native resolution codec trials against archived original pixels, never against last output."""
import json,io,hashlib,shutil,argparse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import numpy as np
from PIL import Image
from build_image_parity_fixtures import reference
from downscale_assets import ssim
R=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser();p.add_argument('--paths',required=True);a=p.parse_args();chosen=set(json.loads(Path(a.paths).read_text()));rows=json.loads((R/'data/storage_quality.json').read_text());registry=json.loads((R/'data/sprite_trims.json').read_text());policy=json.loads((R/'data/image_policy.json').read_text());results=[]
 def worker(row):
  if row['path'] not in chosen:return None
  path=R/row['path'].removeprefix('res://');spec=registry[row['path']];source=reference(row,spec);before=path.stat().st_size;rgba=np.array(source);mask=rgba[:,:,3]>12;best=None;trials=[]
  for q in [82,86,90,94,98]:
   out=io.BytesIO();source.save(out,'WEBP',quality=q,alpha_quality=95,method=6,exact=True);content=out.getvalue();im=Image.open(io.BytesIO(content)).convert('RGBA');pixels=np.array(im);rgb=float(np.abs(rgba[:,:,:3][mask].astype(float)-pixels[:,:,:3][mask]).mean());alpha=float(np.abs(rgba[:,:,3].astype(float)-pixels[:,:,3]).mean());bbox=source.getchannel('A').getbbox()==im.getchannel('A').getbbox();score=ssim(source,im);ok=rgb<=3 and alpha<=.5 and bbox and score>=.93
   trials.append({'quality':q,'bytes':len(content),'rgb_mae':rgb,'alpha_mae':alpha,'bbox_same':bbox,'ssim':score,'pass':ok})
   if ok and len(content)<before and (best is None or len(content)<len(best[0])):best=(content,trials[-1])
  if best:
   backup=R/'archive/stage13/before_codec'/path.relative_to(R);backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,backup);path.write_bytes(best[0])
  return {'path':row['path'],'before':before,'after':len(best[0]) if best else before,'accepted':bool(best),'metrics':best[1] if best else {},'trials':trials}
 with ThreadPoolExecutor(max_workers=3) as pool:
  for future in as_completed([pool.submit(worker,r) for r in rows]):
   result=future.result()
   if result:results.append(result);print(result['path'],result['before'],'->',result['after'],flush=True)
 for result in results:
  if result['accepted']:
   metrics=result['metrics'];metrics.update(mode='lossy',encoder='YUV WebP')
   for row in rows:
    if row['path']==result['path']:row.update(output_bytes=result['after'],**metrics)
   policy.setdefault('overrides',{})[result['path'].removeprefix('res://')]=metrics
 for path,data in [('data/storage_quality.json',rows),('data/image_policy.json',policy),('archive/stage13/codec_trials.json',results)]: (R/path).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 print('CODEC savings',sum(r['before']-r['after'] for r in results)/1048576,'MiB')
if __name__=='__main__':main()
