"""Fixed-step collision traversal for carved corridors, including head impacts.
Uses actual 36x124 body dimensions; does not grant variable-height jumps.
"""
import math
import numpy as np

def add_carved_edges(rows,coords,ids,gate_mask,ea,eb,masks,tuning,regions,source_filter=None):
 a=np.array([list(row) for row in rows]);solid=np.isin(a,['#','W','^']);oneway=a=='=';H,W=solid.shape
 integral=np.pad(solid.astype(np.int32),((1,0),(1,0))).cumsum(0).cumsum(1)
 half=float(tuning['body'][0])/64;height=float(tuning['body'][1])/32;speed=float(tuning['speed'])/32;gravity=float(tuning['gravity'])/32;impulse=float(tuning['jump_impulse'])/32;dt=1/120;added=0
 def bounds(x,y):return math.floor(x-half+1e-7),math.ceil(x+half-1e-7),math.floor(y-height+1e-7),math.ceil(y-1e-7)
 def clear(x,y):
  l,r,t,b=bounds(x,y)
  return 0<=l<r<=W and 0<=t<b<=H and integral[b,r]-integral[t,r]-integral[b,l]+integral[t,l]==0
 for i,(sy,sx) in enumerate(coords):
  if source_filter is not None and not source_filter[i]:continue
  in_carved=any(x<=sx<x+w and y<=sy<y+h for x,y,w,h in regions)
  low_ceiling=solid[max(0,sy-9):max(0,sy-4),max(0,sx-1):min(W,sx+1)].any()
  if not in_carved and not low_ceiling:continue
  for direction in [-1,0,1]:
   for jump in [False,True]:
    for release in ([.22,.45,.8] if jump else [1.15]):
     x=float(sx);y=float(sy);vy=-impulse if jump else 0.;bits=int(gate_mask[sy,sx]);landed=False
     for frame in range(168):
      time=frame*dt;vx=direction*speed if time<release else 0.;nx=x+vx*dt
      if clear(nx,y):x=nx
      vy+=gravity*dt;ny=y+vy*dt
      if vy<0:
       if clear(x,ny):y=ny
       else:
        l,r,t,b=bounds(x,ny);hit=np.argwhere(solid[max(0,t):min(H,b),max(0,l):min(W,r)])
        if hit.size:y=float(max(0,t)+hit[:,0].max()+1)+height+1e-6
        vy=0.
      else:
       l,r,_,_=bounds(x,ny);floor=None
       if 0<=l<r<=W:
        for yy in range(max(0,math.floor(y-1e-6)),min(H,math.floor(ny)+1)):
         if yy<y-1e-5 or yy>ny+1e-5:continue
         if solid[yy,l:r].any() or (oneway[yy,l:r].any() and not(not jump and yy==sy)):
          floor=yy;break
       if floor is not None:
        y=float(floor);vy=0.;landed=True
       elif clear(x,ny):y=ny
       else:break
      if not (0<=x<W and 0<=y<H):break
      bits|=int(gate_mask[min(H-1,math.ceil(y)),min(W-1,round(x))])
      if landed:
       for xx in set([round(x),math.floor(x),math.ceil(x)]):
        j=ids.get((round(y),xx))
        if j is None or j==i:continue
        if all(clear(x+(xx-x)*k/4,y) for k in range(5)):
         ea.append(i);eb.append(j);masks.append(bits|int(gate_mask[round(y),xx]));added+=1
       if jump:break
       landed=False
      if time>release+.35:break
 return added
