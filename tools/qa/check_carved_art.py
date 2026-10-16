#!/usr/bin/env python3
"""Check generated grayscale atlases, padding and every compatible shared edge."""
from pathlib import Path
import json,hashlib,argparse
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];A=ROOT/'archive/stage15_map';BASE=ROOT/'assets/world/zabulistan_v2/shared'
def frames(path,cols,rows,size):
 image=Image.open(path).convert('RGBA');a=np.asarray(image);out=[]
 for y in range(rows):
  for x in range(cols):out.append(a[y*(size+4)+2:y*(size+4)+2+size,x*(size+4)+2:x*(size+4)+2+size])
 return out

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--quality-file',type=Path,default=ROOT/'data/world/zabulistan/art_quality.json');args=parser.parse_args()
 errors=[];crust=frames(BASE/'crust.webp',20,3,32);wall=frames(BASE/'backwall.webp',16,3,32);support=frames(BASE/'supports.webp',4,2,64);fill=frames(BASE/'fill.webp',2,2,32);seams=[]
 for name,items in [('crust',crust),('backwall',wall),('support',support),('fill',fill)]:
  for i,tile in enumerate(items):
   if tile.shape[:2] not in [(32,32),(64,64)] or not tile[:,:,3].any():errors.append(f'{name}/{i}: empty or wrong frame size')
   if name in ['crust','backwall','fill'] and (tile[:,:,3]!=255).any():errors.append(f'{name}/{i}: alpha hole in terrain')
   if (np.max(tile[:,:,:3],axis=2)-np.min(tile[:,:,:3],axis=2)).max()>1:errors.append(f'{name}/{i}: shared source is not grayscale')
   if name=='support' and max(tile[:2,:,3].max(),tile[-2:,:,3].max(),tile[:,:2,3].max(),tile[:,-2:,3].max())>0:errors.append(f'{name}/{i}: 2px sprite margin')
 for name,tiles,columns,connected in [('crust',crust,20,True),('backwall',wall,16,False)]:
  for i,left in enumerate(tiles):
   mask=i%columns
   if mask>=16:continue
   for j,right in enumerate(tiles):
    other=j%columns
    if other>=16:continue
    if bool(mask&2)==connected and bool(other&8)==connected:
     error=float(np.abs(left[:,-1,:3].astype(float)-right[:,0,:3].astype(float)).mean());seams.append(error)
     if error>8:errors.append(f'{name}/{i}->{j}: horizontal seam {error:.2f}')
    if bool(mask&4)==connected and bool(other&1)==connected:
     error=float(np.abs(left[-1,:,:3].astype(float)-right[0,:,:3].astype(float)).mean());seams.append(error)
     if error>8:errors.append(f'{name}/{i}->{j}: vertical seam {error:.2f}')
 # 2x2 and 4x4 material contact sheets use the real atlas pixels.
 directory=A/'seams';directory.mkdir(parents=True,exist_ok=True)
 for n in [2,4]:
  montage=Image.new('RGBA',(32*n,32*n))
  for y in range(n):
   for x in range(n):
    mask=(1 if y else 0)|(2 if x<n-1 else 0)|(4 if y<n-1 else 0)|(8 if x else 0)
    montage.paste(Image.fromarray(crust[(x+y)%3*20+mask]),(x*32,y*32))
  montage.resize((n*128,n*128),Image.Resampling.NEAREST).save(directory/f'crust_{n}x{n}.png')
 quality=json.loads(args.quality_file.read_text())
 for row in quality:
  if '/shared/' not in row['path']:continue
  if hashlib.sha256((ROOT/row['path']).read_bytes()).hexdigest()!=row['sha256']:errors.append(row['path']+': stale quality evidence')
  if row['ssim']<.93 or row['rgb_mae']>3 or row['alpha_mae']>.5 or not row['bbox_same']:errors.append(row['path']+': codec gate')
 result={'passed':not errors,'frames':len(crust)+len(wall)+len(support)+len(fill)+1,'edge_pairs':len(seams),'maximum_edge_rgb_error':max(seams),'threshold':8,'errors':errors}
 (A/'carved_art_qa.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2));return int(bool(errors))
if __name__=='__main__':raise SystemExit(main())
