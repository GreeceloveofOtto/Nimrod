#!/usr/bin/env python3
"""Uniform lossless per-sheet trim. Original frame and anchor stay authoritative.
Dry-run by default. Repeated apply is idempotent; originals are kept in archive.
"""
import argparse,copy,json,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]

def collect():
    specs={}; manifests=[]
    manifest_paths={ROOT/'assets/animation_manifest.json',*sorted((ROOT/'assets/sprites').rglob('manifest.json'))}
    manifest_paths.update(ROOT/'assets'/p for p in json.loads((ROOT/'assets/art_manifest.json').read_text())['sprite_manifests'])
    for p in sorted(manifest_paths):
        if any(x.startswith('_legacy') for x in p.parts):continue
        data=json.loads(p.read_text());manifests.append((p,data))
        for c in data.get('clips',[])+data.get('effects',[]):
            path=c['sheet'];path=path if path.startswith('res://') else 'res://assets/'+path if path.startswith(('sprites/','props/','fx/','tiles/','backgrounds/')) else 'res://'+str((p.parent/path).relative_to(ROOT))
            specs[path]=copy.deepcopy(c)
    # Door and FX descriptors are also used by AssetVisual's sheet registry.
    for p in (ROOT/'data').glob('*.json'):
        def walk(v):
            if isinstance(v,dict):
                path=v.get('path') or v.get('sheet') or v.get('art')
                size=v.get('frame_size');n=v.get('frames')
                if isinstance(path,str) and size and isinstance(n,int) and path.startswith('res://assets/'):
                    specs.setdefault(path,{'frame_width':size[0],'frame_height':size[1],'frames':n,'columns':n,'anchor_px':v.get('anchor',[size[0]/2,size[1]/2])})
                for x in v.values():walk(x)
            elif isinstance(v,list):
                for x in v:walk(x)
        walk(json.loads(p.read_text()))
    # Door definitions store art, frame_size and frame count in the world table.
    levels=json.loads((ROOT/'data/levels.json').read_text())
    for d in levels['world'].get('door_art',{}).values():
        if isinstance(d,dict):
            path=d.get('path',d.get('art',''));size=d.get('frame_size');n=d.get('frames')
            if path and size and n:specs[path]={'frame_width':size[0],'frame_height':size[1],'frames':n,'columns':n,'anchor_px':[size[0]/2,size[1]]}
    interactions=json.loads((ROOT/'data/interactions.json').read_text())
    for name,d in interactions['door_art'].items():
        path='res://assets/props/doors/'+name+'.png';size=d['frame_size'];n=d['frames']
        specs.setdefault(path,{'frame_width':size[0],'frame_height':size[1],'frames':n,'columns':n,'anchor_px':[size[0]/2,size[1]]})
    return specs,manifests

def trim(im,s):
    w,h,n=s['frame_width'],s['frame_height'],s['frames'];assert im.size==(w*n,h),(im.size,w,h,n)
    boxes=[im.crop((i*w,0,(i+1)*w,h)).getchannel('A').getbbox() for i in range(n)]
    assert all(boxes),'Empty source frame'
    x=max(0,min(b[0] for b in boxes)-2);y=max(0,min(b[1] for b in boxes)-2)
    right=min(w,max(b[2] for b in boxes)+2);bottom=min(h,max(b[3] for b in boxes)+2)
    tw,th=right-x,bottom-y;out=Image.new('RGBA',(tw*n,th))
    for i in range(n):out.paste(im.crop((i*w+x,y,i*w+right,bottom)),(i*tw,0))
    return out,{'x':x,'y':y,'w':tw,'h':th}

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');a=p.parse_args();specs,manifests=collect();registry={};records=[]
    for path,s in specs.items():
        if Path(path).stem in ['chain_segment','chain_hook','bone_arrow']:continue
        f=ROOT/path.removeprefix('res://')
        if not f.is_file():continue
        if s.get('trim'):registry[path]=s;continue
        im=Image.open(f).convert('RGBA')
        try:out,t=trim(im,s)
        except AssertionError as e:raise ValueError(f'{path}: {e}')
        s['trim']=t;s['image_size']=list(out.size);registry[path]=s
        records.append({'path':path,'original':list(im.size),'trimmed':list(out.size),'trim':t})
        if a.apply:
            back=ROOT/'archive/untrimmed'/f.relative_to(ROOT);back.parent.mkdir(parents=True,exist_ok=True)
            if not back.exists():shutil.copy2(f,back)
            out.save(f,'WEBP',lossless=True,quality=100,method=6,exact=True) if f.suffix=='.webp' else out.save(f,optimize=True)
    if a.apply:
        for p,data in manifests:
            for c in data.get('clips',[])+data.get('effects',[]):
                key=c['sheet'];key=key if key.startswith('res://') else 'res://assets/'+key if key.startswith(('sprites/','props/','fx/','tiles/','backgrounds/')) else 'res://'+str((p.parent/key).relative_to(ROOT))
                if key in registry:c.update({k:registry[key][k] for k in ['trim','image_size']})
            p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
        art_path=ROOT/'assets/art_manifest.json';art=json.loads(art_path.read_text())
        for entry in art['assets']:
            spec=registry.get('res://assets/'+entry['path'])
            if spec:entry['width'],entry['height']=spec['image_size']
        art_path.write_text(json.dumps(art,ensure_ascii=False,indent=2)+'\n')
        (ROOT/'data/sprite_trims.json').write_text(json.dumps(registry,ensure_ascii=False,indent=2)+'\n')
    report=ROOT/'archive/trim_report.json';report.parent.mkdir(exist_ok=True);report.write_text(json.dumps(records,indent=2));print(f'TRIM: {len(records)} sheets; apply={a.apply}')
if __name__=='__main__':main()
