#!/usr/bin/env python3
"""Frame QA for generated, original or trimmed image strips. Nonzero on failures."""
import argparse,json,sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]

def frame_images(path,c):
 im=Image.open(path).convert('RGBA');t=c.get('trim',{});stored=c.get('storage_trim',t);w=stored.get('w',c['frame_width']);h=stored.get('h',c['frame_height']);n=int(c['frames']);count=c.get('stored_columns',n)
 if im.size!=(w*count,h):raise ValueError(f'sheet size {im.size} expected {(w*count,h)}')
 out=[]
 for i in range(n):
  index=c.get('frame_map',list(range(n)))[i];frame=im.crop((index*w,0,(index+1)*w,h))
  if t:
   if 'storage_trim' in c:frame=frame.resize((t['w'],t['h']),Image.Resampling.LANCZOS)
   full=Image.new('RGBA',(c['frame_width'],c['frame_height']));full.alpha_composite(frame,(t['x'],t['y']));frame=full
  out.append(frame)
 return out

def check(path,c):
 errors=[];warnings=[]
 try:frames=frame_images(path,c)
 except (OSError,ValueError) as e:return [str(e)],[],{}
 boxes=[];areas=[];centers=[];bottoms=[];diff=[];prev=None;equal=0
 for i,im in enumerate(frames):
  p=np.array(im);a=p[:,:,3];occupied=a>0;box=im.getchannel('A').point(lambda v:255 if v>12 else 0).getbbox()
  if not box:errors.append(f'frame {i+1}: empty');continue
  from scipy import ndimage
  labels,total=ndimage.label(a>12,structure=np.ones((3,3),dtype=bool));parts=np.bincount(labels.ravel())[1:]
  if sum(parts > occupied.sum()*.015)>1 and not c.get('qa',{}).get('detached_fx_or_weapon'):
   warnings.append(f'frame {i+1}: multiple substantial disconnected components')
  boxes.append(box);areas.append(int(occupied.sum()));ys,xs=np.where(occupied);mass=a[ys,xs].astype(float);centers.append((float(np.average(xs,weights=mass)),float(np.average(ys,weights=mass))));bottoms.append(box[3])
  if min(box[0],box[1],im.width-box[2],im.height-box[3])<(2 if c.get("storage_scale") else 3):errors.append(f'frame {i+1}: edge clipping')
  magenta=(a>12)&(p[:,:,0]>180)&(p[:,:,2]>180)&(p[:,:,1]<110)
  if magenta.sum()>20:errors.append(f'frame {i+1}: magenta fringe {magenta.sum()}')
  if prev is not None:
   diff.append(float(np.abs(p.astype(float)-prev.astype(float)).mean()));equal=equal+1 if np.array_equal(p,prev) else 0
   if equal==2 and not c.get('qa',{}).get('hold'):warnings.append(f'frame {i+1}: three exact duplicate frames')
  prev=p
 if not boxes:return errors or ['no frames'],warnings,{}
 heights=np.array([b[3]-b[1] for b in boxes]);tol=min(.65 if c.get('qa',{}).get('pose_height_exception') else .35,float(c.get('qa',{}).get('height_tol',.10)));median=float(np.median(heights))
 expected=c.get('qa',{}).get('expected_pose_heights',[])
 for i,h in enumerate(heights):
  if expected:
   if len(expected)!=len(frames):errors.append('authored pose height reference count mismatch');break
   if abs(h-expected[i])>max(6,expected[i]*.03):errors.append(f'frame {i+1}: height differs from authored pose {expected[i]} by more than 3%/6px')
  elif abs(h-median)>median*tol and not c.get("qa",{}).get("fade_out_fx"):errors.append(f'frame {i+1}: height {h} outside {median:.1f} ±{tol:.0%}')
 medarea=float(np.median(areas))
 for i,a in enumerate(areas):
  if a<.4*medarea and not c.get('qa',{}).get('fade_out_fx'):errors.append(f'frame {i+1}: insufficient painted area')
 anchor=c.get('anchor_px',[c['frame_width']//2,c['frame_height']-40]);floating=anchor[1]==c['frame_height']//2
 if floating:
  for i,(x,y) in enumerate(centers):
   if abs(x-anchor[0])>c['frame_width']*.1 or abs(y-anchor[1])>c['frame_width']*.1:errors.append(f'frame {i+1}: floating centroid drift')
 elif sum(abs(y-anchor[1])<=6 for y in bottoms)<len(bottoms)*.8:errors.append('ground anchor drift in more than 20% of frames')
 if not c.get('qa',{}).get('movement'):
  for i in range(1,len(centers)):
   if abs(centers[i][0]-centers[i-1][0])>c['frame_width']*.08:errors.append(f'frame {i+1}: horizontal centroid jump')
 if c.get('loop') and len(diff)>1:
  seam=float(np.abs(np.array(frames[0]).astype(float)-np.array(frames[-1]).astype(float)).mean())
  if seam>1.3*np.mean(diff):warnings.append(f'loop seam difference {seam:.3f} >1.3 average {np.mean(diff):.3f}')
 return errors,warnings,{'median_height':median,'frames':len(frames),'median_area':medarea,'centroids':centers}

def paths(manifest,c):
 sheet=c['sheet']
 if 'packed_enemies' in manifest.parts and (manifest.parent/Path(sheet).name).exists():return manifest.parent/Path(sheet).name
 return ROOT/sheet.removeprefix('res://') if sheet.startswith('res://') else ROOT/'assets'/sheet if sheet.startswith(('sprites/','props/','fx/','tiles/','backgrounds/')) else manifest.parent/sheet

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('manifests',nargs='*');p.add_argument('--json',dest='json_path');a=p.parse_args();ms=[Path(m) for m in a.manifests] or list((ROOT/'assets/sprites/enemies').glob('*/manifest.json'));results=[]
 for m in ms:
  data=json.loads(m.read_text());medians=[]
  for c in data['clips']:
   err,warn,metrics=check(paths(m,c),c);results.append({'manifest':str(m.relative_to(ROOT)) if m.is_absolute() else str(m),'clip':c['name'],'errors':err,'warnings':warn,'metrics':metrics})
   if metrics:medians.append((c['name'],metrics['median_height']))
  # Cross-clip representative heights are evaluated on standing/neutral pose clips.
  base=next((h for n,h in medians if n in ['idle','float','fly_idle','glide']),None)
  if base:
   for n,h in medians:
    c=next(c for c in data['clips'] if c['name']==n)
    if abs(h-base)>base*.08 and not c.get('qa',{}).get('pose_height_exception'):next(v for v in results if v['clip']==n and v['manifest']==(str(m.relative_to(ROOT)) if m.is_absolute() else str(m)))['errors'].append(f'cross-clip height {h} differs from idle {base}')
 if a.json_path:Path(a.json_path).write_text(json.dumps(results,ensure_ascii=False,indent=2))
 errors=sum(len(v['errors']) for v in results);warnings=sum(len(v['warnings']) for v in results);print(f'SPRITE_QA: {len(results)} clips, {errors} errors, {warnings} warnings')
 for row in results:
  for issue in row['errors']:print(f"FAIL {row['manifest']}/{row['clip']}: {issue}")
 return int(errors>0)
if __name__=='__main__':sys.exit(main())
