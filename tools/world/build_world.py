#!/usr/bin/env python3
"""Expand hand-authored ASCII at explicit coordinates. No layout generator or RNG.
Nine legacy regions remain frozen until the landing pilot is approved.
"""
from pathlib import Path
import itertools,json,hashlib
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'data/world/zabulistan';SOURCE=BASE/'source'
def read(path):return json.loads(path.read_text())
def write(path,data):path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
def rle(row):return ''.join(str(len(list(g)))+c for c,g in itertools.groupby(row))
def main():
 world=read(SOURCE/'world_base.json');rows=[list(s) for s in (SOURCE/'legacy_stage14.ascii').read_text().splitlines()];catalogue=read(SOURCE/'entity_catalogue.json');entities=catalogue['entities'];landmarks=catalogue['landmarks'];decor=[];reviews=[];carved=[];lights=[];foreground=[]
 for layout_file in sorted(SOURCE.glob('layout_*.json')):
  layout=read(layout_file);ox,oy=layout['origin'];width,height=layout['size'];carved.append(layout['id'])
  for y in range(oy,oy+height):rows[y][ox:ox+width]=layout['base']*width
  def stamp(item,directory='rooms'):
   template=(SOURCE/directory/(item['template']+'.txt')).read_text().splitlines();assert len(set(map(len,template)))==1,item
   tx,ty=item['at']
   if item.get('flip'):template=[s[::-1] for s in template]
   for y,line in enumerate(template):
    for x,c in enumerate(line):
     if c!='?':rows[oy+ty+y][ox+tx+x]=c
  for item in layout['placements']:stamp(item)
  for item in layout['stamps']:stamp(item,'stamps')
  for item in layout['shafts']:stamp(item)
  for x,y,w,h in layout['connections']:
   for dy in range(h):rows[oy+y+dy][ox+x:ox+x+w]='.'*w
  # Explicit masonry/pocket edits are final, so links cannot erase gate lintels.
  for port in layout['ports']:
   x,y,w,h=port['rect']
   for dy in range(h):
    for dx in range(w):
     if not port.get('only_open',False) or rows[oy+y+dy][ox+x+dx]not in '#W^F':rows[oy+y+dy][ox+x+dx]=port['char']
  for item in layout.get('overlays',[]):stamp(item,'stamps')
  for x,y,w,h in layout['windows']:
   for dy in range(h):
    for dx in range(w):
     if rows[oy+y+dy][ox+x+dx]=='.':rows[oy+y+dy][ox+x+dx]=':'
  for e in entities:
   if e['region']!=layout['id']:continue
   assert e['uid'] in layout['anchors'],e['uid']
   x,y=layout['anchors'][e['uid']];e['position']=[(ox+x)*32,(oy+y)*32]
  for p in landmarks:
   if p['region']==layout['id']:
    positions=layout['landmarks'];x,y=positions[str(p['piece'])] if isinstance(positions,dict) else positions[p['piece']];p['position']=[(ox+x)*32,(oy+y)*32]
  if layout['id']=='landing':world['spawn']=[ox+layout['spawn'][0],oy+layout['spawn'][1]]
  reviews += [dict(row,region=layout['id']) for row in layout['review']];lights += [[ox+x,oy+y] for x,y in layout['lights']];foreground += [[kind,ox+x,oy+y] for kind,x,y in layout['foreground']]
  for y in range(oy,oy+height):
   x=ox
   while x<ox+width:
    if rows[y][x]!='=':x+=1;continue
    start=x
    while x<ox+width and rows[y][x]=='=':x+=1
    end=x-1;left=start>0 and rows[y][start-1] in '#W^';right=end+1<world['width'] and rows[y][end+1] in '#W^'
    if left or right:decor.append([0,start if left else end,y,-1 if left else 1,1]);continue
    found=False
    for side,at in [(-1,start-1),(1,end+1)]:
     for gap in range(1,21):
      if y-gap<0:break
      if rows[y-gap][at] in '#W^':decor.append([1,start if side==-1 else end,y,side,gap]);found=True;break
     if found:break
    if not found:
     for at in [start,end]:
      for gap in range(1,21):
       if y+gap>=world['height']:break
       if rows[y+gap][at]in '#W^':decor.append([2,at,y,0,gap]);found=True;break
      if found:break
 world['authored_spaces']=[dict(region=layout['id'],kind=p['kind'],at=p['at'],size=p['size']) for p in layout.get('spaces',[])];world['fake_walls']=layout.get('fake_walls',[]);world['terrain_spikes']={'damage':12,'interval':1.};world['drop_shafts']=layout.get('drop_shafts',[]);world['carved_regions']=carved;world['review_points']=reviews;world['terrain_lights']=lights;world['foreground']=foreground;world['map_icons']=[e for e in entities if e['type'] not in ['enemy','boss']];world.pop('navigation',None)
 ascii_text='\n'.join(''.join(r) for r in rows)+'\n'
 world['navigation_sha256']=hashlib.sha256(ascii_text.encode()).hexdigest()
 (SOURCE/'world.ascii').write_text(ascii_text)
 for cy in range(10):
  for cx in range(10):
   cid=f'c{cx:02}_{cy:02}';x0,y0=cx*64,cy*36;inside=lambda p:x0*32<=p[0]<(x0+64)*32 and y0*32<=p[1]<(y0+36)*32
   data={'coord':[cx,cy],'rle':[rle(''.join(row[x0:x0+64])) for row in rows[y0:y0+36]],'entities':[e for e in entities if inside(e['position'])],'landmarks':[p for p in landmarks if inside(p['position'])],'decor':[d for d in decor if x0<=d[1]<x0+64 and y0<=d[2]<y0+36]}
   write(BASE/'chunks'/(cid+'.json'),data)
 write(BASE/'world_v2.json',world);print('Compiled explicit carved layouts:',carved,';',len(entities),'entities (enemy UIDs preserved);',len(decor),'supports')
if __name__=='__main__':main()
