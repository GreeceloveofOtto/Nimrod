#!/usr/bin/env python3
"""Key, crop, resize and atlas generated art; never synthesizes game artwork."""
from pathlib import Path
import sys,json,shutil,importlib.util,io
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from downscale_assets import ssim
import numpy as np
from PIL import Image
from scipy.ndimage import binary_fill_holes
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets/world/zabulistan_v2';ARCH=ROOT/'archive/stage14_rework/art';OUT.mkdir(parents=True,exist_ok=True)
def key(image):
    # Only background-connected magenta and nearly exact key pixels are removed.
    # Interior violet markings and rose cheek organs are deliberately preserved.
    p = np.array(image.convert('RGBA'))
    r,g,b = [p[:,:,i].astype(float) for i in range(3)]
    exact = (r>210)&(b>210)&(g<110)&(np.abs(r-b)<40)
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

QUALITY=[]
def save(im,path,q=78):
 path.parent.mkdir(parents=True,exist_ok=True)
 original=im.convert('RGBA');a=np.asarray(original);mask=a[:,:,3]>12
 canonical=ARCH/'canonical'/path.relative_to(OUT).with_suffix('.png');canonical.parent.mkdir(parents=True,exist_ok=True);im.save(canonical)
 candidates=[]
 for quality in [q,90,98]:
  buf=io.BytesIO();im.save(buf,'WEBP',quality=quality,method=6,exact=True);actual=Image.open(io.BytesIO(buf.getvalue())).convert('RGBA');b=np.asarray(actual)
  rgb=float(np.abs(a[:,:,:3][mask].astype(float)-b[:,:,:3][mask]).mean());alpha=float(np.abs(a[:,:,3].astype(float)-b[:,:,3]).mean());bbox=original.getchannel('A').getbbox()==actual.getchannel('A').getbbox();score=ssim(original,actual)
  if rgb<=3 and alpha<=.5 and bbox and score>=.93:candidates.append((buf.getvalue(),quality,rgb,alpha,bbox,score,'WebP'))
 for step in [12,10,8]:
  pixels=a.copy();pixels[:,:,:3]=np.minimum(255,np.round(pixels[:,:,:3].astype(float)/step)*step).astype('uint8');candidate=Image.fromarray(pixels);rgb=float(np.abs(a[:,:,:3][mask].astype(float)-pixels[:,:,:3][mask]).mean());score=ssim(original,candidate)
  if rgb<=3 and score>=.93:
   buf=io.BytesIO();candidate.save(buf,'WEBP',lossless=True,method=6,exact=True);candidates.append((buf.getvalue(),100,rgb,0,True,score,'bounded RGB step '+str(step)))
 if not candidates:
  buf=io.BytesIO();im.save(buf,'WEBP',lossless=True,method=6,exact=True);candidates.append((buf.getvalue(),100,0,0,True,1.,'lossless'))
 content,quality,rgb,alpha,bbox,score,encoder=min(candidates,key=lambda x:len(x[0]))
 path.write_bytes(content);QUALITY.append({'path':str(path.relative_to(ROOT)),'quality':quality,'encoder':encoder,'rgb_mae':rgb,'alpha_mae':alpha,'bbox_same':bbox,'ssim':score,'bytes':path.stat().st_size})
 return path.stat().st_size

