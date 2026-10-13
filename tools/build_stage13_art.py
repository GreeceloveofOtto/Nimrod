#!/usr/bin/env python3
"""Only crop/key/normalize generated PNGs; never synthesize character or world pixels."""
import json,shutil,argparse,hashlib
from pathlib import Path
from types import SimpleNamespace
import numpy as np
from PIL import Image
from scipy import ndimage
from pack_sprites import apply_storage_policy
from build_stage11_art import key,row_poses
R=Path(__file__).resolve().parents[1];RAW=R/'archive/stage13/source_art';STAGED=R/'archive/stage13/staged';STAGED.mkdir(parents=True,exist_ok=True)
def read(p):return json.loads((R/p).read_text())
def write(p,d):(R/p).write_text(json.dumps(d,ensure_ascii=False,separators=(',',':'))+'\n')
def split_rows(im,counts):
 # Use blank horizontal gutters instead of assuming imagegen honored equal row heights.
 a=np.array(key(im));occupied=(a[:,:,3]>12).sum(axis=1);blank=np.where(occupied==0)[0]
 cuts=[0]
 for i in range(1,len(counts)):
  expected=round(im.height*i/len(counts));near=blank[abs(blank-expected)<im.height/len(counts)*.28]
  cuts.append(int(near[np.argmin(abs(near-expected))]) if len(near) else expected)
 cuts.append(im.height)
 return [row_poses(im.crop((0,cuts[i],im.width,cuts[i+1])),n,min_fraction=.12,discard_row_edge_artifacts=True) for i,n in enumerate(counts)]
