#!/usr/bin/env python3
"""Review montages only: copy generated pixels, add UI labels, never paint art."""
import json
from pathlib import Path
from PIL import Image,ImageDraw
from check_sprite_frames import frame_images
ROOT=Path(__file__).resolve().parents[1]

def main():
    out=ROOT/'docs/siyavash_review';out.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((ROOT/'assets/sprites/player/siyavash/manifest.json').read_text())
    for clip in manifest['clips']:
        name=clip['name']
        if name not in ['idle','run','hurt','death']:continue
        index=7 if name=='death' else 1 if name=='hurt' else 0
        source=Image.open(ROOT/'archive/pack_source/sprites/player/siyavash'/f'{name}.png').crop((index*640,0,(index+1)*640,640))
        stored=frame_images(ROOT/'assets'/clip['sheet'],clip)[index]
        x,y=clip['face_landmarks'][index]['cheek_xy'];box=(round(x-35),round(y-40),round(x+40),round(y+50))
        canvas=Image.new('RGB',(1200,700),(30,33,42));labels=ImageDraw.Draw(canvas)
        for column,(image,label) in enumerate([(source,'NEW SOURCE / 6x face'),(stored,'RUNTIME WEBP / 6x face')]):
            enlarged=image.crop(box).resize((450,540),Image.Resampling.BILINEAR)
            canvas.paste(enlarged,(column*470+10,70),enlarged.getchannel('A'))
            labels.text((column*470+12,30),label,fill=(230,225,210))
        for row,zoom in enumerate([1,1.35]):
            pose=stored.crop(stored.getchannel('A').getbbox());size=(round(pose.width*.3*zoom),round(pose.height*.3*zoom))
            pose=pose.resize(size,Image.Resampling.BILINEAR)
            canvas.paste(pose,(970+(180-size[0])//2,100+row*260),pose.getchannel('A'))
            labels.text((970,70+row*260),'game zoom '+str(zoom),fill='white')
        labels.text((15,650),name+' / logical frame '+str(index+1)+' / canonical anchor [320,600]',fill='white')
        canvas.save(out/f'{name}_review.jpg',quality=94)
    contact=Image.new('RGB',(1280,17*160),(30,33,42));labels=ImageDraw.Draw(contact)
    for row,clip in enumerate(manifest['clips']):
        for i,image in enumerate(frame_images(ROOT/'assets'/clip['sheet'],clip)):
            pose=image.crop(image.getchannel('A').getbbox());scale=min(110/pose.width,125/pose.height)
            pose=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.BILINEAR)
            contact.paste(pose,(i*105+15,row*160+20),pose.getchannel('A'))
            labels.text((i*105+12,row*160+145),clip['name']+' '+str(i+1),fill='white')
    contact.save(out/'all_clips.jpg',quality=92)
    print('SIYAVASH_REVIEW: four enlarged comparisons, seventeen-row contact sheet')

if __name__=='__main__':main()
