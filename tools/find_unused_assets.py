#!/usr/bin/env python3
"""Conservative runtime reference graph: dynamic NPC/enemy folders retain clips.
Reports unreachable art, never treats developer catalogs/prompts as runtime use.
"""
import argparse,json,re,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def candidates():
 texts=[]
 for folder in ['scripts','scenes','data']:
  for p in (ROOT/folder).rglob('*'):
   if p.suffix in ['.gd','.json','.tscn','.tres'] and p.name not in ['image_mapping.json','alpha_expectations.json','image_parity_samples.json','storage_quality.json','image_encoding_quality.json','sprite_trims.json']:texts.append(p.read_text())
 used=set(re.findall(r'(?:res://)?(assets/[A-Za-z0-9_./-]+\.(?:webp|png|ogg|wav|otf))','\n'.join(texts)))
 # All logical clips referenced by active manifests remain, including aliases.
 for p in (ROOT/'assets/sprites').rglob('manifest.json'):
  for c in json.loads(p.read_text()).get('clips',[]):
   sheet=c['sheet'];used.add(sheet.removeprefix('res://') if sheet.startswith('res://') else 'assets/'+sheet if sheet.startswith('sprites/') else str((p.parent/sheet).relative_to(ROOT)))
 for p in [ROOT/'assets/animation_manifest.json']:
  for c in json.loads(p.read_text())['clips']:used.add('assets/'+c['sheet'])
 used.update(p.removeprefix('res://') for p in json.loads((ROOT/'data/sprite_trims.json').read_text()))
 # Audio tables intentionally load generated effects by name at runtime.
 used.update(str(p.relative_to(ROOT)) for p in (ROOT/'assets/audio').rglob('*') if p.is_file() and p.suffix in ['.wav','.ogg'])
 return [p for p in (ROOT/'assets').rglob('*') if p.suffix in ['.png','.webp','.ogg','.wav'] and str(p.relative_to(ROOT)) not in used]
def main():
 p=argparse.ArgumentParser();p.add_argument('--apply',action='store_true');a=p.parse_args();unused=candidates();rows=[]
 for f in unused:
  rel=str(f.relative_to(ROOT));rows.append({'path':rel,'bytes':f.stat().st_size})
  if a.apply:
   dest=ROOT/'archive/stage8_unused'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.move(f,dest)
 (ROOT/'docs/STAGE8_UNUSED_ASSETS.json').write_text(json.dumps({'files':rows,'bytes':sum(r['bytes'] for r in rows),'applied':a.apply},indent=2)+'\n');print(f'UNUSED: {len(rows)} files, {sum(r["bytes"] for r in rows)/1048576:.2f}MiB, applied={a.apply}')
if __name__=='__main__':main()
