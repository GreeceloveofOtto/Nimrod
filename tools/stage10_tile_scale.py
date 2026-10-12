from pathlib import Path
import json,shutil,sys
import numpy as np
from PIL import Image
sys.path.insert(0,'tools')
from build_image_parity_fixtures import reference
from downscale_assets import ssim
from stage9_optimize_density import encoded
r=Path('.');rows=json.load(open('data/image_encoding_quality.json'));art=json.load(open('assets/art_manifest.json'))
for row in rows:
 if row['path']!='assets/backgrounds/stage10/homefront_far_tile.webp':continue
 original=reference({**row,'image_resize':None});p=Path(row['path']);before=p.stat().st_size
 for s in [.75,.85,.95]:
  im=original.resize((round(original.width*s),round(original.height*s)),Image.Resampling.LANCZOS);quality=ssim(original,im.resize(original.size,Image.Resampling.LANCZOS));a=np.array(im).astype(float);edge=abs(a[:,0]-a[:,-1]).mean()
  if quality<.93 or edge>2:continue
  content,metrics=encoded(im)
  if len(content)>=before:continue
  backup=Path('archive/stage10_before_tile_scale')/p;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup);p.write_bytes(content);row.update(image_resize=list(im.size),original_size=list(original.size),ssim=quality,after=len(content),**metrics)
  entry=next(x for x in art['assets'] if x['path']==str(p.relative_to('assets')));entry.update(logical_width=2048,logical_height=720,width=im.width,height=im.height)
  print('TILE_SCALE',s,quality,'edge',edge,before,'->',len(content));break
Path('data/image_encoding_quality.json').write_text(json.dumps(rows,indent=2)+'\n');Path('assets/art_manifest.json').write_text(json.dumps(art,ensure_ascii=False,indent=2)+'\n')
