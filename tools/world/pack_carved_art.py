#!/usr/bin/env python3
"""Postprocess one generated grayscale material sheet. No artwork is drawn here.
Masks only composite/correct the supplied painted material for adjacency and AO.
"""
from pathlib import Path
import sys,json,shutil
import numpy as np
from PIL import Image,ImageEnhance,ImageOps
sys.path.insert(0,str(Path(__file__).parent))
import pack_rework_art as art
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets/world/zabulistan_v2/shared';ARCH=ROOT/'archive/stage15_map/art'
def pad_tile(atlas,tile,x,y):
 atlas.paste(tile,(x+2,y+2));atlas.paste(tile.crop((0,0,tile.width,1)).resize((tile.width,2)),(x+2,y));atlas.paste(tile.crop((0,tile.height-1,tile.width,tile.height)).resize((tile.width,2)),(x+2,y+tile.height+2));atlas.paste(atlas.crop((x+2,y,x+3,y+tile.height+4)).resize((2,tile.height+4)),(x,y));atlas.paste(atlas.crop((x+tile.width+1,y,x+tile.width+2,y+tile.height+4)).resize((2,tile.height+4)),(x+tile.width+2,y))
def gray(im):
 alpha=im.getchannel('A') if im.mode=='RGBA' else None
 out=ImageOps.grayscale(im).convert('RGB')
 if alpha is not None:out.putalpha(alpha)
 return out

def match_edges(pixels,reference,enabled=(True,True,True,True),factor=1.):
 out=pixels.copy();source=np.asarray(reference,dtype=float);horizontal=(source[0]+source[-1])/2*factor;vertical=(source[:,0]+source[:,-1])/2*factor;corner=np.clip(source.mean(axis=(0,1))*factor,0,255)
 if enabled[0]:out[0]=horizontal
 if enabled[1]:out[:,-1]=vertical
 if enabled[2]:out[-1]=horizontal
 if enabled[3]:out[:,0]=vertical
 for y,x in [(0,0),(0,-1),(-1,0),(-1,-1)]:out[y,x]=corner
 return np.uint8(np.clip(out,0,255))

