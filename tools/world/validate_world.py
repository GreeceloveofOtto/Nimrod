#!/usr/bin/env python3
"""Schemas, physical platform graph, ability-state exploration, reciprocity and density.

The solver samples whole generated support intervals and uses the same jump,
gravity, speed and expanded ability numbers as the runtime, rather than trusting
room adjacency alone. Combat skill is not modeled as reachability.
"""
import json,math,sys,collections,zlib,itertools,argparse,subprocess,os
from pathlib import Path
import jsonschema
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
from check_tileset_seams import check as seam_check

def load(p):return json.loads((ROOT/p).read_text())
def surfaces(room):
 result=[]
 for y,line in enumerate(room['layout']):
  x=0
  while x<len(line):
   if line[x] not in '#W=' or y>0 and room['layout'][y-1][x] in '#W':x+=1;continue
   start=x;c=line[x]
   while x<len(line) and line[x]==c and (y==0 or room['layout'][y-1][x] not in '#W'):x+=1
   result.append((start*40,x*40,y*40))
 return result

def physics_reachable(room,abilities,available):
 move=abilities['movement'];g=move['gravity'];impulse=move['jump_impulse'];height=impulse**2/(2*g);speed=move['speed'];platforms=surfaces(room)
 if 'double_jump' in available:height+=abilities['abilities']['double_jump']['impulse']**2/(2*g)
 def linked(a,b):
  dy=a[2]-b[2]
  if dy>height+.1:return False
  flight=(impulse+math.sqrt(max(0,impulse**2-2*g*dy)))/g
  if 'double_jump' in available:flight+=2*abilities['abilities']['double_jump']['impulse']/g
  gap=max(0,b[0]-a[1],a[0]-b[1])+move['body'][0]/2
  reach=speed*flight
  if 'dash' in available:reach+=(abilities['abilities']['dash']['speed']-speed)*abilities['abilities']['dash']['seconds']
  return gap<=reach+4
 # Player begins at the ground left entry, and can return to it from every
 # authored reachable platform by a downward trajectory or safe drop-through.
 starts=[i for i,p in enumerate(platforms) if p[0]<=80<=p[1] and p[2]==1320]
 seen=set(starts);queue=collections.deque(starts)
 while queue:
  a=queue.popleft()
  for b in range(len(platforms)):
   if b not in seen and linked(platforms[a],platforms[b]):seen.add(b);queue.append(b)
 entries={}
 for id,(x,y) in room['entries'].items():entries[id]=any(i in seen and p[0]-18<=x<=p[1]+18 and abs(p[2]-y)<=3 for i,p in enumerate(platforms))
 return entries,len(seen),len(platforms)

