#!/usr/bin/env python3
"""Preserve dark garment paint during magenta keying; normalize to original pose boxes."""
from pathlib import Path
from types import SimpleNamespace
import json,math
import numpy as np
from PIL import Image
from scipy import ndimage
from pack_sprites import apply_storage_policy
ROOT=Path(__file__).resolve().parents[1]
def main():
 for variant in ['axe_onearm','axe_prosthetic']:
  source=Image.open(ROOT/'archive/stage10/source_art'/f'{variant}_death.png').convert('RGBA');raw=Image.open(ROOT/'archive/untrimmed/assets/sprites/player/axe/death.png').convert('RGBA');out=Image.new('RGBA',(5120,640));mp=ROOT/'assets/sprites/player'/variant/'manifest.json';m=json.loads(mp.read_text());c=next(c for c in m['clips'] if c['name']=='death')
  for i in range(8):
   cell=source.crop((round(i%4*source.width/4),round(i//4*source.height/2),round((i%4+1)*source.width/4),round((i//4+1)*source.height/2)));a=np.asarray(cell).copy().astype(float);r,g,b=a[:,:,0],a[:,:,1],a[:,:,2];dominance=np.minimum(r,b)-g
   key=(r>=140)&(b>=140)&(g<110)&(dominance>=50);a[key]=0
   # Dark purple is garment shadow reflected from the matte, not empty background.
   fringe=(~key)&(dominance>8);a[:,:,0][fringe]=np.minimum(a[:,:,0][fringe],a[:,:,1][fringe]+8);a[:,:,2][fringe]=np.minimum(a[:,:,2][fringe],a[:,:,1][fringe]+8)
   labels,count=ndimage.label(a[:,:,3]>12);sizes=np.bincount(labels.ravel());sizes[0]=0
   # Remove isolated matte/compression specks before calculating the body bounds.
   a[sizes[labels]<max(8,sizes.max()*.03)]=0
   pose=Image.fromarray(a.astype('uint8'));box=pose.getchannel('A').point(lambda v:255 if v>12 else 0).getbbox();pose=pose.crop(box);reference=raw.crop((i*640,0,(i+1)*640,640));bounds=reference.getchannel('A').point(lambda v:255 if v>12 else 0).getbbox();pose=pose.resize((bounds[2]-bounds[0],bounds[3]-bounds[1]),Image.Resampling.LANCZOS);out.alpha_composite(pose,(i*640+bounds[0],600-pose.height))
  path=mp.parent/'death.png';out.save(path);apply_storage_policy(SimpleNamespace(output=str(path),frames=8,frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='player',canonical_only=False),out,True)
  print('REPAIRED',variant)

if __name__=="__main__":main()
