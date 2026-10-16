#!/usr/bin/env python3
"""Measure visible game pixels against captured camera coordinates, without redraw."""
from pathlib import Path
import json,sys
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/world'))
from terrain_rules import load_world,SOLID
A=ROOT/'archive/stage15_map';OUT=ROOT/'docs/stage15_map_review'
def main():
 world,*_=load_world();rows=world['navigation'];captures=json.loads((A/'capture.json').read_text());results=[]
 def solid(x,y):return 0<=x<640 and 0<=y<360 and rows[y][x] in SOLID
 def kind(x,y):
  c=rows[y][x]
  if c=='.':return 'backwall'
  if c not in SOLID:return None
  if c=='F' or any(not solid(x+dx,y+dy) for dx,dy in [(0,-1),(1,0),(0,1),(-1,0),(-1,-1),(1,-1),(1,1),(-1,1)]):return 'crust'
  if any(not solid(x+dx,y+dy) for dx,dy in [(0,-2),(2,0),(0,2),(-2,0)]):return 'transition'
  return 'fill'
 for cap in captures:
  im=np.asarray(Image.open(OUT/f'landing_{cap["id"]}.png').convert('RGB'));lum=im@np.array([.2126,.7152,.0722]);cx,cy=cap['camera'];groups={k:[] for k in ['crust','transition','backwall','fill']};cells={k:0 for k in groups}
  for y in range(max(0,int((cy-360)//32)),min(360,int((cy+360)//32)+1)):
   for x in range(max(0,int((cx-640)//32)),min(640,int((cx+640)//32)+1)):
    k=kind(x,y)
    if k is None:continue
    # Central 16x16 pixels avoid snow/trim silhouettes; exclude top HUD and subtitle.
    sx=int(x*32-cx+640+8);sy=int(y*32-cy+360+8)
    if sx<0 or sy<80 or sx+16>1280 or sy+16>590:continue
    groups[k].extend(lum[sy:sy+16,sx:sx+16].ravel().tolist());cells[k]+=1
  means={k:round(float(np.mean(v)),3) if v else None for k,v in groups.items()}
  results.append(dict(cap,mean_luminance_255=means,sampled_tiles=cells,luminance_order_passed=means['crust']>means['backwall']>means['fill']))
 result={'method':'GL screenshot central 16x16 pixels per tile; HUD y<80/subtitle y>=590 excluded; overlaid lamps/landmarks retained. Not isolated texture averages.','captures':results}
 (A/'capture_metrics.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 before=Image.open(ROOT/'docs/stage14_rework_review/after_landing.png').convert('RGB');after=Image.open(OUT/'landing_hall.png').convert('RGB')
 montage=Image.new('RGB',(1280,400),(20,22,27));d=ImageDraw.Draw(montage)
 for i,(label,im) in enumerate([('BEFORE: Stage14 landing',before),('AFTER: Stage15 landing pilot',after)]):
  montage.paste(im.resize((640,360),Image.Resampling.LANCZOS),(i*640,40));d.text((i*640+12,12),label,fill='white')
 montage.save(OUT/'landing_before_after.png')
 print(json.dumps(result,ensure_ascii=False,indent=2));return int(not all(r['luminance_order_passed'] for r in results))
if __name__=='__main__':raise SystemExit(main())
