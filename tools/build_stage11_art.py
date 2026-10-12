#!/usr/bin/env python3
"""Normalize generated poses with uniform (isotropic) scales, explicit anchors and storage gutters."""
import json,math,shutil,sys
from pathlib import Path
from types import SimpleNamespace
import numpy as np
from PIL import Image
from scipy import ndimage
from pack_sprites import apply_storage_policy
from make_breathing_sheet import breathing_sheet
R=Path(__file__).resolve().parents[1];RAW=R/'archive/stage11';STAGED=RAW/'staged';STAGED.mkdir(exist_ok=True)
GROUPS=[[('idle',10),('walk',10),('run',10),('crouch_idle',6)],[('crouch_enter',4),('crouch_exit',4),('jump_start',4),('land',5)],[('jump_rise',6),('fall',6),('drop_through',5),('hurt',5)],[('attack_1',8),('attack_2',8),('attack_3',10),('attack_4',10)],[('roll',12),('death',8),('devour',8)]]
ALIASES=['drop_through','crouch_enter','crouch_exit','land']

def key(im):
 a=np.array(im.convert('RGBA')).astype(float);r,g,b=a[:,:,0],a[:,:,1],a[:,:,2];dominance=np.minimum(r,b)-g;blank=(r>=140)&(b>=140)&(g<115)&(dominance>45);a[blank]=0
 fringe=(~blank)&(dominance>8);a[:,:,0][fringe]=np.minimum(a[:,:,0][fringe],a[:,:,1][fringe]+8);a[:,:,2][fringe]=np.minimum(a[:,:,2][fringe],a[:,:,1][fringe]+8)
 return Image.fromarray(a.astype('uint8'))

def row_poses(im,n,min_fraction=.18,discard_row_edge_artifacts=False):
 keyed=key(im);a=np.array(keyed);labels,total=ndimage.label(a[:,:,3]>12,structure=np.ones((3,3)));sizes=np.bincount(labels.ravel());sizes[0]=0
 main=[i for i in range(1,total+1) if sizes[i]>sizes.max()*min_fraction]
 if len(main)<n:raise ValueError(f'Only {len(main)} figures, expected {n}')
 main=sorted(main,key=lambda i:sizes[i],reverse=True)[:n];all_centres=ndimage.center_of_mass(a[:,:,3],labels,range(1,total+1));centers={i:all_centres[i-1][1] for i in main};main.sort(key=lambda i:centers[i]);out=[]
 # Keep complete connected figures even when original artwork overlaps grid boundaries.
 for i in main:
  mask=labels==i
  for j in range(1,total+1):
   if j in main or sizes[j]<max(8,sizes[i]*.0015):continue
   center=all_centres[j-1][1];nearest=min(main,key=lambda k:abs(center-centers[k]))
   if nearest==i and abs(center-centers[i])<im.width/n*.48:
    if discard_row_edge_artifacts:
     part_y=np.where(labels==j)[0];body_y=np.where(labels==i)[0]
     # Cropped boots from the preceding row are not part of this actor.
     # Protect all primary actor pixels, including helmet/axe tips.
     if part_y.min()<=1 and part_y.max()<body_y.min()-2:continue
     if part_y.max()>=im.height-2 and part_y.min()>body_y.max()+2:continue
    mask|=labels==j
  pixels=a.copy();pixels[~mask]=0;pose=Image.fromarray(pixels);box=pose.getchannel('A').point(lambda v:255 if v>12 else 0).getbbox();out.append(pose.crop(box))
 return out

def head_to_foot(pose):
 # Kept only for tooling imports. Pose silhouettes are normalized from the
 # authored neutral starting pose; coat embroidery must not be mistaken for skin.
 return pose.height

