#!/usr/bin/env python3
"""Trial smaller painted backdrop layers, gated separately by GL render parity."""
from pathlib import Path
import json,hashlib,shutil,sys
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent));import pack_rework_art as art
ROOT=Path(__file__).resolve().parents[2];A=ROOT/'archive/stage15_map/art';OUT=ROOT/'assets/world/zabulistan_v2'
def main():
 art.ARCH=A;art.OUT=OUT;art.QUALITY.clear();before=A/'before';before.mkdir(exist_ok=True)
 trials=[]
 for layer,ratio in [(0,.625),(2,.375)]:
  target=OUT/'landing'/f'background_{layer}.webp';original=before/f'landing_background_{layer}.webp'
  if not original.exists():shutil.copy2(target,original)
  im=Image.open(original).convert('RGB');small=im.resize((round(im.width*ratio),round(im.height*ratio)),Image.Resampling.LANCZOS);art.save(small,target,80)
  row=art.QUALITY[-1];row['sha256']=hashlib.sha256(target.read_bytes()).hexdigest();row['requires_gl_render_parity']=True
  trials.append({'layer':layer,'ratio':ratio,'before':original.stat().st_size,'after':target.stat().st_size,'old_size':list(im.size),'new_size':list(small.size)})
 p=ROOT/'data/world/zabulistan/art_quality.json';quality=json.loads(p.read_text());new={row['path']:row for row in art.QUALITY};quality=[new.get(row['path'],row) for row in quality];p.write_text(json.dumps(quality,separators=(',',':'))+'\n');(A/'background_trials.json').write_text(json.dumps(trials,indent=2)+'\n');print(json.dumps(trials,indent=2))
if __name__=='__main__':main()
