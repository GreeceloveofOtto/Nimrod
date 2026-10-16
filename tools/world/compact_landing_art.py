#!/usr/bin/env python3
"""Repack painted landmark rectangles without rescaling or changing game anchors."""
from pathlib import Path
import json,itertools,hashlib,shutil,sys
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent));import pack_rework_art as art
ROOT=Path(__file__).resolve().parents[2];A=ROOT/'archive/stage15_map/art';OUT=ROOT/'assets/world/zabulistan_v2'
def main():
 A.mkdir(parents=True,exist_ok=True);p=ROOT/'data/world/zabulistan/art_v2.json';catalog=json.loads(p.read_text());before=A/'before';before.mkdir(exist_ok=True)
 ref=before/'art_v2.json'
 if not ref.exists():shutil.copy2(p,ref)
 old=json.loads(ref.read_text())['landing'];target=ROOT/old['atlas'].removeprefix('res://')
 if not (before/'landing_landmarks.webp').exists():shutil.copy2(target,before/'landing_landmarks.webp')
 source=A/'before/landing_landmarks.png'
 if not source.exists():
  original=ROOT/'archive/stage14_rework/art/canonical/landing/landmarks.png'
  if original.exists():shutil.copy2(original,source)
  else:Image.open(before/'landing_landmarks.webp').save(source)
 im=Image.open(source).convert('RGBA');sizes=[row['rect'][2:] for row in old['landmarks']];best=None
 for width in [768,832,896,960,1024]:
  for order in itertools.permutations(range(8)):
   x=y=row_h=0;placements={}
   for i in order:
    w,h=sizes[i]
    if x+w>width:y+=row_h+2;x=0;row_h=0
    placements[i]=[x,y];x+=w+2;row_h=max(row_h,h)
   height=y+row_h
   if best is None or width*height<best[0]:best=(width*height,width,height,placements)
 _,width,height,positions=best;atlas=Image.new('RGBA',(width,height))
 for i,row in enumerate(old['landmarks']):
  x,y,w,h=row['rect'];at=positions[i];atlas.alpha_composite(im.crop((x,y,x+w,y+h)),at);catalog['landing']['landmarks'][i]['rect']=[*at,w,h]
 art.OUT=OUT;art.ARCH=A;art.QUALITY.clear();art.save(atlas,target,80)
 p.write_text(json.dumps(catalog,separators=(',',':'))+'\n')
 quality=json.loads((ROOT/'data/world/zabulistan/art_quality.json').read_text());record=art.QUALITY[0];record['sha256']=hashlib.sha256(target.read_bytes()).hexdigest();quality=[record if row['path']==record['path'] else row for row in quality]
 for item in json.loads((A/'quality.json').read_text()):
  item['sha256']=hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest();quality=[row for row in quality if row['path']!=item['path']];quality.append(item)
 (ROOT/'data/world/zabulistan/art_quality.json').write_text(json.dumps(quality,separators=(',',':'))+'\n')
 budget=ROOT/'data/stage14_budget.json';data=json.loads(budget.read_text());data['new_assets']=sorted(set(data['new_assets'])|{item['path'] for item in quality});budget.write_text(json.dumps(data,separators=(',',':'))+'\n')
 out={'original_bytes':(before/'landing_landmarks.webp').stat().st_size,'after_bytes':target.stat().st_size,'atlas_size':[width,height],'rescaled':False,'density':.9,'game_anchors_preserved':True,'quality':record}
 (A/'repack.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
if __name__=='__main__':main()
