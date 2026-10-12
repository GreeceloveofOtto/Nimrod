#!/usr/bin/env python3
"""Reconcile active catalogs after validated replacements; archive old originals."""
import json,shutil
from pathlib import Path
from PIL import Image
R=Path(__file__).resolve().parents[1]
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def main():
 old=R/'assets/sprites/player/axe_prosthetic'
 if old.exists():
  archive=R/'archive/stage11/removed_axe_prosthetic';archive.parent.mkdir(parents=True,exist_ok=True)
  if archive.exists():shutil.rmtree(archive)
  shutil.move(str(old),archive)
 registry=json.loads((R/'data/sprite_trims.json').read_text());registry={k:v for k,v in registry.items() if (R/k.removeprefix('res://')).exists()};write(R/'data/sprite_trims.json',registry)
 for name in ['storage_quality','image_encoding_quality']:
  p=R/'data'/f'{name}.json';rows=json.loads(p.read_text());write(p,[v for v in rows if (R/v['path'].removeprefix('res://')).exists()])
 p=R/'data/image_mapping.json';mapping=json.loads(p.read_text());mapping={k:v for k,v in mapping.items() if (R/v).exists()};write(p,mapping)
 p=R/'assets/art_manifest.json';art=json.loads(p.read_text());existing={e['path']:e for e in art['assets'] if (R/'assets'/e['path']).exists()}
 for path in (R/'assets').rglob('*'):
  if path.suffix not in ['.png','.webp']:continue
  relative=str(path.relative_to(R/'assets'));im=Image.open(path).convert('RGBA');entry=existing.get(relative,{'name':path.stem,'path':relative});entry.update(width=im.width,height=im.height,transparent=im.getchannel('A').getextrema()[0]<255);existing[relative]=entry
 art['assets']=list(existing.values());manifests=[m for m in art['sprite_manifests'] if (R/'assets'/m).exists()]
 for pth in (R/'assets/sprites').rglob('*manifest.json'):
  rel=str(pth.relative_to(R/'assets'))
  if rel not in manifests:manifests.append(rel)
 art['sprite_manifests']=manifests;write(p,art)
 generated=[str(p.relative_to(R)) for folder in ['assets/sprites/player/axe_onearm_helm','assets/sprites/player/axe_prosthetic_helm','assets/sprites/player/axe_prosthetic_helm_r40','assets/sprites/player/axe_prosthetic_helm_r50','assets/sprites/player/axe_prosthetic_helm_r90','assets/sprites/npcs/shimati','assets/sprites/npcs/urshanabi','assets/backgrounds/deathsea','assets/tiles/deathsea'] for p in (R/folder).glob('*') if p.suffix in ['.png','.webp']]
 generated += [f'assets/sprites/fx/{n}.webp' for n in ['devour_bite','mote']]+[f'assets/props/{n}.webp' for n in ['shimati_stall','ferry_boat','small_rock','paper_note']]
 write(R/'data/stage11_asset_inventory.json',{'generated':generated,'regenerated':['assets/sprites/enemies/gugalanna/'+p.name for p in (R/'assets/sprites/enemies/gugalanna').glob('*.webp')],'missing':[]})
 # Developer source/encoding sidecars have authoritative copies in the registry.
 for p in (R/'assets').rglob('*.storage.json'):
  archive=R/'archive/stage11/storage_sidecars'/p.relative_to(R/'assets');archive.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(p),archive)
 from check_alpha_cleanliness import classify
 write(R/'data/alpha_expectations.json',classify())
 print('CATALOG',len(existing),'images;',len(manifests),'manifests;',len(generated),'new images')
if __name__=='__main__':main()
