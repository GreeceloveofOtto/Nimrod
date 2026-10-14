import sys,json,shutil
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools'));sys.path.insert(0,str(root/'tools/world'))
from build_siyavash_redesign import key
from pack_world_art import catalog
raw=root/'archive/stage14/shared_raw.png';source=Image.open(raw);poses=[]
for y0,y1 in [(0,325),(325,700),(700,1024)]:
 for x in range(4):
  cell=key(source.crop((x*384,y0,(x+1)*384,y1)));poses.append(cell.crop(cell.getchannel("A").getbbox()))
names=['crystal','life','altar','switch','gate','portal','spikes','poison','falling_rock','moving_platform','crumble','lore_item'];data={};folder=root/'assets/world/shared';folder.mkdir(parents=True,exist_ok=True)
for name,pose in zip(names,poses):
 target=128 if name in ['gate','portal'] else 80;factor=target/max(pose.size);pose=pose.resize((round(pose.width*factor),round(pose.height*factor)),Image.Resampling.LANCZOS);im=Image.new('RGBA',(pose.width+4,pose.height+4));im.alpha_composite(pose,(2,2));path=folder/(name+'.webp');im.save(path,'WEBP',lossless=True,method=6);data[name]='res://'+str(path.relative_to(root))
data['wind']='res://assets/fx/npc_light_pool.webp';(root/'data/world/art.json').write_text(json.dumps(data,indent=2)+'\n');catalog()
