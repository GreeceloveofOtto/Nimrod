"""Conservative ability entry: unlimited flight through real body-clear space.
Returning still uses the actual fixed-step walking/jump/crawl graph. Short-body
entry is propagated only by grounded crawl edges, never by flying under ceilings.
"""
import collections,math
import numpy as np
from scipy.ndimage import label
from gate_conditions import combine,minimal

def antichains(nodes,root,edges):
 masks=[set()for _ in range(nodes)];masks[root].add(0);adj=collections.defaultdict(list)
 for (a,b),options in edges.items():
  for req in options:adj[a].append((b,req))
 todo=collections.deque([(root,0)])
 while todo:
  a,mask=todo.popleft()
  if mask not in masks[a]:continue
  for b,req in adj[a]:
   new=mask|req
   if any(old&new==old for old in masks[b]):continue
   masks[b].difference_update(old for old in list(masks[b])if old&new==new)
   masks[b].add(new);todo.append((b,new))
 return masks

def entry_masks(rows,coords,physical_labels,renumber,spawn,gates,requirements,ability_ids):
 a=np.array([list(row)for row in rows]);H,W=a.shape;solid=np.isin(a,['#','W','^']);output=[set()for _ in renumber];stats=[]
 for body_rows,crawl in [(4,False)]:
  clear=np.zeros_like(solid)
  for y in range(body_rows,H):
   col=~solid[y-body_rows:y].any(0);clear[y]=col&np.roll(col,1)
  clear[:,0]=False;clear[:,-1]=False
  blocks=np.zeros((H,W),dtype=object)
  for index,e in enumerate(gates):
   if e.get('virtual'):continue
   gx,gy=[v/32 for v in e['position']];xa=max(0,math.ceil(gx-1.4375));xb=min(W,math.floor(gx+1.4375)+1);ya=max(0,math.floor(gy-5)+1);yb=min(H,math.ceil(gy+(1.5 if crawl else 3.875)))
   blocks[ya:yb,xa:xb]|=1<<index
  labels,count=label(clear&(blocks==0));grid=labels.astype(np.int32)-1;node_req=[frozenset([0])for _ in range(count)]
  for bits in set(int(v)for v in blocks[clear]if v):
   local,n=label(clear&(blocks==bits));req=combine(bits,requirements)
   marked=local>0;grid[marked]=local[marked]-1+len(node_req);node_req += [req]*n
  edges={}
  for first,second in [(grid[:-1,:],grid[1:,:]),(grid[:,:-1],grid[:,1:])]:
   adjacent=(first>=0)&(second>=0)&(first!=second)
   for p,q in set(zip(first[adjacent].tolist(),second[adjacent].tolist())):
    req=minimal(a|b for a in node_req[p]for b in node_req[q]);edges.setdefault((p,q),set()).update(req);edges.setdefault((q,p),set()).update(req)
  x,y=spawn;root=int(grid[int(y),int(x)])
  if root<0:raise ValueError('Spawn lacks body-clear flight configuration')
  paths=antichains(len(node_req),root,edges);extra=(1<<ability_ids.index('crawl'))if crawl else 0
  for i,(y,x)in enumerate(coords):
   node=int(grid[y,x]);component=renumber[int(physical_labels[i])]
   if node<0:continue
   for mask in paths[node]:
    mask|=extra
    if any(old&mask==old for old in output[component]):continue
    output[component].difference_update(old for old in list(output[component])if old&mask==mask);output[component].add(mask)
  stats.append({'body_rows':body_rows,'crawl_required':crawl,'components':len(node_req),'gate_contacts':len(edges)})
 return output,stats
