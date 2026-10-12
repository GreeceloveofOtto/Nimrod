#!/usr/bin/env python3
"""Crop generated multi-panel bleed; preserve logical scenery dimensions and archived originals."""
import json,shutil
from pathlib import Path
from PIL import Image
from build_image_parity_fixtures import reference
from stage9_optimize_density import encoded
from downscale_assets import ssim
R=Path(__file__).resolve().parents[1]
rows=json.loads((R/'data/image_encoding_quality.json').read_text());art=json.loads((R/'assets/art_manifest.json').read_text())
for name,cut in [('villa_f4_sky',22),('dilmun_far_tile',78)]:
 key='res://assets/backgrounds/stage10/'+name+'.webp';row=next(r for r in rows if r['path'].removeprefix('res://')==key.removeprefix('res://'));original=reference({**row,'image_resize':None});fixed=original.crop((0,cut,original.width,original.height)).resize(original.size,Image.Resampling.LANCZOS)
 source=R/'archive/stage10/corrected_backgrounds'/f'{name}.png';source.parent.mkdir(parents=True,exist_ok=True);fixed.save(source)
 target=R/key.removeprefix('res://');backup=R/'archive/stage10_before_background_fix'/target.relative_to(R);backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,backup)
 size=Image.open(target).size;scaled=fixed.resize(size,Image.Resampling.LANCZOS);content,metrics=encoded(scaled);target.write_bytes(content)
 row.update(source_archive=str(source.relative_to(R/'archive')),image_resize=list(size),original_size=list(fixed.size),ssim=ssim(fixed,scaled.resize(fixed.size,Image.Resampling.LANCZOS)),after=len(content),**metrics)
 print(name,row['ssim'],len(content))
(R/'data/image_encoding_quality.json').write_text(json.dumps(rows,indent=2)+'\n')
