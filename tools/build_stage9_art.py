#!/usr/bin/env python3
"""Pack generated Stage 9 art with shared pose scale and density/encoding gates."""
import argparse,json,sys,shutil
from pathlib import Path
from types import SimpleNamespace
from PIL import Image
import numpy as np
from pack_sprites import chromakey, apply_storage_policy
ROOT=Path(__file__).resolve().parents[1]
POSE=ROOT/'archive/stage9/poses'
def read(p):return json.loads(p.read_text())
def manifest(folder):
 p=folder/'manifest.json'
 return p,read(p) if p.exists() else {'clips':[],'aliases':{'hurt':'idle'}}
def pack(folder,name,poses,frames,duration,loop,scale,frame=(640,640),anchor=(320,600),kind='npc',exception=False,height_tol=.1,center=False,center_x=False):
 folder.mkdir(parents=True,exist_ok=True)
 sheet=Image.new('RGBA',(frame[0]*frames,frame[1]))
 for i,pose in enumerate(poses):
  pose=pose.crop(pose.getchannel('A').point(lambda x:255 if x>12 else 0).getbbox())
  pose=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.LANCZOS)
  if center:
   pixels=np.array(pose);ys,xs=np.indices(pixels.shape[:2]);mass=pixels[:,:,3].astype(float);cx=(xs*mass).sum()/mass.sum();cy=(ys*mass).sum()/mass.sum()
   x=round(anchor[0]-cx);y=round(anchor[1]-cy)
  elif center_x:
   pixels=np.array(pose);ys,xs=np.indices(pixels.shape[:2]);mass=pixels[:,:,3].astype(float);cx=(xs*mass).sum()/mass.sum();x=round(anchor[0]-cx);y=anchor[1]-pose.height
  else:x=round(anchor[0]-pose.width/2);y=anchor[1]-pose.height
  if x<8 or y<8 or x+pose.width>frame[0]-8 or y+pose.height>frame[1]-8:raise ValueError((name,i,'clips',pose.size,frame))
  sheet.alpha_composite(pose,(i*frame[0]+x,y))
 path=folder/(name+'.png');sheet.save(path)
 mp,m=manifest(folder);clip={'name':name,'sheet':str(path.relative_to(ROOT/'assets')),'frame_width':frame[0],'frame_height':frame[1],'frames':frames,'columns':frames,'rows':1,'duration_seconds':duration,'fps':frames/duration,'loop':loop,'anchor_px':list(anchor),'image_size':list(sheet.size),'qa':{'pose_height_exception':exception,'height_tol':height_tol,'detached_fx_or_weapon':kind=='fx','movement':name=='death'}}
 m['clips']=[c for c in m['clips'] if c['name']!=name]+[clip];mp.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n')
 args=SimpleNamespace(output=str(path),frames=frames,frame_width=frame[0],frame_height=frame[1],anchor=anchor,visual_scale=.3,density_class=kind,canonical_only=False)
 apply_storage_policy(args,sheet,True)
 if name in ['anur_light_cast','anur_light_impact','humbaba_bite_spark']:
  effect_manifest=json.loads((folder/'manifest.json').read_text())
  for clip in effect_manifest['clips']:
   if clip['name']==name:clip.setdefault('qa',{})['fade_out_fx']=True
  (folder/'manifest.json').write_text(json.dumps(effect_manifest,ensure_ascii=False,indent=2)+'\n')
 print('PACKED',name,flush=True)
def poses(id,row,count):return [Image.open(POSE/f'{id}_{row}_{i}.png').convert('RGBA') for i in range(count)]
def characters():
 for id,h in [('shamash',363*1.04),('aya',363*.98)]:
  base=poses(id,0,8);scale=h/base[0].height;folder=ROOT/'assets/sprites/npcs'/id
  for row,(name,n,d,loop) in enumerate([('walk',8,.9,True),('sit_down',4,.4,False),('sit_idle',6,2.4,True),('stand_up',4,.4,False)]):
   pack(folder,name,poses(id,row,n),n,d,loop,scale,exception=name!='walk',height_tol=.4 if name!='walk' else .12)
   if id=='aya' and name=='sit_idle':
    from make_breathing_sheet import breathing_sheet
    source=ROOT/'archive/pack_source/sprites/npcs/aya/sit_idle.png'
    clean=ROOT/'archive/stage9/aya_clean_seated_pose.png';clean.parent.mkdir(parents=True,exist_ok=True)
    Image.open(source).crop((1280,0,1920,640)).save(clean)
    output=folder/'sit_idle.png';breathing_sheet(clean,output)
    apply_storage_policy(SimpleNamespace(output=str(output),frames=6,frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='npc',canonical_only=False),Image.open(output).convert('RGBA'),True)
 folder=ROOT/'assets/sprites/player/unarmed';scale=363/poses('player',0,4)[0].height
 for row,(name,n,d,loop) in enumerate([('sit_down',4,.35,False),('sit_idle',6,2.,True),('stand_up',4,.35,False)]):pack(folder,name,poses('player',row,n),n,d,loop,scale,kind='player',exception=True,height_tol=.4)
