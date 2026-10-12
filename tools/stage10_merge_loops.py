#!/usr/bin/env python3
"""Coalesce adjacent perceptually equivalent idle frames; keep logical timings and at least three poses."""
import json,io,shutil,argparse
from pathlib import Path
from PIL import Image
from downscale_assets import ROOT,ssim
from build_image_parity_fixtures import reference
from stage9_optimize_density import encoded

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--only',help='Process one asset path');args=parser.parse_args()
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());rows=json.loads((ROOT/'data/storage_quality.json').read_text());policy=json.loads((ROOT/'data/image_policy.json').read_text());results=[]
 for row in rows:
  path=ROOT/row['path'].removeprefix('res://');spec=registry[row['path']];n=spec['frames']
  if spec.get('stored_columns',n)!=n:continue
  if args.only and str(path.relative_to(ROOT))!=args.only:continue
  if path.stem not in ['idle','idle_front','float','fly_idle','glide','sit_idle','crouch_idle','walk','run','death','cry_loop'] or n<6:continue
  sheet=reference(row,spec);w,h=spec['storage_trim']['w'],spec['storage_trim']['h'];frames=[sheet.crop((i*w,0,(i+1)*w,h)) for i in range(n)];mapping=[];selected=[];scores=[];merged_last=False
  for i,frame in enumerate(frames):
   score=ssim(frames[selected[-1]],frame) if selected else 0
   if selected and score>=.985 and not merged_last and i!=n-1:
    mapping.append(len(selected)-1);scores.append(score);merged_last=True
   else:selected.append(i);mapping.append(len(selected)-1);merged_last=False
  if len(selected)==n or len(selected)<3:
   results.append({'path':row['path'],'merged':0});continue
  candidate=Image.new('RGBA',(w*len(selected),h))
  for k,i in enumerate(selected):candidate.paste(frames[i],(k*w,0))
  content,metrics=encoded(candidate);before=path.stat().st_size
  if len(content)>=before:continue
  backup=ROOT/'archive/stage10_before_merging'/path.relative_to(ROOT);backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,backup);path.write_bytes(content)
  spec.update(frame_map=mapping,stored_columns=len(selected),image_size=list(candidate.size),temporal_ssim_min=min(scores),logical_duration_unchanged=True,encoding=metrics)
  policy.setdefault('overrides',{})[str(path.relative_to(ROOT))]=metrics
  row.update(output_bytes=len(content),stored_frames=len(selected),temporal_ssim_min=min(scores),**metrics)
  results.append({'path':row['path'],'merged':n-len(selected),'before':before,'after':len(content),'minimum_ssim':min(scores),'frame_map':mapping})
  print(path.parent.name,path.stem,'logical',n,'stored',len(selected),'SSIM',min(scores),flush=True)
 for mp in (ROOT/'assets').rglob('*manifest.json'):
  d=json.loads(mp.read_text());dirty=False
  for c in d.get('clips',[]):
   s=c['sheet'];path=ROOT/s.removeprefix('res://') if s.startswith('res://') else ROOT/'assets'/s if s.startswith(('sprites/','props/','fx/')) else mp.parent/s;key='res://'+str(path.relative_to(ROOT))
   if key in registry:c.update(registry[key]);dirty=True
  if dirty:mp.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
 for p,d in [('data/sprite_trims.json',registry),('data/storage_quality.json',rows),('data/image_policy.json',policy),('archive/stage10/loop_merges.json',results)]: (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
 print('MERGE saved',sum(x.get('before',0)-x.get('after',0) for x in results)/1048576)
if __name__=='__main__':main()
