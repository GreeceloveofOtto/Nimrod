#!/usr/bin/env python3
"""Deterministic authored room recipes + editable seeded arrangements (no image drawing)."""
import argparse,json,random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def write(p,d):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':'))+'\n')
RECIPES=[('계단식 보루',[(22,28,8),(35,25,7),(48,22,7),(61,19,8)]),('부서진 회랑',[(25,30,10),(47,28,11),(71,30,10)]),('쌍탑 사격장',[(28,27,9),(58,27,9),(28,24,9),(58,24,9)]),('천장 매복',[(31,25,12),(62,26,13)]),('독안개 우회',[(30,30,8),(41,27,8),(52,24,9),(64,27,9)]),('수직 발톱',[(25,30,7),(34,27,7),(25,24,7),(34,21,7)]),('갈라진 수정',[(24,28,10),(50,26,10),(75,29,10)]),('무너지는 다리',[(26,28,7),(38,28,7),(50,28,7),(62,28,7)]),('흔들리는 제단',[(32,28,7),(49,25,7),(67,28,7)]),('바람의 능선',[(26,30,9),(41,27,9),(56,24,9),(71,21,9)]),('나선형 옥좌',[(22,29,7),(33,26,7),(44,23,7),(55,20,7),(66,17,7)]),('잊힌 중정',[(24,29,12),(59,29,12),(40,26,13)])]
def build(columns=6,rows=10):
 density=json.loads((ROOT/'data/world/enemy_density.json').read_text());world=json.loads((ROOT/'data/world/zabulistan/world.json').read_text());regions=json.loads((ROOT/'data/world/zabulistan/regions.json').read_text())['regions'];rng=random.Random(world['seed']);rooms={};cells={};abilities=list(json.loads((ROOT/'data/world/abilities.json').read_text())['abilities'])
 for r in regions:
  bx,by=r['grid_block']
  for y in range(rows):
   for x in range(columns):
    k=y*columns+x;id=f"{r['id']}_{k:02d}";gx=bx*columns+x;gy=by*rows+y
    recipe,authored=RECIPES[k%len(RECIPES)];platforms=[(px+(r['number']%3)*2,py-(r['number']%2),n) for px,py,n in authored];layout=[list('.'*96) for _ in range(36)]
    for yy in range(33,36):layout[yy]=list('#'*96)
    # Traversable base route, authored upper challenges; vertical exits use 120px stairs.
    for px,py,n in platforms:
     layout[py][px:px+n]=list('='*n)
    for yy in range(3,33,3):
     px=5 if yy%6==3 else 9;layout[yy][px:px+5]=list('='*5)
    for yy in range(5,23):layout[yy][18]='W'
    entries={'left':[80,1320],'right':[3760,1320],'top':[280,120],'bottom':[280,1320]}
    entities=[];peace=r['number']==6;boss_id={('fortress',columns*rows-1):'kala_ushumgal',('crystal',columns*rows-1):'gugalanna',('deep',columns*rows-1):'humbaba'}.get((r['id'],k))
    if not peace and not boss_id:
     n=min(18,15+round(k/29*3)) if r['number']==1 else min(30,23+r['number']//2+k%3)
     recipe_offset=rng.randrange(len(r['enemy_recipe']))
     for e in range(n):
      species=r['enemy_recipe'][(e+recipe_offset)%len(r['enemy_recipe'])];px=780+e*80;py=1320;kind='ground'
      if r['number']<=7 and k==3:
       slots=[x for x in range(680,3280,80) if abs(x-1580)>=420];px=slots[e%len(slots)]
      if species=='cedar_wisp':py=1140;kind='air'
      elif species=='cedar_archer':
       py=1120;layout[28][px//40-2:px//40+3]=list('='*5);kind='platform'
      elif species=='cedar_demon':
       py=1040;layout[26][px//40-2:px//40+3]=list('='*5);kind='perch'
      entities.append({'type':'enemy','id':species,'position':[px,py],'spawn_kind':kind,'elite':e>=n-round(n*float(density['elite_ratio']))})
    if boss_id:entities.append({'type':'boss','id':boss_id,'boss_id':f"{r['id']}_guardian",'placeholder':True,'display_name':{'fortress':'폐허의 수문장','crystal':'수정의 방랑 거수','deep':'심층의 비늘 수호자'}[r['id']],'position':[2200,1320]})
    secret=k%10==7;gates=[]
    if k%5==4:
     ability=abilities[(k//5+r['number'])%7];gates.append({'id':id+'_cache','requires':[ability],'position':[3300,1320],'size':[40,160],'art_hint':ability});entities.append({'type':'crystal','id':id+'_gated_crystal','position':[3480,1320],'requires':[ability]})
    if k%3==0:entities.append({'type':'crystal','id':id+'_crystal','position':[1180,1320]})
    if k%10==8:entities.append({'type':'life','id':id+'_life','position':[1500,1320]})
    if k%9==5:entities.append({'type':'breakable_wall','id':id+'_breakwall','position':[2800,1320]})
    if k%7==0:entities.append({'type':'lore_item','id':id+'_lore','position':[1700,1320]})
    if k%6==0:entities.append({'type':'switch','id':id+'_switch','position':[1900,1320],'target':id+'_shortcut'})
    if k==2:entities.append({'type':'healing','position':[1150,1320]})
    if r['number']<=7 and k==3:
     a=abilities[r['number']-1];entities.append({'type':'altar','id':a,'position':[1580,1320],'requires':abilities[:r['number']-1],'practice':{'safe_entry':entries['left'],'hint_position':[1300,1320]}})
    if not peace and k%4==0:entities.append({'type':['spikes','poison','wind','falling_rock'][k//4%4],'position':[2600,1320],'size':[160,80]})
    if k%12==7:entities.append({'type':'moving_platform','position':[2400,1160],'size':[200,24],'delta':[240,0],'seconds':3})
    if k%12==8:entities.append({'type':'crumble','position':[2500,1200],'size':[200,24],'seconds':.8})
    room={'id':id,'region':r['id'],'grid_pos':[gx*3,gy*2],'size':[3,2],'layout':[''.join(l) for l in layout],'entries':entries,'exits':[],'entities':entities,'gates':gates,'secret':secret,'secret_requires':['vision'] if secret else [],'save_point':None,'map':{'mask':['###','###'],'icons':[{'kind':e['type'],'position':e['position']} for e in entities if e['type'] in ['altar','life','crystal','boss']]},'design':{'recipe':recipe,'set_piece':k<12,'seed':world['seed']+gx+gy*100,'problem':'지상 통로와 상층 우회로의 선택','solution':'발판 사다리와 구역 능력으로 보상 탐색'},'shortcut':{'id':id+'_shortcut','opened_from':'right','one_way':k==4},'boss_room':bool(boss_id)}
    rooms[id]=room;cells[gx,gy]=id
 for (gx,gy),id in cells.items():
  room=rooms[id]
  for side,dx,dy,reverse in [('left',-1,0,'right'),('right',1,0,'left'),('top',0,-1,'bottom'),('bottom',0,1,'top')]:
   target=cells.get((gx+dx,gy+dy))
   if target:
    req=rooms[target]['secret_requires'][:]
    if side=='right' and room['gates']:req+=room['gates'][0]['requires']
    room['exits'].append({'side':side,'from':240 if side in ['top','bottom'] else 1160,'to':400 if side in ['top','bottom'] else 1440,'target_room':target,'target_entry':reverse,'requires':req,'concealed':rooms[target]['secret'],'one_way':False})
  if room['shortcut']['one_way'] and any(e['side']=='right' for e in room['exits']):
   room['exits'].append({'side':'portal','from':0,'to':1,'target_room':next(e['target_room'] for e in room['exits'] if e['side']=='right'),'target_entry':'left','requires':[],'one_way':True,'position':[2900,1320],'id':id+'_shortcut'})
 # Two hub portals per region, plus paired reverse portals. No adjacent terrain preload for portals.
 for r in regions:
  if r['id']=='village':continue
  for i in range(2):
   hub=rooms[f'village_{i*12:02d}'];other=rooms[f"{r['id']}_{i*12:02d}"]
   for source,target in [(hub,other),(other,hub)]:
    source['exits'].append({'side':'portal','from':0,'to':1,'target_room':target['id'],'target_entry':'left','requires':target['secret_requires'],'one_way':False,'position':[2100+r['number']*110,1320],'id':source['id']+'_to_'+target['id']})
 for room in rooms.values():
  room['map']['icons'] += [{'kind':'gate','position':g['position'],'requires':g['requires']} for g in room['gates']]
  if room['secret']:room['map']['icons'].append({'kind':'secret','position':[280,1320]})
 for room in rooms.values():write(ROOT/'data/world/zabulistan/regions'/room['region']/(room['id']+'.json'),room)
 world['map_grid']=[columns*5,rows*2];write(ROOT/'data/world/zabulistan/world.json',world)
 write(ROOT/'data/world/zabulistan/map_index.json',{id:{'grid_pos':r['grid_pos'],'region':r['region'],'map':r['map'],'exits':r['exits']} for id,r in rooms.items()})
 write(ROOT/'data/world/zabulistan/index.json',{'rooms':{id:f'res://data/world/zabulistan/regions/{r["region"]}/{id}.json' for id,r in rooms.items()},'start':world['start_room']})
 write(ROOT/'data/world/zabulistan/design.json',{'seed':world['seed'],'columns_per_region':columns,'rows_per_region':rows,'authored_recipes':[{'id':i,'name':n,'platforms':p} for i,(n,p) in enumerate(RECIPES)],'intent':'Each region has twelve authored structural problems, seeded encounters, optional ability caches and a safe ground return route.'})
 print('BUILT',len(rooms),'rooms',sum(r['size'][0]*r['size'][1] for r in rooms.values()),'screens')
if __name__=='__main__':build()
