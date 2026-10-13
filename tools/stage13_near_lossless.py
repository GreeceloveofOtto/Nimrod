#!/usr/bin/env python3
"""Use libwebp's adaptive near-lossless preprocessor, with original-pixel quality gates."""
import argparse,io,json,os,shutil,subprocess,tempfile
from concurrent.futures import ThreadPoolExecutor,as_completed
from pathlib import Path
import numpy as np
from PIL import Image
from build_image_parity_fixtures import reference
from downscale_assets import ssim
R=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser();p.add_argument('--paths',required=True);p.add_argument('--cwebp',default=os.environ.get('CWEBP_BIN','/workspace/tools/webp/usr/bin/cwebp'));a=p.parse_args();selected=set(json.loads(Path(a.paths).read_text()));registry=json.loads((R/'data/sprite_trims.json').read_text());sr=json.loads((R/'data/storage_quality.json').read_text());ir=json.loads((R/'data/image_encoding_quality.json').read_text());results=[]
 def worker(row):
  if row['path'] not in selected:return None
  path=R/row['path'].removeprefix('res://');source=reference(row,registry.get(row['path']));pixels=np.array(source);mask=pixels[:,:,3]>12;before=path.stat().st_size;best=None;trials=[]
  with tempfile.TemporaryDirectory(prefix='nimrod-near-',dir='/tmp') as folder:
   src=Path(folder)/'source.png';source.save(src)
   for level in [0,20,40,60]:
    target=Path(folder)/'candidate.webp';subprocess.run([a.cwebp,'-quiet','-lossless','-near_lossless',str(level),'-m','6','-exact',str(src),'-o',str(target)],check=True)
    content=target.read_bytes();im=Image.open(target).convert('RGBA');b=np.array(im);rgb=float(np.abs(pixels[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean());alpha=float(np.abs(pixels[:,:,3].astype(float)-b[:,:,3]).mean());bbox=source.getchannel('A').getbbox()==im.getchannel('A').getbbox();score=ssim(source,im);ok=rgb<=3 and alpha<=.5 and bbox and score>=.93
    trials.append({'near_lossless':level,'bytes':len(content),'rgb_mae':rgb,'alpha_mae':alpha,'bbox_same':bbox,'ssim':score,'accepted_quality':ok})
    if ok and len(content)<before and (best is None or len(content)<len(best[0])):best=(content,trials[-1])
  if best:
   backup=R/'archive/stage13/before_near'/path.relative_to(R);backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,backup);path.write_bytes(best[0])
  return {'path':row['path'],'before':before,'after':len(best[0]) if best else before,'accepted':bool(best),'metrics':best[1] if best else {},'trials':trials}
 with ThreadPoolExecutor(max_workers=3) as pool:
  for future in as_completed([pool.submit(worker,row) for row in sr+ir]):
   result=future.result()
   if result:results.append(result);print(result['path'],result['before'],'->',result['after'],flush=True)
 for result in results:
  if result['accepted']:
   for row in sr+ir:
    if row['path']==result['path']:row.update(encoder='libwebp adaptive near-lossless',output_bytes=result['after'],**result['metrics'])
 for path,data in [('data/storage_quality.json',sr),('data/image_encoding_quality.json',ir),('archive/stage13/near_lossless_trials.json',results)]: (R/path).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 print('NEAR savings MiB',sum(r['before']-r['after'] for r in results)/1048576)
if __name__=='__main__':main()
