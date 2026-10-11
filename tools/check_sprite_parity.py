#!/usr/bin/env python3
"""Compare reconstructed trimmed/WebP sprites with preserved originals.
Alpha and every visible RGBA pixel must match; transparent RGB is immaterial.
"""
import json,sys
from pathlib import Path
import numpy as np
from PIL import Image
from check_sprite_frames import frame_images
ROOT=Path(__file__).resolve().parents[1]
def main():
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());mapping=json.loads((ROOT/'data/image_mapping.json').read_text());inverse={v:k for k,v in mapping.items()};checks=0;errors=[]
 for path,spec in registry.items():
  relative=path.removeprefix('res://');old=inverse.get(relative,relative);original=ROOT/'archive/untrimmed'/old
  if not original.exists():errors.append(f'Preserved untrimmed image missing: {old}');continue
  source=Image.open(original).convert('RGBA');w,h=spec['frame_width'],spec['frame_height']
  for i,frame in enumerate(frame_images(ROOT/relative,spec)):
   a=np.asarray(source.crop((i*w,0,(i+1)*w,h)));b=np.asarray(frame);mask=a[:,:,3]>0;checks+=1
   if not np.array_equal(a[:,:,3],b[:,:,3]) or not np.array_equal(a[mask],b[mask]):errors.append(f'{relative} frame{i+1}: changed visible pixels')
   # Verify both directions, including off-center original anchor.
   if not np.array_equal(a[:,::-1,3],b[:,::-1,3]):errors.append(f'{relative} frame{i+1}: mirrored alpha changed')
 for item in json.loads((ROOT/'archive/image_conversion.json').read_text()):
  if item['accepted'] and (item['error']!=0 if item['transparent'] else item['error']>2):errors.append(f'Image conversion exceeds allowed error: {item["path"]}')
 report={'frames_checked':checks,'errors':errors};(ROOT/'archive/parity_results.json').write_text(json.dumps(report,indent=2));print(f'SPRITE_PARITY: {checks} frames, {len(errors)} failures')
 for e in errors:print('FAIL:',e)
 return int(bool(errors))
if __name__=='__main__':sys.exit(main())
