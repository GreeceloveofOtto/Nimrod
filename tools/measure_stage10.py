#!/usr/bin/env python3
"""Stage10 new-content and total budgets; fail rather than hide budget misses."""
import json,sys
from pathlib import Path
from measure_assets import measure,ROOT
limits={'gugalanna':3.6,'onearm':1.3,'prosthetic':1.4,'cutscene':.4,'bed':.3,'props_fx':.6,'scenery':1.,'audio':.4}
def budgets():
 totals={k:0 for k in limits}
 for rel in json.loads((ROOT/'data/stage10_asset_inventory.json').read_text())['generated']:
  p=ROOT/rel
  if not p.exists():raise FileNotFoundError(rel)
  key='cutscene' if p.stem in ['cry_collapse','cry_loop','arm_loss_hit','melammu_absorb'] else 'gugalanna' if '/enemies/gugalanna/' in rel or '/gugalanna_' in rel and '/fx/' in rel else 'onearm' if '/axe_onearm/' in rel else 'prosthetic' if '/axe_prosthetic/' in rel else 'bed' if '/npcs/enkidua/' in rel else 'scenery' if '/backgrounds/' in rel or '/tiles/' in rel else 'props_fx'
  totals[key]+=p.stat().st_size
 for section,folder in [('sfx','sfx'),('bgm','bgm')]:
  for row in json.loads((ROOT/'data/audio_stage10.json').read_text())[section]:totals['audio']+=(ROOT/'assets/audio'/folder/(row['name']+'.ogg')).stat().st_size
 return {'bytes':totals,'limits_mib':limits,'total_bytes':sum(totals.values()),'passed':sum(totals.values())<=9*1048576 and all(totals[k]<=limits[k]*1048576 for k in limits)}
if __name__=='__main__':
 d=measure();d['new_content']=budgets();(ROOT/'archive/stage10/size_final.json').write_text(json.dumps(d,indent=2));print(json.dumps({k:v for k,v in d.items() if k!='top40'},indent=2));sys.exit(0 if d['new_content']['passed'] and d['total_bytes']<=50*1048576 else 1)
