#!/usr/bin/env python3
"""Six JPEG visual comparisons at runtime zoom1.0 and1.35; no generated art."""
import json,math
from pathlib import Path
from PIL import Image,ImageDraw
from check_sprite_frames import frame_images
from build_image_parity_fixtures import reference
ROOT=Path(__file__).resolve().parents[1]
def main():
 registry=json.loads((ROOT/'data/sprite_trims.json').read_text());rows={v['path']:v for v in json.loads((ROOT/'data/storage_quality.json').read_text())};out=ROOT/'docs/size_compare';out.mkdir(exist_ok=True)
 subjects=[('gugalanna','assets/sprites/enemies/gugalanna/manifest.json',.3),('player_r90','assets/sprites/player/axe_prosthetic_helm_r90/manifest.json',.3),('npc','assets/sprites/npcs/ninsun/manifest.json',.3),('melee','assets/sprites/enemies/melee_beast/manifest.json',.3),('ranged','assets/sprites/enemies/ranged_beast/manifest.json',.3)]
 for label,mp,scale in subjects:
  manifest=json.loads((ROOT/mp).read_text());clip=next(c for c in manifest['clips'] if c['name']=='idle');key='res://assets/'+clip['sheet'];row=rows[key];raw=ROOT/'archive'/row['source_archive'] if row.get('source_archive') else ROOT/'archive/stage8_density_before'/row['source'];original=Image.open(raw).convert('RGBA');trim=clip['trim'];original=original.crop((trim['x'],trim['y'],trim['x']+trim['w'],trim['y']+trim['h'])) if row.get('source_canonical') else original.crop((0,0,trim['w'],trim['h']));after=frame_images(ROOT/'assets'/clip['sheet'],clip)[0];after=after.crop((trim['x'],trim['y'],trim['x']+trim['w'],trim['y']+trim['h']))
  row_h=max(285,math.ceil(original.height*scale*1.35)+70);canvas=Image.new('RGB',(1000,row_h*2),(35,39,48));draw=ImageDraw.Draw(canvas)
  for col,im in enumerate([original,after]):
   for line,zoom in enumerate([1.,1.35]):
    size=(max(1,round(im.width*scale*zoom)),max(1,round(im.height*scale*zoom)));picture=im.resize(size,Image.Resampling.LANCZOS);x=col*500+250-picture.width//2;y=line*row_h+row_h-20-picture.height;canvas.paste(picture,(x,y),picture);draw.text((col*500+14,18+line*row_h),('SOURCE' if col==0 else 'RUNTIME')+' / zoom '+str(zoom),fill=(245,235,210))
  canvas.save(out/('stage11_'+label+'.jpg'),quality=90)
 rows=json.loads((ROOT/'data/image_encoding_quality.json').read_text());row=next(v for v in rows if v['path']=='assets/backgrounds/stage10/homefront_sky.webp');before=reference({**row,'image_resize':None});after=Image.open(ROOT/row['path']).convert('RGBA');canvas=Image.new('RGB',(1000,620),(35,39,48));draw=ImageDraw.Draw(canvas)
 for col,im in enumerate([before,after]):
  for line,zoom in enumerate([1.,1.35]):
   picture=im.resize((500,235),Image.Resampling.LANCZOS)
   if zoom>1:picture=picture.resize((675,317),Image.Resampling.LANCZOS).crop((87,41,587,276))
   canvas.paste(picture,(col*500,40+line*285));draw.text((col*500+14,18+line*285),('SOURCE' if col==0 else 'RUNTIME')+' / zoom '+str(zoom),fill=(245,235,210))
 canvas.save(out/'stage11_background.jpg',quality=90)
if __name__=='__main__':main()
