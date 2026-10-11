#!/usr/bin/env python3
"""Apply folder encoding policy to non-sheet art with checked seam/alpha/color error."""
import json,shutil,io
from pathlib import Path
import numpy as np
from PIL import Image
from downscale_assets import ROOT,encode,rewrite_paths

def main():
 sheets={p.removeprefix('res://') for p in json.loads((ROOT/'data/sprite_trims.json').read_text())};art=json.loads((ROOT/'assets/art_manifest.json').read_text());tiled={str(Path('assets')/v['path']):v for v in art['assets'] if v.get('tile_x') or v.get('tile_y')};mapping={};records=[]
 for file in sorted((ROOT/'assets').rglob('*')):
  rel=str(file.relative_to(ROOT))
  if file.suffix not in ['.png','.webp'] or rel in sheets or any(v in file.parts for v in ['ui','tiles']):continue
  image=Image.open(file).convert('RGBA');original=np.array(image);backup=ROOT/'archive/stage8_encoding_before'/rel;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,backup);out=file.with_suffix('.webp');q=82 if '/backgrounds/' in rel else 86
  result=encode(image,out,q)
  if rel in tiled and result['mode']=='lossy':
   spec=tiled[rel];b=np.array(Image.open(out).convert('RGBA'));edge_error=[]
   for axis in ['tile_x','tile_y']:
    if not spec.get(axis):continue
    first=b[:,0,:3] if axis=='tile_x' else b[0,:,:3];last=b[:,-1,:3] if axis=='tile_x' else b[-1,:,:3]
    # Authored repeating edges must remain within2/255, with lossless fallback.
    edge_error.append(float(np.abs(first.astype(float)-last.astype(float)).mean()))
   if edge_error and max(edge_error)>2:
    image.save(out,'WEBP',lossless=True,method=6,exact=True);result.update(mode='lossless',rgb_mae=0,alpha_mae=0,reason='tile seam')
  if file!=out:file.unlink();mapping[rel]=str(out.relative_to(ROOT))
  records.append({'path':str(out.relative_to(ROOT)),'source':rel,'before':backup.stat().st_size,'after':out.stat().st_size,**result})
 rewrite_paths(mapping);(ROOT/'data/image_encoding_quality.json').write_text(json.dumps(records,indent=2)+'\n');print(f'ENCODING: {len(records)} images, {sum(v["before"] for v in records)/1048576:.2f}→{sum(v["after"] for v in records)/1048576:.2f}MiB')
if __name__=='__main__':main()
