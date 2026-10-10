#!/usr/bin/env python3
"""Crop image-generation outputs, chromakey and pack PNGs. Never draw game art."""
import json,tempfile,argparse,shutil
from pathlib import Path
from types import SimpleNamespace
import numpy as np
from PIL import Image
from pack_sprites import chromakey,foreground,component_poses,pack_sheet,pack_image
from build_stage5_data import SPECS,clips
R=Path(__file__).resolve().parents[1]; A=R/'assets';S=A/'source_art/stage5';ENTRIES=[];MANIFESTS=[]
PREFIX='2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere with advanced space-civilization undertones, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark'
def save(p,obj):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')
def get(src):return Image.open(S/(src+'_atlas.png')).convert('RGBA')
def sheet(poses,path,frame,anchor,duration,loop,scale=None,alignment='bottom-center'):
    if scale is None:scale=min((frame[0]-16)/max(p.width for p in poses),(frame[1]-16)/max(p.height for p in poses))
    w=max(p.width for p in poses)+16;h=max(p.height for p in poses)+16
    im=Image.new('RGBA',(w*len(poses),h))
    for i,p in enumerate(poses):im.alpha_composite(p,(w*i+8,8))
    with tempfile.TemporaryDirectory() as d:
        src=Path(d)/'normalized.png';im.save(src)
        args=SimpleNamespace(source=src,output=A/path,crop=None,frames=len(poses),grid_cols=len(poses),grid_rows=1,column=0,row=0,reference_column=0,reference_row=0,auto_cells=False,boxes=None,components=False,fit=(frame[0]-16,frame[1]-16),scale=scale,scale_xy=None,frame_width=frame[0],frame_height=frame[1],anchor=anchor,alignment=alignment,reverse=False,flip_frames=[],cell_gap=3)
        pack_sheet(args)
    if alignment=='center':
        source=Image.open(A/path).convert('RGBA');result=Image.new('RGBA',source.size)
        for i in range(len(poses)):
            f=source.crop((frame[0]*i,0,frame[0]*(i+1),frame[1]));b=f.getchannel('A').point(lambda a:255 if a>12 else 0).getbbox();dx=round(anchor[0]-(b[0]+b[2])/2);dy=round(anchor[1]-(b[1]+b[3])/2);result.alpha_composite(f,(frame[0]*i+dx,dy))
        result.save(A/path,optimize=True)
    return dict(name=Path(path).stem,sheet=path,frame_width=frame[0],frame_height=frame[1],columns=len(poses),rows=1,frames=len(poses),duration_seconds=duration,fps=len(poses)/duration,loop=loop,anchor_px=anchor,image_size=[len(poses)*frame[0],frame[1]])
def image(src,box,path,size,opaque=False,trim=False,tile=False,**extra):
    pack_image(SimpleNamespace(source=S/(src+'_atlas.png'),output=A/path,crop=(box[0],box[1],box[2]-box[0],box[3]-box[1]),size=size,opaque=opaque,trim=trim,tile_x=32 if tile else 0))
    ENTRIES.append(dict(name=Path(path).stem,path=path,width=size[0],height=size[1],transparent=not opaque,**({'tile_x':True} if tile else {}),**extra))
def row(im,top,bottom,count):return component_poses(chromakey(im.crop((0,top,im.width,bottom))),count)
def split_bands(im,count):
    energy=(np.asarray(chromakey(im).getchannel('A'))>32).sum(axis=1)
    # Atlas rows have magenta gutters; choose the lightest separator near expected rows.
    cuts=[0]
    for i in range(1,count):
        c=round(im.height*i/count);radius=round(im.height/count*.3);lo=max(cuts[-1]+8,c-radius);hi=min(im.height-8,c+radius)
        cuts.append(lo+int(np.argmin(energy[lo:hi])))
    return cuts+[im.height]
