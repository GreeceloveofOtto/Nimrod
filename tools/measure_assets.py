#!/usr/bin/env python3
"""Measure runtime assets and per-sheet texel density without imported caches."""
import argparse,json,sys
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
def stage9_budgets():
 inventory=json.loads((ROOT/'data/stage9_asset_inventory.json').read_text())['generated']
 totals={k:0 for k in ['humbaba','npcs','player','anur_fx','tables','audio','other']}
 for name in inventory:
  p=ROOT/name
  group='humbaba' if '/humbaba/' in name or '/humbaba_' in name else 'npcs' if '/npcs/' in name else 'player' if '/player/' in name else 'anur_fx' if '/anur_' in name else 'tables' if '/props/' in name else 'other'
  totals[group]+=p.stat().st_size
 for sound in json.loads((ROOT/'data/audio_stage9.json').read_text()).get('sfx',[]):
  path=ROOT/'assets/audio/sfx'/str(sound['name']+'.ogg')
  if path.exists():totals['audio']+=path.stat().st_size
 limits={'humbaba':4.5,'npcs':1.4,'player':.4,'anur_fx':.3,'tables':.8,'audio':.3,'other':.3}
 return {'bytes':totals,'limits_mib':limits,'total_bytes':sum(totals.values()),'passed':sum(totals.values())<=8*1048576 and all(totals[k]<=v*1048576 for k,v in limits.items())}
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--output',default='archive/stage9/size_final.json');p.add_argument('--stage9-budget',action='store_true');p.add_argument('--stage10-budget',action='store_true');a=p.parse_args();d=measure()
 if a.stage9_budget:d['new_content']=stage9_budgets()
 if a.stage10_budget:
  from measure_stage10 import budgets
  d['new_content']=budgets()
 out=ROOT/a.output;out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(d,indent=2));print(json.dumps({k:v for k,v in d.items() if k!='top40'},indent=2));sys.exit(1 if (a.stage9_budget or a.stage10_budget) and not d['new_content']['passed'] else 0)