def staged_sheet(folder,name,poses,duration,loop,target,uniform=True,frame=(640,640),anchor=(320,600)):
 helmet='player/' in folder;body=[p.height*(363/398 if helmet else 1) for p in poses];reference=body[0] if name not in ['idle','walk','run','idle_front','crouch_idle'] else float(np.median(body));scale=target/reference;scale=min(scale,(frame[0]-16)/max(p.width for p in poses),(anchor[1]-8)/max(p.height for p in poses));out=Image.new('RGBA',(frame[0]*len(poses),frame[1]));heights=[]
 for i,pose in enumerate(poses):
  factor=scale if uniform else min(target/body[i],(frame[0]-16)/pose.width,(anchor[1]-8)/pose.height)
  small=pose.resize((round(pose.width*factor),round(pose.height*factor)),Image.Resampling.LANCZOS);x=anchor[0]-small.width//2;y=anchor[1]-small.height;out.alpha_composite(small,(i*frame[0]+x,y));heights.append(small.height)
 path=STAGED/folder/(name+'.png');path.parent.mkdir(exist_ok=True,parents=True);out.save(path)
 return {'name':name,'sheet':'sprites/'+folder+'/'+name+'.png','frame_width':frame[0],'frame_height':frame[1],'frames':len(poses),'duration_seconds':duration,'fps':len(poses)/duration,'loop':loop,'anchor_px':list(anchor),'image_size':list(out.size),'qa':{'pose_height_exception':name not in ['idle','walk','idle_front'],'height_tol':.03 if name in ['idle','walk','idle_front'] else .55,'movement':name not in ['idle','idle_front','crouch_idle'],'detached_fx_or_weapon':name in ['devour','dice_loop'],'expected_pose_heights':heights},'body_reference_height_px':target,'normalization':'one isotropic scale per clip; constant anatomy, no width/height warping'}

def players(variants=None):
 original=json.loads((R/'assets/sprites/player/axe/manifest.json').read_text());specs={c['name']:c for c in original['clips']};all_sets={}
 for variant in (variants or ['helm','r40','r50','r90']):
  set_name='axe_prosthetic_helm'+('' if variant=='helm' else '_'+variant);folder='player/'+set_name;clips=[];aliases={}
  for group,rows in enumerate(GROUPS):
   im=Image.open(RAW/'source_art'/f'{variant}_{group}.png').convert('RGBA')
   for row,(name,n) in enumerate(rows):
    if variant=='r40' and name in ALIASES:
     aliases[name]={'set':'axe_prosthetic_helm','clip':name};continue
    override=RAW/'source_art'/f'{variant}_{name}_retry.png'
    if override.exists():
     retry=Image.open(override).convert('RGBA');cols=n//2 if n%2==0 else n;rowcount=2 if n%2==0 else 1;poses=[]
     for j in range(rowcount):poses+=row_poses(retry.crop((0,round(j*retry.height/rowcount),retry.width,round((j+1)*retry.height/rowcount))),cols,discard_row_edge_artifacts=True)
    else:poses=row_poses(im.crop((0,round(row*im.height/len(rows)),im.width,round((row+1)*im.height/len(rows)))),n,discard_row_edge_artifacts=True)
    cfg=specs.get(name,{'duration_seconds':.7,'loop':False});target=260 if name=='crouch_idle' else 320 if name in ['crouch_enter','crouch_exit','jump_start','land'] else 340 if name in ['run','jump_rise','hurt'] else 363
    if variant=='r90':target*=1.04
    c=staged_sheet(folder,name,poses,cfg['duration_seconds'],cfg['loop'],target,uniform=name not in ['idle','crouch_idle']);c['qa']['horn_allowance_px']=45
    if 'frame_boundaries_seconds' in cfg:c['frame_boundaries_seconds']=cfg['frame_boundaries_seconds']
    clips.append(c)
  manifest={'height_excludes_helmet':True,'helmet_height_allowance_px':45,'step':19,'frame_size':[640,640],'clips':clips,'aliases':aliases};p=STAGED/folder/'manifest.json';p.write_text(json.dumps(manifest,indent=2));all_sets[set_name]=manifest
 print('Staged player sets',list(all_sets))

