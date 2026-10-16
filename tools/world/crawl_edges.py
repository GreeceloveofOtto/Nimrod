"""Grounded 36x48 crawl traversal; no jump or flight is granted to crawling."""
import math
import numpy as np

def add(rows,coords,ids,normal,gate_specs,tuning,settings,ea,eb,masks,source_filter=None):
 a=np.array([list(r)for r in rows]);solid=np.isin(a,['#','W','^']);oneway=a=='=';H,W=a.shape;integral=np.pad(solid.astype(np.int32),((1,0),(1,0))).cumsum(0).cumsum(1)
 gate=np.zeros((H,W),dtype=object);crawl_bit=1<<(len(gate_specs)-1)
 for index,e in enumerate(gate_specs):
  if e.get('virtual'):continue
  x,y=[v/32 for v in e['position']];xa=max(0,math.ceil(x-1.4375));xb=min(W,math.floor(x+1.4375)+1);ya=max(0,math.floor(y-5)+1);yb=min(H,math.ceil(y+1.5));gate[ya:yb,xa:xb]|=1<<index
 height=float(settings['height'])/32;half=18/32;speed=float(settings['speed'])/32;gravity=float(tuning['gravity'])/32;dt=1/120;added=0
 def clear(x,y):
  l=math.floor(x-half+1e-7);r=math.ceil(x+half-1e-7);t=math.floor(y-height+1e-7);b=math.ceil(y-1e-7)
  return 0<=l<r<=W and 0<=t<b<=H and integral[b,r]-integral[t,r]-integral[b,l]+integral[t,l]==0
 def link(i,j,bits):
  nonlocal added
  if i!=j:ea.append(i);eb.append(j);masks.append(bits|crawl_bit);added+=1
 for i,(sy,sx)in enumerate(coords):
  if source_filter is not None and not source_filter[i]:continue
  if not clear(sx,sy):continue
  # Bidirectional low tunnels follow actual floors, with the real crawl body.
  for direction in [-1,1]:
   j=ids.get((sy,sx+direction))
   if j is not None and all(clear(sx+direction*k/4,sy)for k in range(5)):
    link(i,j,int(gate[sy,sx])|int(gate[sy,sx+direction]));continue
   if not clear(sx+direction,sy):continue
   # Only ledge sources need falling simulation; all other horizontal movement
   # is represented by the neighboring grounded configurations above.
   for release in [.22,.6,1.2]:
    x=float(sx);y=float(sy);vy=0.;bits=int(gate[sy,sx])
    for frame in range(180):
     time=frame*dt;nx=x+(direction*speed*dt if time<release else 0.)
     if clear(nx,y):x=nx
     vy+=gravity*dt;ny=y+vy*dt;l=math.floor(x-half+1e-7);r=math.ceil(x+half-1e-7);floor=None
     if 0<=l<r<=W:
      for yy in range(max(0,math.floor(y-1e-6)),min(H,math.floor(ny)+1)):
       if yy<y-1e-5 or yy>ny+1e-5:continue
       if solid[yy,l:r].any()or oneway[yy,l:r].any():floor=yy;break
     if floor is not None:
      y=float(floor);vy=0.
      for xx in set([round(x),math.floor(x),math.ceil(x)]):
       j=ids.get((floor,xx))
       if j is not None and all(clear(x+(xx-x)*k/4,y)for k in range(5)):link(i,j,bits|int(gate[floor,xx]))
      if floor!=sy:break
     elif clear(x,ny):y=ny
     else:break
     if not(0<=x<W and 0<=y<H):break
     bits|=int(gate[min(H-1,math.ceil(y)),min(W-1,round(x))])
     if time>release+.35:break
  # The established S+Space one-way drop is available while crouched too.
  if not solid[sy,max(0,sx-1):sx+1].any()and oneway[sy,max(0,sx-1):sx+1].any():
   bits=int(gate[sy,sx])
   for yy in range(sy+1,min(H,sy+61)):
    if not clear(sx,yy):break
    bits|=int(gate[yy,sx]);j=ids.get((yy,sx))
    if j is not None:link(i,j,bits);break
 return added
