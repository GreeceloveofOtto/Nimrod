#!/usr/bin/env python3
"""Compile a hand-authored ASCII plate map. No random seed or layout synthesis.
A plate character expands to an explicitly drawn 8x8 ASCII glyph below.
Changing topology means editing maze.ascii or the literal glyph table, not a seed.
"""
from pathlib import Path
import json,itertools,collections,math
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'data/world/zabulistan'
# Hand-drawn side-view platforms: holes, ledges and wall pieces, not decorative noise.
GLYPHS=json.loads((BASE/'source/glyphs.json').read_text())
def rle(line):return [[c,len(list(g))] for c,g in itertools.groupby(line)]
def write(path,data):path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
def main():
 plates=[''.join(s.split()) for s in (BASE/'source/maze.ascii').read_text().splitlines() if s.strip()]
 assert len(plates)==45 and all(len(s)==80 for s in plates),[(i,len(s)) for i,s in enumerate(plates) if len(s)!=80]
 rows=[''.join(GLYPHS[c][dy] for c in line) for line in plates for dy in range(8)]
 # World-edge collision is external. The ASCII itself is preserved without noise or shuffling.
 (BASE/'source/world.ascii').write_text('\n'.join(rows)+'\n')
 old=json.loads((BASE/'source/region_design.json').read_text())['regions'];byid={r['id']:r for r in old}
 order=['landing','forest','marsh','mine','fortress','village','ridge','skywalk','deep','crystal']
 regions=[];entities=[];landmarks=[];gates=[];connections=[]
 ability_settings=json.loads((ROOT/'data/world/abilities.json').read_text())['abilities'];ability_ids=list(ability_settings)
 enemy_stats={e['id']:e for e in json.loads((ROOT/'data/enemies.json').read_text())['enemies']}
 # Explicit placement lists in local tile units. Compilation only snaps feet to an authored ledge.
 enemy_points=[(20,19),(48,23),(32,59),(76,87),(108,91),(18,119),(62,123),(100,151),(30,155),(86,175)]
 landmark_points=[(8,27),(66,35),(32,63),(96,79),(9,111),(63,131),(25,159),(91,175)]
 def support(x,y,body=(36,124)):
  x=max(1,min(638,int(x)));y=max(1,min(358,int(y)))
  for yy in list(range(y,min(y+16,360)))+list(range(y-1,max(3,y-9),-1)):
   for xx in [x,x-1,x+1,x-2,x+2,x-3,x+3,x-4,x+4]:
    if 1<=xx<639 and rows[yy][xx] in '#W=' and rows[yy][xx-1] in '#W=' and not any(c in '#W' for line in rows[max(0,math.floor(yy-body[1]/32)):yy] for c in line[max(0,math.floor(xx-body[0]/64)):min(640,math.ceil(xx+body[0]/64))]):return xx*32,yy*32
  raise ValueError(('no authored support',x,y))
 for n,id in enumerate(order):
  ox=(n%5)*128;oy=(n//5)*180;r=byid[id]
  regions.append({'id':id,'name':r['name'],'number':r['number'],'palette':r['palette'],'bgm':r['bgm'],'bounds':[ox,oy,128,180], 'setpiece': ['계단식 착륙 잔교','사이프러스 뿌리 회랑','카나트 침수 성소','풍탑 갱도','이완과 왕조 부조','메라브 포도 정원','절벽 수도원','시무르그 둥지','다마반드 봉인 제단','라오차흐 결정 성소'][n]})
  for k,(x,y) in enumerate(landmark_points):
   p=support(ox+x,oy+y);landmarks.append({'region':id,'piece':k,'position':p})
  if id!='village':
   recipe=['cedar_sentinel','cedar_archer','cedar_wisp','cedar_demon','cedar_sentinel']
   for k,(x,y) in enumerate(enemy_points+[(100,35)]):
    kind='cedar_colossus' if k==len(enemy_points) else recipe[k%5];p=support(ox+x,oy+y,enemy_stats[kind]['body_size'])
    if kind=='cedar_wisp':p=(p[0],p[1]-64)
    entities.append({'uid':f'enemy_{id}_{k}','id':kind,'type':'enemy','region':id,'position':p,'elite':k==9 and n%3==0,'patrol':96})
  for k,(x,y) in enumerate([(42,43),(98,99),(46,147),(112,171),(12,71),(72,139)]):
   entities.append({'uid':f'life_{id}_{k}','type':'life','region':id,'position':support(ox+x,oy+y)})
  entities.append({'uid':f'lore_{id}','type':'lore_item','region':id,'position':support(ox+116,oy+147),'requires':['vision'],'secret':True})
  for k,(x,y) in enumerate([(57,35),(15,91),(92,131),(43,167),(119,63),(80,115)]):
   entities.append({'uid':f'crystal_{id}_{k}','type':'crystal','region':id,'position':support(ox+x,oy+y)})
  # One-way doors are opened from their right side; the surrounding traversal stays two-way.
  entities.append({'uid':f'door_{id}','id':f'door_{id}','target':f'door_{id}','type':'switch','region':id,'position':support(ox+54,oy+79),'one_way':True})
  if n<7:
   entities.append({'uid':f'altar_{ability_ids[n]}','id':ability_ids[n],'type':'altar','region':id,'position':support(ox+25,oy+35)})
  for k,ability in enumerate(ability_ids):
   gates.append({'uid':f'gate_{id}_{ability}','type':'gate','region':id,'position':support(ox+(86 if id=='mine' and ability=='vision' else 30+k*12),oy+107),'requires':[ability],'secret':ability=='vision','art_hint':ability_settings[ability]['name']})
  if n in [4,7,9]:
   kind={4:'kala_ushumgal',7:'gugalanna',9:'humbaba'}[n]
   entities.append({'uid':f'boss_{id}','id':kind,'type':'boss','region':id,'position':support(ox+95,oy+171,enemy_stats[kind]['body_size']),'display_name':{'kala_ushumgal':'잊힌 이완의 수호자','gugalanna':'하늘 잔도의 수호자','humbaba':'결정 봉인의 수호자'}[kind],'placeholder':True,'patrol':256})
  # Region adjacency is derived from the fixed world rectangles, never room exits.
  for other in [n+1,n+5]:
   if other<10 and (other==n+5 or n%5<4):connections.append({'from':id,'to':order[other],'main_requires':[],'shortcut_requires':[ability_ids[n%7]]})
 for n,id in enumerate(order):
  ox=(n%5)*128;oy=(n//5)*180
  gates.append({'uid':f'door_gate_{id}','type':'gate','region':id,'position':support(ox+51,oy+79),'requires':[],'opens_with':f'door_{id}','art_hint':'반대편에서 열린다'})
 entities+=gates
 chunks={}
 for cy in range(10):
  for cx in range(10):
   id=f'c{cx:02}_{cy:02}';path=BASE/'chunks'/f'{id}.json';x0=cx*64;y0=cy*36
   inside=lambda p:x0*32<=p[0]<(x0+64)*32 and y0*32<=p[1]<(y0+36)*32
   data={'coord':[cx,cy],'rle':[rle(row[x0:x0+64]) for row in rows[y0:y0+36]],'entities':[e for e in entities if inside(e['position'])],'landmarks':[p for p in landmarks if inside(p['position'])]}
   write(path,data);chunks[id]='res://'+str(path.relative_to(ROOT))
 world={'format':2,'id':'zabulistan','display_name':'자불리스탄','width':640,'height':360,'tile_size':32,'fog_cell_tiles':8,'chunk_size':[64,36],'save_enabled':False,'developer_overlay':False,'spawn':[support(8,19)[0]/32,support(8,19)[1]/32],'life_hp_cap':200,'life_fragments_per_upgrade':4,'life_hp_increment':10,'regions':regions,'chunks':chunks,'navigation':rows,'connections':connections,'map_icons':[e for e in entities if e['type'] not in ['enemy','boss']],'travel':{'fade_out':1.2,'glow_seconds':.45,'caption_seconds':.7,'fade_in':1.0,'palette':['fae0a6','eceefa','df83a7','a4445d','499d9c','61559c']}}
 write(BASE/'world_v2.json',world)
 print('Compiled hand-authored ASCII:',640,360,'tiles;',len(chunks),'chunks;',len(entities),'entities')
if __name__=='__main__':main()
