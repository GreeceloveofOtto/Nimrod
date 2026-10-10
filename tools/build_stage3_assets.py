#!/usr/bin/env python3
"""Repack stage-three image-generated assets; only explicit rim/breathing is derived."""
import json, tempfile, shutil
from pathlib import Path
from types import SimpleNamespace
from PIL import Image
from pack_sprites import chromakey,foreground,cell_box,pack_image,pack_sheet,component_poses
from build_stage2_character_assets import pack
from make_breathing_sheet import breathing_sheet
from add_rim_light import add_rim_light
ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets'
SOURCE=ASSETS/'source_art/stage3'
PROMPTS=json.loads((SOURCE/'generation_prompts.json').read_text())
ENTRIES=[]


def image(source,box,out,size,transparent=True,trim=False,tile=False,**extra):
    args=SimpleNamespace(source=SOURCE/source,output=ASSETS/out,crop=(box[0],box[1],box[2]-box[0],box[3]-box[1]),size=size,trim=trim,opaque=not transparent,tile_x=32 if tile else 0)
    pack_image(args)
    ENTRIES.append(dict(name=Path(out).stem,path=out,width=size[0],height=size[1],transparent=transparent,**({'tile_x':True} if tile else {}),**extra))


def sheet(poses,out,size,duration):
    cell_w=max(p.width for p in poses)+16;cell_h=max(p.height for p in poses)+16
    atlas=Image.new('RGBA',(cell_w*len(poses),cell_h))
    for i,pose in enumerate(poses):atlas.alpha_composite(pose,(i*cell_w+8,8))
    with tempfile.TemporaryDirectory(prefix='stage3-door-') as temp:
        src=Path(temp)/'poses.png';atlas.save(src)
        scale=min((size[0]-8)/max(p.width for p in poses),(size[1]-4)/max(p.height for p in poses))
        args=SimpleNamespace(source=src,output=ASSETS/out,crop=None,frames=len(poses),grid_cols=len(poses),grid_rows=1,column=0,row=0,reference_column=0,reference_row=0,auto_cells=False,boxes=None,components=False,fit=(size[0]-8,size[1]-4),scale=scale,scale_xy=None,frame_width=size[0],frame_height=size[1],anchor=(size[0]//2,size[1]),alignment='bottom-center',reverse=False,flip_frames=[],cell_gap=3)
        pack_sheet(args)
    n=len(poses)
    return dict(name=Path(out).stem,sheet=out,frame_width=size[0],frame_height=size[1],columns=n,rows=1,frames=n,duration_seconds=duration,fps=n/duration,loop=False,anchor_px=[size[0]//2,size[1]],image_size=[size[0]*n,size[1]])


def main():
    ids=['lugalbanda','ninsun','shamhat','inanna','papsukkal']
    stats={n['id']:n for n in json.loads((ROOT/'data/npcs.json').read_text())['npcs']}
    source=chromakey(Image.open(SOURCE/'npc_stills_atlas.png'))
    for id,pose in zip(ids,component_poses(source,5)):
        folder=ASSETS/'sprites/npcs'/id;legacy=ASSETS/'sprites/npcs/_legacy'/id;legacy.mkdir(parents=True,exist_ok=True)
        for name in ['idle.png','manifest.json']:
            if not (legacy/name).exists():shutil.copyfile(folder/name,legacy/name)
        still=SOURCE/(id+'_still.png');pack([pose],still,round(359*stats[id]['height_ratio'])/pose.height)
        add_rim_light(Image.open(still)).save(still);breathing_sheet(still,folder/'idle.png')
        m=json.loads((folder/'manifest.json').read_text());m['height_ratio']=stats[id]['height_ratio'];m['design_reference']='reference/'+id+'_design.png';m['style']='Stage3 near-future tailored clothing; generated still + permitted breathing/rim postprocess'
        (folder/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n')
    # Reuse worker poses; only the explicitly permitted inner rim is added.
    # Always read preserved originals so rebuilding cannot accumulate brightness.
    for id in ['cook_a','cook_b','cook_c','servant_a','servant_b','gatekeeper']:
        folder=ASSETS/'sprites/npcs'/id
        legacy=ASSETS/'sprites/npcs/_legacy'/id
        legacy.mkdir(parents=True,exist_ok=True)
        for clip in stats[id]['clips']:
            name=clip['name']+'.png'
            if not (legacy/name).exists():shutil.copyfile(folder/name,legacy/name)
            add_rim_light(Image.open(legacy/name)).save(folder/name)
    # Atlas separators are excluded; no new pixels are painted.
    for (name,width,ratio,opaque),box in zip([('sky',1536,0.05,True),('far_city',2048,0.2,False),('castle_wall',2816,0.45,False),('foreground',3840,0.8,False)],[(0,0,1254,310),(0,312,1254,627),(0,628,1254,940),(0,942,1254,1254)]):
        image('layers_atlas.png',box,'backgrounds/castle_front/'+name+'.png',(width,720),not opaque,scroll_ratio=ratio,map_width=4400)
    image('facades_atlas.png',(0,0,1448,537),'backgrounds/castle_front/downtown_passage_facade.png',(1100,720))
    image('facades_atlas.png',(0,542,1448,1045),'backgrounds/castle_front/castle_facade.png',(1500,720))
    prop=Image.open(SOURCE/'props_atlas.png')
    specs=[('castle_gate_wall_left',(0,0,724,414),(420,600)),('castle_gate_wall_right',(724,0,1448,414),(420,600)),('castle_front_brazier',(0,414,483,873),(180,200)),('castle_front_statue',(483,414,965,873),(230,320)),('castle_front_lamp_post',(965,414,1448,873),(150,260))]
    for name,box,size in specs:image('props_atlas.png',box,'props/'+name+'.png',size,trim=True)
    for name,box in [('ground_tile',(26,907,704,1054)),('courtyard_tile',(750,907,1420,1054))]:image('props_atlas.png',box,'tiles/castle_front/'+name+'.png',(512,200),False,True,True)
    # Remove two legacy tiles' tiny magenta top margin using their existing
    # generated source. No old background image is regenerated or repainted.
    for name,box in [('floor_tile',(12,88,1436,346)),('balcony_floor_tile',(12,435,1436,694))]:
        image('../stage2_environment/tiles.png',box,'tiles/castle/'+name+'.png',(512,180),False,False,True)
    image('fx_atlas.png',(0,0,1448,766),'fx/npc_light_pool.png',(512,256),trim=True)
    image('fx_atlas.png',(0,766,1448,1086),'fx/contact_shadow.png',(256,64),trim=True)
    doors=chromakey(Image.open(SOURCE/'doors_atlas.png'))
    clips=[]
    for name,box,frames,size in [('castle_front_door_interior',(0,22,1254,266),6,(320,420)),('castle_front_door_exterior',(0,297,1254,573),6,(360,460)),('downtown_passage_door',(0,856,270,1230),1,(320,460))]:
        strip=doors.crop(box)
        poses=[foreground(strip.crop(cell_box(strip,frames,1,i,0)))[0] for i in range(frames)]
        clips.append(sheet(poses,'props/doors/'+name+'.png',size,0.6))
    if (SOURCE/'great_gate_atlas.png').is_file():
        great=chromakey(Image.open(SOURCE/'great_gate_atlas.png'))
        poses=[foreground(great.crop(cell_box(great,4,2,i%4,i//4)))[0] for i in range(8)]
    else:
        strip=doors.crop((0,611,1254,843));poses=[foreground(strip.crop(cell_box(strip,8,1,i,0)))[0] for i in range(8)]
    clips.append(sheet(poses,'props/doors/castle_great_gate.png',(640,520),1.2))
    (ASSETS/'props/doors/stage3_manifest.json').write_text(json.dumps({'clips':clips},indent=2)+'\n')
    # Preserve all four Inanna candidates and the five selected design sheets.
    for name in ['lugalbanda','ninsun','shamhat','papsukkal']:
        path=ASSETS/'reference'/(name+'_design.png');im=Image.open(path).convert('RGBA');im.save(path)
    for name in ['inanna_design']+['inanna_candidate_'+str(i) for i in range(1,5)]:
        path=ASSETS/'reference'/(name+'.png');im=Image.open(path).convert('RGBA');im.save(path)
    for p in sorted((ASSETS/'reference').glob('*.png')):
        im=Image.open(p);ENTRIES.append(dict(name=p.stem,path=str(p.relative_to(ASSETS)),width=im.width,height=im.height,transparent=False))
    master=json.loads((ASSETS/'art_manifest.json').read_text())
    master['sprite_manifests']=list(dict.fromkeys(master['sprite_manifests']+['props/doors/stage3_manifest.json']))
    entries={a['path']:a for a in master['assets']};entries.update({a['path']:a for a in ENTRIES});master['assets']=list(entries.values())
    master['source_metadata']=list(dict.fromkeys(master['source_metadata']+['source_art/stage3/generation_prompts.json']))
    (ASSETS/'art_manifest.json').write_text(json.dumps(master,ensure_ascii=False,indent=2)+'\n')
    # Asset prompts describe the actual original generation request.
    for entry in ENTRIES+clips:
        out=entry.get('path',entry.get('sheet'))
        key='doors' if '/doors/' in out else ('layers' if '/castle_front/' in out and Path(out).stem in ['sky','far_city','castle_wall','foreground'] else 'facades' if 'facade' in out else 'fx' if out.startswith('fx/') else 'inanna' if 'inanna' in out else 'design' if out.startswith('reference/') else 'props')
        if Path(out).stem=='castle_great_gate':key='great_gate'
        text=f"# {Path(out).stem}\n\n목적: 3단계 게임 에셋.\n경로: assets/{out}\n규격: {entry.get('image_size',[entry.get('width'),entry.get('height')])}, 프레임 {entry.get('frames',1)}.\n배경: 투명 스프라이트는 #FF00FF 크로마키, FX는 생성 알파 보존, 하늘·타일·디자인은 불투명.\n후처리: crop/resize/anchor/pack, 타일은 원본 경계 블렌드만.\n\n완성 프롬프트:\n\n{PROMPTS[key]}\n"
        (ASSETS/'image_prompts'/('stage3_'+Path(out).stem+'.md')).write_text(text)
    for id in ids:
        (ASSETS/'image_prompts'/('stage3_'+id+'_idle.md')).write_text(f"# {id} idle\n\n목적: 근미래 NPC 숨쉬기. 경로: assets/sprites/npcs/{id}/idle.png\n640x640 × 6, 2.4초 루프, 오른쪽, 발 앵커 [320,600], 투명.\n생성 정지 이미지를 pack_sprites.py로 크로마키·앵커 정렬 후 make_breathing_sheet.py, add_rim_light.py 5px/40% 후처리.\n\n{PROMPTS['sprite']}\n")
    print('Stage-three packing complete: 5 replaced NPC sheets, 19 new world/FX assets, 9 reference designs.')

if __name__=='__main__':main()
