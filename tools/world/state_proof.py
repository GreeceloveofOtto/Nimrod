"""Exact monotone physical reach/return functions, checked over every flag state."""
import collections
import numpy as np

def prove(nodes,root,edges,ability_bits,door_bits,entry_override=None,symbolic_only=False):
 def minimal_paths(reverse=False):
  adjacency=collections.defaultdict(list)
  for (a,b),options in edges.items():
   if reverse:a,b=b,a
   for req in options:adjacency[a].append((b,req))
  masks=[set()for _ in range(nodes)];masks[root].add(0);queue=collections.deque([(root,0)])
  while queue:
   a,carried=queue.popleft()
   if carried not in masks[a]:continue
   for b,required in adjacency[a]:
    candidate=carried|required
    if any(old&candidate==old for old in masks[b]):continue
    masks[b].difference_update(old for old in list(masks[b])if old&candidate==candidate)
    masks[b].add(candidate);queue.append((b,candidate))
  return masks
 forward=minimal_paths()if entry_override is None else [set(options)for options in entry_override]
 if entry_override is not None:
  adjacency=collections.defaultdict(list)
  for (a,b),options in edges.items():
   for req in options:adjacency[a].append((b,req))
  todo=collections.deque((a,mask)for a,options in enumerate(forward)for mask in options)
  while todo:
   a,mask=todo.popleft()
   if mask not in forward[a]:continue
   for b,req in adjacency[a]:
    new=mask|req
    if any(old&new==old for old in forward[b]):continue
    forward[b].difference_update(old for old in list(forward[b])if old&new==new);forward[b].add(new);todo.append((b,new))
 returned=minimal_paths(True)
 if symbolic_only:
  failure=None
  for component,options in enumerate(forward):
   for reached in options:
    if not any(back&reached==back for back in returned[component]):failure={'minimum_entry_mask':reached,'component':component};break
   if failure:break
  return {'method':'exact minimal-mask implication certificate for every flag superset','states_checked':0,'states_covered':(1<<(ability_bits+door_bits))if failure is None else 0,'ability_bits':ability_bits,'door_bits':door_bits,'condensed_nodes':nodes,'failure':failure}
 # Each bit pattern appears explicitly in this vector, including all closed and
 # all open histories. For every ability subset, evaluate the exact minimal-path
 # Boolean functions on all door states and compare reach => return.
 door_states=np.arange(1<<door_bits,dtype=np.uint32);functions={():False,(0,):True};pairs={};checked=0;failure=None
 ability_mask=(1<<ability_bits)-1
 def evaluate(options):
  key=tuple(sorted(options))
  if key not in functions:
   value=np.zeros(len(door_states),dtype=bool)
   for required in key:value|=(door_states&required)==required
   functions[key]=value
  return functions[key]
 for ability in range(1<<ability_bits):
  for component in range(nodes):
   def allowed(masks):
    reqs={m>>ability_bits for m in masks if not(m&ability_mask)&~ability}
    return (0,)if 0 in reqs else tuple(sorted(reqs))
   reach_key=allowed(forward[component]);return_key=allowed(returned[component]);pair=(reach_key,return_key)
   if pair not in pairs:
    reached=evaluate(reach_key);back=evaluate(return_key)
    bad=np.logical_and(reached,np.logical_not(back));indices=np.flatnonzero(bad);pairs[pair]=int(indices[0])if len(indices)else None
   if pairs[pair]is not None:
    failure={'abilities':ability,'doors':pairs[pair],'component':component};break
  checked+=len(door_states)
  if failure:break
 return {'method':'minimal physical path antichains; vector enumeration of all ability/door states','states_checked':checked,'ability_bits':ability_bits,'door_bits':door_bits,'condensed_nodes':nodes,'condensed_edges':len(edges),'forward_minimal_masks':[sorted(m)for m in forward],'return_minimal_masks':[sorted(m)for m in returned],'distinct_boolean_functions':len(functions),'failure':failure}
