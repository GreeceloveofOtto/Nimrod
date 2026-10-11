#!/usr/bin/env python3
"""Checked RGB near-lossless overrides avoid YUV subsampling color errors.
All thresholds remain: exact alpha bbox, alphaMAE<=1.5 and visible RGBMAE<=3.
"""
import json,os,shutil,subprocess,tempfile
from pathlib import Path
import numpy as np
from PIL import Image
from downscale_assets import ROOT
from build_image_parity_fixtures import reference

def find_encoder():
 p=os.getenv('CWEBP_BIN') or shutil.which('cwebp') or '/workspace/tools/webp-tools/usr/bin/cwebp'
 if not Path(p).is_file():raise RuntimeError('Set CWEBP_BIN to a libwebp cwebp executable; gameplay does not require it')
 return p

def main():
 policy=json.loads((ROOT/'data/image_policy.json').read_text());registry=json.loads((ROOT/'data/sprite_trims.json').read_text());saved=0;accepted=0;encoder=find_encoder()
 with tempfile.TemporaryDirectory(dir='/tmp',prefix='nimrod-near-') as tmp:
  source=Path(tmp)/'source.png';candidate=Path(tmp)/'candidate.webp'
  for table in ['storage_quality','image_encoding_quality']:
   p=ROOT/'data'/f'{table}.json';rows=json.loads(p.read_text())
   for r in rows:
    path=ROOT/r['path'].removeprefix('res://')
    if not path.exists():continue
    before=path.stat().st_size
    if r['mode']!='lossless' or before<40000:continue
    spec=registry.get('res://'+str(path.relative_to(ROOT))) if table=='storage_quality' else None
    image=reference(r,spec);image.save(source);a=np.array(image.convert('RGBA'));mask=a[:,:,3]>12
    for level in [40,60,80]:
     subprocess.run([encoder,'-quiet','-lossless','-near_lossless',str(level),'-q','100','-m','6','-exact',str(source),'-o',str(candidate)],check=True)
     decoded=Image.open(candidate).convert('RGBA')
     # Preserve the source alpha exactly; quantization is limited to RGB.
     decoded.putalpha(image.getchannel('A'))
     decoded.save(candidate,'WEBP',lossless=True,method=6,exact=True)
     b=np.array(Image.open(candidate).convert('RGBA'));alpha=float(np.abs(a[:,:,3].astype(float)-b[:,:,3]).mean());rgb=float(np.abs(a[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean());bbox=image.getchannel('A').getbbox()==Image.fromarray(b[:,:,3]).getbbox()
     if bbox and alpha<=1.5 and rgb<=3 and candidate.stat().st_size<before:
      path.write_bytes(candidate.read_bytes());saved+=before-path.stat().st_size;accepted+=1;r.update(mode='lossy',encoder='RGB near-lossless',near_lossless=level,quality=100,alpha_mae=alpha,rgb_mae=rgb,bbox_same=True)
      if table=='storage_quality':r['output_bytes']=path.stat().st_size
      else:r['after']=path.stat().st_size
      policy.setdefault('overrides',{})[str(path.relative_to(ROOT))]={'mode':'lossy','encoder':'RGB near-lossless','near_lossless':level,'quality':100,'reason':'YUV subsampling exceeded RGBMAE3; bounded RGB preprocessing passes same thresholds'}
      print(f'NEAR_LOSSLESS {path.name}: level{level}, RGB {rgb:.3f}, alpha {alpha:.3f}',flush=True);break
   p.write_text(json.dumps(rows,indent=2)+'\n')
 (ROOT/'data/image_policy.json').write_text(json.dumps(policy,indent=2)+'\n');print(f'NEAR_LOSSLESS: {accepted} files, saved {saved/1048576:.2f}MiB')
if __name__=='__main__':main()
