#!/usr/bin/env python3
"""Keep reproducible art sources separate from the small QA evidence download."""
from pathlib import Path
import json,hashlib,zipfile,argparse
ROOT=Path(__file__).resolve().parents[2];A=ROOT/'archive/stage14_rework'
def write_zip(path,paths):
 path.parent.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  for p in sorted(set(paths)):
   if p.is_file():z.write(p,'Nimrod/'+str(p.relative_to(ROOT)))
 with zipfile.ZipFile(path) as z:assert z.testzip() is None
 return {'file':str(path.relative_to(ROOT)),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--date',default='2026-10-15');a=parser.parse_args();evidence=[]
 for p in A.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.import','.uid'] or p.name.endswith('.pickle.gz') or p.name in ['qa_delivery.json','http_verified.json']:continue
  parts=p.relative_to(A).parts
  if 'userdata' in '/'.join(parts) or '.godot' in parts or 'candidate1' in p.name or 'candidate2' in p.name:continue
  if parts[0]=='art' and p.suffix=='.png':continue
  if 'headless' in parts or 'focused' in '/'.join(parts) or 'persistence' in '/'.join(parts):continue
  evidence.append(p)
 for name in ['stage14_rework_report.md','stage14_rework_placements.json','stage14_rework_file_manifest.json','zabulistan_density_report.md','WORLD_SAVE_POLICY_KO.md','WORLD_STATS_KO.md','WORLD_PROGRESSION_KO.md','SIZE_REPORT_KO.md','SPRITE_QA_REPORT_KO.md']:
  evidence.append(ROOT/'docs'/name)
 evidence+=list((ROOT/'docs/stage14_rework_review').glob('*.png'))
 evidence+=list((ROOT/'data/world/zabulistan/source').glob('*'))
 sources=list((A/'art').rglob('*'))
 sources=[p for p in sources if p.is_file() and p.suffix not in ['.import','.uid']]
 out=[write_zip(ROOT/f'downloads/Nimrod_stage14_rework_QA_{a.date}.zip',evidence),write_zip(ROOT/f'downloads/Nimrod_stage14_rework_ArtSources_{a.date}.zip',sources)]
 (A/'qa_delivery.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
if __name__=='__main__':main()