def world():
    im=get('passage_walls');w,h=im.size
    for i,n in enumerate(['wall_tile_a','wall_tile_b','wall_tile_c','wall_tile_d','far_abyss_tile']):
        image('passage_walls',(350,round(h*i/5),350+round(h/5*(2048 if i==4 else 1024)/720),round(h*(i+1)/5)),'backgrounds/passage/'+n+'.png',(2048 if i==4 else 1024,720),True,tile=True)
    im=get('passage_props');w,h=im.size
    objects=[('passage_pillar_a',(220,620)),('passage_pillar_b',(260,620)),('passage_arch',(600,520)),('passage_window_crimson',(320,420)),('passage_gargoyle',(240,300)),('passage_chandelier',(280,360)),('passage_pipe_cluster',(420,300)),('passage_gear_pillar',(200,520)),('passage_stair_block',(320,120))]
    # Generated first row has a wide arch, third row a wide pipe cluster.
    boxes=[(0,0,405,416),(405,0,700,416),(700,0,w,416),(0,416,490,760),(490,416,940,760),(940,416,w,795),(0,775,605,h),(605,720,900,h),(900,795,w,h)]
    for (name,size),box in zip(objects,boxes):image('passage_props',box,'props/'+name+'.png',size,trim=True)
    im=get('passage_tiles_doors');w,h=im.size
    for i,(name,size) in enumerate([('floor_tile',(512,180)),('platform',(256,48)),('ledge',(480,56)),('ceiling_tile',(512,120)),('low_tunnel_ceiling',(512,140)),('bridge_plank',(320,48))]):
        image('passage_tiles_doors',(round(w*i/6),0,round(w*(i+1)/6),137),'tiles/passage/'+name+'.png',size,trim=True,tile=name in ['floor_tile','ceiling_tile','low_tunnel_ceiling'])
    door_clips=[]
    for name,top,bottom,frame in [('passage_door',137,341,[256,384]),('downtown_passage_door_anim',341,585,[320,460]),('nimrod_home_gate',585,773,[320,420])]:
        poses=row(im,top,bottom,6);scale=min((frame[0]-8)/max(p.width for p in poses),(frame[1]-8)/max(p.height for p in poses))
        door_clips.append(sheet(poses,'props/doors/'+name+'.png',frame,[frame[0]//2,frame[1]-4],.6,False,scale))
    save(A/'props/doors/stage5_manifest.json',{'clips':door_clips});MANIFESTS.append('props/doors/stage5_manifest.json')
    poses=[foreground(chromakey(im.crop((256*i,773,256*(i+1),h))))[0] for i in range(6)];fx=[sheet(poses,'sprites/fx/root_flame.png',[256,512],[128,508],.6,True,min(240/max(p.width for p in poses),490/max(p.height for p in poses)))]
    im=get('fx');cut=[0,148,352,523,719,819,1024]
    spec=json.loads((R/'data/stage5_fx.json').read_text())['fx']
    for i,f in enumerate(spec):
        poses=[foreground(chromakey(im.crop((256*j,cut[i],256*(j+1),cut[i+1]))))[0] for j in range(f['frames'])] if f['frames']>1 else row(im,cut[i],cut[i+1],1);frame=f['frame_size']
        fx.append(sheet(poses,f['path'].removeprefix('res://assets/'),frame,[frame[0]//2,frame[1]//2],f['duration'],f['loop'],min((frame[0]-4)/max(p.width for p in poses),(frame[1]-4)/max(p.height for p in poses)),alignment='center'))
    save(A/'sprites/fx/stage5_manifest.json',{'clips':fx});MANIFESTS.append('sprites/fx/stage5_manifest.json')
    im=get('homeroad_bg');w,h=im.size;cut=[0,212,420,625,h]
    for i,(name,size,op,tile) in enumerate([('sky',(1792,720),True,False),('far_tile',(2048,720),False,True),('mid_district_tile',(2048,720),False,True),('nimrod_home_exterior',(1300,720),False,False)]):
        path=('props/' if i==3 else 'backgrounds/homeroad/')+name+'.png'
        left=[580,300,800,720][i];span=round((cut[i+1]-cut[i])*size[0]/size[1]);image('homeroad_bg',(left,cut[i],min(w,left+span),cut[i+1]),path,size,op,tile=tile,**({'localized':True} if i==3 else {'map_width':10800,'scroll_ratio':[.05,.2,.45][i],**({'repeat_x':True} if tile else {})}))
    im=get('homeroad_props');w,h=im.size
    names=[('house_ruin_a',(500,380)),('house_ruin_b',(420,300)),('broken_overpass',(1100,260)),('canal_wall_left',(300,260)),('canal_wall_right',(300,260)),('market_stall_a',(260,170)),('market_stall_b',(260,170)),('garden_fence',(600,140)),('lamp_post_ruined',(100,260)),('shrub',(220,140))]
    xs=[[0,440,800,1425,1690,w],[0,440,815,1460,1660,w]]
    for i,(name,size) in enumerate(names):
        j=i%5;k=i//5;image('homeroad_props',(xs[k][j],0 if k==0 else 412,xs[k][j+1],412 if k==0 else h),'props/'+name+'.png',size,trim=True)
    for i,(name,size) in enumerate([('ground_tile',(512,200)),('plaza_tile',(512,200)),('canal_floor_tile',(512,200)),('stone_slab_bridge',(360,56)),('balcony_platform',(256,48))]):
        j=i%3;k=i//3;image('homeroad_tiles',(j*512+8,325 if k==0 else 640,(j+1)*512-8,500 if k==0 else 870),'tiles/homeroad/'+name+'.png',size,opaque=k==0,trim=k==1,tile=k==0)
    from build_passage_backgrounds import main as backgrounds
    backgrounds()
    for n in range(1,9):
        path=f'backgrounds/passage/passage_f{n}_bg.png';im=Image.open(A/path);ENTRIES.append(dict(name=f'passage_f{n}_bg',path=path,width=im.width,height=im.height,transparent=False))
def enemies():
    manual={'explosive_spitter':[0,136,258,388,520,644,773,892,1024],'wall_diver':[0,104,229,347,467,570,672,771,871,980,1122],'shell_scorpion':[0,97,192,279,366,448,531,626,717,815,907,1024], 'wraith_ray':[0,225,443,646,887], 'gas_sac':[0,161,313,486,626,827,1024],'root_spewer':[0,145,278,450,588,731,865,1024]}
    for id,name,appearance,hp,damage,turn,speed,detect,body,frame,anchor,sequence in SPECS:
        print('PACKING ENEMY',id,flush=True)
        im=get(id);spec=clips(sequence);cut=manual.get(id,split_bands(im,len(spec)))
        if id=='boar_charger':cut=[0,120,232,344,460,586,722,860,1024]
        if id=='shell_scorpion':cut=[0,97,192,279,366,448,531,626,717,815,907,1024]
        if id=='chain_beastman':cut=[0,101,200,296,386,477,558,643,723,824,919,1006,1085,1173]
        poses_by={}
        if id=='boar_charger':
            extra=Image.open(S/'boar_stun.png')
            for i,c in enumerate(spec):
                if c['name']=='crash_stun':poses_by[c['name']]=row(extra,0,extra.height,4)
                else:
                    j=i if i<4 else i-1
                    poses_by[c['name']]=row(im,cut[j],cut[j+1],c['frames'])
        elif id=='shell_scorpion':
            extra=Image.open(S/'shell_recovery.png')
            for i,c in enumerate(spec):
                if c['name']=='tail_recovery':poses_by[c['name']]=row(extra,0,extra.height,4)
                else:
                    j=i if i<8 else i-1
                    poses_by[c['name']]=row(im,cut[j],cut[j+1],c['frames'])
        elif id=='chain_beastman':
            # Original atlas omitted a distinct smash clip; generated replacement has both windup and impact.
            sm=Image.open(S/'chain_smash.png');smcuts=split_bands(sm,2)
            for i,c in enumerate(spec):
                if c['name']=='smash_windup':poses_by[c['name']]=row(sm,smcuts[0],smcuts[1],4)
                elif c['name']=='smash':poses_by[c['name']]=row(sm,smcuts[1],smcuts[2],3)
                else:
                    j=i if i<8 else i-1
                    poses_by[c['name']]=row(im,cut[j],cut[j+1],c['frames'])
        else:
            for i,c in enumerate(spec):poses_by[c['name']]=row(im,cut[i],cut[i+1],c['frames'])
        if id=='chain_beastman':
            idle_height=poses_by['idle'][0].height
            for name in ['smash_windup','smash']:
                poses_by[name]=[p.resize((round(p.width*idle_height*1.25/p.height),round(idle_height*1.25)),Image.Resampling.LANCZOS) for p in poses_by[name]]
            for name in poses_by:
                selected=[]
                for p in poses_by[name]:
                    a=np.asarray(p.getchannel('A'));width=round(p.height*1.5);weights=(a>32).sum(axis=0);score=np.convolve(weights,np.ones(min(width,p.width)),mode='valid');x=int(np.argmax(score));selected.append(foreground(p.crop((x,0,min(p.width,x+width),p.height)))[0])
                poses_by[name]=selected
        allposes=[p for ps in poses_by.values() for p in ps]
        target=min(520,body[1]/.3);idle=next(iter(poses_by.values()))[0]
        scale=min(target/idle.height,(frame[0]-24)/max(p.width for p in allposes),((min(anchor[1]-8,frame[1]-anchor[1]-8)*2) if anchor[1]==320 else anchor[1]-8)/max(p.height for p in allposes))
        out=[]
        for c in spec:
            path='sprites/enemies/'+id+'/'+c['name']+'.png';out.append(sheet(poses_by[c['name']],path,frame,anchor,c['duration'],c['loop'],scale,'center' if anchor[1]==320 else 'bottom-center'))
            (A/'image_prompts'/f'stage5_{id}_{c["name"]}.md').write_text(f'# {name} / {c["name"]}\n목적: 괴수 애니메이션. 경로: assets/{path}\n규격: {c["frames"]} × {frame[0]}x{frame[1]}, {c["duration"]}초, 앵커 {anchor}.\n배경: #FF00FF → pack_sprites.py 크로마키/정렬/합성.\n\n'+json.loads((S/'enemy_generation_prompts.json').read_text())[id]+'\n')
        path='sprites/enemies/'+id+'/manifest.json';save(A/path,{'character':id,'clips':out});MANIFESTS.append(path)
def roll():
    im=get('roll');poses=[]
    for a,b in [(0,360),(360,614),(614,1024)]:poses+=row(im,a,b,4)
    packed=[];spec=[]
    for i,p in enumerate(poses):
        scale=363/p.height if i in [0,11] else min(300/p.width,220/p.height) if i<7 else min(363/p.height,400/p.width)
        normalized=p.resize((round(p.width*scale),round(p.height*scale)),Image.Resampling.LANCZOS)
        packed.append(normalized);spec.append({'frame':i+1,'size':list(normalized.size),'anchor':[320,600]})
    # Stage5 rollout preserves the preexisting sheet until this candidate meets all size constraints.
    candidate=S/'roll_candidate.png';clip=sheet(packed,'source_art/stage5/roll_candidate.png',[640,640],[320,600],.48,False,1)
    for i in [0,11]:assert abs(packed[i].height-363)<=363*.03
    for p in packed[1:7]:assert p.width<=300 and p.height<=220
    legacy=A/'sprites/_legacy_player/roll_prev.png'
    if not legacy.exists():shutil.copyfile(A/'sprites/roll.png',legacy)
    shutil.copyfile(candidate,A/'sprites/roll.png');clip['sheet']='sprites/roll.png';clip['name']='roll'
    m=json.loads((A/'animation_manifest.json').read_text());m['clips']=[clip if c['name']=='roll' else c for c in m['clips']];save(A/'animation_manifest.json',m)
    pv=json.loads((R/'data/player_visuals.json').read_text());next(c for c in pv['clips'] if c['name']=='roll')['frames']=12;save(R/'data/player_visuals.json',pv)
    save(S/'roll_packing.json',spec)
def main():
    p=argparse.ArgumentParser();p.add_argument('part',choices=['world','enemies','roll','all']);args=p.parse_args()
    if args.part in ['world','all']:world()
    if args.part in ['enemies','all']:enemies()
    if args.part in ['roll','all']:roll()
    m=json.loads((A/'art_manifest.json').read_text());entries={e['path']:e for e in m['assets']};entries.update({e['path']:e for e in ENTRIES});m['assets']=list(entries.values());m['sprite_manifests']=list(dict.fromkeys(m['sprite_manifests']+MANIFESTS));save(A/'art_manifest.json',m)
    for e in ENTRIES:(A/'image_prompts'/('stage5_'+Path(e['path']).stem+'.md')).write_text(f'# {e["name"]}\n목적: 5단계 환경. 경로: assets/{e["path"]}\n크기: {e["width"]}x{e["height"]}, 1프레임. 배경: {"불투명" if not e["transparent"] else "#FF00FF 크로마키"}.\n\n{PREFIX}. {e["name"].replace("_"," ")}, side-view production game asset.\n')
    print('Stage5 packed:',args.part)
if __name__=='__main__':main()
