#!/usr/bin/env python3
"""Validate the continuous physical tile world. Includes empty/solid duplicate windows.
No room graph is used as a proxy for physical traversal.
"""
from pathlib import Path
import json,hashlib,itertools,collections,math,sys,time,pickle,gzip
import numpy as np
import jsonschema
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components,breadth_first_order
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'data/world/zabulistan'
def rle_decode(row):return ''.join(str(c)*int(n) for c,n in row)
def validate():
 started=time.monotonic();w=json.loads((BASE/'world_v2.json').read_text());jsonschema.validate(w,json.loads((ROOT/'data/world/world_v2.schema.json').read_text()));rows=w['navigation'];a=np.array([list(row) for row in rows]);H,W=a.shape;errors=[];entities=[];pieces=[];chunks={}
 check=lambda condition,message:errors.append(message) if not condition else None
 check((W,H)==(w['width'],w['height']),'World bounds mismatch')
 for id,path in w['chunks'].items():
  d=json.loads((ROOT/path.removeprefix('res://')).read_text());jsonschema.validate(d,json.loads((ROOT/'data/world/chunk.schema.json').read_text()));cx,cy=d['coord'];x=cx*64;y=cy*36;actual=[rle_decode(r) for r in d['rle']];check(actual==[r[x:x+64] for r in rows[y:y+36]],f'{id}: boundary/terrain differs from ASCII');entities+=d['entities'];pieces+=d['landmarks'];chunks[id]=d
 enemy_stats={e['id']:e for e in json.loads((ROOT/'data/enemies.json').read_text())['enemies']}
 for e in entities:
  x,y=[float(v)/32 for v in e['position']];check(0<=x<W and 0<=y<H,f'{e["uid"]}: out of bounds')
 for e in entities:
  if e['type'] not in ['enemy','boss']:continue
  x,y=[float(v)/32 for v in e['position']];stats=enemy_stats[e['id']];width,height=stats['body_size'];offset=float(stats.get('body_offset_y',-height/2))
  left=max(0,math.floor(x-width/64));right=min(W,math.ceil(x+width/64));top=max(0,math.floor(y+(offset-height/2)/32));bottom=min(H,math.ceil(y+(offset+height/2)/32))
  check(not any(c in '#W' for line in rows[top:bottom] for c in line[left:right]),e['uid']+': body overlaps solid terrain')
  if e['id']!='cedar_wisp':check(rows[int(y)][int(x)] in '#W=',e['uid']+': feet lack ground')
 for key,n in collections.Counter((p['region'],p['piece']) for p in pieces).items():check(n<=3,f'{key}: reused {n} times')
 # Exact full-content windows, no exclusion for sky or rock and no coordinate salts.
 seen={};duplicates=[];duplicate_count=0
 for y in range(H-13):
  for x in range(W-23):
   raw=''.join(r[x:x+24] for r in rows[y:y+14]).encode();key=hashlib.blake2b(raw,digest_size=16).digest()
   if key in seen:
    duplicate_count+=1
    if len(duplicates)<30:duplicates.append({'first':seen[key],'second':[x,y]})
   else:seen[key]=[x,y]
 check(duplicate_count==0,f'{duplicate_count} exact duplicate 24x14 windows (including empty/solid)')
 # Standing-foot configuration grid: width 36, height124; one-way ceilings are passable.
 solid=np.isin(a,['#','W']);support=np.isin(a,['#','W','=']);valid=np.zeros_like(solid)
 for y in range(4,H):
  clear=~solid[y-4:y].any(axis=0)
  clear=clear & np.roll(clear,1)&np.roll(clear,-1)
  valid[y]=support[y]&clear
 valid[:,0]=False;valid[:,-1]=False
 gate_specs=[e for e in entities if e['type']=='gate']
 gate_mask=np.zeros((H,W),dtype=object)
 for i,e in enumerate(gate_specs):
  gx,gy=[float(v)/32 for v in e['position']]
  xa=max(0,math.ceil(gx-1.4375));xb=min(W,math.floor(gx+1.4375)+1);ya=max(0,math.floor(gy-5)+1);yb=min(H,math.ceil(gy+3.875))
  gate_mask[ya:yb,xa:xb]=gate_mask[ya:yb,xa:xb]|(1<<i)
 coords=np.argwhere(valid);edge_masks=[];ids={tuple(p):i for i,p in enumerate(coords)};edges_a=[];edges_b=[]
 tuning=json.loads((ROOT/'data/world/abilities.json').read_text())['movement'];g=float(tuning['gravity'])/32;v=float(tuning['jump_impulse'])/32;speed=float(tuning['speed'])/32
 def body_clear(x,y):
  ix=int(round(x));iy=int(math.ceil(y))
  return 1<=ix<W-1 and 4<=iy<H and not solid[iy-4:iy,max(0,ix-1):min(W,ix+2)].any()
 # Base movement conservatively samples the actual ballistic arc; only valid landing nodes.
 # Additional abilities can only add edges because all required routes have a base return.
 cache_key=hashlib.sha256(json.dumps(['precise_gate_v2',rows,gate_specs,tuning],sort_keys=True).encode()).hexdigest()[:16]
 cache_file=ROOT/'archive/stage14_rework'/('navigation_'+cache_key+'.pickle.gz')
 cache_file.parent.mkdir(parents=True,exist_ok=True)
 if cache_file.exists():
  edges_a,edges_b,edge_masks=pickle.loads(gzip.decompress(cache_file.read_bytes()))
 else:
  for i,(y,x) in enumerate(coords):
   for dy in range(-4,9):
    yy=y+dy
    if yy<4 or yy>=H:continue
    disc=v*v+2*g*dy
    if disc<0:continue
    flight=(v+math.sqrt(disc))/g
    reach=min(12,int(speed*flight))
    for dx in range(-reach,reach+1):
     j=ids.get((yy,x+dx))
     if j is None or j==i:continue
     if dy==0 and abs(dx)<=2:
      times=[0.];flight=max(.01,abs(dx)/speed)
     else:times=[k*flight/8 for k in range(1,8)]
     if all(body_clear(x+dx*(t/flight),y-v*t+.5*g*t*t) for t in times):
      bits=int(gate_mask[y,x])|int(gate_mask[yy,x+dx])
      for t in times:
       sx=int(round(x+dx*(t/flight)));sy=int(math.ceil(y-v*t+.5*g*t*t))
       if 0<=sx<W and 0<=sy<H:bits|=int(gate_mask[sy,sx])
      edges_a.append(i);edges_b.append(j);edge_masks.append(bits)
   # Dropping through a one-way platform is existing S+Space movement.
   for yy in range(y+1,min(H,y+10)):
    j=ids.get((yy,x))
    if j is not None:
     if all(body_clear(x,y+t) for t in range(1,yy-y+1)):
      bits=0
      for sy in range(y,yy+1):bits|=int(gate_mask[sy,x])
      edges_a.append(i);edges_b.append(j);edge_masks.append(bits)
     break
  cache_file.write_bytes(gzip.compress(pickle.dumps((edges_a,edges_b,edge_masks),protocol=5)))
 # Low world ceilings reject a full jump arc even though stepping off is safe.
 # Model walking to a ledge and falling, without granting an extra jump ability.
 def gate_bits_at(x,y):
  ix=int(round(x));iy=int(math.ceil(y))
  return int(gate_mask[iy,ix]) if 0<=ix<W and 0<=iy<H else 0
 for i,(y,x) in enumerate(coords):
  if y>=9:continue
  for direction in [-1,1]:
   edge_x=x+direction*2
   if not 1<=edge_x<W-1 or support[y,edge_x]:continue
   if not all(body_clear(x+direction*k*.5,y) for k in range(1,5)):continue
   for dy in range(1,9):
    yy=y+dy
    if yy>=H:continue
    duration=math.sqrt(2*dy/g);reach=min(12,int(speed*duration))
    for dx in range(-reach,reach+1):
     j=ids.get((yy,edge_x+dx))
     if j is None:continue
     samples=[(edge_x+dx*k/8,y+dy*(k/8)**2) for k in range(1,8)]
     if not all(body_clear(sx,sy) for sx,sy in samples):continue
     bits=int(gate_mask[y,x])|int(gate_mask[yy,edge_x+dx])
     for k in range(1,5):bits|=gate_bits_at(x+direction*k*.5,y)
     for sx,sy in samples:bits|=gate_bits_at(sx,sy)
     edges_a.append(i);edges_b.append(j);edge_masks.append(bits)
 graph=coo_matrix((np.ones(len(edges_a),dtype=np.uint8),(edges_a,edges_b)),shape=(len(coords),len(coords))).tocsr();count,labels=connected_components(graph,directed=True,connection='strong')
 spawn=w['spawn'];start=min(range(len(coords)),key=lambda i:(coords[i,1]-spawn[0])**2+(coords[i,0]-spawn[1])**2);component=labels[start];reachable=int((labels==component).sum())
 unreachable=[]
 for e in entities:
  if e['type'] in ['enemy','gate']:continue
  x,y=[float(v)/32 for v in e['position']];near=[(idx,(xx-x)**2+(yy-y)**2) for idx,(yy,xx) in enumerate(coords) if (xx-x)**2+(yy-y)**2<=(100/32)**2]
  if not any(labels[idx]==component for idx,_ in near):unreachable.append(e['uid'])
 check(not unreachable,f'{len(unreachable)} rewards/altars/bosses outside bidirectional landing component')
 forward=breadth_first_order(graph,start,directed=True,return_predecessors=False)
 trapped=[int(i) for i in forward if labels[i]!=component]
 check(not trapped,f'{len(trapped)} reachable standing configurations cannot return to landing with base movement')
 diagnostics=collections.Counter((int(coords[i,1]//8),int(coords[i,0]//8)) for i in trapped)
 (ROOT/'archive/stage14_rework/trapped_cells.json').write_text(json.dumps({'forward':len(forward),'trapped':len(trapped),'cells':[[list(k),v] for k,v in diagnostics.items()],'examples':[coords[i].tolist() for i in trapped[:40]]},indent=2))
 # Closed-gate core plus independent gate pockets proves every opening subset,
 # including arbitrary ability combinations and one-way door histories.
 ea=np.asarray(edges_a);eb=np.asarray(edges_b);zero=np.asarray([m==0 for m in edge_masks])
 closed=coo_matrix((np.ones(int(zero.sum()),dtype=np.uint8),(ea[zero],eb[zero])),shape=graph.shape).tocsr()
 _,closed_labels=connected_components(closed,directed=True,connection='strong');core=closed_labels==closed_labels[start]
 node_masks=[int(gate_mask[y,x]) for y,x in coords]
 closed_forward=breadth_first_order(closed,start,directed=True,return_predecessors=False)
 closed_trapped=[int(i) for i in closed_forward if not core[i]]
 check(not closed_trapped,'Closed gates create a reachable one-way trap')
 closed_return=set(int(i) for i in breadth_first_order(closed.transpose().tocsr(),start,directed=True,return_predecessors=False))
 return_missing=[i for i,m in enumerate(node_masks) if m==0 and i not in closed_return]
 check(not return_missing,f'{len(return_missing)} legal standing positions need an extra movement ability to return')
 (ROOT/'archive/stage14_rework/return_invariant.json').write_text(json.dumps({'unmasked_positions':sum(m==0 for m in node_masks),'return_nodes':len(closed_return),'missing':[coords[i].tolist() for i in return_missing]},indent=2))
 cross_zero=[(int(aa),int(bb)) for aa,bb,mm in zip(edges_a,edges_b,edge_masks) if mm==0 and closed_labels[aa]!=closed_labels[bb]]
 (ROOT/'archive/stage14_rework/closed_gate_diagnostics.json').write_text(json.dumps({'closed_trapped':[coords[i].tolist() for i in closed_trapped],'unblocked_outside_core':[coords[i].tolist() for i,m in enumerate(node_masks) if m==0 and not core[i]],'cross_zero_count':len(cross_zero),'cross_examples':[[coords[aa].tolist(),coords[bb].tolist()] for aa,bb in cross_zero[:20]]},indent=2))
 pockets=collections.defaultdict(list)
 for aa,bb,bits in zip(edges_a,edges_b,edge_masks):
  if bits and bits&(bits-1)==0:pockets[bits].append((aa,bb))
 pocket_failures=[];pocket_covered=set()
 for bit,links in pockets.items():
  out=collections.defaultdict(list);back=collections.defaultdict(list)
  for aa,bb in links:out[aa].append(bb);back[bb].append(aa)
  local={n for link in links for n in link};seeds={n for n in local if core[n]}
  def flood(adjacency):
   reached=set(seeds);queue=collections.deque(seeds)
   while queue:
    for n in adjacency.get(queue.popleft(),[]):
     if n not in reached:reached.add(n);queue.append(n)
   return reached
  forward_pocket=flood(out);reverse_pocket=flood(back)
  for n in local:
   if node_masks[n]==bit:
    if n not in forward_pocket or n not in reverse_pocket:pocket_failures.append([int(n),bit.bit_length()-1])
    else:pocket_covered.add(n)
 check(not pocket_failures,f'{len(pocket_failures)} gate pocket positions lack a return route')
 unproved=[int(i) for i in forward if not (core[i] if node_masks[i]==0 else i in pocket_covered)]
 (ROOT/'archive/stage14_rework/unproved_pockets.json').write_text(json.dumps([{'position':coords[i].tolist(),'mask':str(node_masks[i]),'core':bool(core[i])} for i in unproved],indent=2))
 # Larger gated chambers may contain unmasked terrain outside the closed core.
 # Exhaustive ability/door states below cover those chambers rather than assuming them safe.
 check(all(m==0 or m&(m-1)==0 for m in node_masks),'Overlapping gates need a joint pocket proof')
 # Exhaustively traverse a condensation of the physical graph for all ability
 # and one-way-door combinations. Node/edge masks retain swept-body gate contacts.
 ability_ids=list(json.loads((ROOT/'data/world/abilities.json').read_text())['abilities'])
 door_ids=sorted({str(e['opens_with']) for e in gate_specs if e.get('opens_with')})
 requirements=[]
 for e in gate_specs:
  req=0
  for ability in e.get('requires',[]):req|=1<<ability_ids.index(ability)
  if e.get('opens_with'):req|=1<<(7+door_ids.index(str(e['opens_with'])))
  requirements.append(req)
 component_ids=sorted(set(int(closed_labels[i]) for i in forward));renumber={c:i for i,c in enumerate(component_ids)};root_component=renumber[int(closed_labels[start])]
 condensed={}
 for aa,bb,bits in zip(edges_a,edges_b,edge_masks):
  if labels[aa]!=component or labels[bb]!=component:continue
  ca=renumber[int(closed_labels[aa])];cb=renumber[int(closed_labels[bb])]
  if ca==cb:continue
  req=0
  while bits:
   bit=bits&-bits;req|=requirements[bit.bit_length()-1];bits-=bit
  key=(ca,cb);previous=condensed.setdefault(key,set())
  if not any((old&req)==old for old in previous):
   previous.difference_update(old for old in list(previous) if (old&req)==req);previous.add(req)
 state_failure=None;states_checked=0
 for ability_state in range(128):
  outgoing=[[] for _ in component_ids];incoming=[[] for _ in component_ids]
  for (ca,cb),options in condensed.items():
   for req in options:
    if (req&127)&~ability_state:continue
    door_req=req>>7;outgoing[ca].append((cb,door_req));incoming[cb].append((ca,door_req))
  def reach(adjacency,door_state):
   result=1<<root_component;todo=[root_component]
   while todo:
    ca=todo.pop()
    for cb,required in adjacency[ca]:
     bit=1<<cb
     if result&bit or required&~door_state:continue
     result|=bit;todo.append(cb)
   return result
  for door_state in range(1<<len(door_ids)):
   reached=reach(outgoing,door_state);returned=reach(incoming,door_state);states_checked+=1
   if reached&~returned:
    state_failure={'abilities':[a for i,a in enumerate(ability_ids) if ability_state&(1<<i)],'doors':[a for i,a in enumerate(door_ids) if door_state&(1<<i)],'trapped_components':[i for i in range(len(component_ids)) if (reached&~returned)&(1<<i)]};break
  if state_failure:break
 check(state_failure is None,'Ability/door state creates a one-way trap: '+str(state_failure))
 (ROOT/'archive/stage14_rework/state_solver.json').write_text(json.dumps({'states_checked':states_checked,'condensed_nodes':len(component_ids),'condensed_edges':len(condensed),'failure':state_failure},indent=2))
 normal=[e for e in entities if e['type']=='enemy'];density={};max_window=0;windows_with_enemies=0;window_count=0
 for region in w['regions']:
  es=[e for e in normal if e['region']==region['id']];density[region['id']]=dict(count=len(es),elite=sum(e.get('elite',False) for e in es),colossus=sum(e['id']=='cedar_colossus' for e in es))
  check(density[region['id']]['colossus']<=2,f'{region["id"]}: too many colossi')
 counts=np.zeros((H,W),dtype=np.int32)
 for e in normal:counts[min(H-1,int(e['position'][1]/32)),min(W-1,int(e['position'][0]/32))]+=1
 integral=np.pad(counts,((1,0),(1,0))).cumsum(0).cumsum(1)
 windows=integral[23:,40:]-integral[:-23,40:]-integral[23:,:-40]+integral[:-23,:-40]
 max_window=int(windows.max());windows_with_enemies=int((windows>0).sum());window_count=windows.size
 check(max_window<=3,'Sliding 40x23 viewport monster maximum exceeds 3');check(windows_with_enemies/window_count<=.5,'Less than half of exploration cells are peaceful')
 for colossus in [e for e in normal if e['id']=='cedar_colossus']:
  nearby=[e['uid'] for e in normal if e is not colossus and abs(e['position'][0]-colossus['position'][0])<1280 and abs(e['position'][1]-colossus['position'][1])<720]
  check(not nearby,colossus['uid']+': shares a viewport with '+str(nearby))
 check(sum(e.get('elite',False) for e in normal)/max(1,len(normal))<=.05,'Elite ratio exceeds 5%')
 report={'passed':not errors,'errors':errors,'world_tiles':[W,H],'chunks':len(chunks),'landmarks':len(pieces),'normal_enemies':len(normal),'baseline_normal_enemies':13790,'reduction_percent':100*(1-len(normal)/13790),'density_by_region':density,'maximum_enemies_per_viewport':max_window,'peaceful_viewports_percent':100*(1-windows_with_enemies/window_count),'duplicate_windows':duplicate_count,'duplicate_examples':duplicates,'standing_nodes':len(coords),'reachable_standing_nodes':len(forward),'trapped_reachable_nodes':len(trapped),'landing_bidirectional_nodes':reachable,'strong_components':int(count),'closed_gate_core_nodes':int(core.sum()),'ability_independent_return_missing':len(return_missing),'gate_pocket_failures':len(pocket_failures),'gate_states_proved':states_checked,'state_solver_failure':state_failure,'unreachable_rewards':unreachable,'physics':tuning,'seconds':time.monotonic()-started}
 out=ROOT/'archive/stage14_rework/world_validation.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps({k:v for k,v in report.items() if k not in ['duplicate_examples','density_by_region','physics','unreachable_rewards']},ensure_ascii=False,indent=2));return report
if __name__=='__main__':sys.exit(0 if validate()['passed'] else 1)
