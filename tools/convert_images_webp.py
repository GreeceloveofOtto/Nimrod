#!/usr/bin/env python3
"""Dry-run / apply checked WEBP conversion, rewrite references, preserve originals."""
import argparse,json,shutil,re,hashlib
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]

def convert(path,out):
    image=Image.open(path).convert('RGBA');alpha=np.array(image.getchannel('A'));transparent=bool(alpha.min()<255)
    image.save(out,'WEBP',lossless=transparent,quality=100 if transparent else 90,method=6,exact=True)
    restored=np.array(Image.open(out).convert('RGBA'));original=np.array(image);occupied=original[:,:,3]>0
    if transparent:
        error=float(np.abs(original[occupied].astype(float)-restored[occupied].astype(float)).max())
        valid=np.array_equal(original[:,:,3],restored[:,:,3]) and error==0
    else:
        error=float(np.abs(original[:,:,:3].astype(float)-restored[:,:,:3].astype(float)).mean());valid=error<=2
    return valid,error,transparent

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');p.add_argument('--dry-run',action='store_true');p.add_argument('--folders',nargs='+',default=['assets']);a=p.parse_args();
    if a.apply and a.dry_run:p.error('Choose --apply or --dry-run')
    scratch=ROOT/'archive/webp_candidates';scratch.mkdir(parents=True,exist_ok=True);mapping={};records=[]
    art=json.loads((ROOT/'assets/art_manifest.json').read_text())
    precise={str(Path('assets')/entry['path']) for entry in art['assets'] if entry.get('tile_x') or entry.get('tile_y')}
    keep_png={str(Path('assets')/entry['path']) for entry in art['assets'] if entry.get('keep_png')}
    previous_path=ROOT/'archive/image_conversion.json'
    previous={v['path']:v for v in json.loads(previous_path.read_text())} if previous_path.exists() else {}
    def prepare(f):
        relative=str(f.relative_to(ROOT));digest=hashlib.sha256(f.read_bytes()).hexdigest()
        candidate=(scratch/f.relative_to(ROOT/'assets')).with_suffix('.webp');candidate.parent.mkdir(parents=True,exist_ok=True)
        cached=previous.get(relative)
        if cached and cached.get('png_sha256')==digest and candidate.exists():return f,candidate,cached
        # Tiny UI and pixel-exact terrain stay PNG. Opaque repeating backgrounds
        # also stay PNG if lossy encoding changes their matching tile edges.
        if relative in keep_png or 'tiles' in f.parts or 'ui' in f.parts:
            return f,candidate,{'path':relative,'png_bytes':f.stat().st_size,'webp_bytes':f.stat().st_size,'transparent':True,'error':0,'accepted':False,'png_sha256':digest,'reason':'pixel-exact tile/UI'}
        valid,error,transparent=convert(f,candidate)
        if relative in precise:
            im=Image.open(candidate).convert('RGBA')
            if im.crop((0,0,1,im.height)).tobytes()!=im.crop((im.width-1,0,im.width,im.height)).tobytes():valid=False
        accepted=valid and candidate.stat().st_size<f.stat().st_size
        return f,candidate,{'path':relative,'png_bytes':f.stat().st_size,'webp_bytes':candidate.stat().st_size,'transparent':bool(transparent),'error':error,'accepted':bool(accepted),'png_sha256':digest}
    source=sorted({f for folder in a.folders for f in (ROOT/folder).rglob('*.png') if not any(x.startswith('_legacy') for x in f.parts) and 'source_art' not in f.parts and 'reference' not in f.parts})
    with ThreadPoolExecutor(max_workers=4) as pool:
        for f,candidate,record in pool.map(prepare,source):
            records.append(record)
            if record['accepted']:
                dest=f.with_suffix('.webp');mapping[str(f.relative_to(ROOT))]=str(dest.relative_to(ROOT))
                if a.apply:
                    archive=ROOT/'archive/original_png'/f.relative_to(ROOT);archive.parent.mkdir(parents=True,exist_ok=True);shutil.move(f,archive);shutil.copy2(candidate,dest)
    if a.apply:
        # Full asset paths, shortened manifest paths, and basename references.
        substitutions={}
        for old,new in mapping.items():
            substitutions[old]=new
            if old.startswith('assets/'):substitutions[old[7:]]=new[7:]
        ordered=sorted(substitutions,key=len,reverse=True)
        pattern=re.compile('|'.join(re.escape(x) for x in ordered)) if ordered else None
        for folder in ['scripts','data','scenes','tools','tests','assets']:
            for f in (ROOT/folder).rglob('*'):
                if f.suffix not in ['.gd','.json','.tscn','.tres','.py','.md','.txt']:continue
                if any(x.startswith('_legacy') for x in f.parts) or 'source_art' in f.parts or 'reference' in f.parts:continue
                text=f.read_text();new=pattern.sub(lambda m:substitutions[m.group()],text) if pattern else text
                # Local sheet references are only rewritten relative to that manifest.
                if f.suffix=='.json' and f.name=='manifest.json':
                    for old,dest in mapping.items():
                        if Path(old).parent==f.parent.relative_to(ROOT):new=new.replace('"'+Path(old).name+'"','"'+Path(dest).name+'"')
                if new!=text:f.write_text(new)
        existing=ROOT/'data/image_mapping.json';previous=json.loads(existing.read_text()) if existing.exists() else {};previous.update(mapping)
        existing.write_text(json.dumps(previous,indent=2)+'\n')
    (ROOT/'archive/image_conversion.json').write_text(json.dumps(records,indent=2));print(f'WEBP: {len(mapping)}/{len(records)} accepted; apply={a.apply}; saved {sum(r["png_bytes"]-r["webp_bytes"] for r in records if r["accepted"])/1048576:.2f} MiB')
if __name__=='__main__':main()
