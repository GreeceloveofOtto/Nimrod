#!/usr/bin/env python3
"""Pack image-generated stage-four art. No drawing or procedural art generation."""
import json, tempfile, shutil
from pathlib import Path
from types import SimpleNamespace
from PIL import Image
from pack_sprites import pack_image, chromakey, foreground, cell_box, component_poses
from build_stage2_character_assets import pack, clip
from make_breathing_sheet import breathing_sheet
from add_rim_light import add_rim_light

ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'assets'; S=A/'source_art/stage4'; ENTRIES=[]
WORLD='2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark'
PERSON='2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark'

def save_json(path,data):
    path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def image(src,box,out,size,opaque=False,trim=False,tile=False,tile_y=False,**extra):
    args=SimpleNamespace(source=S/src,output=A/out,crop=(box[0],box[1],box[2]-box[0],box[3]-box[1]),size=size,opaque=opaque,trim=trim,tile_x=32 if tile else 0)
    pack_image(args)
    if tile_y:
        # Blend only existing edge pixels vertically, then restore horizontal seam.
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp)/'transpose.png';Image.open(A/out).transpose(Image.Transpose.TRANSPOSE).save(p)
            args.source=p;args.crop=None;args.size=None;args.trim=False;args.tile_x=32;pack_image(args)
            Image.open(A/out).transpose(Image.Transpose.TRANSPOSE).save(p)
            args.source=p;pack_image(args)
    ENTRIES.append(dict(name=Path(out).stem,path=out,width=size[0],height=size[1],transparent=not opaque,**({'tile_x':True} if tile else {}),**({'tile_y':True} if tile_y else {}),**extra))

def npc_pose(id,pose,name,ratio):
    still=S/f'{id}_{name}_packed.png'
    pack([pose],still,round(363*ratio)/pose.height)
    add_rim_light(Image.open(still)).save(still)
    folder=A/'sprites/npcs'/id;folder.mkdir(parents=True,exist_ok=True)
    breathing_sheet(still,folder/(name+'.png'))
    manifest=folder/'manifest.json'
    m=json.loads(manifest.read_text()) if manifest.exists() else {'character':id,'height_ratio':ratio,'clips':[]}
    m['clips']=[c for c in m['clips'] if c['name']!=name]+[clip(name,'sprites/npcs/'+id+'/'+name+'.png',6,2.4,True)]
    save_json(manifest,m)

