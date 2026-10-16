#!/usr/bin/env python3
"""Crop/resize the generated coastal panorama; no procedural scenery drawing."""
from pathlib import Path
import json,hashlib,shutil,sys
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent));import pack_rework_art as art
ROOT=Path(__file__).resolve().parents[2];A=ROOT/'archive/stage15_map/art';OUT=ROOT/'assets/world/zabulistan_v2'
def main():
 A.mkdir(parents=True,exist_ok=True);source=A/'generated_landing_sea.png'
 if not source.exists():shutil.copy2('/workspace/generated_images/exec-b9ab0e9a-b465-41f9-a53a-c4c0876999c4.png',source)
 target=OUT/'landing/background_1.webp';old=A/'before/landing_background_1.webp'
 if not old.exists():shutil.copy2(target,old)
 image=Image.open(source).convert('RGB');image=image.crop((0,round(image.height*.442),image.width,image.height)).resize((512,128),Image.Resampling.LANCZOS)
 pixels=np.array(image);shared=(pixels[:,:12].astype(float)+pixels[:,-12:][:,::-1].astype(float))/2
 for i in range(12):
  t=i/12;value=shared[:,i]*(1-t)+pixels[:,i].astype(float)*t;pixels[:,i]=np.uint8(value);pixels[:,-1-i]=pixels[:,i]
 image=Image.fromarray(pixels);art.ARCH=A;art.OUT=OUT;art.QUALITY.clear();art.save(image,target,80);record=art.QUALITY[-1];record['sha256']=hashlib.sha256(target.read_bytes()).hexdigest();record['intentional_new_generated_content']=True
 p=ROOT/'data/world/zabulistan/art_quality.json';rows=json.loads(p.read_text());rows=[record if row['path']==record['path'] else row for row in rows];p.write_text(json.dumps(rows,separators=(',',':'))+'\n')
 (A/'sea.json').write_text(json.dumps({'source':str(source.relative_to(ROOT)),'before_bytes':old.stat().st_size,'after_bytes':target.stat().st_size,'size':[512,128],'quality':record},indent=2)+'\n')
 (ROOT/'assets/image_prompts/zabulistan_landing_sea.md').write_text('# 착륙 절벽의 바다 원경\n\n생성 원본: archive/stage15_map/art/generated_landing_sea.png\n\n2D side-view hand-painted dark fantasy ancient Persian coastal harbor cliffs, shadowy blue sea and distant horizon, wind-eroded blue-gray sandstone and stepped harbor bastions, weak cyan star light, advanced space-civilization undertones, no characters, no foreground platforms, no text, no watermark. Opaque panorama, horizontal repeat.\n\n원본 하단의 수평선·물·해안 부분 크롭 → 512×128 리사이즈 → 양 끝 12px 색 보정 → 품질 게이트 WebP. 기존 중경 한 장을 의도적으로 새 콘텐츠로 교체했으며, 기존 이미지와의 압축 동등성을 주장하지 않음.\n')
 print('GENERATED_COAST',old.stat().st_size,'->',target.stat().st_size,'B; world art',sum(p.stat().st_size for p in OUT.rglob('*.webp')))
if __name__=='__main__':main()
