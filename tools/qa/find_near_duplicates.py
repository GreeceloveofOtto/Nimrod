#!/usr/bin/env python3
"""Exact hashes plus conservative decoded-pixel similarity within matching dimensions."""
from pathlib import Path
import json,hashlib,collections
from PIL import Image
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
def main():
 groups=collections.defaultdict(list);exact=collections.defaultdict(list)
 for p in (ROOT/'assets').rglob('*.webp'):
  im=Image.open(p).convert('RGBA');small=np.asarray(im.resize((9,8)).convert('L'));bits=tuple((small[:,1:]>small[:,:-1]).ravel());groups[(im.size,bits)].append(p);exact[hashlib.sha256(p.read_bytes()).hexdigest()].append(str(p.relative_to(ROOT)))
 near=[]
 for paths in groups.values():
  for i,a in enumerate(paths):
   for b in paths[i+1:]:
    x=np.asarray(Image.open(a).convert('RGBA'));y=np.asarray(Image.open(b).convert('RGBA'));error=float(np.abs(x.astype(float)-y).mean())
    if error<.25:near.append({'a':str(a.relative_to(ROOT)),'b':str(b.relative_to(ROOT)),'rgba_mae':error,'action':'Retain semantic geometry unless exact hash also matches'})
 out={'hash_duplicates':[v for v in exact.values() if len(v)>1],'near_candidates':near,'threshold_rgba_mae':.25,'merged_bytes':0}
 p=ROOT/'archive/stage14_rework/duplicates.json';p.write_text(json.dumps(out,indent=2));print('DUPLICATES:',len(out['hash_duplicates']),'exact;',len(near),'near; merged 0 bytes')
if __name__=='__main__':main()
