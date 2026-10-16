#!/usr/bin/env python3
"""Static atlas margins, alpha, anchor, density and source parity for world art."""
from pathlib import Path
import json,sys,hashlib,argparse
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--quality-file',type=Path,default=ROOT/'data/world/zabulistan/art_quality.json');args=parser.parse_args()
 data=json.loads((ROOT/'data/world/zabulistan/art_v2.json').read_text());errors=[];count=0
 for id,spec in data.items():
  im=Image.open(ROOT/spec['atlas'].removeprefix('res://')).convert('RGBA')
  for i,p in enumerate(spec['landmarks']):
   x,y,w,h=p['rect'];a=np.asarray(im.crop((x,y,x+w,y+h)));alpha=a[:,:,3]
   if alpha.max()==0:errors.append(f'{id}/{i}: empty')
   if max(alpha[:2].max(),alpha[-2:].max(),alpha[:,:2].max(),alpha[:,-2:].max())>0:errors.append(f'{id}/{i}: less than 2px margin')
   if not .9-1e-8<=1/p['game_scale']<=1.2+1e-8:errors.append(f'{id}/{i}: density')
   if p['anchor'][1]!=h-2:errors.append(f'{id}/{i}: foot anchor')
   if ((a[:,:,0]>240)&(a[:,:,2]>240)&(a[:,:,1]<30)&(alpha>12)).sum():errors.append(f'{id}/{i}: magenta')
   count+=1
  minimum=3 if spec.get('rendering')=='carved_shared' else 6
  if len(spec['backgrounds'])!=3 or spec['material_variants']<minimum:errors.append(id+': regional layers/variants')
 quality=json.loads(args.quality_file.read_text())
 for row in quality:
  if hashlib.sha256((ROOT/row['path']).read_bytes()).hexdigest()!=row['sha256']:errors.append(row['path']+': runtime hash differs from verified encoding')
  if row['rgb_mae']>3 or row['alpha_mae']>.5 or not row['bbox_same'] or row['ssim']<.93:errors.append(row['path']+': parity')
 result={'landmarks':count,'regions':len(data),'quality_rows':len(quality),'errors':errors};out=ROOT/'archive/stage14_rework/art_qa.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(result,indent=2));print('WORLD ART:',count,'landmarks,',len(errors),'errors');print('\n'.join(errors));return int(bool(errors))
if __name__=='__main__':sys.exit(main())
