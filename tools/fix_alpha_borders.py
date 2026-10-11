#!/usr/bin/env python3
"""Pack existing generated silhouettes with transparent padding, never draw art."""
import json,shutil
from pathlib import Path
from PIL import Image
import numpy as np
from pack_sprites import chromakey
ROOT=Path(__file__).resolve().parents[1]
def backup(path):
 dest=ROOT/'archive/alpha_before'/path.relative_to(ROOT);dest.parent.mkdir(parents=True,exist_ok=True)
 if not dest.exists():shutil.copy2(path,dest)

manifest_path=ROOT/'assets/art_manifest.json';manifest=json.loads(manifest_path.read_text());fixed=[]
for spec in manifest['assets']:
 path=ROOT/'assets'/spec['path']
 if not spec.get('transparent') or not spec['path'].startswith(('props/','fx/')) or '/doors/' in spec['path'] or not path.exists():continue
 im=Image.open(path).convert('RGBA');a=np.array(im.getchannel('A'));border=np.concatenate([a[0],a[-1],a[:,0],a[:,-1]])
 if border.max()>0:
  backup(path);inside=im.resize((im.width-4,im.height-4),Image.Resampling.LANCZOS);out=Image.new('RGBA',im.size);out.paste(inside,(2,2));out.save(path,optimize=True,**({"lossless": True} if path.suffix==".webp" else {}));fixed.append(spec['path'])
# Replace the opaque middle-trunk layer with an image-generated keyed layer.
path=ROOT/'assets/backgrounds/cedar/mid_trunks_tile_2d.webp';backup(path)
im=chromakey(Image.open(ROOT/'archive/source_art/stage7/cedar_mid.png')).resize((1024,1024),Image.Resampling.LANCZOS)
pix=np.array(im);pix[0]=pix[-1]=(pix[0].astype(float)*.5+pix[-1].astype(float)*.5).astype(np.uint8);pix[:,0]=pix[:,-1]=(pix[:,0].astype(float)*.5+pix[:,-1].astype(float)*.5).astype(np.uint8);pix[pix[:,:,3]==0,:3]=0
Image.fromarray(pix).save(path,optimize=True,**({"lossless": True} if path.suffix==".webp" else {}))
for spec in manifest['assets']:
 if spec['path']=='backgrounds/cedar/mid_trunks_tile_2d.webp':spec['transparent']=True;spec['edge_exception']='Repeats on both axes; matching RGBA seam columns/rows intentionally contain trunk pixels.'
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');(ROOT/'archive/alpha_fixed.json').write_text(json.dumps({'padded':fixed,'regenerated':['backgrounds/cedar/mid_trunks_tile_2d.webp']},indent=2));print('ALPHA FIX:',len(fixed),'padded props and one regenerated parallax layer')
