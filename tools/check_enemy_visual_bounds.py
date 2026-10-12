#!/usr/bin/env python3
"""Measure the real first neutral frame against the data-defined combat body."""
import json
from pathlib import Path
from check_sprite_frames import frame_images,paths
R=Path(__file__).resolve().parents[1]
def check():
 reference=json.loads((R/'data/size_reference.json').read_text());rows=[];warnings=[];errors=[]
 for enemy in json.loads((R/'data/enemies.json').read_text())['enemies']:
  manifest_path=R/'assets/sprites/enemies'/enemy['id']/'manifest.json';manifest=json.loads(manifest_path.read_text());clips={c['name']:c for c in manifest['clips']};name='idle'
  if name not in clips:name=manifest.get('aliases',{}).get(name,next(iter(clips)))
  clip=clips[name];frame=frame_images(paths(manifest_path,clip),clip)[0];box=frame.getchannel('A').getbbox();height=box[3]-box[1];scale=enemy['visual_scale']*enemy.get('size_multiplier',1);body=[x*enemy.get('size_multiplier',1) for x in enemy['body_size']];expected=enemy.get('art_height_px',body[1]/scale)
  density=clip.get('storage_scale',[1,1])[1]/scale;minimum=.9 if enemy['id'] in ['gugalanna','humbaba','kala_ushumgal'] else .8
  for entry in clips.values():
   clip_density=entry.get('storage_scale',[1,1])[1]/scale
   if clip_density < minimum-1e-9:errors.append(enemy['id']+'/'+entry['name']+f': storage density {clip_density:.3f} below {minimum}')
  delta=(height/expected-1)*100;row={'id':enemy['id'],'clip':name,'painted_height_px':height,'expected_art_height_px':expected,'display_height':height*scale,'body_size':body,'melee_width_ratio':body[0]/150,'melee_height_ratio':body[1]/90,'difference_percent':delta};rows.append(row)
  if abs(delta)>15:warnings.append(enemy['id'])
  print(f"{enemy['id']}: art {height}/{expected:.1f}px ({delta:+.1f}%), display {height*scale:.1f}px, body {body[0]:.1f}x{body[1]:.1f}, melee ratios {body[0]/150:.2f}/{body[1]/90:.2f}")
 registry=json.loads((R/'data/sprite_trims.json').read_text());npc_data=json.loads((R/'data/npcs.json').read_text());npc_scales={n['sheet_dir']:.3*n.get('visual_scale_multiplier',1) for n in npc_data['npcs']}
 for path,spec in registry.items():
  if '/sprites/player/' not in path and '/sprites/npcs/' not in path:continue
  folder=str(Path(path.removeprefix('res://')).parent);base=npc_scales.get(folder,.3);density=spec.get('storage_scale',[1,1])[1]/base
  if density < .8-1e-9:errors.append(path+f': person storage density {density:.3f} below0.8')
 report={'reference':reference,'enemies':rows,'warnings':warnings,'density_errors':errors};(R/'docs/STAGE7_VISUAL_BOUNDS.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(f'ENEMY_BOUNDS: {len(rows)} enemies, {len(warnings)} size warnings');print("DENSITY_FLOOR:",len(errors),"failures",errors);return not warnings and not errors
if __name__=='__main__':raise SystemExit(0 if check() else 1)
