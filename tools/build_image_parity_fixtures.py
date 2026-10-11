#!/usr/bin/env python3
"""Ship samples from pre-encoding art at its new storage resolution, not encoded output."""
import base64,json
from pathlib import Path
from PIL import Image
R=Path(__file__).resolve().parents[1]
def reference(row,spec=None):
 archive='stage8_density_before' if spec else 'stage8_encoding_before';im=Image.open(R/'archive'/archive/row['source']).convert('RGBA')
 if spec:
  t=spec['trim'];st=spec['storage_trim'];out=Image.new('RGBA',tuple(spec['image_size']));seen=set()
  for i,k in enumerate(spec['frame_map']):
   if k in seen:continue
   seen.add(k);frame=im.crop((i*t['w'],0,(i+1)*t['w'],t['h'])).resize((st['w'],st['h']),Image.Resampling.LANCZOS);out.paste(frame,(k*st['w'],0))
  return out
 return im

def main():
 density=json.loads((R/'data/storage_quality.json').read_text());encoding=json.loads((R/'data/image_encoding_quality.json').read_text());registry=json.loads((R/'data/sprite_trims.json').read_text());selected=[]
 for row in density:
  if Path(row['source']).stem in ['idle','fly_idle','float','glide','perch_ceiling']:selected.append((row,registry[row['path']]))
 selected.extend((r,None) for r in encoding[:8]);samples=[]
 for row,spec in selected:
  image=reference(row,spec);w,h=image.size;pw,ph=min(32,w),min(32,h);points=[(0,0),(w//2,h//2),(max(0,w-pw),max(0,h-ph))];patches=[]
  for x,y in points:
   x=min(x,w-pw);y=min(y,h-ph);crop=image.crop((x,y,x+pw,y+ph));decoded=Image.open(R/row['path'].removeprefix('res://')).convert('RGBA').crop((x,y,x+pw,y+ph));import numpy as np;a=np.array(crop);b=np.array(decoded);mask=a[:,:,3]>12;local_rgb=float(np.abs(a[:,:,:3].astype(float)-b[:,:,:3]).astype(float)[mask].mean()) if mask.any() else 0.;patches.append({'rect':[x,y,pw,ph],'rgba':base64.b64encode(crop.tobytes()).decode(),'encoded_patch_rgb_mae':local_rgb})
  path=row['path'];samples.append({'path':path if path.startswith('res://') else 'res://'+path,'size':[w,h],'patches':patches,'source':row['source']})
 (R/'data/image_parity_samples.json').write_text(json.dumps({'policy':'pre-encoding samples after authorized density resampling','samples':samples},indent=2)+'\n');print('IMAGE_PARITY_FIXTURES:',len(samples))
if __name__=='__main__':main()
