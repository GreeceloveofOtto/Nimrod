#!/usr/bin/env python3
"""Recompute every stored image's encoding error against archived authored pixels."""
import json
import numpy as np
from PIL import Image
from build_image_parity_fixtures import reference
from downscale_assets import ROOT

def main():
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());errors=[];frames=0;checked=0;maxrgb=0.;maxalpha=0.
 for table in ['storage_quality','image_encoding_quality']:
  for r in json.loads((ROOT/'data'/f'{table}.json').read_text()):
   path=ROOT/r['path'].removeprefix('res://')
   if not path.exists():
    if table=='storage_quality':errors.append(r['path']+': missing image')
    continue
   spec=registry.get(r['path']) if table=='storage_quality' else None
   source=reference(r,spec);actual=Image.open(path).convert('RGBA');checked+=1
   if source.size!=actual.size:errors.append(r['path']+': dimensions changed');continue
   a=np.array(source);b=np.array(actual);mask=a[:,:,3]>12
   alpha=float(np.abs(a[:,:,3].astype(float)-b[:,:,3]).mean());rgb=float(np.abs(a[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean()) if mask.any() else 0.
   bbox=source.getchannel('A').getbbox()==actual.getchannel('A').getbbox();maxrgb=max(maxrgb,rgb);maxalpha=max(maxalpha,alpha)
   if alpha>.5 or rgb>3 or not bbox:errors.append(r['path']+f': alpha {alpha:.5f}, RGB {rgb:.5f}, bbox {bbox}')
   if spec:
    frames+=r['frames']
    if r['ssim']<.93:errors.append(r['path']+': resampling SSIM below .93')
 report={'images_checked':checked,'frames_checked':frames,'max_rgb_mae':maxrgb,'max_alpha_mae':maxalpha,'errors':errors,'policy':'SSIM >=.93; alphaMAE <=0.5; RGBMAE <=3; bbox unchanged during encoding'};(ROOT/'archive/parity_results.json').write_text(json.dumps(report,indent=2));print(f'SPRITE_PARITY: {checked} images, {frames} frames, {len(errors)} failures');print('\n'.join(errors));return int(bool(errors))
if __name__=='__main__':raise SystemExit(main())
