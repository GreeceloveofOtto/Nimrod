#!/usr/bin/env python3
"""Recheck 30 large sheets and scenery against immutable pre-encoding pixels."""
import argparse,io,json,shutil,hashlib
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import numpy as np
from PIL import Image
from build_image_parity_fixtures import reference
from downscale_assets import ROOT,ssim
from check_alpha_cleanliness import audit
ARCHIVE=ROOT/'archive/siyavash_redesign_2026-10-14'

def trial(item):
    row,spec=item;path=ROOT/row['path'].removeprefix('res://');source=reference(row,spec)
    original=np.array(source);visible=original[:,:,3]>12;before=path.stat().st_size
    outcomes=[];best=None
    for method in ['webp74','webp82','webp90','webp94','palette128']:
        candidate=source
        if method=='palette128':
            rgb=source.convert('RGB').quantize(colors=128,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
            candidate=rgb.convert('RGBA');candidate.putalpha(source.getchannel('A'))
        quality=int(method[4:]) if method.startswith('webp') else 100
        buf=io.BytesIO();candidate.save(buf,'WEBP',lossless=method=='palette128',quality=quality,alpha_quality=95,method=6,exact=True)
        actual=Image.open(io.BytesIO(buf.getvalue())).convert('RGBA');pixels=np.array(actual)
        rgb_error=float(np.abs(original[:,:,:3][visible].astype(float)-pixels[:,:,:3][visible]).mean())
        alpha=float(np.abs(original[:,:,3].astype(float)-pixels[:,:,3]).mean())
        bbox=source.getchannel('A').getbbox()==actual.getchannel('A').getbbox()
        score=ssim(source,actual);tile='tile' in path.stem or '/tiles/' in str(path)
        edges=max(float(np.abs(a.astype(float)-b).mean()) for a,b in [(original[0,:,:3],pixels[0,:,:3]),(original[-1,:,:3],pixels[-1,:,:3]),(original[:,0,:3],pixels[:,0,:3]),(original[:,-1,:3],pixels[:,-1,:3])])
        candidate_path=ARCHIVE/'candidates'/(hashlib.sha256(str(path).encode()).hexdigest()[:16]+'.webp')
        candidate_path.parent.mkdir(parents=True,exist_ok=True);candidate_path.write_bytes(buf.getvalue())
        expectations=json.loads((ROOT/'data/alpha_expectations.json').read_text())[str(path.relative_to(ROOT))]
        alpha_issues=audit(candidate_path,expectations)
        catalog=json.loads((ROOT/'assets/art_manifest.json').read_text())
        art=next((entry for entry in catalog['assets'] if entry['path']==str(path.relative_to(ROOT/'assets'))),{})
        seam_ok=(not art.get('tile_x') or np.array_equal(pixels[:,0],pixels[:,-1])) and (not art.get('tile_y') or np.array_equal(pixels[0],pixels[-1]))
        ok=rgb_error<=3 and alpha<=.5 and bbox and score>=.93 and (not tile or edges<=2) and not alpha_issues and seam_ok
        metrics={'mode':'lossy','quality':quality,'encoder':method,'rgb_mae':rgb_error,'alpha_mae':alpha,'bbox_same':bbox,'encoding_ssim':score}
        outcomes.append({'method':method,'candidate_bytes':len(buf.getvalue()),'gates_pass':bool(ok),'max_edge_rgb_mae':edges,'seam_exact':bool(seam_ok),'alpha_qa_issues':alpha_issues,**metrics})
        if ok and len(buf.getvalue())<before and (best is None or len(buf.getvalue())<len(best[0])):best=(buf.getvalue(),metrics)
    return row,spec,path,before,best,outcomes

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--only');args=parser.parse_args()
    registry=json.loads((ROOT/'data/sprite_trims.json').read_text())
    sheets=json.loads((ROOT/'data/storage_quality.json').read_text());scenery=json.loads((ROOT/'data/image_encoding_quality.json').read_text())
    selected=sorted((r for r in sheets if '/siyavash/' not in r['path']),key=lambda r:(ROOT/r['path'].removeprefix('res://')).stat().st_size,reverse=True)[:30]
    items=[(r,registry[r['path']]) for r in selected]
    items.extend((r,None) for r in sorted(scenery,key=lambda r:(ROOT/r['path'].removeprefix('res://')).stat().st_size if (ROOT/r['path'].removeprefix('res://')).exists() else 0,reverse=True)[:12])
    if args.only:items=[item for item in items if args.only in item[0]['path']]
    results=[]
    with ThreadPoolExecutor(max_workers=3) as pool:
        for row,spec,path,before,best,outcomes in pool.map(trial,items):
            record={'path':row['path'],'before':before,'accepted':best is not None,'trials':outcomes}
            if best:
                dest=ARCHIVE/'compression_before'/path.relative_to(ROOT);dest.parent.mkdir(parents=True,exist_ok=True)
                if not dest.exists():shutil.copy2(path,dest)
                content,metrics=best;path.write_bytes(content);row.update(metrics)
                if spec:row['output_bytes']=len(content);spec['encoding']=metrics
                else:row['after']=len(content)
                record['after']=len(content)
            results.append(record)
            print(path.name,'APPLY' if best else 'KEEP',before,record.get('after',before),flush=True)
    for mp in (ROOT/'assets').rglob('*manifest.json'):
        data=json.loads(mp.read_text());dirty=False
        for clip in data.get('clips',[]):
            sheet=clip['sheet'];key='res://assets/'+sheet if sheet.startswith(('sprites/','props/','fx/')) else sheet
            if key in registry and clip.get('encoding')!=registry[key].get('encoding'):
                clip['encoding']=registry[key]['encoding'];dirty=True
        if dirty:mp.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    for rel,data in [('data/sprite_trims.json',registry),('data/storage_quality.json',sheets),('data/image_encoding_quality.json',scenery)]:
        (ROOT/rel).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    previous=json.loads((ARCHIVE/'compression_trials.json').read_text()) if args.only and (ARCHIVE/'compression_trials.json').exists() else []
    results=[r for r in previous if r['path'] not in [n['path'] for n in results]]+results
    (ARCHIVE/'compression_trials.json').write_text(json.dumps(results,indent=2)+'\n')
    print('COMPRESSION SAVED',sum(r['before']-r.get('after',r['before']) for r in results))

if __name__=='__main__':main()
