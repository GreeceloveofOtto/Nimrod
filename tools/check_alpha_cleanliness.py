#!/usr/bin/env python3
"""Audit alpha/magenta against the authored asset manifest, including tile edges."""
import argparse,json,sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--report',default='docs/STAGE7_ALPHA_FIX.txt');a=p.parse_args();manifest=json.loads((ROOT/'assets/art_manifest.json').read_text());errors=[];rows=[]
 for spec in manifest['assets']:
  path=ROOT/'assets'/spec['path']
  if not path.exists():errors.append(f'Missing {spec["path"]}');continue
  pix=np.array(Image.open(path).convert('RGBA'));alpha=pix[:,:,3];occupied=alpha>12
  magenta=occupied&(pix[:,:,0]>245)&(pix[:,:,2]>245)&(pix[:,:,1]<20);fringe=int(magenta.sum())
  issues=[]
  if fringe>20:issues.append(f'{fringe} magenta pixels')
  if spec.get('transparent'):
   if alpha.min()==255:issues.append('opaque transparent asset')
   # Background layers and tiles may deliberately continue through edges.
   standalone=spec['path'].startswith(('props/','fx/')) and '/doors/' not in spec['path']
   if standalone:
    border=np.concatenate([alpha[0],alpha[-1],alpha[:,0],alpha[:,-1]])
    if border.max()>12:issues.append(f'border alpha {border.max()}')
  elif alpha.min()!=255:issues.append('nonopaque background/tile')
  if issues:errors.extend(f'{spec["path"]}: {i}' for i in issues)
  rows.append(f'{spec["path"]}\talpha={alpha.min()}..{alpha.max()}\tmagenta={fringe}\t'+('; '.join(issues) or 'PASS'))
 repair_path=ROOT/'data/alpha_repairs.json';repairs=json.loads(repair_path.read_text()) if repair_path.exists() else {}
 header='수정 목록 (원본은 archive/alpha_before에 보관):\n'+'\n'.join(repairs.get('reprocessed',[]))+ '\n재생성: '+', '.join(repairs.get('regenerated',[]))+'\n\n'
 (ROOT/a.report).write_text(header+f'ALPHA CLEANLINESS: {len(rows)} assets, {len(errors)} failures\n'+'\n'.join(errors+rows)+'\n');print(f'ALPHA_CLEANLINESS: {len(rows)} assets, {len(errors)} failures')
 for e in errors:print('FAIL',e)
 return int(bool(errors))
if __name__=='__main__':sys.exit(main())
