#!/usr/bin/env python3
"""Use explicit per-image high-quality overrides where86 requires bulky lossless.
A higher quality never relaxes alpha/bbox/RGB error thresholds.
"""
import json,io
from pathlib import Path
import numpy as np
from PIL import Image
from downscale_assets import ROOT,encode
from build_image_parity_fixtures import reference

def main():
 policy=json.loads((ROOT/'data/image_policy.json').read_text());policy['overrides']={};registry=json.loads((ROOT/'data/sprite_trims.json').read_text());saved=0
 for table in ['storage_quality','image_encoding_quality']:
  p=ROOT/'data'/f'{table}.json';rows=json.loads(p.read_text())
  for r in rows:
   path=ROOT/r['path'].removeprefix('res://');size=path.stat().st_size
   if r['mode']!='lossless' or size<40000:continue
   spec=registry.get('res://'+str(path.relative_to(ROOT))) if table=='storage_quality' else None
   source=reference(r,spec);candidate=ROOT/'archive/stage8_high_quality_candidate.webp';metrics=encode(source,candidate,94)
   if metrics['mode']=='lossy' and candidate.stat().st_size<size:
    saved+=size-candidate.stat().st_size;path.write_bytes(candidate.read_bytes());r.update(metrics);policy['overrides'][str(path.relative_to(ROOT))]={'mode':'lossy','quality':94,'reason':'meet RGBMAE<=3 without lossless size cost'}
    if table=='storage_quality':r['output_bytes']=path.stat().st_size
    else:r['after']=path.stat().st_size
  p.write_text(json.dumps(rows,indent=2)+'\n')
 (ROOT/'data/image_policy.json').write_text(json.dumps(policy,indent=2)+'\n');print(f'QUALITY94: {len(policy["overrides"])} overrides, saved {saved/1048576:.2f}MiB')
if __name__=='__main__':main()
