#!/usr/bin/env python3
"""Warn when painted body height differs from the configured combat body."""
import json
from pathlib import Path
from PIL import Image
R=Path(__file__).resolve().parents[1]
def check():
 lines=[];warnings=0
 for e in json.loads((R/'data/enemies.json').read_text())['enemies']:
  m=json.loads((R/'assets/sprites/enemies'/e['id']/'manifest.json').read_text());clips={c['name']:c for c in m['clips']};name='idle'
  if name not in clips:name=m.get('aliases',{}).get(name,next(iter(clips)))
  c=clips[name];im=Image.open(R/'assets'/c['sheet']).convert('RGBA').crop((0,0,c['frame_width'],c['frame_height']));box=im.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox();h=(box[3]-box[1])*e['visual_scale']*e.get('size_multiplier',1);body=e['body_size'][1]*e.get('size_multiplier',1);ratio=h/body
  line=f"{e['id']}: clip={name}, painted={h:.1f}px, body={body:.1f}px, difference={(ratio-1)*100:+.1f}%"
  if abs(ratio-1)>.15:warnings+=1;line='WARNING '+line
  lines.append(line)
 lines.append(f'{len(lines)} enemies, {warnings} non-failing size warnings; original Stage5 art is reused without regeneration.')
 text='\n'.join(lines)+'\n';(R/'docs/STAGE6_VISUAL_BOUNDS.txt').write_text(text);print(text,end='')
if __name__=='__main__':check()
