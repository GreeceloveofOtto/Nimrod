#!/usr/bin/env python3
"""Stage11 content and total budgets; size failure is separate from gameplay QA."""
import json,subprocess
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def budgets():
 groups={k:0 for k in ['helmet','onearm','r40','r50','r90','shimati','urshanabi','props_fx','sea','audio','gugalanna_increase']};inventory=json.loads((R/'data/stage11_asset_inventory.json').read_text())
 for name in inventory['generated']:
  p=R/name
  group='r40' if '_r40/' in name else 'r50' if '_r50/' in name else 'r90' if '_r90/' in name else 'helmet' if '/axe_prosthetic_helm/' in name else 'onearm' if '/axe_onearm_helm/' in name else 'shimati' if '/shimati/' in name else 'urshanabi' if '/urshanabi/' in name else 'sea' if '/deathsea/' in name else 'props_fx';groups[group]+=p.stat().st_size
 for p in inventory['regenerated']:
  old=int(subprocess.check_output(['git','cat-file','-s','33369b6dc355e88066a264c574f54d2a9edd01a2:'+p],cwd=R));groups['gugalanna_increase']+=(R/p).stat().st_size-old
 for entry in json.loads((R/'data/audio_stage11.json').read_text())['sfx']+json.loads((R/'data/audio_stage11.json').read_text())['bgm']:
  kind='bgm' if entry['name']=='deathsea_drone' else 'sfx';groups['audio']+=(R/'assets/audio'/kind/(entry['name']+'.ogg')).stat().st_size
 limits={'helmet':1.5,'onearm':.15,'r40':1.0,'r50':1.3,'r90':1.4,'gugalanna_increase':1.6,'shimati':.35,'urshanabi':.25,'props_fx':.8,'sea':.6,'audio':.5};return {'bytes':groups,'limits_mib':limits,'total_bytes':sum(max(0,v) for v in groups.values()),'passed':sum(max(0,v) for v in groups.values())<=10.5*1048576 and all(groups[k]<=v*1048576 for k,v in limits.items())}
if __name__=='__main__':print(json.dumps(budgets(),indent=2))
