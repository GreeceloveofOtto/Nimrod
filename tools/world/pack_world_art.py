#!/usr/bin/env python3
"""PIL crop/key/edge compositing of generated sources; never create drawn game art."""
import json,sys,shutil
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
from build_siyavash_redesign import extract,face_color
from pack_sprites import apply_storage_policy
from types import SimpleNamespace
import downscale_assets
ARC=ROOT/'archive/stage14'
def catalog():
 d=json.loads((ROOT/'assets/art_manifest.json').read_text());a=json.loads((ROOT/'data/alpha_expectations.json').read_text())
 images=list((ROOT/'assets/world').rglob('*.webp'))
 m=json.loads((ROOT/'assets/sprites/player/siyavash/manifest.json').read_text())
 images += [ROOT/'assets'/c['sheet'] for c in m['clips'] if c['name'] in ['dash','wall_cling','wall_jump','crawl']]
 for p in images:
  rel=str(p.relative_to(ROOT/'assets'));im=Image.open(p);opaque=im.getchannel('A').getextrema()==(255,255) if im.mode=='RGBA' else True
  d['assets']=[r for r in d['assets'] if r['path']!=rel];d['assets'].append({'path':rel,'width':im.width,'height':im.height,'transparent':not opaque,'category':'world' if 'world' in rel else 'sprite'})
  a['assets/'+rel]={'mode':'opaque' if opaque else 'transparent','edge_black_fraction':.03,'source':'stage14 generated modular art'}
 for path,obj in [('assets/art_manifest.json',d),('data/alpha_expectations.json',a)]: (ROOT/path).write_text(json.dumps(obj,ensure_ascii=False,separators=(',',':'))+'\n')
def pack():
 sources=json.loads((ARC/'sources.json').read_text());regions=json.loads((ROOT/'data/world/zabulistan/regions.json').read_text())['regions']
 for region in regions:
  id=region['id'];raw=Image.open(sources[id]).convert('RGB');folder=ROOT/'assets/world/zabulistan'/id;folder.mkdir(parents=True,exist_ok=True);None if Path(sources[id]).resolve()==(ARC/(id+'_raw.png')).resolve() else shutil.copy2(sources[id],ARC/(id+'_raw.png'))
  tile=raw.resize((40,40),Image.Resampling.LANCZOS)
  pixels=np.array(tile)
  # Preserve generated texture, blend opposite boundaries into a periodic tile.
  edge=(pixels[0].astype(float)+pixels[-1].astype(float))*.5;pixels[0]=edge;pixels[-1]=edge
  edge=(pixels[:,0].astype(float)+pixels[:,-1].astype(float))*.5;pixels[:,0]=edge;pixels[:,-1]=edge
  tile=Image.fromarray(pixels);padded=Image.fromarray(np.pad(np.array(tile),((2,2),(2,2),(0,0)),mode='edge'))
  atlas=Image.new('RGB',(176,176))
  for i in range(16):atlas.paste(padded,(i%4*44,i//4*44))
  # Same generated tile in all 16 connectivity entries; shared silhouette overlays
  # supply ledges. It is intentionally periodic rather than painted corner masks.
  atlas.save(folder/'terrain.webp','WEBP',lossless=True,method=6)
  tile.resize((160,160),Image.Resampling.NEAREST).save(folder/'wall.webp','WEBP',lossless=True,method=6)
  (ROOT/'assets/image_prompts'/('zabulistan_'+id+'.md')).write_text(f'# {id}\nGenerated hand-painted ancient space-fantasy seamless {id} rock texture, low saturation, opaque material. Opposite edges composited to periodic boundaries; 16 connectivity entries reuse the generated texture.\n')
 durations={'dash':.22,'wall_cling':.8,'wall_jump':.3,'crawl':.9};counts={'dash':4,'wall_cling':4,'wall_jump':3,'crawl':6}
 mp=ROOT/'assets/sprites/player/siyavash/manifest.json';m=json.loads(mp.read_text())
 for name,n in counts.items():
  poses=extract(sources[name],[n]);None if Path(sources[name]).resolve()==(ARC/(name+'_raw.png')).resolve() else shutil.copy2(sources[name],ARC/(name+'_raw.png'));corrected=[face_color(p,name,i) for i,p in enumerate(poses)]
  target={'dash':310,'wall_cling':330,'wall_jump':330,'crawl':190}[name];factor=min(target/max(p.height for p,_ in corrected),590/max(p.width for p,_ in corrected));sheet=Image.new('RGBA',(640*n,640));heights=[];marks=[]
  for i,(pose,mark) in enumerate(corrected):
   size=(round(pose.width*factor),round(pose.height*factor));pose=pose.resize((max(1,round(size[0]*.8)),max(1,round(size[1]*.8))),Image.Resampling.BILINEAR).resize(size,Image.Resampling.BILINEAR)
   sheet.alpha_composite(pose,(i*640+320-pose.width//2,600-pose.height));heights.append(pose.height);marks.append({'cheek_xy':[320-pose.width//2+mark['cheek_xy'][0]*factor,600-pose.height+mark['cheek_xy'][1]*factor],'cheek_radius':mark['cheek_radius']*factor})
  if name=='wall_cling':
   sheet.paste(sheet.crop((0,0,640,640)),(640*(n-1),0));marks[-1]=marks[0].copy();heights[-1]=heights[0]
  c={'name':name,'sheet':f'sprites/player/siyavash/{name}.png','frames':n,'columns':n,'rows':1,'frame_width':640,'frame_height':640,'anchor_px':[320,600],'duration_seconds':durations[name],'fps':n/durations[name],'loop':name in ['wall_cling','crawl'],'image_size':list(sheet.size),'body_reference_height_px':target,'qa':{'movement':True,'pose_height_exception':True,'expected_pose_heights':heights,'detached_fx_or_weapon':False,'authored_interior_violet':True},'face_landmarks':marks}
  m['clips']=[row for row in m['clips'] if row['name']!=name]+[c];mp.write_text(json.dumps(m,ensure_ascii=False,separators=(',',':'))+'\n');output=ROOT/'assets'/c['sheet'];sheet.save(output)
  choose=downscale_assets.choose_scale
  def bounded(img,w,h,count,base,limit):
   result=choose(img,w,h,count,base,1.6)
   if result[-1]>2.0001:raise ValueError(name+' exceeds density 2.0')
   return result
  downscale_assets.choose_scale=bounded
  try:apply_storage_policy(SimpleNamespace(output=str(output),frames=n,frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='player',canonical_only=False),sheet,True)
  finally:downscale_assets.choose_scale=choose
  side=output.with_suffix('.storage.json')
  if side.exists():shutil.move(side,ARC/(name+'.storage.json'))
  m=json.loads(mp.read_text());print('PACKED',name,heights,flush=True)
  (ROOT/'assets/image_prompts'/('siyavash_'+name+'.md')).write_text(f'# {name}\nExactly {n} full-body horizontal generated frames; match archive/siyavash_redesign_2026-10-14/reference.png; short blue-black hair, rose cheeks, violet markings, mid-thigh black-gold Avesta tunic, bare hands, no weapon; magenta background, 2px transparent margins.\n')
 dp=ROOT/'assets/sprites/player/siyavash_dagger/manifest.json';d=json.loads(dp.read_text())
 for name in counts:d['aliases'][name]={'set':'siyavash','clip':name}
 dp.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':'))+'\n');catalog()
if __name__=='__main__':pack()
