#!/usr/bin/env python3
"""Measure spatial repetition in expanded terrain, never names as a geometry proxy."""
from pathlib import Path
import argparse,json,re,collections
import numpy as np
from scipy.ndimage import label
from terrain_rules import load_world,SOLID,window_counts
ROOT=Path(__file__).resolve().parents[2]
FORBIDDEN=re.compile(r'(?<![a-z])(?:sea|salt)(?![a-z])|바다|소금|시무르그|다마반드|수도원|기도',re.I)
def runs(mask):
 padded=np.r_[False,mask,False];edges=np.flatnonzero(padded[1:]!=padded[:-1]);return list(zip(edges[::2].tolist(),edges[1::2].tolist()))
def measure_layout(w,entities,region_id='landing'):
 region=next(r for r in w['regions'] if r['id']==region_id);ox,oy,width,height=region['bounds'];a=np.array([list(row[ox:ox+width]) for row in w['navigation'][oy:oy+height]]);solid=np.isin(a,list(SOLID));free=~solid;errors=[]
 floor=solid[1:]&free[:-1];bands=[]
 for y in range(height-1):
  score=int(floor[y].sum())
  if score>=width*.3:
   if bands and y+1-bands[-1][0]<=3:
    if score>bands[-1][1]:bands[-1]=[y+1,score]
   else:bands.append([y+1,score])
 ys=[p[0] for p in bands];intervals=[b-a for a,b in zip(ys,ys[1:])];repeats=[i for i in range(len(intervals)-1) if intervals[i]==intervals[i+1]]
 if repeats:errors.append('repeated_floor_spacing')
 # A walk-height horizontal aperture >=70% width; adjacent rows form one corridor.
 wide_rows=[]
 for y in range(4,height):
  clear=free[y-4:y].all(axis=0)
  if any(end-start>=width*.7 for start,end in runs(clear)):wide_rows.append(y)
 wide_groups=[]
 for y in wide_rows:
  if not wide_groups or y>wide_groups[-1][-1]+1:wide_groups.append([y])
  else:wide_groups[-1].append(y)
 if len(wide_groups)>2:errors.append('too_many_full_width_corridors')
 # Open rectangles: vertical spans over >=12 columns are halls, >=4 are low passages.
 spans=collections.defaultdict(list)
 for x in range(width):
  for top,bottom in runs(free[:,x]):spans[(top,bottom)].append(x)
 tall=[];low=[]
 for (top,bottom),xs in spans.items():
  for left,right in runs(np.isin(np.arange(width),xs)):
   if 4<=bottom-top<=6 and right-left>=4:low.append([left+ox,top+oy,right-left,bottom-top])
 # Arched tops/uneven floors need overlapping rectangles, not identical column spans.
 rectangles=window_counts(np.isin(a,['.','=']),12,16)==12*16
 labels,count=label(rectangles)
 for index in range(1,count+1):
  yy,xx=np.where(labels==index)
  tall.append([int(xx.min())+ox,int(yy.min())+oy,int(xx.max()-xx.min())+12,int(yy.max()-yy.min())+16])
 if len(tall)<2:errors.append('fewer_than_two_tall_spaces')
 if len(low)<3:errors.append('fewer_than_three_low_spaces')
 long=[]
 for x in range(width):
  for top,bottom in runs(free[:,x]):
   if bottom-top>90:long.append([x+ox,top+oy,bottom-top])
 groups=[]
 for x,top,length in long:
  if not groups or x>groups[-1][-1][0]+1:groups.append([])
  groups[-1].append([x,top,length])
 if len(groups)>1:errors.append('multiple_shafts_over_90')
 gates=[e for e in entities if e['region']==region_id and e['type']=='gate'];columns=[];close=[]
 for i,e in enumerate(gates):
  x=e['position'][0]/32;near=[g['uid'] for g in gates if abs(g['position'][0]/32-x)<=3]
  if len(near)>=3:columns.append(near)
  for g in gates[i+1:]:
   if abs(g['position'][0]/32-x)<12:close.append([e['uid'],g['uid']])
 if columns:errors.append('three_gates_in_one_column')
 if close:errors.append('gate_x_spacing_below_12')
 exterior=100*float((a==':').mean())
 if region_id in ['landing','ridge','skywalk'] and exterior<10:errors.append('exterior_below_10_percent')
 if region_id=='landing' and exterior>20:errors.append('exterior_above_20_percent')
 return {'passed':not errors,'errors':errors,'floor_bands':bands,'floor_intervals':intervals,'full_width_corridors':wide_groups,'tall_spaces':tall,'low_spaces':low,'long_shaft_groups':groups,'gate_columns':columns,'gate_spacing_failures':close,'exterior_percent':exterior}
def forbidden_themes():
 paths=list((ROOT/'data/world/zabulistan/source/rooms').glob('*.txt'))+list((ROOT/'assets/image_prompts').glob('zabulistan_*.md'));bad=[]
 for p in paths:
  text=p.name+'\n'+(p.read_text() if p.suffix=='.md' else '')
  words=sorted(set(m[0] for m in FORBIDDEN.finditer(text)))
  if words:bad.append({'path':str(p.relative_to(ROOT)),'words':words})
 return bad
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--output',default='archive/stage15_landing_revision/layout.json');args=parser.parse_args();w,e,*_=load_world();result=measure_layout(w,e);result['forbidden_themes']=forbidden_themes();result['passed']=result['passed'] and not result['forbidden_themes'];out=ROOT/args.output;out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');print(json.dumps(result,ensure_ascii=False,indent=2));raise SystemExit(int(not result['passed']))
