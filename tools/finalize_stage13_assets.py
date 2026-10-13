#!/usr/bin/env python3
import json,shutil
from pathlib import Path
import numpy as np
from PIL import Image
from finalize_stage11_assets import main as catalogs
R=Path(__file__).resolve().parents[1]
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':'))+'\n')
def main():
 catalogs()
 registry=json.loads((R/'data/sprite_trims.json').read_text())
 for mp in (R/'assets/sprites/player').glob('*/manifest.json'):
  d=json.loads(mp.read_text())
  if mp.parent.name=='siyavash':
   for c in d['clips']:
    if c['name'] in ['idle','walk','crouch_idle']:
     heights=c.get('qa',{}).get('expected_pose_heights',[363]*c['frames']);c.setdefault('qa',{})['head_top_px']=[600-int(h) for h in heights];c['qa']['head_center_x_px']=[320]*c['frames']
    registry['res://assets/'+c['sheet']].pop('qa',None)
   write(mp,d)
 for mp in (R/'assets/sprites/enemies').glob('*/manifest.json'):
  if mp.parent.name not in ['ninazu_mother','lilith','zu']:continue
  d=json.loads(mp.read_text())
  for c in d['clips']:c.setdefault('qa',{})['check_head_ghost']=True
  write(mp,d)
 write(R/'data/sprite_trims.json',registry)
 surfaces=json.loads((R/'data/surface_offsets.json').read_text())
 for p in [R/'assets/tiles/huluppu/branch.png',R/'assets/tiles/hwanira/plaza.png']:
  im=Image.open(p).convert('RGBA');alpha=np.array(im)[:,:,3];y,x=np.where(alpha>128)
  surfaces['res://'+str(p.relative_to(R))]={'image_width':im.width,'image_height':im.height,'top_offset_px':int(y.min()),'bottom_offset_px':int(im.height-y.max()-1),'opaque_x0':int(x.min()),'opaque_x1':int(x.max()+1)}
 write(R/'data/surface_offsets.json',surfaces)
 created=[str(p.relative_to(R)) for folder in ['assets/sprites/player/siyavash','assets/sprites/enemies/ninazu_mother','assets/sprites/enemies/lilith','assets/sprites/enemies/zu','assets/backgrounds/hwanira','assets/backgrounds/tiamat','assets/tiles/hwanira','assets/tiles/huluppu'] for p in (R/folder).glob('*') if p.suffix in ['.png','.webp']]+['assets/props/utnapishtim_blood.webp']
 write(R/'data/stage13_asset_inventory.json',{'generated':created,'reused':['assets/props/huluppu_trunk.webp','assets/props/ferry_boat.webp','assets/backgrounds/deathsea/stars_tile.webp','assets/sprites/npcs/enkidua/idle.webp','assets/sprites/fx/gas_cloud.webp','assets/sprites/fx/spit_projectile.webp','assets/sprites/fx/guard_spark.webp','assets/sprites/fx/humbaba_ember_aura.webp'],'missing':[]})
 for p in (R/'assets').rglob('*.json'):write(p,json.loads(p.read_text()))
 budget={'baseline_assets_bytes':63482603,'baseline_zip_bytes':63886770,'zip_target_mib':62,'stretch_zip_mib':60,'new_assets_limit_bytes':int(7.5*1048576),'new_assets':created,'categories':{'ninazu_mother':1.2,'lilith':1.2,'zu':1.2,'siyavash':2.,'backgrounds':1.5,'props_tiles':.4}}
 write(R/'data/stage13_budget.json',budget)
 print('STAGE13 CATALOG',len(created),'generated images',sum((R/f).stat().st_size for f in created)/1048576,'MiB')
if __name__=='__main__':main()
