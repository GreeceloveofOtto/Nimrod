#!/usr/bin/env python3
"""Measure the real first neutral frame against the data-defined combat body."""
import json
from pathlib import Path
from check_sprite_frames import frame_images,paths
R=Path(__file__).resolve().parents[1]
def check():
 reference=json.loads((R/'data/size_reference.json').read_text());rows=[];warnings=[]
 for enemy in json.loads((R/'data/enemies.json').read_text())['enemies']:
  manifest_path=R/'assets/sprites/enemies'/enemy['id']/'manifest.json';manifest=json.loads(manifest_path.read_text());clips={c['name']:c for c in manifest['clips']};name='idle'
  if name not in clips:name=manifest.get('aliases',{}).get(name,next(iter(clips)))
  clip=clips[name];frame=frame_images(paths(manifest_path,clip),clip)[0];box=frame.getchannel('A').getbbox();height=box[3]-box[1];scale=enemy['visual_scale']*enemy.get('size_multiplier',1);body=[x*enemy.get('size_multiplier',1) for x in enemy['body_size']];expected=enemy.get('art_height_px',body[1]/scale)
  delta=(height/expected-1)*100;row={'id':enemy['id'],'clip':name,'painted_height_px':height,'expected_art_height_px':expected,'display_height':height*scale,'body_size':body,'melee_width_ratio':body[0]/150,'melee_height_ratio':body[1]/90,'difference_percent':delta};rows.append(row)
  if abs(delta)>15:warnings.append(enemy['id'])
  print(f"{enemy['id']}: art {height}/{expected:.1f}px ({delta:+.1f}%), display {height*scale:.1f}px, body {body[0]:.1f}x{body[1]:.1f}, melee ratios {body[0]/150:.2f}/{body[1]/90:.2f}")
 report={'reference':reference,'enemies':rows,'warnings':warnings};(R/'docs/STAGE7_VISUAL_BOUNDS.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(f'ENEMY_BOUNDS: {len(rows)} enemies, {len(warnings)} size warnings');return not warnings
if __name__=='__main__':raise SystemExit(0 if check() else 1)