def publish_players():
 for folder in (STAGED/'player').iterdir():
  target=R/'assets/sprites/player'/folder.name;target.mkdir(parents=True,exist_ok=True);shutil.copy2(folder/'manifest.json',target/'manifest.json')
  for p in folder.glob('*.png'):
   dest=target/p.name;shutil.copy2(p,dest);im=Image.open(dest).convert('RGBA');n=im.width//640;apply_storage_policy(SimpleNamespace(output=str(dest),frames=n,frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='player_stage11',canonical_only=False),im,True)

def npc_and_props():
 im=Image.open(RAW/'npc_props.png').convert('RGBA');folder=R/'assets/sprites/npcs/shimati';folder.mkdir(parents=True,exist_ok=True);clips=[]
 for i,name in enumerate(['idle','idle_front']):
  cell=im.crop((round(i*im.width/3)+8,8,round((i+1)*im.width/3)-8,im.height//2-8));pose=row_poses(cell,1)[0];c=staged_sheet('npcs/shimati',name,[pose],2.4,True,363,uniform=False);source=STAGED/'npcs/shimati'/(name+'.png');base=source.with_name(name+'_base.png');shutil.copy2(source,base);breathing_sheet(base,source);c.update(frames=6,fps=2.5,image_size=[3840,640]);c['qa'].pop('expected_pose_heights');clips.append(c)
 paper=Image.open(RAW/'shimati_give.png').convert('RGBA');clips.append(staged_sheet('npcs/shimati','give_paper',row_poses(paper,4),.6,False,363))
 for ident,manifest in [('shimati',{'clips':clips}),('urshanabi',{'clips':[staged_sheet('npcs/urshanabi','dice_loop',sum([row_poses(Image.open(RAW/'urshanabi_no_rock.png').crop((0,j*Image.open(RAW/'urshanabi_no_rock.png').height//2,Image.open(RAW/'urshanabi_no_rock.png').width,(j+1)*Image.open(RAW/'urshanabi_no_rock.png').height//2)),4) for j in range(2)],[]),1.6,True,280)]})]:
  dest=R/'assets/sprites/npcs'/ident;dest.mkdir(parents=True,exist_ok=True)
  if ident=='urshanabi':manifest['clips'][0]['seat_contact_offset_y']=-35
  manifest.update(character=ident,height_ratio=1.0 if ident=='shimati' else .7,frame_size=[640,640],step=19)
  (dest/'manifest.json').write_text(json.dumps(manifest,indent=2))
  for c in manifest['clips']:
   source=STAGED/c['sheet'].removeprefix('sprites/');path=dest/(c['name']+'.png');shutil.copy2(source,path);apply_storage_policy(SimpleNamespace(output=str(path),frames=c['frames'],frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='npc',canonical_only=False),Image.open(path).convert('RGBA'),True)
 for col,name,size in [(0,'shimati_stall',(480,300)),(1,'ferry_boat',(420,180)),(2,'small_rock',(260,180))]:
  cell=im.crop((round(col*im.width/3)+8,im.height//2+8,round((col+1)*im.width/3)-8,im.height-8));pose=row_poses(cell,1)[0]
  if name=='ferry_boat':pose=pose.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
  pose=pose.resize((size[0]-4,size[1]-4),Image.Resampling.LANCZOS);out=Image.new('RGBA',size);out.alpha_composite(pose,(2,2));path=R/'assets/props'/(name+'.png');out.save(path);apply_storage_policy(SimpleNamespace(output=str(path),canonical_only=False),out,False)

def one_arm():
 im=Image.open(RAW/'onearm_helm.png').convert('RGBA');folder=R/'assets/sprites/player/axe_onearm_helm';folder.mkdir(parents=True,exist_ok=True);clips=[]
 for row,name,n,d,loop in [(0,'idle',10,2.2,True),(1,'helm_equip',5,.6,False)]:
  pose=row_poses(im.crop((0,row*im.height//2,im.width,(row+1)*im.height//2)),n);clips.append(staged_sheet('player/axe_onearm_helm',name,pose,d,loop,363))
 base=json.loads((R/'assets/sprites/player/axe_onearm/manifest.json').read_text());aliases={c['name']:{'set':'axe_onearm','clip':c['name']} for c in base['clips'] if c['name']!='idle'};(folder/'manifest.json').write_text(json.dumps({'clips':clips,'aliases':aliases},indent=2))
 for c in clips:
  src=STAGED/c['sheet'].removeprefix('sprites/');p=folder/(c['name']+'.png');shutil.copy2(src,p);apply_storage_policy(SimpleNamespace(output=str(p),frames=c['frames'],frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='player_stage11',canonical_only=False),Image.open(p).convert('RGBA'),True)

def gugalanna(names=None):
 original=json.loads((R/'assets/sprites/enemies/gugalanna/manifest.json').read_text());clips=[];changed=[]
 for old in original['clips']:
  name=old['name']
  if names and name not in names:clips.append(old);continue
  source=Image.open(RAW/'source_art'/('gugalanna_'+name+'.png')).convert('RGBA');n=8 if name=='death' else old['frames'];poses=[]
  rows=2 if n==8 else 1
  for j in range(rows):poses+=row_poses(source.crop((0,j*source.height//rows,source.width,(j+1)*source.height//rows)),n//rows)
  target=1400 if not name.startswith('charge') else 1180
  if name=='death':target=1400
  # Boss horns belong to its body reference, unlike the human's helmet allowance.
  reference=poses[0].height if name=='death' else np.median([p.height for p in poses]);factor=target/reference
  frame=(2560,1536);anchor=(1280,1480);out=Image.new('RGBA',(frame[0]*len(poses),frame[1]));heights=[]
  for i,pose in enumerate(poses):
   scale=min(target/pose.height if name=='idle' else factor,(frame[0]-16)/max(p.width for p in poses),(anchor[1]-8)/max(p.height for p in poses));small=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.LANCZOS);out.alpha_composite(small,(i*frame[0]+anchor[0]-small.width//2,anchor[1]-small.height));heights.append(small.height)
  if name=='death':
   mapping=[0,1,2,3,4,5,6,6,7,7];expanded=Image.new('RGBA',(25600,1536))
   for i,k in enumerate(mapping):expanded.paste(out.crop((k*2560,0,(k+1)*2560,1536)),(i*2560,0))
   out=expanded;heights=[heights[k] for k in mapping]
  c={k:old[k] for k in ['name','duration_seconds','fps','loop','frames','frame_width','frame_height','anchor_px']};c.update(sheet='sprites/enemies/gugalanna/'+name+'.png',image_size=list(out.size),qa={'movement':True,'pose_height_exception':name!='idle','height_tol':.03 if name=='idle' else .55,'expected_pose_heights':heights})
  dest=R/'assets/sprites/enemies/gugalanna';path=dest/(name+'.png');out.save(path);clips.append(c);changed.append(c)
 original['clips']=clips;(dest/'manifest.json').write_text(json.dumps(original,indent=2))
 for c in changed:
  path=dest/(c['name']+'.png');apply_storage_policy(SimpleNamespace(output=str(path),frames=c['frames'],frame_width=2560,frame_height=1536,anchor=[1280,1480],visual_scale=.3,density_class='large_enemy',canonical_only=False),Image.open(path).convert('RGBA'),True)

def gugalanna_idle():gugalanna(['idle'])

def fx_and_scenery():
 im=Image.open(RAW/'fx.png').convert('RGBA');folder=R/'assets/sprites/fx';manifest={'clips':[]}
 for col,name,n,size,d in [(0,'devour_bite',5,(256,192),.35),(1,'mote',4,(64,64),2.0)]:
  cell=im.crop((col*im.width//3+4,4,(col+1)*im.width//3-4,im.height//2-4));poses=row_poses(cell,n,.006);out=Image.new('RGBA',(size[0]*n,size[1]))
  for i,p in enumerate(poses):
   limits=[]
   for q in poses:
    qa=np.asarray(q)[:,:,3].astype(float);qy,qx=np.indices(qa.shape);qc=(qx*qa).sum()/qa.sum();qr=(qy*qa).sum()/qa.sum();limits.append(min((size[0]/2-8)/max(qc,q.width-qc),(size[1]/2-8)/max(qr,q.height-qr)))
   scale=min(limits);p=p.resize((round(p.width*scale),round(p.height*scale)),Image.Resampling.LANCZOS);a=np.asarray(p)[:,:,3].astype(float);yy,xx=np.indices(a.shape);cx=(xx*a).sum()/a.sum();cy=(yy*a).sum()/a.sum();out.alpha_composite(p,(round(i*size[0]+size[0]/2-cx),round(size[1]/2-cy)))
  path=folder/(name+'.png');out.save(path);manifest['clips'].append({'name':name,'sheet':'sprites/fx/'+name+'.png','frame_width':size[0],'frame_height':size[1],'anchor_px':[size[0]//2,size[1]//2],'frames':n,'duration_seconds':d,'fps':n/d,'loop':False,'image_size':list(out.size),'qa':{'movement':True,'pose_height_exception':True,'height_tol':.65,'detached_fx_or_weapon':True,'fade_out_fx':True}})
 (folder/'stage11_manifest.json').write_text(json.dumps(manifest,indent=2))
 for c in manifest['clips']:
  path=folder/(c['name']+'.png');apply_storage_policy(SimpleNamespace(output=str(path),frames=c['frames'],frame_width=c['frame_width'],frame_height=c['frame_height'],anchor=c['anchor_px'],visual_scale=1.0,density_class='fx',canonical_only=False),Image.open(path).convert('RGBA'),True)
 note=row_poses(im.crop((2*im.width//3+4,4,im.width-4,im.height//2-4)),1)[0];note.thumbnail((92,68));paper=Image.new('RGBA',(96,72));paper.alpha_composite(note,((96-note.width)//2,(72-note.height)//2));path=R/'assets/props/paper_note.png';paper.save(path);apply_storage_policy(SimpleNamespace(output=str(path),canonical_only=False),paper,False)
 for source,name,size in [(Image.open(RAW/'stars.png').convert('RGB'),'assets/backgrounds/deathsea/stars_tile.png',(1024,1024)),(im.crop((4,round(im.height*.66),im.width-4,im.height-4)).convert('RGB'),'assets/tiles/deathsea/ground_tile.png',(512,200))]:
  source=source.resize(size,Image.Resampling.LANCZOS);p=np.array(source).astype(float)
  # Seam repair blends only generated pixels. No painted world art is synthesized.
  for axis in [0,1]:
   p=np.swapaxes(p,0,axis);a=p[:16].copy();b=p[-16:][::-1].copy();shared=(a+b)/2;w=np.linspace(1,0,16)[:,None,None];p[:16]=a*(1-w)+shared*w;p[-16:]=(b*(1-w)+shared*w)[::-1];p[-1]=p[0];p=np.swapaxes(p,0,axis)
  luma=p@np.array([.2126,.7152,.0722]);p+=np.maximum(0,15-luma)[:,:,None];source=Image.fromarray(np.rint(p).clip(0,255).astype('uint8'));path=R/name;path.parent.mkdir(parents=True,exist_ok=True);source.save(path);apply_storage_policy(SimpleNamespace(output=str(path),canonical_only=False),source.convert('RGBA'),False)
if __name__=='__main__':
 for name in sys.argv[1:] or ['players','publish_players','npc_and_props','one_arm']:globals()[name]()
