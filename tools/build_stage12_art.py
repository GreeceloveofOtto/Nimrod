#!/usr/bin/env python3
"""Only normalize, key, compose and encode image-generated artwork; never synthesize sprites."""
import json,shutil,sys
from pathlib import Path
from types import SimpleNamespace
from PIL import Image
from build_stage11_art import key,row_poses
from pack_sprites import apply_storage_policy
from make_breathing_sheet import breathing_sheet
R=Path(__file__).resolve().parents[1];A=R/'archive/stage12';A.mkdir(exist_ok=True)
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def environment():
 poses=row_poses(Image.open(A/'tiamat_source.png'),3,min_fraction=.08)
 for name,picture,size in [('huluppu_trunk',poses[0],(1440,1760)),('utnapishtim_hut',poses[1],(352,176))]:
  out=Image.new('RGBA',size);inner=picture.resize((size[0]-4,size[1]-4),Image.Resampling.LANCZOS);out.alpha_composite(inner,(2,2))
  p=R/'assets/props'/(name+'.png');out.save(p)
  apply_storage_policy(SimpleNamespace(output=str(p),canonical_only=False),out,False)
 folder=R/'assets/sprites/npcs/utnapishtim';folder.mkdir(parents=True,exist_ok=True)
 pose=poses[2];scale=363*.98/pose.height;pose=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.LANCZOS)
 base=Image.new('RGBA',(640,640));base.alpha_composite(pose,(320-pose.width//2,600-pose.height));base.save(A/'utnapishtim_idle_base.png')
 canonical=folder/'idle.png';breathing_sheet(A/'utnapishtim_idle_base.png',canonical)
 manifest={'character':'utnapishtim','height_ratio':.98,'step':20,'frame_size':[640,640],'clips':[{'name':'idle','sheet':'sprites/npcs/utnapishtim/idle.png','frames':6,'frame_width':640,'frame_height':640,'anchor_px':[320,600],'duration_seconds':2.4,'fps':2.5,'loop':True,'image_size':[3840,640],'qa':{'height_tol':.03,'movement':False},'body_reference_height_px':363*.98}]}
 write(folder/'manifest.json',manifest)
 apply_storage_policy(SimpleNamespace(output=str(canonical),frames=6,frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.39,density_class='npc',canonical_only=False),Image.open(canonical).convert('RGBA'),True)
 # The renderer preserves displayed dimensions despite storage downsampling.
 levels=json.loads((R/'data/levels.json').read_text());level=next(x for x in levels['levels'] if x['id']=='TiamatZone')
 house=next(x for x in level['decorations'] if x['name']=='HermitHouse');house.update(position=[1500,660],size=[440,220]);write(R/'data/levels.json',levels)
 print('Generated Tiamat assets',sum(p.stat().st_size for p in [R/'assets/props/huluppu_trunk.webp',R/'assets/props/utnapishtim_hut.webp',folder/'idle.webp']))


def helmets():
 import build_stage11_art as original
 # Reuse the proven stage11 normalization, with independent source/staging roots.
 original.RAW=A
 original.STAGED=A/'staged'
 original.STAGED.mkdir(exist_ok=True)
 original.players()
 original.publish_players()
 shutil.copy2(A/'source_art/onearm_helm.png',A/'onearm_helm.png')
 original.one_arm()
 for folder in [R/'assets/sprites/player'/n for n in ['axe_prosthetic_helm','axe_prosthetic_helm_r40','axe_prosthetic_helm_r50','axe_prosthetic_helm_r90','axe_onearm_helm']]:
  mp=folder/'manifest.json';d=json.loads(mp.read_text());d.update(helmet_height_allowance_px=45,helmet_horns=1,step=20)
  for c in d['clips']:
   c['qa']['helmet_horns']=1
   if c['name'] in ['idle','walk','crouch_idle']:
    c['qa']['head_top_px']=[round(c['anchor_px'][1]-c.get('body_reference_height_px',363))]*c['frames']
    c['qa']['head_center_x_px']=[c['anchor_px'][0]]*c['frames']
  write(mp,d)

if __name__=='__main__':
 if '--helmets' in sys.argv:helmets()
 else:environment()
