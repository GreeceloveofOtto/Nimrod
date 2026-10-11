#!/usr/bin/env python3
"""Pack generated Stage6 atlases; copy pixels only, never synthesize game art."""
import json,copy,shutil,math
from pathlib import Path
import numpy as np
from PIL import Image
from build_stage5_assets import sheet
from pack_sprites import chromakey,foreground,component_poses
from make_breathing_sheet import breathing_sheet
from build_stage6_data import SPECS,FX,P2
R=Path(__file__).resolve().parents[1];A=R/'assets';S=A/'source_art/stage6';entries=[];manifests=[]
PREFIX='2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere with advanced space-civilization undertones, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark'
HUMAN='2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark'
def save(p,x):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n')
def atlas(name):return Image.open(S/(name+'_atlas.png')).convert('RGBA')
def pose_row(im,row,rows,frames,columns=8):
 band=chromakey(im.crop((0,round(im.height*row/rows),im.width,round(im.height*(row+1)/rows))))
 # Magenta vertical gutters sometimes drift slightly; connected original figures
 # are preferable to fixed boxes, with explicit cell crops as a fallback.
 poses=None
 for count in range(columns,frames-1,-1):
  try:
   candidates=component_poses(band,count)
   heights=[p.height for p in candidates]
   if min(heights)>=max(heights)*.58:
    poses=candidates;break
  except ValueError:pass
 if poses is None:poses=[foreground(band.crop((round(im.width*i/columns),0,round(im.width*(i+1)/columns),band.height)))[0] for i in range(columns)]
 return poses[:frames]
