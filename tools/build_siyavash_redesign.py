#!/usr/bin/env python3
"""Normalize freshly generated Siyavash poses; never draw character pixels."""
import argparse, json, shutil
from pathlib import Path
from types import SimpleNamespace
import numpy as np
from PIL import Image
from scipy import ndimage
from build_stage11_art import row_poses
from pack_sprites import apply_storage_policy

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / 'archive/siyavash_redesign_2026-10-14'

def key(image):
    # Only background-connected magenta and nearly exact key pixels are removed.
    # Interior violet markings and rose cheek organs are deliberately preserved.
    p = np.array(image.convert('RGBA'))
    r,g,b = [p[:,:,i].astype(float) for i in range(3)]
    exact = (r>235)&(b>235)&(g<45)
    candidate = (r>170)&(b>170)&(g<110)&(np.minimum(r,b)-g>95)
    seed = np.zeros(candidate.shape, bool)
    seed[0,:]=candidate[0,:];seed[-1,:]=candidate[-1,:]
    seed[:,0]=candidate[:,0];seed[:,-1]=candidate[:,-1]
    blank = ndimage.binary_propagation(seed, mask=candidate)|exact
    p[blank]=0
    edge = ndimage.binary_dilation(blank, iterations=1)&~blank
    edge=ndimage.binary_dilation(blank,iterations=3)&~blank
    fringe=edge&(np.minimum(r,b)-g>20)
    p[fringe,0]=np.minimum(p[fringe,0],p[fringe,1]+20)
    p[fringe,2]=np.minimum(p[fringe,2],p[fringe,1]+30)
    p[fringe,3]=np.minimum(p[fringe,3],190)
    return Image.fromarray(p, 'RGBA')

def face_color(pose, name, frame_index):
    """Hue/saturation correction of existing cheek/iris pixels, no new shapes."""
    p=np.array(pose);r,g,b=[p[:,:,i].astype(float) for i in range(3)]
    mask=(p[:,:,3]>200)&(r>160)&(g>35)&(g<180)&(b>g*1.05)&(r>b*1.08)
    labels,_=ndimage.label(ndimage.binary_dilation(mask,iterations=1))
    scores=[]
    for label in range(1,labels.max()+1):
        selected=(labels==label)&mask;ys,xs=np.where(selected)
        if len(xs)<12:continue
        aspect=max((xs.max()-xs.min()+1)/(ys.max()-ys.min()+1),(ys.max()-ys.min()+1)/(xs.max()-xs.min()+1))
        score=len(xs)*float(g[selected].mean())/max(1,aspect*aspect)
        scores.append((score,selected))
    if not scores:raise ValueError(f'{name}/{frame_index}: cheek pixels not found')
    selected=max(scores,key=lambda entry:entry[0])[1];ys,xs=np.where(selected)
    cx,cy=float(xs.mean()),float(ys.mean());radius=max(4,(xs.max()-xs.min()+ys.max()-ys.min())/4)
    hsv=np.array(Image.fromarray(p[:,:,:3]).convert('HSV'))
    scarlet=name in ['hurt','death'];exertion=name in ['roll','jump_start']
    if scarlet:
        yy,xx=np.indices(mask.shape)
        selected |= ((xx-cx)**2+(yy-cy)**2<(radius*2.5)**2)&(hsv[:,:,0]>230)&(hsv[:,:,1]>35)&(r>b*1.02)&(p[:,:,3]>200)
    hsv[selected,0]=3 if scarlet else 247 if exertion else 242
    hsv[selected,1]=np.maximum(hsv[selected,1],210 if scarlet else 185)
    if name=='death' and frame_index==7:hsv[selected,2]=np.minimum(hsv[selected,2],190)
    # Correct warm generated irises to the requested dark gray-green, retaining
    # luminance/texture. Do not recolor skin, pupil, white or violet markings.
    if name!='roll' and not (name=='death' and frame_index>=4):
        x0,x1=int(cx+radius*1.2),int(cx+radius*2.6)
        y0,y1=int(cy-radius*2.7),int(cy-radius*1.1)
        region=np.zeros(mask.shape,bool);region[max(0,y0):max(0,y1),max(0,x0):max(0,x1)]=True
        iris=region&(hsv[:,:,0]>=8)&(hsv[:,:,0]<45)&(hsv[:,:,1]>35)&(hsv[:,:,2]>90)&(hsv[:,:,2]<210)&(p[:,:,3]>200)
        hsv[iris,0]=110;hsv[iris,1]=65;hsv[iris,2]=np.minimum(hsv[iris,2],150)
    p[:,:,:3]=np.array(Image.fromarray(hsv,'HSV').convert('RGB'));p[p[:,:,3]==0,:3]=0
    return Image.fromarray(p,'RGBA'),{'cheek_xy':[cx,cy],'cheek_radius':radius}

