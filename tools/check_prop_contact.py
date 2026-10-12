#!/usr/bin/env python3
"""Align painted support surfaces, never Node anchors, for bed/chair/rock actors."""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image
from check_sprite_frames import frame_images,paths
R=Path(__file__).resolve().parents[1]
def broad_first(image,fraction=.3,roi_x=None):
 a=np.asarray(image.convert('RGBA'))[:,:,3]
 if roi_x is not None:a=a[:,roi_x[0]:roi_x[1]]
 rows=np.flatnonzero((a>200).sum(axis=1)>=image.width*fraction)
 if not len(rows):raise ValueError('No readable support surface')
 return int(rows[0])
def check(fix=False):
 p=R/'data/levels.json';data=json.loads(p.read_text());lines=[];failures=0
 for level in data['levels']:
  if level['id']=='NimrodHome':
   bed=next(e for e in level['decorations'] if Path(e['path']).stem=='home_bed');im=Image.open(R/bed['path'].removeprefix('res://'));support=bed['position'][1]+broad_first(im,roi_x=(round(im.width*.43),im.width))*bed['size'][1]/im.height
   npc=next(n for n in level['npcs'] if n.get('instance_id')=='enkidua_bed');mp=R/'assets/sprites/npcs/enkidua/manifest.json';m=json.loads(mp.read_text())
   bottoms=[]
   for c in m['clips']:
    if c['name'] in ['bed_awake','bed_asleep']:
     for f in frame_images(paths(mp,c),c):
      box=f.getchannel('A').point(lambda v:255 if v>12 else 0).getbbox();bottoms.append((box[3]-c['anchor_px'][1])*.3)
   if fix:npc['position']=[bed['position'][0]+bed['size'][0]/2,round(support-float(np.mean(bottoms)),3)]
   for offset in bottoms:
    delta=npc['position'][1]+offset-support
    if abs(delta)>3:failures+=1
    lines.append(f'Bed body contact {delta:+.3f}px')
   blood=Image.open(R/'assets/props/home_bed_blood.webp');bloodsize=[420,86];bloodtop=support-broad_first(blood)*bloodsize[1]/blood.height
   settings={'mattress_roi_x_fraction':[.43,1.0],'bed_surface_y':support,'bed_center_x':bed['position'][0]+bed['size'][0]/2,'blood_position':[bed['position'][0],round(bloodtop,3)],'blood_size':bloodsize,'body_position':npc['position']}
   if fix:
    contacts_path=R/'data/prop_contacts.json';previous=json.loads(contacts_path.read_text()) if contacts_path.exists() else {};settings['chair_contacts']=previous.get('chair_contacts',[]);contacts_path.write_text(json.dumps(settings,indent=2)+'\n')
  if level['id']=='DeathSea' and (R/'assets/props/small_rock.webp').exists():
   rock=next(e for e in level['decorations'] if 'small_rock' in e['path']);im=Image.open(R/rock['path'].removeprefix('res://'));support=rock['position'][1]+broad_first(im)*rock['size'][1]/im.height
   old=next(n for n in level['npcs'] if n['id']=='urshanabi');mp=R/'assets/sprites/npcs/urshanabi/manifest.json'
   if mp.exists():
    clip=json.loads(mp.read_text())['clips'][0];f=frame_images(paths(mp,clip),clip)[0];bottom=f.getchannel('A').point(lambda v:255 if v>12 else 0).getbbox()[3];offset=float(clip.get('seat_contact_offset_y',-35))
    if fix:old['position'][1]=round(support-offset,3)
    delta=old['position'][1]+offset-support;failures+=abs(delta)>3;lines.append(f'Urshanabi seat rock contact {delta:+.3f}px')
 contacts=json.loads((R/'data/prop_contacts.json').read_text())
 for c in contacts.get('chair_contacts',[]):
  prop=Image.open(R/c['prop_path']);surface=c['prop_position'][1]+c['seat_row_px']*c['prop_size'][1]/prop.height;body=c['actor_y']+(c['actor_seat_y_px']-c['anchor_y'])*c['visual_scale'];delta=body-surface;failures+=abs(delta)>3;lines.append(f"Chair {c['actor']} painted seat contact {delta:+.3f}px")
 if fix:p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 text='\n'.join(lines)+f'\nPROP_CONTACT: {len(lines)} checks, {failures} failures\n';(R/'docs/STAGE11_PROP_CONTACT.txt').write_text(text);print(text);return not failures
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--fix',action='store_true');a=p.parse_args();raise SystemExit(not check(a.fix))
