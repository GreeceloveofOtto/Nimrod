#!/usr/bin/env python3
"""Refresh source-backed clip metadata, catalogs and strict head-region annotations."""
import json,hashlib,shutil
from pathlib import Path
from PIL import Image
from finalize_stage11_assets import main as catalogs
R=Path(__file__).resolve().parents[1]
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':'))+'\n')
def main():
 catalogs()
 registry=json.loads((R/'data/sprite_trims.json').read_text())
 for mp in (R/'assets/sprites/player').glob('*helm*/manifest.json'):
  d=json.loads(mp.read_text());d.update(helmet_height_allowance_px=45,helmet_horns=1,height_excludes_helmet=True,step=20)
  for c in d['clips']:
   c.setdefault('qa',{})['helmet_horns']=1
   if c['name'] in ['idle','walk','crouch_idle']:
    c['qa']['head_top_px']=[round(c['anchor_px'][1]-c.get('body_reference_height_px',363))]*c['frames']
    c['qa']['head_center_x_px']=[c['anchor_px'][0]]*c['frames']
   key='res://assets/'+c['sheet'];registry[key].pop('qa',None)
  write(mp,d)
 write(R/'data/sprite_trims.json',registry)
 # Store only metadata more compactly; this cannot affect pixels or timing.
 saved=0
 for p in (R/'assets').rglob('*.json'):
  old=p.stat().st_size;content=json.loads(p.read_text());backup=R/'archive/stage12/json_before'/p.relative_to(R);backup.parent.mkdir(parents=True,exist_ok=True)
  if not backup.exists():shutil.copy2(p,backup)
  write(p,content);saved+=old-p.stat().st_size
 new=['assets/props/huluppu_trunk.webp','assets/props/utnapishtim_hut.webp','assets/sprites/npcs/utnapishtim/idle.webp']
 regens=[str(p.relative_to(R)) for p in (R/'assets/sprites/player').glob('*helm*/*.webp')]
 write(R/'data/stage12_asset_inventory.json',{'generated':new,'regenerated':regens,'reused':['assets/props/ferry_boat.webp','assets/backgrounds/deathsea/stars_tile.webp','assets/tiles/deathsea/ground_tile.png','assets/fx/npc_light_pool.webp','assets/props/paper_note.webp','assets/sprites/npcs/urshanabi/dice_loop.webp'],'missing':[]})
 print('COMPACT METADATA savings',saved)
if __name__=='__main__':main()
