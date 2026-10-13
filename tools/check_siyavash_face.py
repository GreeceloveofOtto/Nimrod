#!/usr/bin/env python3
"""Pixel ROI QA for generated Siyavash art, plus explicit human anatomy review.

Color/region checks are measurable; they do not claim to identify two incisors
or anatomical beauty automatically. Those remain documented contact-sheet QA.
"""
import argparse,json,sys
from pathlib import Path
import numpy as np
from PIL import Image
from check_sprite_frames import frame_images
ROOT=Path(__file__).resolve().parents[1]

def crop(im,xy,radius,offset=(-1,-1,1,1)):
    x,y=xy;r=max(2,radius)
    return im.crop(tuple(round(v) for v in (x+offset[0]*r,y+offset[1]*r,x+offset[2]*r,y+offset[3]*r)))

def inspect(im,mark,name,index):
    errors=[]
    cheek=crop(im,mark['cheek_xy'],mark['cheek_radius'])
    hsv=np.array(cheek.convert('HSV'));alpha=np.array(cheek)[:,:,3]
    valid=alpha>200
    saturation=float(hsv[:,:,1][valid].mean()/255) if valid.any() else 0
    hue=float(np.median(hsv[:,:,0][valid])/255) if valid.any() else 0
    if saturation<.42:errors.append('cheek saturation below 0.42')
    if name in ['hurt','death']:
        if not (hue<.06 or hue>.99):errors.append('injured cheek is not scarlet')
    elif not .90<hue<.995:errors.append('normal/exertion cheek is not rose-red')
    mouth=crop(im,mark['cheek_xy'],mark['cheek_radius'],(-1,.8,4,5))
    a=np.array(mouth);h=np.array(mouth.convert('HSV'))
    tooth_pixels=int(((a[:,:,3]>200)&(h[:,:,2]>175)&(h[:,:,1]<35)).sum())
    if name not in ['hurt','death'] and tooth_pixels>0:errors.append('white tooth-like pixels in normal mouth ROI')
    if name=='death' and index==7 and hsv[:,:,2][valid].max()>210:errors.append('final cheek highlight is still luminous')
    return errors,{'hsv_saturation_mean':saturation,'hue':hue,'mouth_white_pixels':tooth_pixels}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',default='archive/siyavash_redesign_2026-10-14/face_qa.json');parser.add_argument('--self-test',action='store_true');args=parser.parse_args()
    manifest=json.loads((ROOT/'assets/sprites/player/siyavash/manifest.json').read_text())
    rows=[];errors=[];idle_saturation=[]
    for clip in manifest['clips']:
        frames=frame_images(ROOT/'assets'/clip['sheet'],clip)
        marks=clip.get('face_landmarks',[])
        if len(marks)!=len(frames):errors.append(clip['name']+': missing face landmarks');continue
        local=[]
        for i,(im,mark) in enumerate(zip(frames,marks)):
            failures,metrics=inspect(im,mark,clip['name'],i)
            rows.append({'clip':clip['name'],'frame':i,'errors':failures,**metrics})
            errors.extend(f'{clip["name"]}/{i+1}: {f}' for f in failures)
            local.append(metrics)
            if clip['name']=='idle':idle_saturation.append(metrics['hsv_saturation_mean'])
        if clip['name'] in ['hurt','death'] and not any(r['mouth_white_pixels'] for r in local):errors.append(clip['name']+': no clenched-mouth highlight survives storage')
        if clip['name']=='idle':
            for i,im in enumerate(frames):
                mark=marks[i];x,y=mark['cheek_xy'];r=max(2,mark['cheek_radius'])
                eye=crop(im,[x,y],r,(.7,-3,3.5,-.3));h=np.array(eye.convert('HSV'))
                if not ((h[:,:,0]>65)&(h[:,:,0]<140)&(h[:,:,1]>25)&(h[:,:,2]<170)).any():errors.append(f'idle/{i+1}: gray-green iris color not readable')
                head=crop(im,[x,y],r,(-6,-8,2,0));p=np.array(head)
                dark=(p[:,:,3]>200)&(p[:,:,:3].max(axis=2)<110)
                if dark.sum()<10 or float((p[:,:,2][dark].astype(float)-p[:,:,0][dark]).mean())<2:errors.append(f'idle/{i+1}: dark hair lacks subtle blue bias')
                bbox=im.getchannel('A').getbbox();height=bbox[3]-bbox[1]
                # The gold embroidered hem is a horizontal band above the knee.
                p=np.array(im);rr,gg,bb=[p[:,:,q].astype(float) for q in range(3)]
                gold=(p[:,:,3]>200)&(rr>110)&(gg>70)&(bb<gg*.8)&(rr>gg*1.1)
                region=gold[bbox[1]+round(height*.40):bbox[1]+round(height*.63),bbox[0]:bbox[2]]
                if not region.any() or region.sum(axis=1).max()<max(8,(bbox[2]-bbox[0])*.22):errors.append(f'idle/{i+1}: short embroidered hem is not above knee')
    baseline=.4570940170940171 # measured old idle cheek ROI [340,270,355,283]
    if not idle_saturation or float(np.mean(idle_saturation))<=baseline:errors.append('idle cheek saturation did not improve over archived baseline')
    old_spelling='시야우와르'+'산'
    candidates=[ROOT/'README_KO.txt']
    for directory in ['data','scripts','tests','docs','tools']:
        candidates.extend(p for p in (ROOT/directory).rglob('*') if p.suffix in ['.json','.gd','.md','.txt','.py'])
    for path in candidates:
        if path.is_file() and old_spelling in path.read_text():errors.append('obsolete display spelling: '+str(path.relative_to(ROOT)))
    if args.self_test:
        clip=next(c for c in manifest['clips'] if c['name']=='idle')
        original=frame_images(ROOT/'assets'/clip['sheet'],clip)[0];mark=clip['face_landmarks'][0]
        desaturated=original.convert('RGB').convert('HSV');p=np.array(desaturated);p[:,:,1]=0
        faded=Image.fromarray(p,'HSV').convert('RGBA');faded.putalpha(original.getchannel('A'))
        assert any('saturation' in e for e in inspect(faded,mark,'idle',0)[0])
        fixture=np.array(original);x,y=mark['cheek_xy'];radius=max(2,mark['cheek_radius'])
        fixture[round(y+radius*2),round(x+radius*2)]=[240,240,240,255]
        assert any('tooth-like' in e for e in inspect(Image.fromarray(fixture),mark,'idle',0)[0])
        assert any('scarlet' in e for e in inspect(original,mark,'hurt',0)[0])
        print('FACE_SELF_TEST: faded cheek, normal teeth, incorrect injury hue rejected')
    out={'frames':len(rows),'errors':errors,'rows':rows,'old_idle_cheek_roi':[340,270,355,283],'old_idle_saturation_mean':baseline,'new_idle_saturation_mean':float(np.mean(idle_saturation)),'human_review':'Two-incisor anatomy, ear outline and hem semantics are additionally reviewed in docs/SIYAVASH_LOOK_KO.md; HSV checks alone do not prove anatomy.'}
    target=ROOT/args.output;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
    print(f'SIYAVASH_FACE: {len(rows)} frames, {len(errors)} errors')
    for error in errors:print('FAIL',error)
    return int(bool(errors))

if __name__=='__main__':sys.exit(main())