def extract(path, counts):
    import build_stage11_art
    build_stage11_art.key = key
    path=Path(path)
    if not path.is_absolute():path=ROOT/path
    image=key(Image.open(path));a=np.array(image)[:,:,3]
    blank=np.where((a>12).sum(axis=1)==0)[0];cuts=[0]
    for i in range(1,len(counts)):
        expected=round(image.height*i/len(counts))
        near=blank[abs(blank-expected)<image.height/len(counts)*.35]
        if not len(near): raise ValueError('No transparent row gutter: '+str(path))
        cuts.append(int(near[np.argmin(abs(near-expected))]))
    cuts.append(image.height)
    poses=[]
    for i,count in enumerate(counts):
        row=image.crop((0,cuts[i],image.width,cuts[i+1]))
        poses.extend(row_poses(row,count,min_fraction=.12,discard_row_edge_artifacts=True))
    return poses

def build(job, spec):
    name=job['name'];poses=extract(job['path'],job['rows'])
    corrected=[face_color(p,name,i) for i,p in enumerate(poses)]
    poses=[entry[0] for entry in corrected]
    target={'crouch_idle':225,'sit_idle':290,'run':340,'jump_rise':335}.get(name,363)
    scale=target/max(p.height for p in poses)
    scale=min(scale,620/max(p.width for p in poses))
    image=Image.new('RGBA',(640*len(poses),640));heights=[];landmarks=[]
    for i,pose in enumerate(poses):
        # Normalize high-resolution generated detail with an antialiased linear
        # reduction. This avoids ringing in hair, embroidery and small eyes.
        resized=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.BILINEAR)
        p=np.array(resized);p[p[:,:,3]==0,:3]=0;resized=Image.fromarray(p)
        foot_offset=0
        if name=='crouch_idle':
            pixels=np.array(resized)
            dark=(pixels[:,:,3]>128)&(pixels[:,:,:3].mean(axis=2)<110)
            dark[:round(resized.height*.85)]=False
            ys=np.where(dark)[0]
            if len(ys):foot_offset=resized.height-int(ys.max())-1
        image.alpha_composite(resized,(i*640+320-resized.width//2,600-resized.height+foot_offset))
        heights.append(resized.height)
        feature=corrected[i][1];cx,cy=feature['cheek_xy']
        landmarks.append({'cheek_xy':[320-resized.width//2+cx*scale,600-resized.height+foot_offset+cy*scale],'cheek_radius':feature['cheek_radius']*scale})
    dest=ROOT/'assets/sprites/player/siyavash'/f'{name}.png'
    image.save(dest)
    manifest_path=dest.parent/'manifest.json';manifest=json.loads(manifest_path.read_text())
    clip={'name':name,'sheet':f'sprites/player/siyavash/{name}.png','frame_width':640,'frame_height':640,'frames':len(poses),'columns':len(poses),'rows':1,'duration_seconds':spec['duration_seconds'],'fps':len(poses)/spec['duration_seconds'],'loop':spec['loop'],'anchor_px':[320,600],'image_size':list(image.size),'body_reference_height_px':target,'qa':{'pose_height_exception':name not in ['idle','walk'],'movement':name not in ['idle','crouch_idle','sit_idle'],'expected_pose_heights':heights,'detached_fx_or_weapon':False,'authored_interior_violet':True},'normalization':'new generated reference; one isotropic scale per clip; feet anchored at y=600'}
    if name in ['idle','walk','crouch_idle','sit_idle']:
        clip['qa'].update(head_top_px=[600-h for h in heights],head_center_x_px=[320]*len(poses))
    clip['face_landmarks']=landmarks
    manifest['clips']=[clip if c['name']==name else c for c in manifest['clips']]
    manifest.update(character='siyavash',display_name='시야우와르샨',redesign='2026-10-14',source_reference='archive/siyavash_redesign_2026-10-14/reference.png')
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    import downscale_assets
    original_choose=downscale_assets.choose_scale
    # Preserve readable eyes/teeth in the three close-review clips. Other
    # motions start at the permitted floor and grow only to satisfy SSIM.
    initial_density=2.0 if name in ['idle','hurt','death'] else .8
    def bounded_choose(img,w,h,count,base,limit):
        result=original_choose(img,w,h,count,base,initial_density)
        if result[-1]>2.0001:
            raise ValueError(f'{name}: SSIM gate requires density {result[-1]} above 2.0; regenerate simpler detail')
        return result
    downscale_assets.choose_scale=bounded_choose
    try:
        apply_storage_policy(SimpleNamespace(output=str(dest),frames=len(poses),frame_width=640,frame_height=640,anchor=[320,600],visual_scale=.3,density_class='player',canonical_only=False),image,True)
    finally:
        downscale_assets.choose_scale=original_choose
    sidecar=dest.with_suffix('.storage.json')
    if sidecar.exists():shutil.move(sidecar,ARCHIVE/(name+'.storage.json'))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--clips');args=parser.parse_args()
    specs={c['name']:c for c in json.loads((ROOT/'assets/sprites/player/unarmed/manifest.json').read_text())['clips']}
    for job in json.loads((ARCHIVE/'sources.json').read_text()):
        if not args.clips or job['name'] in args.clips.split(','):build(job,specs[job['name']])