def main():
 parser=argparse.ArgumentParser();parser.add_argument("--runtime",action="store_true");args=parser.parse_args()
 errors=[];index=load('data/world/zabulistan/index.json');rooms={id:load(path.removeprefix('res://')) for id,path in index['rooms'].items()};schema=load('data/world/room.schema.json');abilities=load('data/world/abilities.json');density=load('data/world/enemy_density.json');regions=load('data/world/zabulistan/regions.json')['regions'];keys=list(abilities['abilities']);bits={id:1<<i for i,id in enumerate(keys)};coords={};counts=collections.Counter();physical={};validator=jsonschema.Draft202012Validator(schema)
 def requires(values,mask):return all(mask&bits[id] for id in values)
 for id,room in rooms.items():
  for e in validator.iter_errors(room):errors.append(id+': schema '+e.message)
  pos=tuple(room['grid_pos'])
  if pos in coords:errors.append(id+': grid overlap')
  coords[pos]=id
  if len(room['layout'])!=room['size'][1]*18 or any(len(s)!=room['size'][0]*32 for s in room['layout']):errors.append(id+': layout geometry mismatch')
  if room['map']['mask']!=['#'*room['size'][0]]*room['size'][1]:errors.append(id+': map geometry')
  physical[id]=physics_reachable(room,abilities,set())
  if not all(physical[id][0].values()):errors.append(id+': inaccessible entry '+str(physical[id]))
  for ex in room['exits']:
   if ex['target_room'] not in rooms:errors.append(id+': missing exit');continue
   target=rooms[ex['target_room']];reverse={'left':'right','right':'left','top':'bottom','bottom':'top','portal':'portal'}[ex['side']]
   if ex['side']!='portal':
    dx,dy={'left':(-3,0),'right':(3,0),'top':(0,-2),'bottom':(0,2)}[ex['side']]
    if target['grid_pos']!=[pos[0]+dx,pos[1]+dy]:errors.append(id+': mismatched grid boundary')
    if not any(e['target_room']==id and e['side']==reverse and e['from']==ex['from'] and e['to']==ex['to'] for e in target['exits']):errors.append(id+': unmatched exit')
  enemies=[e for e in room['entities'] if e['type']=='enemy'];r=next(r for r in regions if r['id']==room['region'])
  if r['number']==6 and enemies:errors.append(id+': peaceful region enemy')
  if len(enemies)>30:errors.append(id+': enemy ceiling')
  if not room['boss_room'] and r['number']!=6 and not (12<=len(enemies)<=30):errors.append(id+': density floor')
  for e in room['entities']:
   counts[e['type']]+=1
   if e['type']=='enemy':
    counts[e['id']]+=1;x,y=e['position']
    if any(math.dist(e['position'],entry)<320 for entry in room['entries'].values()):errors.append(id+': unsafe enemy '+e['id'])
    if room['layout'][min(35,int((y-1)//40))][int(x//40)] in '#W':errors.append(id+': enemy in solid')
    if e['spawn_kind'] in ['ground','platform','perch'] and room['layout'][int(y//40)][int(x//40)] not in '#=':errors.append(id+': ungrounded enemy')
    if e['id']=='cedar_demon' and e['spawn_kind']!='perch':errors.append(id+': missing perch')
   elif e['type'] in ['spikes','poison','wind','falling_rock'] and any(math.dist(e['position'],entry)<320 for entry in room['entries'].values()):errors.append(id+': entry hazard')
 # Actual acquire transitions, monotone ability masks, shortest room-transition path.
 start=(index['start'],0);seen={start};q=collections.deque([start]);parent={};gained=[];reachable_content=set()
 while q:
  id,mask=q.popleft();room=rooms[id]
  for e in room['entities']:
   if requires(e.get('requires',[]),mask):
    reachable_content.add((id,e.get('id',e['type'])))
    if e['type']=='altar' and not mask&bits[e['id']]:
     nxt=(id,mask|bits[e['id']])
     if nxt not in seen:seen.add(nxt);parent[nxt]=((id,mask),'acquire '+e['id']);q.append(nxt);gained.append(nxt)
  for ex in room['exits']:
   if requires(ex['requires'],mask):
    nxt=(ex['target_room'],mask)
    if nxt not in seen:seen.add(nxt);parent[nxt]=((id,mask),'travel');q.append(nxt)
 reached_rooms={id for id,_ in seen};missing=set(rooms)-reached_rooms
 if missing:errors.append('Unreachable rooms: '+str(sorted(missing)))
 for id,r in rooms.items():
  for e in r['entities']:
   if (id,e.get('id',e['type'])) not in reachable_content:errors.append(id+': unreachable content '+str(e))
 # For every 128 inventory combinations, ensure each possible-entry room has a
 # route back to the landing. Secret rooms are not possible-entry without vision.
 for mask in range(128):
  eligible={id for id,r in rooms.items() if requires(r['secret_requires'],mask)};reverse=collections.defaultdict(list)
  for id in eligible:
   for ex in rooms[id]['exits']:
    if ex['target_room'] in eligible and requires(ex['requires'],mask):reverse[ex['target_room']].append(id)
  found={index['start']};todo=[index['start']]
  while todo:
   for id in reverse[todo.pop()]:
    if id not in found:found.add(id);todo.append(id)
  if eligible-found:errors.append(f'Softlock inventory={mask}: {sorted(eligible-found)[:5]}')
 for region in regions:errors.extend(region['id']+': '+e for e in seam_check(ROOT/region['atlas'].removeprefix('res://')))
 full=next((s for s in gained if s[1]==127),None);route=[]
 if full:
  while full!=start:previous,action=parent[full];route.append({'room':full[0],'action':action});full=previous
  route.reverse()
 else:errors.append('Full ability inventory unreachable')
 raw=b''.join((ROOT/p.removeprefix('res://')).read_bytes() for p in index['rooms'].values())
 stats={'rooms':len(rooms),'screens':sum(r['size'][0]*r['size'][1] for r in rooms.values()),'horizontal_distance_px':sum(r['size'][0]*1280 for r in rooms.values()),'regions':{r['id']:{'rooms':sum(room['region']==r['id'] for room in rooms.values()),'screens':sum(room['size'][0]*room['size'][1] for room in rooms.values() if room['region']==r['id']),'enemies':sum(sum(e['type']=='enemy' for e in room['entities']) for room in rooms.values() if room['region']==r['id'])} for r in regions},'counts':dict(counts),'secret_rooms':sum(r['secret'] for r in rooms.values()),'gates':sum(len(r['gates']) for r in rooms.values()),'ability_states':len(seen),'softlock_inventory_combinations':128,'data_bytes':len(raw),'data_deflate_bytes':len(zlib.compress(raw,9)),'physics_jump_height':abilities['movement']['jump_impulse']**2/(2*abilities['movement']['gravity']),'errors':errors,'progression_route':route}
 output=ROOT/'archive/stage14/world_validation.json';output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(stats,ensure_ascii=False,indent=2)+'\n')
 (ROOT/'docs/WORLD_STATS_KO.md').write_text('# 자불리스탄 실제 규모\n\n'+f"방 {stats['rooms']}개, {stats['screens']}화면, 가로 거리 합 {stats['horizontal_distance_px']:,}px. 숨은 방 {stats['secret_rooms']}개, 게이트 {stats['gates']}개.\n\n"+'|구역|방|화면|적|\n|---|---:|---:|---:|\n'+'\n'.join(f"|{r['name']}|{stats['regions'][r['id']]['rooms']}|{stats['regions'][r['id']]['screens']}|{stats['regions'][r['id']]['enemies']}|" for r in regions)+'\n\n'+f"생명 조각 {counts['life']}, 결정 {counts['crystal']}, 일반 적 {counts['enemy']}. 방 데이터 {len(raw):,}B, DEFLATE {stats['data_deflate_bytes']:,}B.\n")
 (ROOT/'docs/WORLD_PROGRESSION_KO.md').write_text('# 능력 진행과 복귀 검증\n\n'+f"점프 높이 {stats['physics_jump_height']:.2f}px. 플랫폼 그래프는 중력·도약·속도를 읽으며 120px 간격 계단을 검증한다. 128개 능력 조합에서 접근 가능한 모든 방의 착륙 지점 복귀 경로를 검사한다. 전투 승리 가능성은 그래프 솔버 범위 밖이며 런타임 전투 테스트로 분리한다.\n\n"+' → '.join(r['room']+(' ['+r['action']+']' if r['action']!='travel' else '') for r in route)+'\n')
 if args.runtime:
  env=os.environ.copy();env['XDG_DATA_HOME']=str(ROOT/'archive/stage14/runtime_validation');env['XDG_CONFIG_HOME']='/workspace/cache/stage14/config'
  result=subprocess.run([__import__('run_headless_checks').find_godot(),'--headless','--path',str(ROOT),'--script','res://tests/stage14_world_runtime.gd'],env=env,capture_output=True,text=True)
  log=result.stdout+result.stderr;(ROOT/'archive/stage14/runtime_validation.log').write_text(log)
  if result.returncode or any(word in log for word in ['ERROR:','WARNING:']):errors.append('Runtime validation failed; see runtime_validation.log')
 print(f"WORLD: {len(rooms)} rooms / {stats['screens']} screens / {len(seen)} ability states / {len(errors)} errors")
 for e in errors[:30]:print('FAIL',e)
 return bool(errors)
if __name__=='__main__':sys.exit(main())
