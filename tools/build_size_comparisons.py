#!/usr/bin/env python3
"""Six review montages of authored before/after pixels at actual game zooms."""
import json
from PIL import Image,ImageDraw
from pathlib import Path
from downscale_assets import ROOT
from build_image_parity_fixtures import reference

def main():
 enemies={v['id']:v for v in json.loads((ROOT/'data/enemies.json').read_text())['enemies']};npcs=json.loads((ROOT/'data/npcs.json').read_text());npc_scales={v['id']:npcs['common']['visual_scale']*v.get('visual_scale_multiplier',1) for v in npcs['npcs']};quality=json.loads((ROOT/'data/storage_quality.json').read_text());registry=json.loads((ROOT/'data/sprite_trims.json').read_text());backgrounds=json.loads((ROOT/'data/image_encoding_quality.json').read_text());wanted=['/kala_ushumgal/','/player/axe/idle','/npcs/inanna/idle','/melee_beast/idle','/cedar_demon/perch'];selected=[next(r for r in quality if token in r['path']) for token in wanted];selected.append(next(r for r in backgrounds if '/backgrounds/cedar/' in r['path']));out=ROOT/'docs/size_compare';out.mkdir(parents=True,exist_ok=True)
 for i,row in enumerate(selected):
  spec=registry.get(row['path']);before=reference(row,spec);after=Image.open(ROOT/row['path'].removeprefix('res://')).convert('RGBA')
  if spec:
   st=spec['storage_trim'];t=spec['trim'];before=Image.open(ROOT/'archive/stage8_density_before'/row['source']).convert('RGBA').crop((0,0,t['w'],t['h']));after=after.crop((0,0,st['w'],st['h']));base=.3
   if '/enemies/' in row['path']:
    v=enemies[Path(row['path']).parent.name];base=v.get('visual_scale',.3)*v.get('size_multiplier',1)
   elif '/npcs/' in row['path']:base=npc_scales[Path(row['path']).parent.name]
   sx=sy=base
  else:sx=sy=min(1,480/before.width)
  canvas=Image.new('RGB',(1024,700),(28,32,40));draw=ImageDraw.Draw(canvas)
  for j,zoom in enumerate([1,1.35]):
   for k,im in enumerate([before,after]):
    fx=1/spec['storage_scale'][0] if spec and k==1 else 1;fy=1/spec['storage_scale'][1] if spec and k==1 else 1;size=(min(480,max(1,round(im.width*sx*fx*zoom))),min(300,max(1,round(im.height*sy*fy*zoom))));patch=im.resize(size,Image.Resampling.LANCZOS);canvas.paste(patch,(k*512+(512-size[0])//2,j*350+40+(300-size[1])//2),patch)
    draw.text((k*512+16,j*350+12),f'{"ORIGINAL STORAGE" if k==0 else "WEBP"} / zoom {zoom}',fill='white')
  canvas.save(out/f'stage8_{i+1}.jpg',quality=85)
 print('SIZE_COMPARE: 6 JPEG montages')
if __name__=='__main__':main()
