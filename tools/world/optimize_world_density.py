#!/usr/bin/env python3
"""Try the 30 largest atlases against immutable canonical art, preserve logical geometry/maps."""
import json,shutil
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from PIL import Image
from downscale_assets import ROOT,choose_scale
from stage10_optimize_density import encoded
from stage11_repack import pad_sheet,pad_spec
ARC=ROOT/'archive/stage14'
def main():
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());rows=json.loads((ROOT/'data/storage_quality.json').read_text());enemies={e['id']:e for e in json.loads((ROOT/'data/enemies.json').read_text())['enemies']};npcs={e['id']:e for e in json.loads((ROOT/'data/npcs.json').read_text())['npcs']};results=[]
 selected=sorted(rows,key=lambda r:(ROOT/r['path'].removeprefix('res://')).stat().st_size,reverse=True)[:30]
 selected += [r for r in rows if '/cedar_colossus/' in r['path'] or '/cedar_demon/' in r['path'] if r not in selected]
 for row in selected:
  path=ROOT/row['path'].removeprefix('res://');spec=registry[row['path']];before=path.stat().st_size;base=.3;floor=.8
  if '/enemies/' in row['path']:
   e=enemies[path.parent.name];base=e['visual_scale']*e.get('size_multiplier',1);floor=.9 if path.parent.name in ['humbaba','kala_ushumgal','gugalanna','chain_beastman','cedar_colossus','boar_charger','ninazu_mother','lilith','zu'] else .8
   if path.parent.name=='humbaba':floor=max(floor,.9*json.loads((ROOT/'data/humbaba_form.json').read_text())['visual_multiplier'])
  elif '/npcs/' in row['path']:base=.3*npcs[path.parent.name].get('visual_scale_multiplier',1)
  elif '/props/' in row['path']:base=1;floor=.8
  current=spec['storage_scale'][1]/base;record={'path':row['path'],'before':before,'current_density':current,'floor':floor,'accepted':False}
  if current<=floor+.02:record['reason']='already at density floor';results.append(record);continue
  t=spec['trim'];w,h=t['w'],t['h'];n=spec['frames'];source_path=ROOT/'archive'/row['source_archive'] if row.get('source_archive') else ROOT/'archive/stage8_density_before'/row['source'];source=Image.open(source_path).convert('RGBA');packed=Image.new('RGBA',(w*n,h))
  for i in range(n):
   rect=(i*spec['frame_width']+t['x'],t['y'],i*spec['frame_width']+t['x']+w,t['y']+h) if row.get('source_canonical') else (i*w,0,(i+1)*w,h)
   packed.paste(source.crop(rect),(i*w,0))
  _,iw,ih,score,density=choose_scale(packed,w,h,n,base,floor);record.update(candidate_density=density,ssim=score)
  if density>=current-.03:record['reason']='lower density fails original-art SSIM .93';results.append(record);continue
  mapping=spec['frame_map'];count=spec['stored_columns'];inner=Image.new('RGBA',(iw*count,ih));seen=set()
  for i,k in enumerate(mapping):
   if k in seen:continue
   seen.add(k);inner.paste(packed.crop((i*w,0,(i+1)*w,h)).resize((iw,ih),Image.Resampling.LANCZOS),(k*iw,0))
  candidate=pad_sheet(inner,iw,ih,count);content,metrics=encoded(candidate);record['candidate_bytes']=len(content)
  if len(content)>=before:record['reason']='quality-safe encoding does not save bytes';results.append(record);continue
  dest=ARC/'density_before'/path.relative_to(ROOT);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest);path.write_bytes(content)
  spec.update(storage_scale=[iw/w,ih/h],stored_frame_size=[round(spec['frame_width']*iw/w),round(spec['frame_height']*ih/h)],stored_anchor_px=[spec['anchor_px'][0]*iw/w,spec['anchor_px'][1]*ih/h],ssim=score,effective_density=density,encoding=metrics)
  pad_spec(spec,iw,ih,count);row.update(output_bytes=len(content),storage_scale=spec['storage_scale'],density=density,ssim=score,**metrics);record.update(accepted=True,after=len(content));results.append(record);print('DENSITY',path.name,current,'->',density,before,'->',len(content),flush=True)
 for mp in (ROOT/'assets').rglob('*manifest.json'):
  d=json.loads(mp.read_text());dirty=False
  for c in d.get('clips',[]):
   path=c['sheet'];key='res://assets/'+path if path.startswith(('sprites/','props/','fx/')) else path
   if key in registry:c.update(registry[key]);dirty=True
  if dirty:mp.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
 for p,d in [('data/sprite_trims.json',registry),('data/storage_quality.json',rows),('archive/stage14/density_trials.json',results)]: (ROOT/p).write_text(json.dumps(d,indent=2)+'\n')
 print('DENSITY SAVED',sum(r['before']-r.get('after',r['before']) for r in results),flush=True)
if __name__=='__main__':main()