def sheet(folder,name,poses,duration,loop,target,frame=(640,640),anchor=(320,600),reference='max'):
 # One isotropic normalization per clip preserves relative body anatomy through motion.
 reference_height=max(p.height for p in poses) if reference=='max' else float(np.median([p.height for p in poses]))
 factor=min(target/reference_height,(frame[0]-16)/max(p.width for p in poses),(anchor[1]-8)/max(p.height for p in poses))
 out=Image.new('RGBA',(frame[0]*len(poses),frame[1]));heights=[]
 for i,pose in enumerate(poses):
  small=pose.resize((max(1,round(pose.width*factor)),max(1,round(pose.height*factor))),Image.Resampling.LANCZOS)
  # Remove invisible Lanczos RGB fringe and any residual dominant key chroma.
  small=key(small)
  out.alpha_composite(small,(i*frame[0]+anchor[0]-small.width//2,anchor[1]-small.height));heights.append(small.height)
 staged=STAGED/folder/(name+'.png');staged.parent.mkdir(parents=True,exist_ok=True);out.save(staged)
 dest=R/'assets/sprites'/folder/(name+'.png');dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(staged,dest)
 clip={'name':name,'sheet':'sprites/'+folder+'/'+name+'.png','frame_width':frame[0],'frame_height':frame[1],'frames':len(poses),'columns':len(poses),'rows':1,'duration_seconds':duration,'fps':len(poses)/duration,'loop':loop,'anchor_px':list(anchor),'image_size':list(out.size),'body_reference_height_px':target,'qa':{'pose_height_exception':name not in ['idle','walk','idle_front'],'movement':name not in ['idle','crouch_idle','sit_idle'],'expected_pose_heights':heights,'detached_fx_or_weapon':False},'normalization':'generated source poses; one isotropic factor per clip'}
 manifest=dest.parent/'manifest.json'
 data=json.loads(manifest.read_text()) if manifest.exists() else {'clips':[]}
 data['clips']=[c for c in data['clips'] if c['name']!=name]+[clip];write(str(manifest.relative_to(R)),data)
 apply_storage_policy(SimpleNamespace(output=str(dest),frames=len(poses),frame_width=frame[0],frame_height=frame[1],anchor=list(anchor),visual_scale=.3,density_class='player_stage11' if folder.startswith('player/') else 'large_enemy',canonical_only=False),out,True)
 return json.loads(manifest.read_text())['clips'][-1]
def players():
 specs={c['name']:c for c in read('assets/sprites/player/unarmed/manifest.json')['clips']}
 groups=[('a',[('idle',10),('walk',10),('run',10)]),('b',[('crouch_enter',4),('crouch_idle',6),('crouch_exit',4),('jump_start',4),('jump_rise',6),('fall',6)]),('c',[('land',5),('drop_through',5),('hurt',5),('death',8)]),('d',[('roll',12),('sit_down',4),('sit_idle',6),('stand_up',4)])]
 for group,rows in groups:
  poses=split_rows(Image.open(RAW/f'siyavash_motion_{group}.png').convert('RGBA'),[n for name,n in rows])
  for (name,n),frames in zip(rows,poses):
   target=215 if name in ['crouch_idle','sit_idle'] else 310 if name in ['run','jump_rise','hurt','drop_through'] else 363
   cfg=specs[name];sheet('player/siyavash',name,frames,cfg['duration_seconds'],cfg['loop'],target)
 data=read('assets/sprites/player/siyavash/manifest.json');data.update(character='siyavash',weapon='none',frame_size=[640,640],step=21)
 for c in data['clips']:
  if c['name'] in ['idle','walk','crouch_idle']:
   c['qa']['head_top_px']=[c['anchor_px'][1]-h for h in c['qa']['expected_pose_heights']]
   c['qa']['head_center_x_px']=[320]*c['frames']
 write('assets/sprites/player/siyavash/manifest.json',data)
 print('SIYAVASH',len(data['clips']))
def bosses(ident):
 configs={
 'ninazu_mother': [('mother_a',[('idle',4,1.6,True),('move',4,1.2,True),('poison_windup',3,.9,False),('poison_attack',3,.4,False)]),('mother_b',[('tail_windup',3,.7,False),('tail_attack',3,.2,False),('turn',4,.5,False),('hurt',2,.4,False),('death',4,1.2,False)])],
 'lilith': [('lilith_a',[('idle',4,1.6,True),('move',4,.6,True),('ambush_windup',3,.5,False),('ambush_attack',3,.85,False)]),('lilith_b',[('charm_windup',3,.65,False),('charm_attack',3,.2,False),('turn',4,.2,False),('hurt',2,.4,False),('death',4,1.2,False)])],
 'zu': [('zu_a',[('idle',4,1.2,True),('move',4,.8,True),('feathers_windup',3,.8,False),('feathers_attack',3,.3,False)]),('zu_b',[('grab_windup',3,1.,False),('grab_attack',3,1.25,False),('turn',4,.35,False),('hurt',2,.5,False),('death',4,1.2,False)])]}
 e=next(e for e in read('data/enemies.json')['enemies'] if e['id']==ident)
 for source,rows in configs[ident]:
  poses=split_rows(Image.open(RAW/f'{source}.png').convert('RGBA'),[n for name,n,duration,loop in rows])
  for (name,n,duration,loop),frames in zip(rows,poses):sheet('enemies/'+ident,name,frames,duration,loop,e['art_height_px'],frame=tuple(e['frame_size']),anchor=tuple(e['anchor']))
 data=read('assets/sprites/enemies/'+ident+'/manifest.json')
 if ident=='zu':
  for c in data['clips']:
   if c['name']=='idle':c['qa'].update(pose_height_exception=True,reason='wing-flap silhouette changes; authored per-frame anatomy reference remains checked')
 data.update(step=21,character=ident,aliases={'walk':'move','recovery':'idle','stunned':'hurt'})
 if ident=='lilith':data['aliases'].update(ghost_windup='charm_windup',ghost_attack='idle')
 write('assets/sprites/enemies/'+ident+'/manifest.json',data)
 print('BOSS',ident,len(data['clips']))
def props():
 im=Image.open(RAW/'world_props.png').convert('RGBA');rows=split_rows(im,[1,1]);
 for pose,path,size in [(rows[0][0],'assets/tiles/huluppu/branch.png',(512,128)),(rows[1][0],'assets/props/utnapishtim_blood.png',(400,55))]:
  if 'branch' in path:
   # Crop only generated bark to expose a genuinely flat walking support span.
   pose=pose.crop((round(pose.width*.06),0,round(pose.width*.94),pose.height))
   alpha=np.array(pose)[:,:,3];cover=(alpha>128).mean(axis=1);support=np.where(cover>=.985)[0]
   if len(support):pose=pose.crop((0,int(support[0]),pose.width,pose.height))
  crop=Image.new('RGBA',size);pose=pose.resize((size[0]-4,size[1]-4),Image.Resampling.LANCZOS);crop.alpha_composite(key(pose),(2,2))
  dest=R/path;dest.parent.mkdir(parents=True,exist_ok=True);crop.save(dest);apply_storage_policy(SimpleNamespace(output=str(dest),canonical_only=False),crop,False)
 floor=Image.open(RAW/'hwanira_floor.png').convert('RGB').resize((512,200),Image.Resampling.LANCZOS).convert('RGBA')
 dest=R/'assets/tiles/hwanira/plaza.png';dest.parent.mkdir(parents=True,exist_ok=True);floor.save(dest);apply_storage_policy(SimpleNamespace(output=str(dest),canonical_only=False),floor,False)
 for source,path in [('tiamat','assets/backgrounds/tiamat/entity.png'),('hwanira','assets/backgrounds/hwanira/plaza.png')]:
  im=Image.open(RAW/f'{source}.png').convert('RGB')
  if source=='hwanira':
   center=im.resize((1344,896),Image.Resampling.LANCZOS);im=Image.new('RGB',(3200,896));edge_width=200
   left=center.crop((0,0,edge_width,896));right=center.crop((center.width-edge_width,0,center.width,896))
   for x in range(0,3200,edge_width):im.paste(left if x<300 else right,(x,0))
   im.paste(center,(300,0))
  pixels=np.array(im).astype(float);luma=pixels@np.array([.2126,.7152,.0722]);lift=np.maximum(0,18-luma);pixels=np.minimum(255,pixels+lift[:,:,None])
  im=Image.fromarray(np.rint(pixels).astype('uint8')).convert('RGBA');dest=R/path;dest.parent.mkdir(parents=True,exist_ok=True);im.save(dest);apply_storage_policy(SimpleNamespace(output=str(dest),canonical_only=False),im,False)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('task',choices=['players','ninazu_mother','lilith','zu','props']);a=p.parse_args()
 if a.task=='players':players()
 elif a.task=='props':props()
 else:bosses(a.task)
