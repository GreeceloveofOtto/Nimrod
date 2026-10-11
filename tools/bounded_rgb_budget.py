#!/usr/bin/env python3
"""Per-file bounded RGB quantization, preserving alpha exactly and authored shape.
A color-storage transform, never art generation. Retains only smaller candidates
that meet the user's whole-image RGBMAE<=3, alphaMAE<=1.5 and exact alpha bbox.
"""
import json,tempfile
from pathlib import Path
import numpy as np
from PIL import Image
from downscale_assets import ROOT
from build_image_parity_fixtures import reference

def main():
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());policy=json.loads((ROOT/'data/image_policy.json').read_text());saved=0;accepted=0
 with tempfile.TemporaryDirectory(dir='/tmp',prefix='nimrod-bounded-') as tmp:
  candidate=Path(tmp)/'candidate.webp'
  for table in ['storage_quality','image_encoding_quality']:
   p=ROOT/'data'/f'{table}.json';rows=json.loads(p.read_text())
   for r in sorted(rows,key=lambda r:(ROOT/r['path'].removeprefix('res://')).stat().st_size if (ROOT/r['path'].removeprefix('res://')).exists() else 0,reverse=True):
    path=ROOT/r['path'].removeprefix('res://')
    if not path.exists() or path.stat().st_size<40000 or '/backgrounds/' in path.as_posix() or '/tiles/' in path.as_posix():continue
    spec=registry.get('res://'+str(path.relative_to(ROOT))) if table=='storage_quality' else None
    image=reference(r,spec);a=np.array(image);mask=a[:,:,3]>12;best=None;old=path.stat().st_size
    for step in [12,10]:
     b=a.copy();b[:,:,:3]=np.minimum(255,np.floor(a[:,:,:3].astype(float)/step+.5)*step).astype(np.uint8)
     rgb=float(np.abs(a[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean()) if mask.any() else 0
     if rgb>3:continue
     Image.fromarray(b).save(candidate,'WEBP',lossless=True,method=6,exact=True)
     decoded=Image.open(candidate).convert('RGBA');actual=np.array(decoded);alpha=float(np.abs(a[:,:,3].astype(float)-actual[:,:,3]).mean());bbox=image.getchannel('A').getbbox()==decoded.getchannel('A').getbbox()
     if bbox and alpha<=1.5 and candidate.stat().st_size<old:
      best=(candidate.read_bytes(),step,rgb,alpha);break
    if best:
     content,step,rgb,alpha=best;path.write_bytes(content);saved+=old-len(content);accepted+=1;r.update(mode='lossy',encoder='bounded RGB quantization',rgb_step=step,quality=100,rgb_mae=rgb,alpha_mae=alpha,bbox_same=True)
     r['output_bytes' if table=='storage_quality' else 'after']=len(content)
     policy.setdefault('overrides',{})[str(path.relative_to(ROOT))]={'mode':'lossy','encoder':'bounded RGB quantization','rgb_step':step,'quality':100,'reason':'Whole-image RGBMAE <=3 and exact source alpha; smaller than YUV or near-lossless alternatives'}
     print(f'BOUNDED_RGB {path.relative_to(ROOT)}: step{step}, RGB {rgb:.3f}, saved {(old-len(content))/1024:.1f}KiB',flush=True)
   p.write_text(json.dumps(rows,indent=2)+'\n')
 (ROOT/'data/image_policy.json').write_text(json.dumps(policy,indent=2)+'\n');print(f'BOUNDED_RGB: {accepted} files, saved {saved/1048576:.2f}MiB')
if __name__=='__main__':main()