def boss():
 specs=[('boss1',0,'idle',8,1.6,True),('boss1',1,'walk',8,1.2,True),('boss1',2,'bite_windup',5,.9,False),('boss1',3,'bite',3,.2,False),('boss2',0,'bite_recovery',4,1.,False),('boss2',1,'claw_windup',4,.6,False),('claw_fix',0,'claw_swipe',6,.75,False),('boss2',3,'claw_recovery',4,1.1,False),('boss3',0,'breath_windup',5,.8,False),('breath_fix',0,'breath_loop',4,.4,True),('boss3',2,'breath_recovery',4,1.3,False),('boss3',3,'tail_windup',3,.3,False),('boss4',0,'tail_strike',3,.15,False),('boss4',1,'tail_recovery',4,.6,False),('boss4',2,'turn',6,.6,False),('boss5',0,'phase_roar',8,1.8,False),('death_fix',0,'death',8,1.6,False)]
 # Each generated atlas is calibrated to its standing pose once; all its poses use that scale.
 heights={'boss1':274,'boss2':245,'boss3':270,'boss4':276,'boss5':287,'claw_fix':None,'breath_fix':None,'death_fix':None}
 for id,row,name,n,d,loop in specs:
  pp=poses(id,row,n);reference=252 if name=='walk' else heights[id] or pp[0].height;scale=(310/.3)/reference
  pack(ROOT/'assets/sprites/enemies/humbaba',name,pp,n,d,loop,scale,frame=(1408,1152),anchor=(704,1100),kind='large_enemy',exception=name not in ['idle','walk','turn','breath_windup','breath_loop'],height_tol=.65 if name=='death' else .35)
 mp,m=manifest(ROOT/'assets/sprites/enemies/humbaba');m.setdefault('aliases',{}).update(windup='bite_windup',attack='bite',recovery='bite_recovery');mp.write_text(json.dumps(m,indent=2)+'\n')
def effects():
 source=chromakey(Image.open(ROOT/'archive/stage9/source_art/6e274676-8126-466e-a92e-c713f8553da3.png').convert('RGBA'))
 for row,(id,n,size,d) in enumerate([('anur_light_projectile',4,(128,64),.3),('anur_light_cast',4,(192,192),.2),('anur_light_impact',5,(192,192),.25),('humbaba_flame_cone',6,(768,384),.4),('humbaba_ember_aura',6,(512,512),.8),('humbaba_bite_spark',4,(192,192),.2)]):
  pp=[]
  for i in range(n):
   cell=source.crop((round(i*source.width/6),[0,150,350,510,680,850][row],round((i+1)*source.width/6),[150,350,510,680,850,source.height][row]))
   box=cell.getchannel('A').point(lambda x:255 if x>12 else 0).getbbox();pp.append(cell.crop(box))
  extents=[]
  for pose in pp:
   pixels=np.array(pose);ys,xs=np.indices(pixels.shape[:2]);mass=pixels[:,:,3].astype(float);cx=(xs*mass).sum()/mass.sum();cy=(ys*mass).sum()/mass.sum();extents.append((max(cx,pose.width-cx),max(cy,pose.height-cy)))
  scale=min((size[0]/2-12)/max(x for x,y in extents),(size[1]/2-12)/max(y for x,y in extents))
  pack(ROOT/'assets/sprites/fx',id,pp,n,d,id in ['anur_light_projectile','humbaba_flame_cone','humbaba_ember_aura'],scale,frame=size,anchor=(size[0]//2,size[1]//2),kind='fx',exception=True,height_tol=.65,center=True)
def tables():
 source=Image.open(ROOT/'archive/stage9/source_art/17c85cff-fb90-44aa-8687-85d1d455d8b4.png').convert('RGBA')
 for row,id in enumerate(['prep','full']):
  cell=chromakey(source.crop((0,round(row*source.height/2),source.width,round((row+1)*source.height/2))));box=cell.getchannel('A').point(lambda x:255 if x>12 else 0).getbbox();cell=cell.crop(box).resize((894,214),Image.Resampling.LANCZOS);image=Image.new('RGBA',(900,220));image.alpha_composite(cell,(3,3));p=ROOT/'assets/props'/('villa_dining_table_'+id+'.png');image.save(p);apply_storage_policy(SimpleNamespace(output=str(p),canonical_only=False),image,False)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('parts',nargs='*',default=['characters','boss','effects','tables']);a=p.parse_args()
 for part in a.parts:globals()[part]()
