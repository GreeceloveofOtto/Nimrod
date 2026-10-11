#!/usr/bin/env python3
"""Diagnostic contact sheets and timing GIFs; never writes game artwork."""
import argparse,json,math
from pathlib import Path
from PIL import Image,ImageDraw
from check_sprite_frames import frame_images,paths
ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('manifests',nargs='+');a=p.parse_args();count=0
 for manifest in map(Path,a.manifests):
  data=json.loads(manifest.read_text());folder=ROOT/'docs/sprite_qa'/manifest.parent.name;folder.mkdir(parents=True,exist_ok=True)
  for c in data['clips']:
   frames=frame_images(paths(manifest,c),c);n=len(frames);side=240;cols=min(6,n);grid=Image.new('RGB',(cols*side,math.ceil(n/cols)*(side+20)),(30,35,44));draw=ImageDraw.Draw(grid);preview=[]
   for i,f in enumerate(frames):
    thumb=f.copy();thumb.thumbnail((side,side));x=(i%cols)*side+(side-thumb.width)//2;y=(i//cols)*(side+20)+(side-thumb.height)//2;grid.paste(thumb,(x,y),thumb)
    anchor=c['anchor_px'];scale=thumb.height/f.height;line_y=y+anchor[1]*scale;draw.line([(x,line_y),(x+thumb.width,line_y)],fill=(60,130,180))
    draw.text(((i%cols)*side+4,(i//cols)*(side+20)+side+2),f'{i+1} / {i*c["duration_seconds"]/n:.3f}s',fill=(240,230,200))
    canvas=Image.new('RGB',thumb.size,(30,35,44));canvas.paste(thumb,(0,0),thumb);preview.append(canvas)
   grid.save(folder/(c['name']+'_contact.jpg'),quality=85)
   preview[0].save(folder/(c['name']+'.gif'),save_all=True,append_images=preview[1:],duration=max(20,round(c['duration_seconds']/n*1000)),loop=0,disposal=2);count+=1
 print(f'SPRITE_REVIEW: {count} contact sheets and GIFs')
if __name__=='__main__':main()
