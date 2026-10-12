#!/usr/bin/env python3
"""Pack image-generator outputs; preserve original pose extents and timing."""
import json,sys,copy,math,shutil
from pathlib import Path
from types import SimpleNamespace
from PIL import Image
import numpy as np
from scipy.ndimage import label
from pack_sprites import chromakey,apply_storage_policy
from build_stage9_art import pack
ROOT=Path(__file__).resolve().parents[1];RAW=ROOT/'archive/stage10'
def read(p):return json.loads((ROOT/p).read_text())
def save(p,d):(ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def crop_pose(cell,preserve_dark=False):
 if preserve_dark:
  pixels=np.asarray(cell).copy();r,g,b=[pixels[:,:,j].astype(float) for j in range(3)];dominance=np.minimum(r,b)-g;key=(r>=140)&(b>=140)&(g<110)&(dominance>=50);pixels[key]=0
  fringe=(~key)&(dominance>8);pixels[:,:,0][fringe]=np.minimum(pixels[:,:,0][fringe],pixels[:,:,1][fringe].astype(float)+8);pixels[:,:,2][fringe]=np.minimum(pixels[:,:,2][fringe],pixels[:,:,1][fringe].astype(float)+8)
  components,n=label(pixels[:,:,3]>12);counts=np.bincount(components.ravel());counts[0]=0;pixels[counts[components]<max(8,counts.max()*.03)]=0;cell=Image.fromarray(pixels)
 else:cell=chromakey(cell)
 a=np.asarray(cell.getchannel('A'));components,n=label(a>12);counts=np.bincount(components.ravel());remove=[i for i in range(1,n+1) if counts[i]<max(8,a.size*.00008)]
 if remove:
  arr=np.asarray(cell).copy();arr[np.isin(components,remove)]=0;cell=Image.fromarray(arr)
 bbox=cell.getchannel('A').point(lambda v:255 if v>12 else 0).getbbox()
 if not bbox:raise ValueError('Empty generated pose')
 return cell.crop(bbox)
def grid(id,row,n,cols,rows,bounds=None):
 im=Image.open(RAW/(id+'.png')).convert('RGBA');ys=bounds or [round(i*im.height/rows) for i in range(rows+1)]
 return [crop_pose(im.crop((round(i*im.width/cols),ys[row],round((i+1)*im.width/cols),ys[row+1]))) for i in range(n)]
def players():
 original=read('assets/sprites/player/axe/manifest.json')
 for variant in ['axe_onearm','axe_prosthetic']:
  folder=ROOT/'assets/sprites/player'/variant;folder.mkdir(exist_ok=True)
  # Clear temporary development aliases. New clips always come from edited art.
  save(str((folder/'manifest.json').relative_to(ROOT)),{'step':18,'frame_size':[640,640],'clips':[]})
  for c in original['clips']:
   name=c['name'];im=Image.open(RAW/(('idle_onearm_final' if variant=='axe_onearm' else 'idle_prosthetic_final')+'.png') if name=='idle' else RAW/'source_art'/(variant+'_'+name+'.png')).convert('RGBA');cols=5 if name=='idle' else 4;source=ROOT/'archive/untrimmed/assets'/Path(c['sheet']).with_suffix('.png');ref=Image.open(source).convert('RGBA');n=c['frames'];rows=math.ceil(n/cols)
   out=Image.new('RGBA',(640*n,640));heights=[];areas=[]
   for i in range(n):
    cell=im.crop((round(i%cols*im.width/cols),round(i//cols*im.height/rows),round((i%cols+1)*im.width/cols),round((i//cols+1)*im.height/rows)));pose=crop_pose(cell,preserve_dark=name=='death')
    box=ref.crop((i*640,0,(i+1)*640,640)).getchannel('A').point(lambda v:255 if v>12 else 0).getbbox();heights.append(box[3]-box[1]);areas.append(int((np.asarray(ref.crop((i*640,0,(i+1)*640,640)))[:,:,3]>0).sum()))
    pose=pose.resize((box[2]-box[0],box[3]-box[1]),Image.Resampling.LANCZOS);out.alpha_composite(pose,(i*640+box[0],600-pose.height))
   path=folder/(name+'.png');out.save(path)
   clip={k:copy.deepcopy(v) for k,v in c.items() if k in ['name','duration_seconds','fps','loop','frame_boundaries_seconds']};clip.update(sheet=str(path.relative_to(ROOT/'assets')),frame_width=640,frame_height=640,frames=n,columns=n,rows=1,anchor_px=[320,600],image_size=list(out.size),qa={'expected_pose_heights':heights,'expected_pose_height_tolerance':.03,'pose_height_exception':name!='idle','detached_fx_or_weapon':False})
   if name=='death':clip['qa'].update(expected_pose_areas=areas,minimum_authored_area_ratio=.55)
   mp=folder/'manifest.json';m=json.loads(mp.read_text());m['clips'].append(clip);mp.write_text(json.dumps(m,indent=2)+'\n')
   apply_storage_policy(SimpleNamespace(output=str(path),frames=n,frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='player',canonical_only=False),out,True)
   print('PLAYER',variant,name,flush=True)
def boss():
 specs=[('boss1',0,'idle',8,1.8,True),('boss1',1,'walk',8,1.4,True),('boss1',2,'stomp_windup',6,1.,False),('boss1',3,'stomp',3,.2,False),('boss2',0,'stomp_recovery',5,1.1,False),('boss2',1,'charge_windup',5,.8,False),('boss2',2,'charge_loop',4,.3,True),('boss2',3,'charge_crash',5,1.2,False),('boss3',0,'charge_recovery',4,.8,False),('boss3',1,'uppercut_windup',5,.9,False),('boss3',2,'uppercut',3,.25,False),('boss3',3,'uppercut_recovery',5,1.2,False),('boss4',0,'rake_windup',6,1.4,False),('boss4',1,'rake',5,.4,False),('boss4',2,'rake_recovery',5,1.5,False),('boss4',3,'turn',6,.8,False),('boss_death',0,'death',10,2.4,False)]
 folder=ROOT/'assets/sprites/enemies/gugalanna';folder.mkdir(parents=True,exist_ok=True)
 save(str((folder/'manifest.json').relative_to(ROOT)),{'clips':[],'aliases':{'hurt':'idle','windup':'uppercut_windup','attack':'uppercut','recovery':'uppercut_recovery'}})
 # Generated atlases share a standing-height baseline; keep the natural lowered poses.
 references={'boss1':grid('boss1',0,8,8,4)[0].height,'boss2':grid('boss2',0,5,8,4)[-1].height,'boss3':grid('boss3',0,4,8,4)[-1].height,'boss4':grid('boss4',3,6,8,4)[0].height,'boss_death':grid('boss_death',0,5,5,2)[0].height}
 for id,row,name,n,d,loop in specs:
  pp=grid(id,row,n if id!='boss_death' else 5,8 if id!='boss_death' else 5,4 if id!='boss_death' else 2)
  if id=='boss_death':pp+=grid(id,1,5,5,2)
  scale=1400/references[id]
  # Horn lift has natural height growth; all feet stay at anchor.
  if max(p.height*scale for p in pp)>1470:scale=1470/max(p.height for p in pp)
  pack(folder,name,pp,n,d,loop,scale,frame=(2560,1536),anchor=(1280,1480),kind='large_enemy',exception=name not in ['idle','walk'],height_tol=.55,center_x=True)
def cinematics():
 for name,n,d,loop,folder,target in [('arm_loss_hit',5,.5,False,'axe_onearm',363),('melammu_absorb',6,1.2,False,'axe_onearm',245),('cry_collapse',5,.7,False,'cutscene',250),('cry_loop',6,2.,True,'cutscene',225)]:
  pp=grid(name+'_final',0,n,n,1);scale=target/pp[0].height
  pack(ROOT/'assets/sprites/player'/folder,name,pp,n,d,loop,scale,kind='player',exception=True,height_tol=.65,center_x=True)
def effects():
 config={}
 for row,(name,n,size,d,scale) in enumerate([('gugalanna_shockwave',4,(512,96),.4,1.),('gugalanna_lightning',4,(256,512),.35,1.),('gugalanna_rake_arc',5,(768,384),.4,1.),('gugalanna_dust',5,(256,256),.5,1.),('severed_arm',4,(192,192),1.,.35)]):
  pp=grid('fx',row,n,5,5);extents=[]
  for pose in pp:
   pixels=np.array(pose);ys,xs=np.indices(pixels.shape[:2]);mass=pixels[:,:,3].astype(float);cx=(xs*mass).sum()/mass.sum();cy=(ys*mass).sum()/mass.sum();extents.append((max(cx,pose.width-cx),max(cy,pose.height-cy)))
  ratio=min((size[0]/2-12)/max(x for x,y in extents),(size[1]/2-12)/max(y for x,y in extents));pack(ROOT/'assets/sprites/fx',name,pp,n,d,False,ratio,frame=size,anchor=(size[0]//2,size[1]//2),kind='fx',exception=True,height_tol=.85,center=True)
  mp=ROOT/'assets/sprites/fx/manifest.json';mf=json.loads(mp.read_text())
  for clip in mf['clips']:
   if clip['name']==name:clip.setdefault('qa',{})['fade_out_fx']=True
  mp.write_text(json.dumps(mf,indent=2)+'\n')
  config[name]={'path':'assets/sprites/fx/'+name+'.webp','frame_size':size,'frames':n,'duration':d,'scale':scale}
 save('data/stage10_fx.json',config)
def props():
 for row,col,name,size in [(0,0,'melammu_pickup',(128,128)),(0,1,'gugalanna_helm',(160,160)),(1,0,'home_bed_blood',(420,200)),(1,1,'space_pod',(480,260))]:
  im=Image.open(RAW/'props.png').convert('RGBA');pose=crop_pose(im.crop((round(col*im.width/2),round(row*im.height/2),round((col+1)*im.width/2),round((row+1)*im.height/2))))
  pose=pose.resize((size[0]-4,size[1]-4),Image.Resampling.LANCZOS);out=Image.new('RGBA',size);out.alpha_composite(pose,(2,2));path=ROOT/'assets/props'/(name+'.png');out.save(path);apply_storage_policy(SimpleNamespace(output=str(path),canonical_only=False),out,False)
def bed():
 from make_breathing_sheet import breathing_sheet
 folder=ROOT/'assets/sprites/npcs/enkidua'
 for row,name,d in [(0,'bed_awake',3.),(1,'bed_asleep',3.6)]:
  pose=grid('bed',row,1,1,2)[0];pose=pose.resize((540,round(pose.height*540/pose.width)),Image.Resampling.LANCZOS);base=Image.new('RGBA',(640,640));base.alpha_composite(pose,(50,600-pose.height));src=RAW/(name+'_base.png');base.save(src);path=folder/(name+'.png');breathing_sheet(src,path)
  m=json.loads((folder/'manifest.json').read_text());m['clips']=[c for c in m['clips'] if c['name']!=name]+[{'name':name,'sheet':'sprites/npcs/enkidua/'+name+'.png','frame_width':640,'frame_height':640,'frames':6,'columns':6,'rows':1,'duration_seconds':d,'fps':6/d,'loop':True,'anchor_px':[320,600],'image_size':[3840,640],'qa':{'pose_height_exception':True}}];(folder/'manifest.json').write_text(json.dumps(m,indent=2)+'\n')
  apply_storage_policy(SimpleNamespace(output=str(path),frames=6,frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='npc',canonical_only=False),Image.open(path).convert('RGBA'),True)
 n=read('data/npcs.json');entry=next(x for x in n['npcs'] if x['id']=='enkidua');entry['clips']=[x for x in entry['clips'] if x['name'] not in ['bed_awake','bed_asleep']]+[{'name':'bed_awake','frames':6,'duration':3.,'loop':True},{'name':'bed_asleep','frames':6,'duration':3.6,'loop':True}];save('data/npcs.json',n)
def scenery():
 items=[('homefront_sky',None,'homefront_sky',(1536,720),False),('dilmun_sky',None,'dilmun_sky',(1792,720),False),('villa_roof',None,'villa_f4_terrace',(2200,720),True),('far_layers',0,'homefront_far_tile',(2048,720),True),('far_layers',1,'dilmun_far_tile',(2048,720),True),('far_layers',2,'villa_f4_sky',(1536,720),False),('dilmun_ground',None,'dilmun_ground_tile',(512,200),False)]
 for id,row,name,size,key in items:
  im=Image.open(RAW/(id+'.png')).convert('RGBA')
  if row is not None:im=im.crop((0,round(row*im.height/3),im.width,round((row+1)*im.height/3)))
  if key:im=chromakey(im)
  im=im.resize(size,Image.Resampling.LANCZOS)
  if name in ['villa_f4_sky','dilmun_far_tile']:
   cut=22 if name=='villa_f4_sky' else 78;im=im.crop((0,cut,im.width,im.height)).resize(size,Image.Resampling.LANCZOS)
  if name=='dilmun_ground_tile':
   a=np.asarray(im).astype(float);luma=a[:,:,:3]@np.array([.2126,.7152,.0722]);a[:,:,:3]+=np.maximum(0,16-luma)[:,:,None];im=Image.fromarray(np.clip(a,0,255).astype('uint8'))
  if 'tile' in name:
   # Blend the generated opposite edge pixels only, preserving authored interiors.
   a=np.asarray(im).copy();width=12
   for i in range(width):
    alpha=(width-i)/width;mean=(a[:,i].astype(float)+a[:,-1-i].astype(float))*.5;a[:,i]=np.rint(a[:,i]*(1-alpha)+mean*alpha).astype('uint8');a[:,-1-i]=np.rint(a[:,-1-i]*(1-alpha)+mean*alpha).astype('uint8')
   im=Image.fromarray(a)
  folder=ROOT/('assets/tiles/stage10' if name=='dilmun_ground_tile' else 'assets/backgrounds/stage10');folder.mkdir(parents=True,exist_ok=True);p=folder/(name+'.png');im.save(p);apply_storage_policy(SimpleNamespace(output=str(p),canonical_only=False),im,False)
if __name__=='__main__':
 for arg in sys.argv[1:] or ['players','boss','cinematics','effects','props','bed','scenery']:globals()[arg]()
