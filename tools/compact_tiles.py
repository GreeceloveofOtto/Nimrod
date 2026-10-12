#!/usr/bin/env python3
"""Lossless tile encoding preserves exact repeating edge pixels."""
import json,shutil
from PIL import Image
from downscale_assets import ROOT,rewrite_paths

def main():
 mapping={};rows=json.loads((ROOT/'data/image_encoding_quality.json').read_text())
 for p in (ROOT/'assets/tiles').rglob('*.png'):
  candidate=ROOT/'archive/stage8_tile_candidate.webp';Image.open(p).save(candidate,'WEBP',lossless=True,method=6,exact=True)
  if candidate.stat().st_size>=p.stat().st_size:continue
  rel=str(p.relative_to(ROOT));backup=ROOT/'archive/stage8_encoding_before'/rel;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup);out=p.with_suffix('.webp');out.write_bytes(candidate.read_bytes());p.unlink();mapping[rel]=str(out.relative_to(ROOT));rows.append({'path':str(out.relative_to(ROOT)),'source':rel,'before':backup.stat().st_size,'after':out.stat().st_size,'mode':'lossless','quality':100,'alpha_mae':0,'rgb_mae':0,'bbox_same':True,'transparent':Image.open(out).mode=='RGBA'})
 rewrite_paths(mapping);(ROOT/'data/image_encoding_quality.json').write_text(json.dumps(rows,indent=2)+'\n');print('LOSSLESS TILES:',len(mapping))
if __name__=='__main__':main()