def register(path,size,transparent=True,**meta):entries.append(dict(name=Path(path).stem,path=path,width=size[0],height=size[1],transparent=transparent,**meta))
def still(pose,path,size,opaque=False,tile_x=False,tile_y=False):
 im=pose.resize(size,Image.Resampling.LANCZOS).convert('RGBA')
 if not opaque:im=chromakey(im)
 if opaque:im.putalpha(255)
 if tile_x or tile_y:
  pix=np.asarray(im).copy().astype(float)
  for axis,on in [(1,tile_x),(0,tile_y)]:
   if not on:continue
   arr=np.swapaxes(pix,axis,0);band=min(32,arr.shape[0]//4);left=arr[:band].copy();right=arr[-band:][::-1].copy();shared=(left+right)*.5
   w=np.linspace(1,0,band).reshape((band,)+(1,)*(arr.ndim-1));arr[:band]=left*(1-w)+shared*w;arr[-band:]=(right*(1-w)+shared*w)[::-1];arr[-1]=arr[0];pix=np.swapaxes(arr,0,axis)
  im=Image.fromarray(np.rint(pix).astype('uint8'),'RGBA')
 p=A/path;p.parent.mkdir(parents=True,exist_ok=True);im.save(p,optimize=True);register(path,size,not opaque,**({'tile_x':True} if tile_x else {}),**({'tile_y':True} if tile_y else {}))
def enemies():
 for id,spec in SPECS.items():
  if id=='kala_ushumgal':continue
  name=id.removeprefix('cedar_');im=atlas(name);rows=len(spec['clips']);allposes=[pose_row(im,i,rows,c['frames']) for i,c in enumerate(spec['clips'])]
  frame=spec['frame_size'];anchor=spec['anchor'];alignment='center' if id=='cedar_wisp' else 'bottom-center'
  target_height=spec['body_size'][1]/spec['visual_scale'];reference_row=next((row for row,c in zip(allposes,spec['clips']) if c['name'] in ['idle','float']),allposes[0]);refh=reference_row[0].height;scale=target_height/refh
  clips=[]
  for poses,clip in zip(allposes,spec['clips']):
   clip_scale=min(scale,(frame[0]-16)/max(p.width for p in poses),((frame[1]-16) if alignment=='center' else anchor[1]-8)/max(p.height for p in poses))
   clips.append(sheet(poses,f'sprites/enemies/{id}/{clip["name"]}.png',frame,anchor,clip['duration'],clip['loop'],clip_scale,alignment=alignment))
  path=f'sprites/enemies/{id}/manifest.json';save(A/path,dict(character=id,aliases=spec['aliases'],clips=clips));manifests.append(path)
 # Wall diver additions use the existing body proportions and exact center anchor.
 im=atlas('wall');folder=A/'sprites/enemies/wall_diver';m=json.loads((folder/'manifest.json').read_text());known={c['name']:c for c in m['clips']}
 for i,(name,duration) in enumerate([('idle',.8),('windup',.35)]):
  poses=pose_row(im,i,2,4,4);scale=min(200/poses[0].height,620/max(p.width for p in poses),620/max(p.height for p in poses));known[name]=sheet(poses,f'sprites/enemies/wall_diver/{name}.png',[640,640],[320,320],duration,name=='idle',scale,'center')
 m['clips']=list(known.values());save(folder/'manifest.json',m)
 data=json.loads((R/'data/enemies.json').read_text());e=next(x for x in data['enemies'] if x['id']=='wall_diver')
 for name,duration in [('idle',.8),('windup',.35)]:
  e['clips']=[c for c in e['clips'] if c['name']!=name]+[dict(name=name,frames=4,duration=duration,loop=name=='idle')]
 save(R/'data/enemies.json',data)
def boss():
 spec=SPECS['kala_ushumgal'];base=spec['clips'][:10];special=spec['clips'][10:20];p2=[next(c for c in spec['clips'] if c['name']==n+'_p2') for n in P2];groups=[]
 for name,clips in [('boss_base',base),('boss_special',special),('boss_p2',p2)]:
  im=atlas(name);groups +=[(clip,pose_row(im,i,10,clip['frames'])) for i,clip in enumerate(clips)]
 # High-resolution idle and turn atlases retain their native pixel detail.
 scale=1120/groups[0][1][0].height
 replacement={}
 if (S/'boss_turn_atlas.png').exists():
  im=atlas('boss_turn');replacement.update({'turn':pose_row(im,0,2,6,6),'turn_p2':pose_row(im,1,2,6,6)})
 for source,clip in [('boss_idle','idle'),('boss_idle_p2','idle_p2')]:
  if (S/(source+'_atlas.png')).exists():
   im=atlas(source);replacement[clip]=pose_row(im,0,2,4,4)+pose_row(im,1,2,4,4)
 groups=[(c,replacement.get(c['name'],poses)) for c,poses in groups]
 cs=[]
 for c,poses in groups:
  native_scale=1120/poses[0].height if c['name'] in replacement else scale
  clip_scale=min(native_scale,1520/max(p.width for p in poses),1192/max(p.height for p in poses))
  cs.append(sheet(poses,f'sprites/enemies/kala_ushumgal/{c["name"]}.png',spec['frame_size'],spec['anchor'],c['duration'],c['loop'],clip_scale))
 path='sprites/enemies/kala_ushumgal/manifest.json';save(A/path,dict(character='kala_ushumgal',aliases=spec['aliases'],clips=cs));manifests.append(path)
def npc():
 im=atlas('enkidua');shutil.copy2(S/'enkidua_atlas.png',A/'reference/enkidua_design.png')
 cs=[]
 for name,box in [('idle_front',(0,0,470,im.height)),('idle',(480,0,790,im.height))]:
  pose=foreground(chromakey(im.crop(box)))[0];scale=min((363*1.04)/pose.height,624/pose.width)
  clip=sheet([pose],f'source_art/npc_front/enkidua_{name}.png',[640,640],[320,600],2.4,True,scale)
  stationary=A/clip['sheet'];target=f'sprites/npcs/enkidua/{name}.png';breathing_sheet(stationary,A/target)
  cs.append(dict(clip,name=name,sheet=target,frames=6,columns=6,fps=2.5,image_size=[3840,640]))
 path='sprites/npcs/enkidua/manifest.json';save(A/path,dict(character='enkidua',height_ratio=1.04,clips=cs));manifests.append(path)
def world():
 im=atlas('backgrounds');cuts=[0,365,795,im.height]
 for i,(path,size,floor,targetfloor) in enumerate([('backgrounds/nimrod_home/home_interior_bg.webp',(1800,720),281,620),('backgrounds/villa_backyard/backyard_bg.webp',(1500,720),360,720),('backgrounds/cedar/boss_bg.webp',(1600,960),360,800)]):
  band=im.crop((0,cuts[i],im.width,cuts[i+1]));floor=min(floor,band.height-1);upper=band.crop((0,0,band.width,floor)).resize((size[0],targetfloor),Image.Resampling.LANCZOS);result=Image.new('RGBA',size);result.alpha_composite(upper)
  if targetfloor<size[1]:result.alpha_composite(band.crop((0,floor,band.width,band.height)).resize((size[0],size[1]-targetfloor),Image.Resampling.LANCZOS),(0,targetfloor))
  still(result,path,size,True)
 im=atlas('forest_tiles')
 for i,name in enumerate(['far_tile_2d','mid_trunks_tile_2d']):still(im.crop((round(im.width*i/2),0,round(im.width*(i+1)/2),im.height)),f'backgrounds/cedar/{name}.png',(1024,1024),True,True,True)
 im=atlas('world_props');cuts=[0,350,700,im.height];sizes=[[(420,200),(360,180),(300,420),(120,260),(420,60)],[(240,200),(280,120),(200,360),(220,130),(360,120)],[(512,180),(256,48),(320,48),(160,512),(512,160)]];names=[['home_bed','home_table','home_shelf','home_lamp','home_rug'],['cedar_stump','skeleton_remains','hanging_vines','bone_pile','cedar_branch_perch'],['root_floor_tile','root_platform','branch_platform','wall_trunk_tile','canopy_top_tile']]
 for i in range(3):
  poses=component_poses(chromakey(im.crop((0,cuts[i],im.width,cuts[i+1]))),5)
  for j,(name,size,pose) in enumerate(zip(names[i],sizes[i],poses)):
   tile=i==2;path=('tiles/cedar/' if tile else 'props/')+name+'.png';still(pose,path,size,opaque=tile and j in [0,3],tile_x=tile and j!=3,tile_y=tile and j==3)
 im=atlas('extra_tiles')
 for i,(path,size) in enumerate([('tiles/home/home_floor_tile.webp',(512,180)),('tiles/cedar/bone_floor_tile.webp',(512,180)),('tiles/cedar/boss_end_platform.webp',(280,56))]):
  pose=foreground(chromakey(im.crop((0,round(i*im.height/3),im.width,round((i+1)*im.height/3)))))[0];still(pose,path,size,i<2,True)
 im=atlas('doors');cs=[]
 for i,(name,frame) in enumerate([('nimrod_home_inner_door',[256,384]),('villa_back_door_exterior',[320,420]),('cedar_forest_portal',[320,460]),('cedar_portal',[256,384])]):
  poses=pose_row(im.crop((0,[0,225,445,723,im.height][i],im.width,[0,225,445,723,im.height][i+1])),0,1,6,6);scale=min((frame[0]-8)/max(p.width for p in poses),(frame[1]-4)/max(p.height for p in poses));cs.append(sheet(poses,'props/doors/'+name+'.png',frame,[frame[0]//2,frame[1]],.6,False,scale))
  interactions=json.loads((R/'data/interactions.json').read_text());interactions['door_art'][name]=dict(frame_size=frame,frames=6);save(R/'data/interactions.json',interactions)
 path='props/doors/stage6_manifest.json';save(A/path,{'clips':cs});manifests.append(path)
 im=atlas('fx');cs=[]
 for i,(name,frame,frames,duration,loop) in enumerate(FX):
  poses=pose_row(im.crop((0,[0,184,384,462,646,851,im.height][i],im.width,[0,184,384,462,646,851,im.height][i+1])),0,1,frames,6);scale=min((frame[0]-4)/max(p.width for p in poses),(frame[1]-4)/max(p.height for p in poses));cs.append(sheet(poses,'sprites/fx/'+name+'.png',frame,[frame[0]//2,frame[1]//2],duration,loop,scale,'center'))
 path='sprites/fx/stage6_manifest.json';save(A/path,{'clips':cs});manifests.append(path)
def prompts():
 for path in manifests:
  m=json.loads((A/path).read_text())
  for clip in m['clips']:
   prompt=HUMAN if 'npcs/' in path else PREFIX
   spec=SPECS.get(m.get('character',''),{});description=spec.get('appearance',m.get('character','image-generated animation'))
   target=A/'image_prompts'/('stage6_'+m.get('character','art')+'_'+clip['name']+'.md')
   target.write_text(f'# {clip["name"]}\n목적: 6단계 이미지 생성 애니메이션.\n경로: assets/{clip["sheet"]}\n프레임: {clip["frame_width"]}x{clip["frame_height"]}, {clip["frames"]}프레임, {clip["duration_seconds"]}초, 앵커 {clip["anchor_px"]}.\n배경: #FF00FF → pack_sprites.py 크로마키 투명 처리.\n\n{prompt}. {description}, {clip["name"].replace("_"," ")} sequential poses, consistent identity, right-facing, no text, solid magenta background.\n')
 for item in entries:(A/'image_prompts'/('stage6_'+item['name']+'.md')).write_text(f'# {item["name"]}\n목적: 6단계 환경.\n경로: assets/{item["path"]}\n크기: {item["width"]}x{item["height"]}, 1프레임.\n배경: {"불투명" if not item["transparent"] else "#FF00FF 크로마키"}.\n\n{PREFIX}. {item["name"].replace("_"," ")}, side view painted game asset.\n')
def main():
 import argparse
 p=argparse.ArgumentParser();p.add_argument('part',choices=['enemies','boss','npc','world','all']);args=p.parse_args()
 for name in ['enemies','boss','npc','world']:
  if args.part in [name,'all']:globals()[name]()
 m=json.loads((A/'art_manifest.json').read_text());known={e['path']:e for e in m['assets']};known.update({e['path']:e for e in entries});m['assets']=list(known.values());m['sprite_manifests']=list(dict.fromkeys(m['sprite_manifests']+manifests));save(A/'art_manifest.json',m);prompts()
if __name__=='__main__':main()
