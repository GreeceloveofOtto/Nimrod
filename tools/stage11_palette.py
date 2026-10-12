#!/usr/bin/env python3
"""Trial adaptive palettes against immutable pre-encoding references, alpha unchanged."""
import json,io,shutil,argparse
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.spatial import cKDTree
from build_image_parity_fixtures import reference
from downscale_assets import ROOT,ssim

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--prefix',default='');parser.add_argument('--paths');args=parser.parse_args();selected=set(json.loads(Path(args.paths).read_text())) if args.paths else None;registry=json.loads((ROOT/'data/sprite_trims.json').read_text());results=[]
 for table in ['storage_quality','image_encoding_quality']:
  p=ROOT/'data'/f'{table}.json';rows=json.loads(p.read_text())
  for row in rows:
   path=ROOT/row['path'].removeprefix('res://')
   if args.prefix and args.prefix not in row['path']:continue
   if selected is not None and row['path'] not in selected:continue
   if not path.exists() or path.suffix!='.webp':continue
   spec=registry.get(row['path']) if table=='storage_quality' else None
   source=reference(row,spec);a=np.array(source);mask=a[:,:,3]>12;visible=a[:,:,:3][mask]
   if not len(visible):continue
   best=None;trials=[]
   for n in [64,128,256]:
    sample=visible[::max(1,len(visible)//120000)];palette=Image.fromarray(sample.reshape(1,-1,3)).quantize(colors=n,method=Image.Quantize.MEDIANCUT).getpalette();colors=np.array(palette,dtype=np.uint8).reshape(-1,3);index=cKDTree(colors.astype(float)).query(visible,k=1,workers=1)[1];b=a.copy();b[:,:,:3][mask]=colors[index];rgb=float(np.abs(a[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean());trials.append({'colors':n,'rgb_mae':rgb})
    if rgb>3:
     errors=np.abs(visible.astype(float)-b[:,:,:3][mask].astype(float)).sum(axis=1);order=np.argsort(errors)[::-1];needed=errors.sum()-2.98*3*len(errors);cumulative=np.cumsum(errors[order]);count=int(np.searchsorted(cumulative,needed))+1;changed=b[:,:,:3][mask];changed[order[:count]]=visible[order[:count]];b[:,:,:3][mask]=changed;rgb=float(np.abs(a[:,:,:3][mask].astype(float)-changed.astype(float)).mean())
    # Preserve intentional graded dark borders; palette approximation cannot reintroduce black boxes.
    luma=b[:,:,:3].astype(float)@np.array([.2126,.7152,.0722]);bad=(luma<14)&(b[:,:,3]>200);b[:,:,:3][bad]=a[:,:,:3][bad]
    dark=(b[:,:,:3].astype(float)@np.array([.2126,.7152,.0722])<14)&(b[:,:,3]>200);edge=np.concatenate([dark[0],dark[-1],dark[:,0],dark[:,-1]])
    if edge.mean()>(.02 if a[:,:,3].min()==255 else .03):continue
    candidate=Image.fromarray(b);buf=io.BytesIO();candidate.save(buf,'WEBP',lossless=True,method=6,exact=True);content=buf.getvalue()
    if len(content)>=path.stat().st_size:continue
    # The palette gate supplements resampling SSIM. Check all stored cells.
    if spec:
     w,h=spec['stored_cell'];count=spec['stored_columns'];scores=[ssim(source.crop((i*w,0,(i+1)*w,h)),candidate.crop((i*w,0,(i+1)*w,h))) for i in range(count)];score=min(scores)
    else:score=ssim(source,candidate)
    if score<.93:continue
    if best is None or len(content)<len(best[0]):best=(content,rgb,n,score)
   result={'path':row['path'],'trials':trials,'accepted':best is not None}
   if best:
    backup=ROOT/'archive/stage11_before_palette'/path.relative_to(ROOT);backup.parent.mkdir(parents=True,exist_ok=True)
    if not backup.exists():shutil.copy2(path,backup)
    result.update(before=path.stat().st_size,after=len(best[0]),colors=best[2],ssim=best[3]);path.write_bytes(best[0]);row.update(mode='lossy',encoder=f'adaptive RGB{best[2]} palette / lossless WebP container',quality=100,rgb_mae=best[1],alpha_mae=0.,bbox_same=True,palette_ssim=best[3]);row['output_bytes' if spec else 'after']=len(best[0])
   results.append(result)
  p.write_text(json.dumps(rows,indent=2)+'\n')
 (ROOT/'archive/stage11/palette_trials.json').write_text(json.dumps(results,indent=2));print('PALETTE',len(results),'trials;',sum(r['accepted'] for r in results),'accepted; saved',sum(r.get('before',0)-r.get('after',0) for r in results)/1048576,'MiB')
if __name__=='__main__':main()
