#!/usr/bin/env python3
"""Create diagnostic contact sheets and previews; annotations are not game art."""
import json, math, sys
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]

def main():
    manifest=json.loads((ROOT/'assets/animation_manifest.json').read_text());out=ROOT/'docs/motion_review';out.mkdir(parents=True,exist_ok=True)
    clips=[c for c in manifest['clips'] if len(sys.argv)==1 or c['name'] in sys.argv[1:]]
    for c in clips:
        source=Image.open(ROOT/'assets'/c['sheet']).convert('RGBA');n=c['frames'];cols=5;size=256
        grid=Image.new('RGB',(cols*size,math.ceil(n/cols)*(size+28)),(30,35,44));draw=ImageDraw.Draw(grid);frames=[];durations=[];previous=None
        boundaries=c.get('frame_boundaries_seconds',[i*c['duration_seconds']/n for i in range(n+1)])
        for i in range(n):
            f=source.crop((640*i,0,640*(i+1),640));x=(i%cols)*size;y=(i//cols)*(size+28)
            thumb=f.resize((size,size),Image.Resampling.LANCZOS);grid.paste(thumb,(x,y),thumb)
            draw.line((x,y+240,x+size,y+240),fill=(95,160,190),width=1)
            b=f.getchannel('A').getbbox();foot=(b[0]+b[2])/2
            draw.line((x+foot*.4,y+235,x+foot*.4,y+245),fill=(240,180,80),width=2)
            if previous is not None:draw.line((x+previous*.4,y+233,x+previous*.4,y+247),fill=(100,210,120),width=1)
            draw.text((x+5,y+size+4),f"frame {i+1}  {boundaries[i]:.3f}s",fill=(230,230,230));previous=foot
            preview=Image.new('RGB',(640,640),(30,35,44));preview.paste(f,(0,0),f);frames.append(preview);durations.append(max(10,(round(boundaries[i+1]*100)-round(boundaries[i]*100))*10))
        grid.save(out/(c['name']+'_sheet.png'));frames[0].save(out/(c['name']+'.gif'),save_all=True,append_images=frames[1:],duration=durations,loop=0,disposal=2)
    print(f'MOTION_REVIEW: {len(clips)} contact sheets and timing previews written.')

if __name__=='__main__':main()
