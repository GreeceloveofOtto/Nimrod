#!/usr/bin/env python3
"""Slice generated pose strips by connected components; refuse merged/missing figures."""
import argparse,json
from pathlib import Path
from PIL import Image,ImageFilter
import numpy as np
from pack_sprites import chromakey,component_poses,cell_box,foreground

def slices(path,count):
    from scipy import ndimage
    source=chromakey(Image.open(path));alpha=np.array(source.getchannel('A'))>12
    labels,total=ndimage.label(alpha, structure=np.ones((3,3),dtype=bool));areas=np.bincount(labels.ravel())[1:]
    actual=int((areas>=max(areas)*.20).sum()) if len(areas) else 0
    if actual!=count:raise ValueError(f'Actual painted body count {actual}, expected {count}; regenerate strip')
    layout_path=Path(path).with_suffix(".layout.json")
    if layout_path.exists():
        layout=json.loads(layout_path.read_text());cols=layout["columns"];rows=layout["rows"]
        if cols*rows!=count:raise ValueError("Source grid does not match frame count")
        # Grid boundaries are presentation only. Copy complete connected poses,
        # sorting by source row then x; never cut a limb at an artificial cell.
        return component_poses(source,count,rows=rows)
    return component_poses(source,count)

def pack(path,clip,output,target_height,center=False,reference_height=None,fit=False):
    poses=slices(path,int(clip['frames']))
    height=reference_height or poses[0].height
    factor=target_height/height
    w,h=int(clip['frame_width']),int(clip['frame_height']);ax,ay=clip['anchor_px']
    if fit:
        max_width=max(p.width for p in poses);max_height=max(p.height for p in poses)
        centers=[]
        for pose in poses:
            aa=np.asarray(pose.getchannel('A'),dtype=float);yy,xx=np.indices(aa.shape);centers.append((float((xx*aa).sum()/aa.sum()),float((yy*aa).sum()/aa.sum())))
        factor=min(factor,(ax-4)/max(cx for cx,cy in centers),(w-ax-4)/max(p.width-cx for p,(cx,cy) in zip(poses,centers)))
        if center:factor=min(factor,(ay-4)/max(cy for cx,cy in centers),(h-ay-4)/max(p.height-cy for p,(cx,cy) in zip(poses,centers)))
        vertical=2*min(ay,h-ay)-8 if center else ay-4
        factor=min(factor,(2*min(ax,w-ax)-8)/max_width,vertical/max_height)
    sheet=Image.new('RGBA',(w*len(poses),h));info=[]
    for i,p in enumerate(poses):
        p=p.resize((round(p.width*factor),round(p.height*factor)),Image.Resampling.LANCZOS)
        p=chromakey(p)
        # Feather only the alpha boundary by one source pixel, preserve interior.
        a=np.array(p.getchannel('A'));soft=np.array(p.getchannel('A').filter(ImageFilter.GaussianBlur(.35)));a=np.minimum(a,soft)
        p.putalpha(Image.fromarray(a))
        aa=np.asarray(p.getchannel('A'),dtype=float);yy,xx=np.indices(aa.shape)
        cx=float((xx*aa).sum()/aa.sum());cy=float((yy*aa).sum()/aa.sum())
        x=round(ax-cx);y=round(ay-cy) if center else ay-p.height
        if min(x,y)<4 or x+p.width>w-4 or y+p.height>h-4:raise ValueError(f'Frame {i+1} exceeds frame at uniform scale {factor}')
        sheet.alpha_composite(p,(i*w+x,y));info.append({'source_size':list(poses[i].size),'bbox':[x,y,x+p.width,y+p.height]})
    Path(output).parent.mkdir(parents=True,exist_ok=True);sheet.save(output,compress_level=4)
    return {'source':str(path),'uniform_scale':factor,'reference_height':height,'frames':info}

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('source');p.add_argument('out');p.add_argument('--frames',type=int,required=True);a=p.parse_args();out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
    for i,im in enumerate(slices(a.source,a.frames)):im.save(out/f'{i:02}.png')
    print(json.dumps({'frames':a.frames,'source':a.source}))
if __name__=='__main__':main()