def main():
 OUT.mkdir(parents=True,exist_ok=True);ARCH.mkdir(parents=True,exist_ok=True)
 src=ARCH/'generated_materials.png'
 if not src.exists():shutil.copy2('/workspace/generated_images/exec-7757abe1-adcc-42f8-b564-1d34093318ef.png',src)
 image=Image.open(src).convert('RGBA');art.OUT=ROOT/'assets/world/zabulistan_v2';art.ARCH=ARCH;art.QUALITY.clear()
 # Crops are manually inspected panel bounds, excluding magenta gutters.
 rock=[gray(image.crop(box).convert('RGB')).resize((64,64),Image.Resampling.LANCZOS) for box in [(12,12,300,300),(326,12,614,300),(640,12,928,300)]]
 wall=[gray(image.crop(box).convert('RGB')).resize((64,64),Image.Resampling.LANCZOS) for box in [(12,321,300,609),(326,321,614,609),(640,321,928,609)]]
 crust=Image.new('RGB',(20*36,3*36))
 for variant in range(3):
  face=np.asarray(rock[variant].resize((32,32),Image.Resampling.LANCZOS)).astype(float)
  for mask in range(20):
   yy,xx=np.mgrid[:32,:32];edge=np.zeros((32,32))
   if mask<16:
    for bit,distance in [(1,yy),(2,31-xx),(4,31-yy),(8,xx)]:
     if mask&bit==0:edge=np.maximum(edge,np.clip((5-distance)/5,0,1))
   else:
    cy,cx=[(0,0),(0,31),(31,31),(31,0)][mask-16];edge=np.clip(1-(abs(xx-cx)+abs(yy-cy))/8,0,1)
   # Tone correction of the painted texture; no new surface illustration.
   corrected=np.clip(face*(.78+edge[:,:,None]*.45),0,255).astype('uint8')
   connected=tuple(mask>=16 or bool(mask&bit) for bit in [1,2,4,8])
   corrected=match_edges(corrected,rock[0].resize((32,32),Image.Resampling.LANCZOS),connected,.78)
   pad_tile(crust,Image.fromarray(corrected),mask*36,variant*36)
 art.save(crust,OUT/'crust.webp',80)
 back=Image.new('RGB',(16*36,3*36))
 for material in range(3):
  source=wall[material].resize((32,32),Image.Resampling.LANCZOS);pixels=np.asarray(source).astype(float)
  for mask in range(16):
   yy,xx=np.mgrid[:32,:32];shade=np.zeros((32,32))
   for bit,d in [(1,yy),(2,31-xx),(4,31-yy),(8,xx)]:
    if mask&bit:shade=np.maximum(shade,np.clip((18-d)/18,0,1))
   corrected=np.clip(pixels*(1-shade[:,:,None]*.48),0,255).astype('uint8')
   corrected=match_edges(corrected,wall[0].resize((32,32),Image.Resampling.LANCZOS),tuple(not(mask&bit) for bit in [1,2,4,8]),.65)
   pad_tile(back,Image.fromarray(corrected),mask*36,material*36)
 art.save(back,OUT/'backwall.webp',80)
 fill=ImageEnhance.Contrast(gray(image.crop((955,323,1240,609)).convert('RGB')).resize((64,64),Image.Resampling.LANCZOS)).enhance(.045)
 fillatlas=Image.new('RGB',(72,72))
 for y in range(2):
  for x in range(2):pad_tile(fillatlas,fill.crop((x*32,y*32,x*32+32,y*32+32)),x*36,y*36)
 art.save(fillatlas,OUT/'fill.webp',80)
 supports=Image.new('RGBA',(4*68,2*68));boxes=[(9,634,303,921),(323,634,617,921),(636,634,932,921),(950,634,1245,921),(9,936,303,1244),(323,936,617,1244),(636,936,932,1244),(950,936,1245,1244)]
 for i,box in enumerate(boxes):
  piece=gray(art.key(image.crop(box)))
  if i==4:piece=piece.crop((0,92,piece.width,138)) # Salt crust only; omit the long icicles.
  piece=piece.crop(piece.getbbox());scale=min(60/piece.width,60/piece.height);piece=piece.resize((max(1,round(piece.width*scale)),max(1,round(piece.height*scale))),Image.Resampling.LANCZOS)
  x=(i%4)*68+4+(60-piece.width)//2;y=(i//4)*68+4+(60-piece.height if i==4 else 0);supports.alpha_composite(piece,(x,y))
 art.save(supports,OUT/'supports.webp',80)
 pillar=gray(art.key(image.crop(boxes[2])));pillar=pillar.crop(pillar.getbbox()).resize((60,252),Image.Resampling.LANCZOS)
 foreground=Image.new('RGBA',(64,256));foreground.alpha_composite(pillar,(2,2));art.save(foreground,OUT/'foreground.webp',80)
 catalogue={'crust':'res://assets/world/zabulistan_v2/shared/crust.webp','backwall':'res://assets/world/zabulistan_v2/shared/backwall.webp','fill':'res://assets/world/zabulistan_v2/shared/fill.webp','supports':'res://assets/world/zabulistan_v2/shared/supports.webp','palette':'65788c','crust_light':1.4,'transition_light':.52,'fill_light':.27,'backwall_light':.78}
 catalogue['foreground']='res://assets/world/zabulistan_v2/shared/foreground.webp'
 (ROOT/'data/world/zabulistan/carved_art.json').write_text(json.dumps(catalogue,indent=2)+'\n');(ARCH/'quality.json').write_text(json.dumps(art.QUALITY,indent=2)+'\n')
 (ROOT/'assets/image_prompts/zabulistan_carved_shared.md').write_text('# 공유 굴착 지형 재질\n\n이미지 생성 원본: archive/stage15_map/art/generated_materials.png\n\n4×4 소재 시트, 회색조 해풍 침식 사암 4종, 흙벽돌·갈대 뒷벽 3종과 낮은 대비 암반 1종, 까치발·사슬·기둥·나무 선반, 소금 테두리·늘어진 뿌리·창틀·등잔. 마젠타 #FF00FF 배경, 정측면, 손그림, 고대 페르시아/우루크 분위기, no text, no watermark. 눈 덮인 돌은 제외.\n\n생성 이미지 크롭 → 크로마키·디스필 → 회색조 → 리사이즈 → 인접 마스크 합성/명도 보정 → 2px 확장 패딩 → WebP. 런타임 색 변조. 새 원본 아트는 코드로 그리지 않음.\n')
 print('CARVED SHARED ART',sum(p.stat().st_size for p in OUT.glob('*.webp')),'bytes;',len(art.QUALITY),'quality-gated files')
if __name__=='__main__':main()
