#!/usr/bin/env python3
"""Keep declared image dimensions in sync after the landing art packers."""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
def main():
 path=ROOT/'assets/art_manifest.json';manifest=json.loads(path.read_text());entries={r['path']:r for r in manifest['assets']}
 targets=list((ROOT/'assets/world/zabulistan_v2/shared').glob('*.webp'))+list((ROOT/'assets/world/zabulistan_v2/landing').glob('*.webp'))
 targets += [ROOT/'assets/world/shared/cord.webp', ROOT/'assets/world/shared/ember.webp']
 for image_path in targets:
  relative=image_path.relative_to(ROOT/'assets').as_posix();image=Image.open(image_path).convert('RGBA');width,height=image.size
  row=entries.get(relative)
  if row is None:
   row={'path':relative,'width':width,'height':height,'transparent':image.getchannel('A').getextrema()[0]<255,'generated':True};manifest['assets'].append(row)
  row['width']=width;row['height']=height
 path.write_text(json.dumps(manifest,ensure_ascii=False,separators=(',',':'))+'\n');print('Synchronized landing/shared dimensions:',len(targets))
if __name__=='__main__':main()