def main():
    # Crops exclude atlas gutters; the underlying pixels were image-generated.
    for name,box,size,ratio,opaque,tile in [
        ('sky',(0,0,1254,260),(1792,720),.05,True,False),
        ('far_city_tile',(0,260,1254,539),(2048,720),.20,False,True),
        ('mid_ruins_tile',(0,539,1254,781),(2048,720),.45,False,True),
        ('far_landmark',(0,781,1254,1254),(900,720),.20,False,False)]:
        image('bg_atlas.png',box,'backgrounds/outskirts/'+name+'.png',size,opaque,tile=tile,scroll_ratio=ratio,**({'repeat_x':True} if tile else {}),**({'localized':True} if name=='far_landmark' else {'map_width':10000}))
    for name,box,size in [
        ('ruin_wall_a',(0,0,470,465),(600,420)),('ruin_wall_b',(470,0,930,465),(480,360)),('broken_tower',(930,0,1254,465),(360,560)),
        ('chasm_edge_left',(0,465,627,763),(300,260)),('chasm_edge_right',(627,465,1254,763),(300,260)),
        ('collapsed_bridge',(0,780,1254,962),(960,180)),('upper_walkway',(0,975,1254,1254),(1000,120))]:
        image('ruins_atlas.png',box,'props/'+name+'.png',size,trim=True)
    for name,box,size in [('large_rubble_a',(0,0,500,768),(220,120)),('large_rubble_b',(500,0,825,768),(160,90)),('dead_tree',(825,0,1205,768),(240,380)),('crashed_pod_wreck',(1205,0,1880,768),(420,240)),('outskirts_lamp',(1880,0,2048,768),(100,260))]:
        image('props_atlas.png',box,'props/'+name+'.png',size,trim=True)
    for name,box,size,opaque in [('ground_tile',(12,125,618,261),(512,200),True),('plaza_tile',(638,125,1240,261),(512,200),True),('ruin_platform',(25,320,610,470),(256,48),False),('bridge_platform',(640,320,1240,470),(320,48),False),('ruin_ledge',(0,530,620,685),(480,56),False)]:
        image('tiles_atlas.png',box,'tiles/outskirts/'+name+'.png',size,opaque,trim=not opaque,tile=opaque)
    image('tiles_atlas.png',(644,515,1235,1210),'tiles/underground_fill.png',(512,512),True,tile=True,tile_y=True)
    for name,box,size,line in [('villa_f2_dining',(0,0,1448,532),(2200,720),475),('villa_f3_chamber',(0,548,1448,1086),(2000,720),466)]:
        source=Image.open(S/'villa_atlas.png').convert('RGBA').crop(box)
        # Move the generated floor seam to y620 by resizing its two painted regions.
        result=Image.new('RGBA',size);result.alpha_composite(source.crop((0,0,source.width,line)).resize((size[0],620)),(0,0));result.alpha_composite(source.crop((0,line,source.width,source.height)).resize((size[0],100)),(0,620));result.putalpha(255)
        out='backgrounds/villa/'+name+'.png';result.save(A/out) if (A/out).parent.exists() else ((A/out).parent.mkdir(parents=True),result.save(A/out))
        ENTRIES.append(dict(name=name,path=out,width=size[0],height=720,transparent=False))
    stats={n['id']:n for n in json.loads((ROOT/'data/npcs.json').read_text())['npcs']}
    for id in ['lugalbanda','ninsun','shamhat','inanna','papsukkal']:
        # Exact original previously generated design rows; first third is front pose.
        source=Image.open(A/'reference'/f'{id}_design.png');front=source.crop((0,0,source.width//3,source.height))
        front.save(A/'source_art/npc_front'/f'{id}_front.png')
        pose=foreground(chromakey(front))[0];npc_pose(id,pose,'idle_front',stats[id]['height_ratio'])
    # Preserve a faithful image-generated derivative of the conversation-only reference.
    source=Image.open(S/'nimrod_base_atlas.png');source.convert('RGBA').save(A/'reference/nimrod_design.png')
    poses=[foreground(chromakey(source.crop(cell_box(source,3,1,i,0))))[0] for i in range(3)]
    for name,pose in zip(['nimrod_base_right','nimrod_base_rear','nimrod_base_three_quarter'],poses):
        pack([pose],A/'reference'/f'{name}.png',363/pose.height)
    if (S/'couple_design_atlas.png').exists():
        source=Image.open(S/'couple_design_atlas.png')
        for row,id in enumerate(['shamash','aya']):
            design=source.crop(cell_box(source,1,2,0,row));design.convert('RGBA').save(A/'reference'/f'{id}_design.png')
            for col,name in [(0,'idle_front'),(1,'idle')]:
                pose=foreground(chromakey(design.crop((0,0,design.width//3,design.height) if col==0 else (design.width//3,0,round(design.width*.59),design.height))))[0];npc_pose(id,pose,name,stats[id]['height_ratio'])
    if (S/'villa_props_atlas.png').exists():
        source=Image.open(S/'villa_props_atlas.png');w,h=source.size
        for i,(name,size) in enumerate([('villa_dining_table_wide',(900,220)),('villa_chairs',(520,150)),('villa_sofa',(360,200)),('villa_side_table',(160,120))]):
            image('villa_props_atlas.png',([0,630,1095,1590][i],0,[630,1095,1590,w][i],h//2),'props/'+name+'.png',size,trim=True)
        from build_stage3_assets import sheet
        strip=chromakey(source.crop((0,h//2,w,h)));poses=[foreground(strip.crop(cell_box(strip,6,1,i,0)))[0] for i in range(6)]
        c=sheet(poses,'props/doors/villa_back_door.png',(320,420),.6);save_json(A/'props/doors/stage4_manifest.json',{'clips':[c]})
    master=json.loads((A/'art_manifest.json').read_text());entries={e['path']:e for e in master['assets']};entries.update({e['path']:e for e in ENTRIES})
    for path in (A/'reference').glob('nimrod*.png'):
        im=Image.open(path);entries[str(path.relative_to(A))]=dict(name=path.stem,path=str(path.relative_to(A)),width=im.width,height=im.height,transparent=path.name!='nimrod_design.png')
    for id in ['shamash','aya']:
        if (A/'reference'/f'{id}_design.png').exists():
            im=Image.open(A/'reference'/f'{id}_design.png');out=f'reference/{id}_design.png';entries[out]=dict(name=id+'_design',path=out,width=im.width,height=im.height,transparent=False)
            path=f'sprites/npcs/{id}/manifest.json'
            if path not in master['sprite_manifests']:master['sprite_manifests'].append(path)
    if (A/'props/doors/stage4_manifest.json').exists() and 'props/doors/stage4_manifest.json' not in master['sprite_manifests']:master['sprite_manifests'].append('props/doors/stage4_manifest.json')
    master['assets']=list(entries.values());save_json(A/'art_manifest.json',master)
    for e in ENTRIES:
        out=e['path'];(A/'image_prompts'/('stage4_'+Path(out).stem+'.md')).write_text(f"# {Path(out).stem}\n\n목적: 4단계 환경 이미지. 경로: assets/{out}\n크기: {e['width']}x{e['height']}, 1프레임.\n배경: {'불투명' if not e['transparent'] else '#FF00FF 크로마키 투명'}. 원본 source_art/stage4, crop/resize/기존 경계 블렌드만 사용.\n\n{WORLD}. Side-view Uruk wasteland / elegant villa, warm upper-left light; {Path(out).stem.replace('_',' ')}.\n")
    print('Stage4 generated environment and existing NPC fronts packed.')

if __name__=='__main__':main()
