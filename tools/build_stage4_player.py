#!/usr/bin/env python3
"""Extract independently image-generated motion poses; validate before replacing."""
import json, shutil, argparse
from pathlib import Path
from PIL import Image
from pack_sprites import chromakey, foreground, component_poses
from build_stage2_character_assets import pack, clip

ROOT=Path(__file__).resolve().parents[1];A=ROOT/'assets';S=A/'source_art/stage4';STAGE=S/'player_staged'
GROUPS={
    'locomotion': [('idle',10),('walk',10),],
    'crouch':[('crouch_enter',4),('crouch_idle',6),('crouch_exit',4)],
    'airborne':[('jump_start',4),('jump_rise',6),('fall',6)],
    'responses':[('land',5),('drop_through',5),('hurt',5),('death',8)],
    'attack_1':[('attack_1',8)], 'attack_2':[('attack_2',8)],
    'attack_3':[('attack_3',10)], 'attack_4':[('attack_4',10)],
    'run':[('run',10)],
    'roll':[('roll',10)]}

def main(apply=False):
    settings=json.loads((ROOT/'data/player_visuals.json').read_text());timings={c['name']:c for c in settings['clips']}
    STAGE.mkdir(parents=True,exist_ok=True);manifest={'step':12,'frame_size':[640,640],'clips':[]};provenance={}
    for group,rows in GROUPS.items():
        path=S/(group+('_clean_atlas.png' if group in ['attack_1','attack_4'] else '_atlas.png'))
        if not path.exists():raise ValueError('Generated source missing: '+str(path))
        source=chromakey(Image.open(path));extracted=[]
        if group in ['attack_1','attack_4']:
            cuts=[0,410,780,1096,1536] if group=='attack_1' else [0,322,650,923,1155,1536]
            poses=[]
            for top,bottom in zip(cuts,cuts[1:]):poses.extend(component_poses(source.crop((0,top,source.width,bottom)),2))
            if group=='attack_1':
                ready=foreground(chromakey(Image.open(S/'attack_1_atlas.png').crop((1160,512,1536,1024))))[0]
                ready=ready.resize((round(ready.width*poses[-1].height/ready.height),poses[-1].height),Image.Resampling.LANCZOS)
                poses[-1]=ready
            if group=="attack_4":
                strike_source=chromakey(Image.open(S/"attack_1_clean_atlas.png"))
                poses[3]=component_poses(strike_source.crop((0,410,strike_source.width,780)),2)[0]
            extracted=[poses]
        elif group=='roll' or group=='run' or group.startswith('attack_'):
            for row in range(2):extracted.extend(component_poses(source.crop((0,round(row*source.height/2),source.width,round((row+1)*source.height/2))),rows[0][1]//2))
            extracted=[extracted]
        else:
            for row,(_,count) in enumerate(rows):
                cuts={'locomotion':[0,280,536], 'crouch':[0,360,630,1024], 'airborne':[0,330,660,1024]}.get(group)
                top,bottom=(cuts[row],cuts[row+1]) if cuts else (round(row*source.height/len(rows)),round((row+1)*source.height/len(rows)))
                strip=source.crop((0,top,source.width,bottom))
                extracted.append(component_poses(strip,count))
        if group=='run':
            height=extracted[0][0].height
            extracted[0]=[p.resize((round(p.width*height/p.height),height),Image.Resampling.LANCZOS) for p in extracted[0]]
        if group in ['locomotion','crouch']:scale=363/extracted[0][0].height
        elif group=='responses':scale=363/extracted[0][-1].height
        elif group=='airborne':scale=363/(source.height/3-14)
        elif group.startswith('attack_'):scale=363/extracted[0][-1].height
        elif group=='run':scale=320/extracted[0][0].height
        else:scale=363/extracted[0][-1].height
        # Keep the atlas-wide character scale. Wide action poses may need a
        # smaller source-to-frame scale to preserve every painted axe pixel.
        max_width=max(p.width for row in extracted for p in row);max_height=max(p.height for row in extracted for p in row)
        scale=min(scale,620/max_width,588/max_height)
        for (name,count),poses in zip(rows,extracted):
            out=STAGE/(name+'.png');pack(poses,out,scale)
            if name=='roll':
                compact=component_poses(chromakey(Image.open(S/'roll_compact_atlas.png')),5)
                compact_scale=160/max(p.height for p in compact)
                temporary=STAGE/'roll_compact.png';pack(compact,temporary,compact_scale)
                combined=Image.open(out).convert('RGBA');compact_sheet=Image.open(temporary).convert('RGBA')
                for i in range(5):
                    # Paste a newly generated complete frame; never warp a pose.
                    combined.paste(compact_sheet.crop((i*640,0,(i+1)*640,640)),((i+1)*640,0))
                combined.save(out);temporary.unlink()
            t=timings[name];c=clip(name,'sprites/'+name+'.png',count,t['duration'],t['loop'])
            if name=='roll':c['frame_boundaries_seconds']=[0,.03,.08,.13,.18,.23,.28,.33,.38,.43,.48]
            if name=='attack_4':c['frame_boundaries_seconds']=[0,.056,.112,.168,.224,.28,.34,.396,.452,.508,.56]
            manifest['clips'].append(c);provenance[name]={'source':str(path.relative_to(A)),'scale':scale,'source_pose_sizes':[list(p.size) for p in poses]}
            if name=='attack_1':provenance[name]['frame_8_source']='source_art/stage4/attack_1_atlas.png; crop (1160,512,1536,1024), scale to preceding ready pose height'
            if name=='attack_4':provenance[name]['frame_4_source']='source_art/stage4/attack_1_clean_atlas.png; second row first generated descending strike pose'
            if name=='run':provenance[name]['normalization']='Uniformly resize each complete generated pose to the first source pose height; packed height 320px'
            if name=='roll':provenance[name]['compact_frames']={'frames':[2,3,4,5,6],'source':'source_art/stage4/roll_compact_atlas.png','scale':compact_scale,'maximum_packed_height_px':160}
    # Every requested frame must exist, fit margins, be transparent and differ.
    for c in manifest['clips']:
        im=Image.open(STAGE/(c['name']+'.png'));previous=None
        for i in range(c['frames']):
            f=im.crop((i*640,0,(i+1)*640,640));bbox=f.getchannel('A').getbbox()
            if not bbox or bbox[0]<8 or bbox[1]<8 or bbox[2]>632 or bbox[3]>632:raise ValueError(f"{c['name']} frame {i+1}: missing/clipped art {bbox}")
            if previous==f.tobytes():raise ValueError(f"{c['name']} repeated pose {i+1}")
            previous=f.tobytes()
    idle=Image.open(STAGE/'idle.png').crop((0,0,640,640));b=idle.getchannel('A').getbbox();height=b[3]-b[1]
    if abs(height-363)>363*.03:raise ValueError(f'Idle height {height} outside 363±3%')
    (STAGE/'animation_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');(S/'player_packing.json').write_text(json.dumps(provenance,indent=2)+'\n')
    if apply:
        legacy=A/'sprites/_legacy_player';legacy.mkdir(parents=True,exist_ok=True);(legacy/'.gdignore').touch()
        if not (legacy/'animation_manifest.json').exists():shutil.copyfile(A/'animation_manifest.json',legacy/'animation_manifest.json')
        for c in manifest['clips']:
            name=c['name']+'.png'
            if not (legacy/name).exists():shutil.copyfile(A/'sprites'/name,legacy/name)
            shutil.copyfile(STAGE/name,A/'sprites'/name)
        shutil.copyfile(STAGE/'animation_manifest.json',A/'animation_manifest.json')
        settings['status']='generated_validated_applied';settings['after_height_px']=height;settings['after_bounds']=list(b)
        (ROOT/'data/player_visuals.json').write_text(json.dumps(settings,ensure_ascii=False,indent=2)+'\n')
    print(f'PLAYER STAGED PASS: 18 clips, idle alpha>0 height {height}px; applied={apply}')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--apply',action='store_true');args=parser.parse_args();main(args.apply)
