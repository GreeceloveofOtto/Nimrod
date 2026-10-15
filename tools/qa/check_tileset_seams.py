#!/usr/bin/env python3
"""Audit all painted tile interfaces and render independent 2x2 /4x4 montages."""
from pathlib import Path
import json,sys
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
def main():
 catalog=json.loads((ROOT/'data/world/zabulistan/art_v2.json').read_text());errors=[];report=[];folder=ROOT/'archive/stage14_rework/seams';folder.mkdir(parents=True,exist_ok=True)
 for id,spec in catalog.items():
  im=Image.open(ROOT/spec['terrain'].removeprefix('res://')).convert('RGBA');tiles=[im.crop((2+x*36,2,34+x*36,34)) for x in range(6)];maximum=0.
  for a in tiles:
   for b in tiles:
    aa=np.asarray(a).astype(float);bb=np.asarray(b).astype(float)
    maximum=max(maximum,float(np.abs(aa[:,-1,:3]-bb[:,0,:3]).mean()),float(np.abs(aa[-1,:,:3]-bb[0,:,:3]).mean()))
    if np.asarray(a)[:,:,3].min()!=255:errors.append(id+': alpha hole in opaque material')
  # Shared sampled edge correction must remain below a visible 8/255 seam.
  if maximum>8:errors.append(f'{id}: edge mean {maximum:.3f} >8')
  for n in [2,4]:
   montage=Image.new('RGBA',(32*n,32*n))
   for y in range(n):
    for x in range(n):montage.paste(tiles[(x+y*3)%6],(x*32,y*32))
   montage.resize((n*128,n*128),Image.Resampling.NEAREST).save(folder/f'{id}_{n}x{n}.png')
  report.append({'region':id,'materials':6,'edge_rgb_mean_max':maximum,'threshold':8,'alpha_holes':0})
 (folder/'report.json').write_text(json.dumps({'rows':report,'errors':errors},indent=2));print('TILE SEAMS:',len(report),'regions;',len(errors),'errors');return int(bool(errors))
if __name__=='__main__':sys.exit(main())
