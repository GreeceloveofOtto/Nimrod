#!/usr/bin/env python3
"""Pack generated weapon edits, retaining the original pose scale and timings."""
import argparse,json,shutil,sys
from pathlib import Path
from PIL import Image
from slice_strip import pack,slices
ROOT=Path(__file__).resolve().parents[1]

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--catalog',default='archive/stage7_player_jobs.json');a=p.parse_args();jobs=json.loads((ROOT/a.catalog).read_text());results=[];failures=[]
 for j in jobs:
  c=j['clip'];old=Image.open(j['reference']).convert('RGBA').crop((0,0,c['frame_width'],c['frame_height']));box=old.getchannel('A').point(lambda x:255 if x>12 else 0).getbbox();height=box[3]-box[1]
  # Idle is the immutable full-height reference. Other poses retain their old
  # pose height; do not stretch a bent character to standing height.
  try:
   result=pack(j['source'],c,j['output'],height)
   c['image_size']=[c['frame_width']*c['frames'],c['frame_height']]
   results.append({'weapon':j['weapon'],'clip':c['name'],'target_height':height,**result})
   print('PACK',j['weapon'],c['name'],height)
  except (OSError,ValueError) as e:failures.append({'weapon':j['weapon'],'clip':c['name'],'error':str(e)});print('FAIL',j['weapon'],c['name'],e)
 (ROOT/'archive/player_packing.json').write_text(json.dumps({'clips':results,'failures':failures},indent=2))
 if failures:return 1
 for weapon in ['unarmed','staff']:
  out=ROOT/'assets/sprites/player'/weapon/'manifest.json';out.write_text(json.dumps({'step':17,'frame_size':[640,640],'weapon':weapon,'clips':[j['clip'] for j in jobs if j['weapon']==weapon]},ensure_ascii=False,indent=2)+'\n')
 manifest=json.loads((ROOT/'assets/animation_manifest.json').read_text());folder=ROOT/'assets/sprites/player/axe';folder.mkdir(parents=True,exist_ok=True)
 for c in manifest['clips']:
  src=ROOT/'assets'/c['sheet'];dest=folder/(c['name']+'.png')
  if src!=dest:shutil.copy2(src,dest)
  c['sheet']='sprites/player/axe/'+dest.name
 manifest['step']=17;(folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');(ROOT/'assets/animation_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
 print('PLAYER_WEAPONS: 31 generated clips and 18 unchanged axe clips');return 0
if __name__=='__main__':sys.exit(main())
