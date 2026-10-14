#!/usr/bin/env python3
"""Check generated periodic atlas boundaries and its two-pixel extrusion padding."""
import json,sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def check(path):
 p=np.array(Image.open(path).convert('RGBA'));errors=[]
 if p.shape[:2]!=(176,176):return ['Atlas must be 4x4 padded44px cells']
 for i in range(16):
  x=i%4*44;y=i//4*44;a=p[y+2:y+42,x+2:x+42]
  if not (a[:,:,3]==255).all():errors.append(f'{i}: alpha hole')
  if not np.array_equal(a[0],a[-1]) or not np.array_equal(a[:,0],a[:,-1]):errors.append(f'{i}: nonperiodic edges')
  if not np.array_equal(p[y+1,x+2:x+42],a[0]) or not np.array_equal(p[y+42,x+2:x+42],a[-1]):errors.append(f'{i}: padding mismatch')
 return errors
if __name__=='__main__':
 errors=[]
 for p in (ROOT/'assets/world/zabulistan').glob('*/terrain.webp'):errors.extend(str(p.relative_to(ROOT))+': '+s for s in check(p))
 print('TILE_SEAMS:',len(list((ROOT/'assets/world/zabulistan').glob('*/terrain.webp'))),'atlases;',len(errors),'errors');print('\n'.join(errors));sys.exit(bool(errors))
