#!/usr/bin/env python3
"""Preserve small original pixel samples for Godot decoder parity in the slim ZIP.
Copies authored pixels only; creates no artwork. Run before image conversion.
"""
import base64,json
from pathlib import Path
from PIL import Image
R=Path(__file__).resolve().parents[1]
def main():
 selected=[]
 for manifest in sorted((R/'assets/sprites/enemies').glob('*/manifest.json')):
  c=json.loads(manifest.read_text())['clips'][0];p=c['sheet'];selected.append(R/p.removeprefix('res://') if p.startswith('res://') else R/'assets'/p)
 for w in ['axe','staff','unarmed']:
  c=json.loads((R/'assets/sprites/player'/w/'manifest.json').read_text())['clips'][0];selected.append(R/'assets'/c['sheet'])
 for folder in ['backgrounds','props/doors','sprites/npcs','fx']:
  selected+=sorted(list((R/'assets'/folder).rglob('*.png'))+list((R/'assets'/folder).rglob('*.webp')))[:4]
 samples=[]
 for p in selected:
  relative=str(p.relative_to(R));mapping_path=R/'data/image_mapping.json';mapping=json.loads(mapping_path.read_text()) if mapping_path.exists() else {};inverse={v:k for k,v in mapping.items()};original=R/'archive/original_png'/inverse[relative] if relative in inverse else p
  im=Image.open(original).convert('RGBA');box=im.getchannel('A').getbbox();x0,y0,x1,y1=box
  points=[(x0,y0),((x0+x1)//2,(y0+y1)//2),(x1-32,y1-32),(0,0)]
  patches=[]
  for x,y in points:
   x=max(0,min(x,im.width-32));y=max(0,min(y,im.height-32));crop=im.crop((x,y,x+32,y+32));patches.append({'rect':[x,y,32,32],'rgba':base64.b64encode(crop.tobytes()).decode()})
  samples.append({'path':'res://'+str(p.relative_to(R)),'size':list(im.size),'patches':patches})
 (R/'data/image_parity_samples.json').write_text(json.dumps({'samples':samples},indent=2)+'\n')
 print('IMAGE_PARITY_FIXTURES:',len(samples),'images,',sum(len(s['patches']) for s in samples),'original 32x32 pixel samples')
if __name__=='__main__':main()