def main():
 sources=json.loads((ARCH/'sources.json').read_text());only='--landmarks-only' in sys.argv;catalog=json.loads((ROOT/'data/world/zabulistan/art_v2.json').read_text()) if only else {};new=[ROOT/r['path'] for r in json.loads((ARCH/'quality.json').read_text()) if not r['path'].endswith('landmarks.webp')] if only else []
 if only:QUALITY.extend(r for r in json.loads((ARCH/'quality.json').read_text()) if not r['path'].endswith('landmarks.webp'))
 for src in sources:
  target=ARCH/(src['id']+'_'+src['kind']+'.png')
  if not target.exists():shutil.copy2(src['path'],target)
 for src in sources:
  if src['kind']!='art':continue
  id=src['id'];folder=OUT/id;folder.mkdir(exist_ok=True);im=Image.open(ARCH/(id+'_art.png')).convert('RGBA');atlas=Image.new('RGBA',(1024,1024));items=[]
  for i in range(8):
   x=i%4;y=i//4;box=(round(x*im.width/4),round(y*im.height/2),round((x+1)*im.width/4),round((y+1)*im.height/2));piece=key(im.crop(box));bbox=piece.getbbox()
   if not bbox:raise ValueError((id,i,'empty'))
   piece=piece.crop(bbox);ratio=min(min(331/piece.width,331/piece.height),max(min(280/piece.width,280/piece.height),227/piece.width,169/piece.height));piece=piece.resize((max(1,round(piece.width*ratio)),max(1,round(piece.height*ratio))),Image.Resampling.LANCZOS)
   pixels=np.asarray(piece).copy();red,green,blue=[pixels[:,:,c].astype(float) for c in range(3)]
   rim=ndimage.binary_dilation(pixels[:,:,3]<13,iterations=2)&(pixels[:,:,3]>=13)&(np.minimum(red,blue)-green>20)
   pixels[rim,0]=np.minimum(pixels[rim,0],pixels[rim,1]+20);pixels[rim,2]=np.minimum(pixels[rim,2],pixels[rim,1]+30);pixels[rim,3]=np.minimum(pixels[rim,3],190)
   piece=Image.fromarray(pixels)

   # A 2px transparent margin and atlas separation protect linear sampling.
   px=(i%3)*341;py=(i//3)*341;at=(px+2,py+2);atlas.alpha_composite(piece,at);items.append({'rect':[px,py,piece.width+4,piece.height+4],'game_scale':1/.9,'density':.9,'anchor':[2,piece.height+2]})
  p=folder/'landmarks.webp';save(atlas,p,80);new.append(p);catalog.setdefault(id,{});catalog[id].update({'atlas':'res://'+str(p.relative_to(ROOT)),'landmarks':items})
  prompt=ROOT/'assets/image_prompts'/f'zabulistan_v2_{id}.md';prompt.write_text(f'# {id}\n\nGenerated source: archive/stage14_rework/art/{id}_art.png\n\n8 isolated side-view hand-painted Persian myth architecture pieces, magenta #FF00FF, 4 columns ×2 rows. Theme: {src["motif"]}. Cool dark stone, restrained Laocach light; no text or watermark.\n\nBackground: three independent parallax panorama layers, same regional motif, magenta gutters. Materials: six unique generated stone/soil/ornament samples. Key → despill → trim 2px → WebP quality 78–80.\n')
 for src in sources:
  if src['kind']!='bg' or only:continue
  id=src['id'];im=Image.open(ARCH/(id+'_bg.png')).convert('RGB');a=np.asarray(im);mag=(a[:,:,0]>180)&(a[:,:,2]>150)&(a[:,:,1]<80);cuts=np.where(mag.mean(axis=1)>.8)[0]
  groups=[]
  for arr in np.split(cuts,np.where(np.diff(cuts)>1)[0]+1):
   if len(arr):groups.append((int(arr[0]),int(arr[-1])))
  boundaries=[0]+[int((a+b)/2) for a,b in groups if im.height*.15<a<im.height*.85]+[im.height]
  if len(boundaries)!=4:boundaries=[0,im.height//3,im.height*2//3,im.height]
  paths=[]
  for i in range(3):
   crop=im.crop((0,boundaries[i]+(4 if i else 0),im.width,boundaries[i+1]-(4 if i<2 else 0)));crop=crop.resize((1024,256),Image.Resampling.LANCZOS)
   # Cross-edge RGB correction (PIL compositing), not new artwork.
   arr=np.array(crop);edge=((arr[:,:8].astype(float)+arr[:,-8:].astype(float))/2).astype('uint8')
   for j in range(8):
    t=j/8;arr[:,j]=(edge[:,j]*(1-t)+arr[:,j]*t).astype('uint8');arr[:,-1-j]=arr[:,j]
   crop=Image.fromarray(arr);p=OUT/id/f'background_{i}.webp';save(crop,p,78);new.append(p);paths.append('res://'+str(p.relative_to(ROOT)))
  catalog[id]['backgrounds']=paths
 ids=[s['id'] for s in sources if s['kind']=='art']
 for batch in range(0 if only else 2):
  im=Image.open(ARCH/f'tiles{batch}_tiles.png').convert('RGB')
  for row in range(5):
   id=ids[batch*5+row];atlas=Image.new('RGB',(216,144));panels=[]
   for col in range(6):
    box=(round(col*im.width/6)+5,round(row*im.height/5)+5,round((col+1)*im.width/6)-5,round((row+1)*im.height/5)-5);tile=im.crop(box);rgb=np.asarray(tile).copy();mask=(rgb[:,:,0]>rgb[:,:,1]*1.5)&(rgb[:,:,2]>rgb[:,:,1]*1.5)&(rgb[:,:,0]>110)
    if mask.any():
     from scipy.ndimage import distance_transform_edt
     indices=distance_transform_edt(mask,return_distances=False,return_indices=True);rgb[mask]=rgb[tuple(indices[:,mask])];tile=Image.fromarray(rgb)
    tile=tile.resize((32,32),Image.Resampling.LANCZOS);panels.append(tile)
   # Color-correct the 2px interface to a shared mean sampled from the six generated edges.
   common=np.mean([np.asarray(t).mean((0,1)) for t in panels],axis=0)
   for col,tile in enumerate(panels):
    arr=np.asarray(tile).copy().astype(float)
    for y in range(32):
     for x in range(32):
      dist=min(x,31-x,y,31-y);weight=min(1.,dist/3.)
      arr[y,x]=arr[y,x]*weight+common*(1-weight)
    tile=Image.fromarray(np.uint8(arr))
    padded=Image.fromarray(np.pad(np.asarray(tile),((2,2),(2,2),(0,0)),mode='edge'))
    for variant in range(4):atlas.paste(padded.transpose([Image.Transpose.ROTATE_90,Image.Transpose.ROTATE_180,Image.Transpose.ROTATE_270][variant-1]) if variant else padded,(col*36,variant*36))
   p=OUT/id/'terrain.webp';save(atlas,p,94);new.append(p);catalog[id].update(terrain='res://'+str(p.relative_to(ROOT)),tile_cell=32,material_variants=6,junction_variants=4)
 path=ROOT/'data/world/zabulistan/art_v2.json';path.write_text(json.dumps(catalog,ensure_ascii=False,separators=(',',':'))+'\n')
 artpath=ROOT/'assets/art_manifest.json';data=json.loads(artpath.read_text());data['assets']=[x for x in data['assets'] if not x['path'].startswith(('world/zabulistan/','world/zabulistan_v2/'))]
 for p in new:
  im=Image.open(p);data['assets'].append({'path':str(p.relative_to(ROOT/'assets')),'width':im.width,'height':im.height,'transparent':p.name=='landmarks.webp','category':'world'})
 artpath.write_text(json.dumps(data,separators=(',',':'))+'\n')
 alphapath=ROOT/'data/alpha_expectations.json';data=json.loads(alphapath.read_text());data={k:v for k,v in data.items() if not k.startswith('assets/world/zabulistan/')}
 for p in new:data[str(p.relative_to(ROOT))]={'mode':'transparent' if p.name=='landmarks.webp' else 'opaque','edge_black_fraction':.03 if p.name=='landmarks.webp' else 1.,'source':'stage14_rework_generated'}
 alphapath.write_text(json.dumps(data,separators=(',',':'))+'\n')
 if (ROOT/'assets/world/zabulistan').exists():shutil.move(ROOT/'assets/world/zabulistan',ROOT/'archive/stage14_rework/retired/assets_world_zabulistan')
 (ARCH/'quality.json').write_text(json.dumps(QUALITY,indent=2))
 (ARCH/'budget.json').write_text(json.dumps({'bytes':sum(p.stat().st_size for p in new),'limit':6*1048576,'files':{str(p.relative_to(ROOT)):p.stat().st_size for p in new}},indent=2))
 print('Generated:',len(new),'files,',sum(p.stat().st_size for p in new)/1048576,'MiB; landmarks',sum(len(x['landmarks']) for x in catalog.values()))
if __name__=='__main__':main()
