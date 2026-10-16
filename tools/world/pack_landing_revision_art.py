#!/usr/bin/env python3
"""Postprocess generated valley and physical festival pickups; no painted code art."""
from pathlib import Path
import sys,json,shutil,hashlib
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent));import pack_rework_art as art
R=Path(__file__).resolve().parents[2];A=R/'archive/stage15_landing_revision/art'
def main():
 A.mkdir(parents=True,exist_ok=True);art.ARCH=A;art.QUALITY.clear()
 source=R.parent/'generated_images/exec-5595afed-052e-436d-b015-53eae38d096b.png';shutil.copy2(source,A/'generated_valley.png')
 target=R/'assets/world/zabulistan_v2/landing/background_1.webp';
 if not (A/'previous_background_1.webp').exists():shutil.copy2(target,A/'previous_background_1.webp')
 im=Image.open(source).convert('RGB').resize((1024,360),Image.Resampling.LANCZOS);pixels=np.array(im)
 for x in range(8):
  mean=(pixels[:,x].astype(float)+pixels[:,-1-x].astype(float))*.5;pixels[:,x]=mean;pixels[:,-1-x]=mean
 art.OUT=R/'assets/world/zabulistan_v2';art.save(Image.fromarray(pixels),target,80)
 source=R.parent/'generated_images/exec-192034f9-bace-411f-93a6-a94cd523ab26.png';shutil.copy2(source,A/'generated_pickups.png');im=Image.open(source).convert('RGBA')
 art.OUT=R/'assets/world'
 for name,box in [('cord',(0,0,im.width//2,im.height)),('ember',(im.width//2,0,im.width,im.height))]:
  keyed=art.key(im.crop(box));keyed=keyed.crop(keyed.getbbox());keyed.thumbnail((92,92),Image.Resampling.LANCZOS);padded=Image.new('RGBA',(keyed.width+4,keyed.height+4));padded.alpha_composite(keyed,(2,2));art.save(padded,R/f'assets/world/shared/{name}.webp',80)
 records=art.QUALITY
 for row in records:row['sha256']=hashlib.sha256((R/row['path']).read_bytes()).hexdigest();row['intentional_new_generated_content']=True
 q=R/'data/world/zabulistan/art_quality.json';data=json.loads(q.read_text());replaced={row['path'] for row in records};data=[row for row in data if row['path'] not in replaced]+records;q.write_text(json.dumps(data,separators=(',',':'))+'\n');(A/'quality.json').write_text(json.dumps(records,indent=2)+'\n')
 print('NEW GENERATED ART',[(p['path'],p['bytes']) for p in records])
if __name__=='__main__':main()
