#!/usr/bin/env python3
"""Measure runtime assets and per-sheet texel density without imported caches."""
import argparse,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def measure():
 rows=[{'path':str(p.relative_to(ROOT)),'bytes':p.stat().st_size} for p in (ROOT/'assets').rglob('*') if p.is_file() and p.suffix not in ['.import','.uid'] and '.gdignore' not in p.parts]
 folders={}
 for r in rows:folders[r['path'].split('/')[1]]=folders.get(r['path'].split('/')[1],0)+r['bytes']
 density={};e=json.loads((ROOT/'data/enemies.json').read_text())['enemies'];n=json.loads((ROOT/'data/npcs.json').read_text())
 for v in e:density['assets/sprites/enemies/'+v['id']]=1/(v.get('visual_scale',.3)*v.get('size_multiplier',1))
 for v in n['npcs']:density[v['sheet_dir']]=1/(n['common']['visual_scale']*v.get('visual_scale_multiplier',1))
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());density['assets/sprites/player']=1/.3
 for r in rows:
  base=next((v for k,v in density.items() if r['path'].startswith(k+'/')),None);spec=registry.get('res://'+r['path'],{});r['texel_density']=round(base*spec.get('storage_scale',[1,1])[1],3) if base else None
 return {'total_bytes':sum(r['bytes'] for r in rows),'folders':folders,'top40':sorted(rows,key=lambda r:r['bytes'],reverse=True)[:40]}
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--output',default='archive/stage8_size_before.json');a=p.parse_args();d=measure();out=ROOT/a.output;out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(d,indent=2));print(json.dumps({k:v for k,v in d.items() if k!='top40'},indent=2))
