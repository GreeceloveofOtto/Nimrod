#!/usr/bin/env python3
"""Despill a few pink edge pixels introduced by RGB encoding; never alter alpha."""
import json,shutil,io
import numpy as np
from pathlib import Path
from PIL import Image
from build_image_parity_fixtures import reference
R=Path(__file__).resolve().parents[1]
registry=json.loads((R/'data/sprite_trims.json').read_text());rows=json.loads((R/'data/storage_quality.json').read_text());policy=json.loads((R/'data/image_policy.json').read_text());results=[]
for row in rows:
 if '/gugalanna/' not in row['path']:continue
 path=R/row['path'].removeprefix('res://');im=Image.open(path).convert('RGBA');a=np.array(im);mask=(a[:,:,3]>0)&(a[:,:,0]>175)&(a[:,:,2]>175)&(a[:,:,1]<115)
 if not mask.any():continue
 backup=R/'archive/stage10_before_despill'/path.relative_to(R);backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,backup)
 a[:,:,2][mask]=np.minimum(a[:,:,2][mask],a[:,:,1][mask].astype(int)+8)
 fixed=Image.fromarray(a);raw=np.array(reference(row,registry[row['path']]));visible=raw[:,:,3]>12;rgb=float(abs(raw[:,:,:3][visible].astype(float)-a[:,:,:3][visible]).mean());alpha=float(abs(raw[:,:,3].astype(float)-a[:,:,3]).mean());bbox=reference(row,registry[row['path']]).getchannel('A').getbbox()==fixed.getchannel('A').getbbox()
 assert rgb<=3 and alpha<=.5 and bbox,(path,rgb,alpha,bbox)
 fixed.save(path,'WEBP',lossless=True,method=6,exact=True);metrics={'mode':'lossy','quality':100,'encoder':'edge blue-despill / lossless WebP container','rgb_mae':rgb,'alpha_mae':alpha,'bbox_same':bbox};row.update(**metrics,output_bytes=path.stat().st_size);registry[row['path']]['encoding']=metrics;policy.setdefault('overrides',{})[str(path.relative_to(R))]=metrics;results.append({'path':row['path'],'pixels':int(mask.sum()),**metrics})
for mp in (R/'assets/sprites/enemies/gugalanna').glob('manifest.json'):
 m=json.loads(mp.read_text())
 for c in m['clips']:c.update(registry['res://assets/'+c['sheet']])
 mp.write_text(json.dumps(m,indent=2)+'\n')
for f,d in [('data/storage_quality.json',rows),('data/sprite_trims.json',registry),('data/image_policy.json',policy),('archive/stage10/fringe_fixes.json',results)]: (R/f).write_text(json.dumps(d,indent=2)+'\n')
print('DESPILL',len(results),'files',sum(r['pixels'] for r in results),'pixels, all parity gates passed')
