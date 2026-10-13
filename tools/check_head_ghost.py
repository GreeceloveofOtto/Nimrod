#!/usr/bin/env python3
"""Audit real cell gutters and disconnected alpha above the authored head region."""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[1]
RULES=json.loads((ROOT/'data/head_ghost.json').read_text()) if (ROOT/'data/head_ghost.json').exists() else {'head_above_px':60,'head_half_width_px':80}

def audit(path,spec):
    from check_sprite_frames import frame_images
    physical=np.array(Image.open(path).convert('RGBA'))[:,:,3]
    cell=spec.get('stored_cell',[spec['frame_width'],spec['frame_height']]);cw,ch=cell
    count=spec.get('stored_columns',spec['frames']);errors=[];head_rows=[]
    for i in range(count):
        a=physical[:ch,i*cw:(i+1)*cw]
        if min(a.shape)<4:errors.append(f'{i+1}: invalid cell');continue
        if a[:2].any() or a[-2:].any() or a[:,:2].any() or a[:,-2:].any():
            errors.append(f'{i+1}: cell edge contact/neighbor sampling risk')
    frames=frame_images(path,spec)
    for i,im in enumerate(frames):
        a=np.array(im.getchannel('A'))>12;ys,xs=np.where(a)
        if not len(xs):continue
        head=spec.get('qa',{}).get('head_top_px',[])
        top=int(head[i]) if head else int(ys.min()+45)
        center=spec.get('qa',{}).get('head_center_x_px',[])
        x=int(center[i]) if center else int(spec['anchor_px'][0])
        roi=a[max(0,top-RULES['head_above_px']):min(im.height,top+1),max(0,x-RULES['head_half_width_px']):min(im.width,x+RULES['head_half_width_px']+1)]
        labels,_=ndimage.label(a,structure=np.ones((3,3)))
        ids=np.unique(labels[max(0,top-RULES['head_above_px']):min(im.height,top+1),max(0,x-RULES['head_half_width_px']):min(im.width,x+RULES['head_half_width_px']+1)])
        size=np.bincount(labels.ravel());body=int(np.argmax(size[1:])+1)
        detached=[int(k) for k in ids if k and k!=body and size[k]>=4]
        head_rows.append({'frame':i+1,'head_roi':[x-RULES['head_half_width_px'],top-RULES['head_above_px'],x+RULES['head_half_width_px'],top],'detached_alpha_components':detached,'occupied_head_pixels':int(roi.sum())})
        # Weapons and effects in attack/turn poses are reviewed separately, never erased.
        if detached and head and not spec.get('qa',{}).get('head_detached_weapon_or_fx',False):
            errors.append(f'{i+1}: detached alpha above the authored head: {detached}')
    return {'errors':errors,'head_regions':head_rows,'neighbor_alpha_overlap':bool(errors),'stored_frames':count,'logical_frames':len(frames)}

def self_test():
    import tempfile
    with tempfile.TemporaryDirectory() as directory:
        path=Path(directory)/'fixture.png'
        # Artificial alpha is a QA fixture only, never game artwork.
        im=Image.new('RGBA',(100,100));a=np.zeros((100,100,4),dtype=np.uint8)
        a[50:85,40:60]=255
        spec={'frames':1,'frame_width':100,'frame_height':100,'anchor_px':[50,85],'qa':{'head_top_px':[50],'head_center_x_px':[50]}}
        Image.fromarray(a).save(path);assert not audit(path,spec)['errors']
        a[25:30,45:50]=255;Image.fromarray(a).save(path);assert any('detached' in x for x in audit(path,spec)['errors'])
        a[0,50]=255;Image.fromarray(a).save(path);assert any('edge contact' in x for x in audit(path,spec)['errors'])
    print('HEAD_GHOST_SELF_TEST: clean accepted; detached head and dirty gutter rejected')

def main():
    p=argparse.ArgumentParser();p.add_argument('--phase',default='after');a=p.parse_args();rows=[]
    self_test()
    for mp in sorted(list((ROOT/'assets/sprites/player').glob('*/manifest.json'))+[ROOT/'assets/sprites/enemies'/i/'manifest.json' for i in ['ninazu_mother','lilith','zu'] if (ROOT/'assets/sprites/enemies'/i/'manifest.json').exists()]):
        d=json.loads(mp.read_text())
        for c in d.get('clips',[]):
            path=ROOT/'assets'/c['sheet'];r=audit(path,c);rows.append({'path':str(path.relative_to(ROOT)),**r})
    folder=ROOT/'tests/artifacts/head_ghost'/a.phase;folder.mkdir(parents=True,exist_ok=True)
    (folder/'audit.json').write_text(json.dumps(rows,indent=2))
    from check_sprite_frames import frame_images
    for cell in folder.glob('*_cell.png'):
        Image.open(cell).getchannel('A').save(cell.with_name(cell.stem+'_alpha.png'))
    fail=sum(len(r['errors']) for r in rows)
    print(f'HEAD_GHOST: {len(rows)} player/boss clips, {fail} border/detached-head failures')
    return int(bool(fail))
if __name__=='__main__':raise SystemExit(main())
