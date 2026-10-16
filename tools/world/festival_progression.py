"""Physical base-route, site supply and short-run checks for schema-3 attempts."""
from pathlib import Path
import collections,json,math
import numpy as np
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra
ROOT=Path(__file__).resolve().parents[2]
def measure(w,entities,coords,ea,eb,masks,gate_specs,closed_core,start,tuning):
 errors=[];check=lambda ok,msg:errors.append(msg) if not ok else None
 ability_data=json.loads((ROOT/'data/world/abilities.json').read_text())['abilities'];ability_ids=list(ability_data)
 sites=[e for e in entities if e['type']=='site'];cords=[e for e in entities if e['type']=='cord'];embers=[e for e in entities if e['type']=='ember'];piers=[e for e in entities if e['type']=='return_pier']
 check(len(sites)>=14,'Fewer than fourteen festival sites');check(len(cords)==60 and len(embers)==60,'Cords/embers must each total sixty');check(len(piers)==4,'Four return piers required')
 supply={id:sorted({e['region']for e in sites if e['ability']==id})for id in ability_ids}
 for id,regions in supply.items():check(len(regions)>=2,id+': supply is not in two distinct regions')
 check(not any(e['region']=='village'for e in sites),'Village cannot have a festival site')
 check(all(not row.get('requires')for row in ability_data.values()),'Acquisition chain remains')
 def near(e):
  x,y=[v/32 for v in e['position']];dist=(coords[:,1]-x)**2+(coords[:,0]-y)**2
  return np.flatnonzero(dist<=(100/32)**2)
 base_sites={}
 for region in w['regions']:
  rid=region['id'];local=[e for e in sites if e['region']==rid];base_sites[rid]=[e['uid']for e in local if any(closed_core[near(e)]) and not e.get('requires')]
  if rid!='village':check(bool(base_sites[rid]),rid+': no site reachable with zero abilities and all shortcuts closed')
  doors=[e for e in entities if e['region']==rid and e['type']=='gate' and e.get('opens_with')]
  check(len({e['opens_with']for e in doors})>=2,rid+': fewer than two permanent shortcuts')
 for e in entities:
  if e['type']in ['boss','return_pier','switch']:check(any(closed_core[near(e)]),e['uid']+': mandatory target lacks a closed-shortcut base route')
 # Distances use real directed physical edges, base jump/fall timing and walking.
 # All permanent doors are open, ability barriers remain closed.
 ability_gate_bits=sum(1<<i for i,g in enumerate(gate_specs)if g.get('requires'))
 allowed=np.array([not (mask&ability_gate_bits)for mask in masks]);aa=np.asarray(ea)[allowed];bb=np.asarray(eb)[allowed]
 delta=coords[bb]-coords[aa];dx=np.abs(delta[:,1])*32;dy=delta[:,0]*32;speed=float(tuning['speed']);gravity=float(tuning['gravity']);impulse=float(tuning['jump_impulse'])
 times=np.maximum(.02,np.hypot(dx,dy)/speed)
 up=dy<0;disc=np.maximum(0,impulse**2+2*gravity*dy[up]);times[up]=np.maximum(times[up],(impulse+np.sqrt(disc))/gravity)
 down=dy>0;times[down]=np.maximum(times[down],np.sqrt(2*dy[down]/gravity))
 # COO duplicate summation would inflate costs; retain the cheapest physical edge.
 cheapest={}
 for a,b,c in zip(aa,bb,times):
  key=(int(a),int(b));cheapest[key]=min(cheapest.get(key,float('inf')),float(c))
 weighted=coo_matrix(([v for v in cheapest.values()],([k[0]for k in cheapest],[k[1]for k in cheapest])),shape=(len(coords),len(coords))).tocsr();dist=dijkstra(weighted,directed=True,indices=start)
 entrances={}
 for region in w['regions']:
  x,y,width,height=region['bounds'];inside=(coords[:,1]>=x)&(coords[:,1]<x+width)&(coords[:,0]>=y)&(coords[:,0]<y+height)
  border=inside&((coords[:,1]<=x+2)|(coords[:,1]>=x+width-2)|(coords[:,0]<=y+4)|(coords[:,0]>=y+height-2))
  candidates=np.flatnonzero(border)
  if region['id']=='landing':candidates=np.array([start])
  check(bool(len(candidates)),region['id']+': no physical entry positions')
  check(any(closed_core[candidates]),region['id']+': no main entrance has a zero-ability closed-shortcut route')
  reachable=[int(i)for i in candidates if closed_core[i] and math.isfinite(float(dist[i]))]
  if reachable:
   best=min(reachable,key=lambda i:dist[i]);entrances[region['id']]={'main_entry_tile':[int(coords[best,1]),int(coords[best,0])],'seconds':round(float(dist[best]),3),'boundary_positions':len(candidates),'closed_base_main_entry':bool(closed_core[best]),'closed_base_boundary_positions':int(closed_core[candidates].sum())}
   check(dist[best]<=180,region['id']+': main entry travel exceeds 180 seconds')
  else:errors.append(region['id']+': no base route with shortcuts open')
 # All sites currently have a physical zero-ability route: depth 0 is a valid
 # special case of the required <=2 acquisition graph, with no inferred chain.
 tiers={e['uid']:0 if any(closed_core[near(e)]) and not e.get('requires') else None for e in sites}
 check(all(v is not None for v in tiers.values()),'A site needs a separate tier-1/2 path proof')
 return {'passed':not errors,'errors':errors,'site_count':len(sites),'supply_regions':supply,'base_sites':base_sites,'site_tiers':tiers,'maximum_tier':max([v for v in tiers.values()if v is not None],default=0),'cord_count':len(cords),'ability_locked_cords':sum(bool(e.get('requires'))for e in cords),'ember_count':len(embers),'return_piers':[e['uid']for e in piers],'entrances':entrances,'travel_model':'360px/s walking, ballistic jump/fall time, no abilities, permanent doors open'}
