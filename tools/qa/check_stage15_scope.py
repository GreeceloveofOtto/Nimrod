#!/usr/bin/env python3
"""Verify protected art/game data and the nine unapproved terrain regions."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/world'))
from terrain_rules import load_world
REFERENCE=Path(__file__).with_name('stage15_scope_baseline.json')
def digest_files(paths):
 rows=[]
 for text in paths:
  p=ROOT/text;files=sorted(p.rglob('*'))if p.is_dir()else[p]
  for f in files:
   if f.is_file() and f.suffix not in ['.import','.uid'] and '__pycache__'not in f.parts:rows.append([f.relative_to(ROOT).as_posix(),hashlib.sha256(f.read_bytes()).hexdigest()])
 return hashlib.sha256(json.dumps(sorted(rows),separators=(',',':')).encode()).hexdigest()
def main():
 ref=json.loads(REFERENCE.read_text());errors=[];checks={}
 for name,row in ref['groups'].items():
  checks[name]=digest_files(row['paths'])==row['sha256']
  if not checks[name]:errors.append(name+': protected content changed')
 abilities=json.loads((ROOT/'data/world/abilities.json').read_text())
 balance={'movement':abilities['movement'],'abilities':{k:{a:v for a,v in row.items()if a not in ['requires','use_requires']}for k,row in abilities['abilities'].items()}}
 checks['ability_numbers_and_keys']=hashlib.sha256(json.dumps(balance,sort_keys=True,separators=(',',':')).encode()).hexdigest()==ref['ability_numbers_sha256']
 if not checks['ability_numbers_and_keys']:errors.append('Ability movement numbers/keys changed')
 w,*_=load_world();terrain={}
 for region in w['regions']:
  if region['id']=='landing':continue
  x,y,width,height=region['bounds'];raw='\n'.join(r[x:x+width]for r in w['navigation'][y:y+height])
  terrain[region['id']]=hashlib.sha256(raw.encode()).hexdigest()==ref['terrain'][region['id']]
  if not terrain[region['id']]:errors.append(region['id']+': unapproved terrain changed')
 result={'passed':not errors,'protected_groups':checks,'frozen_terrain':terrain,'baseline_commit':ref['commit'],'errors':errors};out=ROOT/'archive/stage15_landing_revision/scope.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');print(json.dumps(result,ensure_ascii=False,indent=2));return int(bool(errors))
if __name__=='__main__':raise SystemExit(main())
