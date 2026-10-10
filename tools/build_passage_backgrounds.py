#!/usr/bin/env python3
"""Build eight backgrounds solely from generated tiles with permitted color correction."""
import json
from pathlib import Path
from PIL import Image,ImageEnhance
ROOT=Path(__file__).resolve().parents[1]
def main():
    levels=json.loads((ROOT/'data/levels.json').read_text())['levels'];folder=ROOT/'assets/backgrounds/passage'
    for level in levels:
        if not level['id'].startswith('DowntownPassage_'):continue
        n=int(level['id'][-1]);height=level['camera_limits'][3];tile=Image.open(folder/('wall_tile_'+['a','a','b','b','c','d','d','b'][n-1]+'.png')).convert('RGB')
        tile=ImageEnhance.Color(tile).enhance(.62);tile=ImageEnhance.Brightness(tile).enhance(.77)
        hsv=tile.convert('HSV');h,s,v=hsv.split();shift=[8,30,36,85,55,-20,-15,-12][n-1];h=h.point(lambda x:(x+shift)%256);tile=Image.merge('HSV',(h,s,v)).convert('RGBA').resize((1024,height))
        result=Image.new('RGBA',(3600,height))
        for x in range(0,3600,1024):result.alpha_composite(tile,(x,0))
        # Distinct generated fixtures composited into the wall, never drawn.
        names=['passage_arch','passage_window_crimson','passage_pillar_b','passage_gargoyle','passage_pipe_cluster','passage_gear_pillar','passage_window_crimson','passage_arch']
        piece=Image.open(ROOT/'assets/props'/(names[n-1]+'.png')).convert('RGBA');piece.thumbnail((450,480))
        for x in [700,2200]:result.alpha_composite(piece,(x,40))
        result.putalpha(255);result.save(folder/f'passage_f{n}_bg.png',optimize=True)
    print('Eight color-corrected generated-tile backgrounds composed.')
if __name__=='__main__':main()
