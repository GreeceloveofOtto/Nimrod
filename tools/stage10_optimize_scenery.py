#!/usr/bin/env python3
"""Resample scenery under SSIM and color/alpha gates; retain its original game-space dimensions."""
import json,shutil
from pathlib import Path
from PIL import Image
from downscale_assets import ROOT,ssim
from build_image_parity_fixtures import reference
from stage9_optimize_density import encoded

def main():
 rows=json.loads((ROOT/'data/image_encoding_quality.json').read_text());art=json.loads((ROOT/'assets/art_manifest.json').read_text());catalog={v['path']:v for v in art['assets']};results=[]
 for row in rows:
  path=ROOT/row['path'].removeprefix('res://')
  if not path.exists() or path.suffix!='.webp' or '/backgrounds/' not in str(path) and '/props/' not in str(path):continue
  if path.stat().st_size<50000:continue
  original=reference({**row,'image_resize':None});entry=catalog.get(str(path.relative_to(ROOT/'assets')),{})
  if entry.get('tile_x') or entry.get('tile_y'):continue # Retain authored seamless edges.
  best=None;score=1
  for scale in [.65,.75,.85,.95]:
   resized=original.resize((round(original.width*scale),round(original.height*scale)),Image.Resampling.LANCZOS)
   score=ssim(original,resized.resize(original.size,Image.Resampling.LANCZOS))
   if score>=.93:
    content,metrics=encoded(resized)
    if len(content)<path.stat().st_size:best=(content,resized.size,scale,score,metrics);break
  before=path.stat().st_size;results.append({'path':row['path'],'before':before,'accepted':best is not None,'last_ssim':score})
  if best:
   content,size,scale,score,metrics=best;backup=ROOT/'archive/stage10_before_compression'/path.relative_to(ROOT);backup.parent.mkdir(parents=True,exist_ok=True)
   if not backup.exists():shutil.copy2(path,backup)
   path.write_bytes(content);row.update(image_resize=list(size),original_size=list(original.size),ssim=score,after=len(content),**metrics)
   if entry:
    entry['logical_width']=entry.get('logical_width',entry['width']);entry['logical_height']=entry.get('logical_height',entry['height']);entry['width'],entry['height']=size
   results[-1].update(after=len(content),ssim=score,scale=scale)
   print(path.name,scale,score,before,len(content),flush=True)
 (ROOT/'data/image_encoding_quality.json').write_text(json.dumps(rows,indent=2)+'\n');(ROOT/'assets/art_manifest.json').write_text(json.dumps(art,ensure_ascii=False,indent=2)+'\n');(ROOT/'archive/stage10/scenery_attempts.json').write_text(json.dumps(results,indent=2)+'\n')
 print('SCENERY saved',sum(x['before']-x['after'] for x in results if x['accepted'])/1048576)
if __name__=='__main__':main()
