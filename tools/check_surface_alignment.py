#!/usr/bin/env python3
"""Measure alpha-visible surface edges and audit the data-driven collision offsets."""
import argparse,json,sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]

def measure(path):
 im=Image.open(ROOT/path.removeprefix('res://')).convert('RGBA');a=np.array(im)[:,:,3];solid=a>12;rows=(a>12).mean(axis=1);indices=np.flatnonzero(rows>=.30)
 if not len(indices):raise ValueError(f'No readable 30% surface edge: {path}')
 x=np.flatnonzero(solid.any(axis=0));return {'top_offset_px':int(indices[0]),'bottom_offset_px':int(im.height-indices[-1]-1),'opaque_x0':int(x[0]),'opaque_x1':int(x[-1]+1),'image_width':im.width,'image_height':im.height}

def entries(registry):
 world=registry['world']
 for l in registry['levels']:
  tile=l.get('floor_art_size',[512,200]);path=l.get('floor_art','')
  for i,s in enumerate(l.get('terrain',[])):yield l['id'],f'terrain_{i}',s.get('art',path),[s['to']-s['from'],tile[1]],'floor'
  if not l.get('terrain') and path:yield l['id'],'floor',path,[l['width'],tile[1]],'floor'
  for i,s in enumerate(l.get('steps',[])):yield l['id'],f'step_{i}',world['step_art'],[s['width'],s['height']],'step'
  for i,s in enumerate(l.get('platforms',[])):yield l['id'],s.get('id',f'platform_{i}'),s.get('art',world['platform_art']),[s['width'],s.get('art_height',world['platform_art_height'])],'platform'
  for group,kind in [('obstacles','wall'),('ceilings','ceiling')]:
   for i,s in enumerate(l.get(group,[])):yield l['id'],f'{group}_{i}',s['art'],s['rect'][2:],kind

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--write-offsets',action='store_true');p.add_argument('--report',default='docs/STAGE7_SURFACE_ALIGNMENT.txt');a=p.parse_args();reg=json.loads((ROOT/'data/levels.json').read_text());rows=list(entries(reg));offsets={}
 for path in sorted({row[2] for row in rows}):offsets[path]=measure(path)
 target=ROOT/'data/surface_offsets.json'
 if a.write_offsets:target.write_text(json.dumps(offsets,ensure_ascii=False,indent=2)+'\n')
 saved=json.loads(target.read_text());errors=[];lines=[]
 for level,item,path,sz,kind in rows:
  edge=offsets[path];record=saved.get(path,{})
  # All drawing and collision use the same measured offsets, at display scale.
  diff=abs(float(record.get('top_offset_px',-999))-edge['top_offset_px'])*sz[1]/edge['image_height']
  if diff>4:errors.append(f'{level}/{item}: {diff:.2f}px')
  lines.append(f'{level}\t{item}\t{kind}\t{path}\ttop={edge["top_offset_px"]}\twidth={edge["opaque_x0"]}:{edge["opaque_x1"]}\tdiff={diff:.2f}px')
 (ROOT/a.report).write_text('SURFACE ALIGNMENT\n'+f'{len(rows)} surfaces, {len(errors)} failures\n'+'\n'.join(errors+lines)+'\n');print(f'SURFACE_ALIGNMENT: {len(rows)} surfaces, {len(errors)} failures');return bool(errors)
if __name__=='__main__':sys.exit(main())
