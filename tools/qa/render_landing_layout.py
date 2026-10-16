#!/usr/bin/env python3
"""Review-only colored glyph diagram; never a runtime game asset."""
from pathlib import Path
import json,sys
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[2];sys.path.insert(0,str(R/'tools/world'))
from terrain_rules import load_world,decode
A=R/'archive/stage15_landing_revision';D=R/'docs/stage15_map_review_revision'
COLORS={'#':'#443c50','W':'#574961','.':'#c9c9d5',':':'#8db6d6','=':'#e8ac43','F':'#a078c2','^':'#dd5967','~':'#577548'}
def render(rows,entities):
 im=Image.new('RGB',(512,720));p=im.load()
 for y in range(180):
  for x in range(128):
   color=Image.new('RGB',(1,1),COLORS[rows[y][x]]).getpixel((0,0))
   for dy in range(4):
    for dx in range(4):p[x*4+dx,y*4+dy]=color
 draw=ImageDraw.Draw(im)
 for e in entities:
  if e['region']!='landing':continue
  x,y=[v/8 for v in e['position']];color={'enemy':'#ff596b','cord':'#f979b2','ember':'#ffb24c','site':'#6effd8','return_pier':'#459be9','gate':'#e87d22','switch':'#40c67c'}.get(e['type'],'white');draw.rectangle((x-2,y-5,x+3,y),fill=color)
 return im
def main():
 D.mkdir(parents=True,exist_ok=True);w,e,*_=load_world();after=render(w['navigation'],e);after.save(D/'landing_layout_after.png')
 b=A/'before/world';w=json.load(open(b/'world_v2.json'));rows=[list('#'*640) for _ in range(360)];entities=[]
 for path in w['chunks'].values():
  c=json.load(open(b/'chunks'/Path(path).name));x,y=c['coord'][0]*64,c['coord'][1]*36
  for dy,row in enumerate(c['rle']):rows[y+dy][x:x+64]=decode(row)
  entities+=c['entities']
 before=render([''.join(r) for r in rows],entities);before.save(D/'landing_layout_before.png');montage=Image.new('RGB',(1032,756),'#18191d');montage.paste(before,(0,36));montage.paste(after,(520,36));draw=ImageDraw.Draw(montage);draw.text((12,10),'Before: uniform floors',fill='white');draw.text((532,10),'After: crags, halls, staggered shafts',fill='white');montage.save(D/'landing_layout_comparison.png')
if __name__=='__main__':main()
