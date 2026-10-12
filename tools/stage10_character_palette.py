#!/usr/bin/env python3
"""Try a 128-color adaptive RGB palette; keep alpha and reject failed quality/seam gates."""
import json,io,shutil,argparse
from PIL import Image
import numpy as np
from scipy.spatial import cKDTree
from downscale_assets import ROOT
from build_image_parity_fixtures import reference

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--scenery-only',action='store_true');args=parser.parse_args()
 inventory=set(json.loads((ROOT/'data/stage10_asset_inventory.json').read_text())['generated'])
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());result=[];catalog={v['path']:v for v in json.loads((ROOT/'assets/art_manifest.json').read_text())['assets']}
 for table in (['image_encoding_quality'] if args.scenery_only else ['storage_quality','image_encoding_quality']):
  p=ROOT/'data'/f'{table}.json';rows=json.loads(p.read_text())
  for row in rows:
   if row['path'].removeprefix('res://') not in inventory:continue
   path=ROOT/row['path'].removeprefix('res://')
   if not path.exists() or path.suffix!='.webp' or not any('/'+k+'/' in str(path) for k in ['axe_onearm']):continue
   source=reference(row,registry.get(row['path']) if table=='storage_quality' else None);a=np.array(source);mask=a[:,:,3]>12;visible=a[:,:,:3][mask]
   if len(visible)==0:continue
   # Learn only from visible paint; unused transparent RGB must not dominate.
   pixels=Image.fromarray(visible.reshape(1,-1,3));palette=pixels.quantize(colors=256,method=Image.Quantize.MEDIANCUT).getpalette();colors=np.array(palette,dtype=np.uint8).reshape(-1,3);tree=cKDTree(colors.astype(float));idx=tree.query(visible,k=1,workers=1)[1];b=a.copy();b[:,:,:3][mask]=colors[idx];error=float(abs(a[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean());entry={'path':row['path'],'rgb_mae':error,'accepted':False}
   spec=catalog.get(str(path.relative_to(ROOT/'assets')),{})
   seam_ok=(not spec.get('tile_x') or abs(b[:,0,:].astype(float)-b[:,-1,:].astype(float)).mean()<=2) and (not spec.get('tile_y') or abs(b[0,:,:].astype(float)-b[-1,:,:].astype(float)).mean()<=2)
   luma=b[:,:,:3].astype(float)@np.array([.2126,.7152,.0722]);dark=(luma<14)&(b[:,:,3]>200);edges=np.concatenate([dark[0],dark[-1],dark[:,0],dark[:,-1]]);black_ok=float(edges.mean())<=(.02 if a[:,:,3].min()==255 else .03)
   if error<=3 and seam_ok and black_ok:
    candidate=Image.fromarray(b);buffer=io.BytesIO();candidate.save(buffer,'WEBP',lossless=True,method=6,exact=True);content=buffer.getvalue()
    if len(content)<path.stat().st_size:
     backup=ROOT/'archive/stage10_before_character_palette'/path.relative_to(ROOT);backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,backup);entry.update(accepted=True,before=path.stat().st_size,after=len(content));path.write_bytes(content);row.update(mode='lossy',encoder='adaptive RGB256 palette / lossless WebP container',rgb_mae=error,alpha_mae=0,bbox_same=True);row['output_bytes' if table=='storage_quality' else 'after']=len(content)
   result.append(entry)
  p.write_text(json.dumps(rows,indent=2)+'\n')
 (ROOT/'archive/stage10/character_palette_256_attempts.json').write_text(json.dumps(result,indent=2)+'\n');print('PALETTE',len(result),'trials',sum(x['accepted'] for x in result),'accepted, saved',sum(x.get('before',0)-x.get('after',0) for x in result)/1048576)
if __name__=='__main__':main()
