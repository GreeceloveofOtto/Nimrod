#!/usr/bin/env python3
"""QA overlay: authored inputs, changed originals, quality evidence and captures."""
import json,zipfile,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def main():
 output=ROOT/'downloads/Nimrod_stage14_zabulistan_QA_2026-10-15.zip';entries=set()
 for p in (ROOT/'archive/stage14').rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.pyc','.import'] or p.name in ['qa_package.json','delivery.json','http_verified.json']:continue
  if any(part in ['candidates','userdata','runtime_validation','__pycache__'] or part.startswith('runtime_validation') for part in p.relative_to(ROOT/'archive/stage14').parts):continue
  entries.add(p)
 for p in (ROOT/'docs/world_review').rglob('*'):
  if p.is_file():entries.add(p)
 entries.add(ROOT/'archive/siyavash_redesign_2026-10-14/reference.png')
 for row in json.loads((ROOT/'data/storage_quality.json').read_text()):
  if '/siyavash/' in row['path'] and Path(row['path']).stem in ['dash','wall_cling','wall_jump','crawl'] or '/cedar_colossus/' in row['path'] and Path(row['path']).stem in ['idle','slam','slam_windup','sweep_recovery']:
   source=ROOT/'archive'/row['source_archive'] if row.get('source_archive') else ROOT/'archive/stage8_density_before'/row['source']
   if source.exists():entries.add(source)
 with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  z.writestr('Nimrod/archive/.gdignore','')
  for p in sorted(entries):z.write(p,'Nimrod/'+p.relative_to(ROOT).as_posix())
 report={'path':str(output.relative_to(ROOT)),'files':len(entries),'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest()}
 (ROOT/'archive/stage14/qa_package.json').write_text(json.dumps(report,indent=2)+'\n');print(report)
if __name__=='__main__':main()
