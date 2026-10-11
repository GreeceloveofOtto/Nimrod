#!/usr/bin/env python3
"""Classify and audit every runtime image, including opaque black edge contamination."""
import argparse,json,sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import label
ROOT=Path(__file__).resolve().parents[1]
def classify():
 art={str(Path('assets')/v['path']):v for v in json.loads((ROOT/'assets/art_manifest.json').read_text())['assets']}
 result={}
 for p in sorted((ROOT/'assets').rglob('*')):
  if p.suffix.lower() not in ['.png','.webp','.jpg','.jpeg']:continue
  rel=str(p.relative_to(ROOT));im=Image.open(p).convert('RGBA');a=np.array(im.getchannel('A'))
  transparent=art.get(rel,{}).get('transparent',bool(a.min()<255))
  result[rel]={'mode':'transparent' if transparent else 'opaque','edge_black_fraction':.03 if transparent else .02,'source':'art_manifest' if rel in art else 'runtime image'}
 return result

def audit(path,spec):
 a=np.array(Image.open(path).convert('RGBA'));alpha=a[:,:,3];occupied=alpha>12;luma=a[:,:,:3].astype(float)@np.array([.2126,.7152,.0722]);issues=[]
 if ((a[:,:,0]>245)&(a[:,:,2]>245)&(a[:,:,1]<20)&occupied).sum()>20:issues.append('magenta contamination')
 opaque=spec['mode']=='opaque'
 if opaque and alpha.min()!=255:issues.append('expected opaque')
 if not opaque and alpha.min()==255:issues.append('expected transparency')
 mask=(luma<14)&(alpha>200)
 edge=np.concatenate([mask[0],mask[-1],mask[:,0],mask[:,-1]])
 frac=float(edge.mean())
 if frac>spec['edge_black_fraction']:issues.append(f'near-black edge {frac:.4%}')
 # Connected nearly uniform opaque areas touching an edge reveal baked backdrops.
 if not opaque:
  rgb=a[:,:,:3];q=(rgb.astype(np.int32)//6);codes=q[:,:,0]*44*44+q[:,:,1]*44+q[:,:,2]
  border_codes=np.unique(np.concatenate([codes[0][alpha[0]>200],codes[-1][alpha[-1]>200],codes[:,0][alpha[:,0]>200],codes[:,-1][alpha[:,-1]>200]]))
  for c in border_codes:
   m=(codes==c)&(alpha>200)
   if m.sum()<alpha.size*.04:continue
   components,count=label(m);sizes=np.bincount(components.ravel());border_ids=np.unique(np.concatenate([components[0],components[-1],components[:,0],components[:,-1]]));border_ids=border_ids[border_ids>0]
   if any(sizes[i]>=alpha.size*.04 for i in border_ids):issues.append('uniform edge-connected opaque backdrop >=4%');break
 return issues

def main():
 p=argparse.ArgumentParser();p.add_argument('--report',default='docs/STAGE8_ALPHA_FIX.txt');p.add_argument('--classify',action='store_true');a=p.parse_args();specpath=ROOT/'data/alpha_expectations.json'
 if a.classify or not specpath.exists():specpath.write_text(json.dumps(classify(),indent=2)+'\n')
 specs=json.loads(specpath.read_text());rows=[];fail=[]
 for path,spec in specs.items():
  issues=audit(ROOT/path,spec) if (ROOT/path).exists() else ['missing image'];rows.append(path+'\t'+('; '.join(issues) or 'PASS'));fail.extend(path+': '+v for v in issues)
 (ROOT/a.report).write_text('ALPHA CLEANLINESS: '+str(len(rows))+' images, '+str(len(fail))+' failures\n'+'\n'.join(fail+rows)+'\n');print(f'ALPHA_CLEANLINESS: {len(rows)} images, {len(fail)} failures')
 for v in fail:print('FAIL',v)
 return int(bool(fail))
if __name__=='__main__':sys.exit(main())
