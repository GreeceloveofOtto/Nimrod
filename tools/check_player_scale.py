#!/usr/bin/env python3
"""Verify the real replacement sprite silhouette, anchors and margins."""
import json
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
def check():
    config=json.loads((ROOT/'data/player_visuals.json').read_text());manifest=json.loads((ROOT/'assets/animation_manifest.json').read_text());errors=[];checks=0
    def expect(ok,message):
        nonlocal checks
        checks+=1
        if not ok:errors.append(message)
    expect(config['visual_scale']==.30 and config['anchor']==[320,600] and config['frame_size']==[640,640],'Player visual configuration changed')
    targets={c['name']:c for c in config['clips']};expect(len(manifest['clips'])==18,'All 18 clips required')
    for c in manifest['clips']:
        im=Image.open(ROOT/'assets'/c['sheet']).convert('RGBA');t=targets[c['name']]
        expect(c['frames']==t['frames'] and c['duration_seconds']==t['duration'],'Timing/count mismatch '+c['name'])
        expect(c['anchor_px']==[320,600] and im.size==(640*c['frames'],640),'Frame/anchor mismatch '+c['name'])
        for i in range(c['frames']):
            b=im.crop((640*i,0,640*(i+1),640)).getchannel('A').getbbox()
            expect(b is not None and min(b[0],b[1],640-b[2],640-b[3])>=8,f"{c['name']} frame {i+1} clipped")
            expect(b is not None and b[3]==600,f"{c['name']} frame {i+1} bottom anchor drift")
        if c['name']=='idle':
            b=im.crop((0,0,640,640)).getchannel('A').getbbox();height=b[3]-b[1]
            expect(abs(height-config['reference_height_px'])<=config['reference_height_px']*.03,'Standing height changed')
            print(f"PLAYER HEIGHT: before {config['before_height_px']}px, after {height}px, alpha>0 bbox {b}")
    print(f'PLAYER_SCALE: {checks} checks, {len(errors)} failures')
    for error in errors:print('FAIL:',error)
    return not errors

if __name__=='__main__':raise SystemExit(0 if check() else 1)
