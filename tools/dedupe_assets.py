#!/usr/bin/env python3
"""Find byte-identical image files, preserving distinct canonical geometry."""
import json,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
 groups={}
 for p in (ROOT/'assets').rglob('*'):
  if p.suffix in ['.webp','.png','.ogg']:
   groups.setdefault(hashlib.sha256(p.read_bytes()).hexdigest(),[]).append(str(p.relative_to(ROOT)))
 duplicates=[v for v in groups.values() if len(v)>1]
 out={'duplicates':duplicates,'candidate_bytes':sum(sum((ROOT/p).stat().st_size for p in g[1:]) for g in duplicates),'note':'Canonical sprite geometry and semantic audio names retained; no unsafe alias rewrite.'}
 (ROOT/'docs/STAGE9_DUPLICATE_ASSETS.json').write_text(json.dumps(out,indent=2)+'\n');print('DEDUPE',len(duplicates),'groups',out['candidate_bytes'],'candidate bytes')
if __name__=='__main__':main()
