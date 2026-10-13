#!/usr/bin/env python3
"""Write measured redesign reports; keep earlier stage records in the archive."""
import argparse,json,subprocess
from collections import defaultdict
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ARCHIVE=ROOT/'archive/siyavash_redesign_2026-10-14'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--verified',action='store_true');args=parser.parse_args()
    manifest=json.loads((ROOT/'assets/sprites/player/siyavash/manifest.json').read_text())
    old=json.loads((ARCHIVE/'previous_set/manifest.json').read_text());old_clips={c['name']:c for c in old['clips']}
    new_bytes=sum((ROOT/'assets'/c['sheet']).stat().st_size for c in manifest['clips'])
    old_bytes=sum((ARCHIVE/'previous_set'/Path(c['sheet']).name).stat().st_size for c in old['clips'])
    baseline=json.loads((ARCHIVE/'baseline_sizes.json').read_text());current=defaultdict(int)
    for p in (ROOT/'assets').rglob('*'):
        if not p.is_file() or p.suffix in ['.import','.uid']:continue
        parts=p.relative_to(ROOT).parts;category='sprites/'+parts[2] if len(parts)>2 and parts[1]=='sprites' else parts[1]
        current[category]+=p.stat().st_size
    package=json.loads((ROOT/'archive/package_report.json').read_text()) if (ROOT/'archive/package_report.json').exists() else {}
    face=json.loads((ARCHIVE/'face_qa.json').read_text())
    status='○' if args.verified else '× (최종 패키지 검증 대기)'
    clip_table='| 클립 | 프레임 | 길이(s) | 이전→새 밀도 | 이전→새 KiB |\n|---|---:|---:|---:|---:|\n'
    for c in manifest['clips']:
        previous=old_clips[c['name']];before=(ARCHIVE/'previous_set'/Path(previous['sheet']).name).stat().st_size;after=(ROOT/'assets'/c['sheet']).stat().st_size
        clip_table+=f"| {c['name']} | {c['frames']} | {c['duration_seconds']} | {previous['effective_density']}→{c['effective_density']} | {before/1024:.1f}→{after/1024:.1f} |\n"
    assumptions='''- 귀는 작고 얇은 인간 귀를 기본으로 하며, 짧은 머리 사이로 보이는 쪽 상부와 둥근 귓바퀴 윤곽을 노출했다. 거대한 설치류 귀·꼬리·수염은 넣지 않았다.
- 앞니 노출은 hurt/death에만 지정했다. roll/land/drop_through도 입을 다물도록 정했다. hurt/death의 귀는 약간 뒤로 눕는 목표 포즈다.
- 미세 흉터는 목·손등·팔뚝 각 한 곳, 총 3곳을 생성 프롬프트에 지정했다. 매우 작은 게임 표시에서는 각 흉터의 수를 판독하기 어렵다.
- 튜닉은 허벅지 중간에서 끝나고 무릎을 덮지 않는다. 뒤로 늘어지는 천·망토·투구·장갑·무기는 없다. 가벼운 사슬·관절 보호대와 미세한 발광선을 사용했다.
- 머리는 귀를 덮고 위쪽 목덜미에서 끝나는 약한 굴곡의 청흑색, 이마는 노출한다. 회녹색 홍채와 눈 바깥 보랏빛 문양을 유지했다.
- 뺨 원본 코어 HSV 채도 하한은 평상시 185/255(0.725), hurt/death 210/255(0.824)로 정했다. 런타임 ROI 평균 하한은 0.42다. 마지막 death의 뺨 밝기는 190/255 이하로 내려 광택을 없앴다.
- 표기 변경 위치: data/siyavash.json, README_KO.txt, docs/STAGE13_REPORT_KO.md, docs/SPRITE_QA_REPORT_KO.md, tools/write_stage13_reports.py. scripts/dialogue_system.gd는 현재 캐릭터 표시 이름을 사용하게 했다. ID·폴더명 siyavash는 그대로다.
'''
    report='# 13단계 시야우와르샨 외형 재제작 — 2026-10-14\n\n가정·재량 값(이번 수정이 이전 외형 설명보다 우선한다):\n\n'+assumptions
    report+='\n새 기준 시트를 먼저 생성해 17개 클립 109프레임을 모두 새로 그렸다. 이전 캐릭터를 리컬러하거나 수정한 시트는 사용하지 않았다. 재생성한 클립은 idle/walk/run/crouch_enter/crouch_idle/crouch_exit/jump_start/jump_rise/fall/land/roll/drop_through/hurt/death/sit_down/sit_idle/stand_up이다. 잘린 run, 얕은 crouch_idle, 반복되는 walk, 착지 자세가 섞인 fall은 새 이미지로 다시 생성했다.\n\n'
    report+='생성 이미지의 크로마키는 배경과 연결된 마젠타만 제거해 장밋빛 뺨과 보랏빛 문양을 보존한다. 상태별 뺨 색과 생성 시 따뜻하게 변한 홍채는 PIL 색 보정으로 처리했으며, 홍채 보정은 눈 주변의 좁은 영역으로 제한했다. 런타임 modulate로 뺨의 상태 색을 바꾸지 않는다. 셀에는 물리적 2px 투명 테두리를 두고 기존 [320,600] 앵커를 유지한다.\n\n'
    report+='프로젝트에서 363px는 canonical 시트의 몸 높이 기준이다. 기존 표시 배율 0.30에서 화면 몸 높이는 약 109px이며, 니므롯/unarmed와 같은 크기를 유지했다. 저장 해상도를 게임 표시 키로 혼동해 확대하지 않았다. HP100·맨손·이동·폭주 비활성·R/L 비활성·F5 초기화는 기존 로직을 유지한다. 새 이름의 ‘샨’ 글리프가 기존 폰트에 없어 Korean UI 폰트 서브셋을 갱신하고 실제 glyph 존재 테스트를 추가했다.\n\n'
    report+=clip_table
    report+=f'\n시트 합계 {old_bytes:,}→{new_bytes:,} B ({(1-new_bytes/old_bytes)*100:.2f}% 감소). 모든 프레임 수·duration_seconds는 unarmed와 같고 공격 클립은 없다. 밀도는 0.8에서 시작해 SSIM≥0.93을 만족하는 값을 선택했다. idle/hurt/death는 눈·앞니 보존을 위해 2.0을 사용했다. run은 1.8→1.6으로 낮췄으며 일부 클립은 얼굴 보존/SSIM 기준 때문에 이전보다 높은 밀도가 필요했지만 전부 상한2.0 이내이고 전체 바이트 예산은 감소했다.\n\n'
    report+='검증 및 한계:\n\n- 신규 17클립: 오류0, sit_idle 루프 이음새 리뷰1. 전체482클립: 오류0, 기존 포함 리뷰48. 이는 GDScript 경고가 아니라 육안 검토 안내다. sit_idle의 미세 호흡·옷 변화는 유지했다.\n- 얼굴109프레임: 오류0. 흐려진 뺨·평상시 입의 흰 픽셀·잘못된 부상 색을 넣은 QA fixture는 모두 거부됐다. 기존 idle 뺨 ROI 평균 채도0.457→'+f"{face['new_idle_saturation_mean']:.3f}"+'로 증가했다.\n- 픽셀 검사는 HSV·영역·흰 하이라이트 검사다. 정확히 두 앞니인지, 귀의 아름다움이나 의상 의미는 자동으로 증명하지 않는다. 원본/저장 확대4장과 전체109프레임 접촉 시트로 별도 검수했다.\n- 최종 OpenGL: 685 단언/398 비교, 실패0. 최신 atlas 크기·선형 필터·양옆 이웃 프레임 번짐을 비교했다. 광장 1.0/1.35 줌8캡처,8단언 실패0. X11 드라이버의 VSync 지원 경고1은 런타임 코드 경고와 분리한다.\n- 알파651이미지·머리 위 잔상192클립·괴수 접지119스폰·크기23종·소품 접촉16검사: 실패0. 새 캐릭터 접지는 기존 collider와 발 앵커를 런타임에서 확인했다.\n- 이미지 인코딩 parity646이미지/2704프레임: 실패0. SSIM≥0.93, RGB 평균≤3, alpha 평균≤0.5, 인코딩 bbox 불변을 확인했다.\n- 미사용0·해시 중복0. crouch_idle/sit_idle 병합 후보는 SSIM0.985 기준과 절감 조건을 충족하지 않아 유지했고, idle의 시선 변화는 병합하지 않았다.167개 OGG는 모두 모노로 확인했다.\n'
    report+='\n새 파일: data/gayomaretan_style.json, data/siyavash_face_qa.json, assets/image_prompts/gayomaretan_common.md, assets/image_prompts/siyavash_reference.md 및 17클립 프롬프트, tools/build_siyavash_redesign.py, tools/check_siyavash_face.py, tools/optimize_siyavash_delivery.py, tools/write_siyavash_review.py, tools/write_siyavash_reports.py, tests/stage13_siyavash_redesign.gd, tests/stage13_siyavash_look_capture.gd, docs/SIYAVASH_LOOK_KO.md. 저장/불러오기 ID는 변경하지 않았다.\n\n이전 시트·기준 그림·실패 후보·변환 전 폰트·PNG 원본은 archive/siyavash_redesign_2026-10-14 및 archive/pack_source에 보존했다. archive/.gdignore와 배포 제외 규칙을 유지한다. 생성 불가/MISSING_TEXTURE 에셋은 없다.\n\n'
    report+='| 완료 항목 | 결과 |\n|---|---|\n'
    for item in ['17클립 전체 재생성','코·귀·앞니·회녹색 눈(수동 검수 포함)','뺨 강화/상태별 색/사망 광택 소멸','짧은 청흑색 머리','짧은 아베스타/SF 의상','날렵한 체형과 맨손','표기 전체 반영 및 폰트 glyph','공통 종족 데이터·프롬프트','기존 게임 규칙 유지']:report+=f'| {item} | ○ |\n'
    report+=f'| 전체 테스트·추출 패키지 검증 | {status} |\n| 교체 시트 기존 바이트 예산 | ○ |\n| ZIP62/60MiB 목표 | × |\n'
    history=ARCHIVE/'previous_stage13_report.md'
    if not history.exists():history.write_text((ROOT/'docs/STAGE13_REPORT_KO.md').read_text())
    (ROOT/'docs/STAGE13_REPORT_KO.md').write_text(report+'\n---\n\n이전13단계 구현 기록(외형·용량은 위 최신 수치를 따른다):\n\n'+history.read_text())
    look='# 시야우와르샨 외형 검수\n\n새 기준 시트와 17클립은 생성 이미지다. 아래4장은 새 canonical 원본과 런타임 WebP를 각각6배 확대한 얼굴, 게임 줌1.0/1.35의 몸 크기를 비교한다. JPG는 QA ZIP에만 포함하며 실행 ZIP에서는 제외한다.\n\n'
    for name,detail in [('idle','평상시 입은 닫혀 있고 짧은 청흑색 머리·작은 귀·회녹색 눈·장밋빛 뺨을 확인한다.'),('run','짧은 튜닉과 맨손, 경량 부츠, 닫힌 입을 확인한다.'),('hurt','2번 프레임. 이를 악문 앞니·선홍 뺨·귀의 긴장을 확인한다.'),('death','8번 마지막 프레임. 이를 악문 표정과 어두워진 선홍 뺨을 확인한다.')]:
        look+=f'{name}: {detail}\n\n![{name} 확대](siyavash_review/{name}_review.jpg)\n\n'
    look+='원본의 두 앞니 형태·귀의 크기·옷 길이는 수동 검수 대상이다. 낮은 게임 해상도에서는 치아 개수·3곳의 미세 흉터를 픽셀만으로 판독할 수 없다. 자동 검사 결과는 해당 색/영역 증거의 범위를 넘어서 해석하지 않는다. 전체 접촉 시트는 QA ZIP의 docs/siyavash_review/all_clips.jpg, 실제 장면8장은 같은 폴더의 runtime_*.png다.\n'
    (ROOT/'docs/SIYAVASH_LOOK_KO.md').write_text(look)
    size='# 용량 측정 — 시야우와르샨 재제작\n\n기능 검증과 용량 판정은 별도로 기록한다.\n\n| 단계 | assets MiB | 실행 ZIP MiB |\n|---|---:|---:|\n| 11 |61.15|69.42|\n| 12 |60.54|60.93|\n| 13 훔바바 수정 |65.13|'+f'{68782059/1048576:.3f}'+'|\n| 13 외형 재제작 |'+f'{sum(current.values())/1048576:.3f}|{package.get("zip_bytes",0)/1048576:.3f}'+'|\n\n'
    size+=f'기존 ZIP68,782,059 B. 새 ZIP은 최종 패키징 후 기록한다. 교체 시트 {old_bytes:,}→{new_bytes:,} B, 기존 {old_bytes:,}B 한도 통과. 기준 시트·구 시트·원본·QA 캡처는 runtime ZIP에 없다. 새 보스·FX·배경 이미지는 만들지 않았다.\n\n'+clip_table
    size+='\n| 카테고리 | 이전 MiB | 새 MiB | 변화 KiB |\n|---|---:|---:|---:|\n'
    for name in ['sprites/player','sprites/npcs','sprites/enemies','sprites/fx','backgrounds','props','tiles','audio','fonts','image_prompts']:
        size+=f'| {name} |{baseline.get(name,0)/1048576:.3f}|{current.get(name,0)/1048576:.3f}|{(current.get(name,0)-baseline.get(name,0))/1024:+.1f}|\n'
    size+='\n상위30시트+배경/소품12개를 source archive와 비교해 WebP74·128색 팔레트를 시험했다. Homeroad mid_district_tile 후보는 처음에 평균 색차를 통과했지만, 좌우 가장자리 색차와 정확한 반복 열 검사를 추가하자 실패해 원본으로 복원했다. deathsea stars_tile과 underground_fill 후보는 RGB/SSIM/bbox를 통과했어도 거의 검은 가장자리 알파 기준을 넘겨 원본으로 복원했다. stars는82/90, mid는82/90/94도 재검사했지만 정확한 타일 이음새까지 통과하는 절감 후보가 없어 유지했다. 나머지는 RGB평균3/255 초과, 현재 파일보다 큼 또는 품질 기준 미달이다. 실패 후보는 archive/.../compression_trials.json에 기록했다. 167 OGG가 모두 모노이며 이전 단계의 32kbps 변환을 유지했다.\n\n'
    size+='최종ZIP62MiB/60MiB 목표는 미달이다. 필요한 클립을 삭제하거나 품질/밀도 하한을 낮춰 맞추지 않았다. 추가 절감은 다음 후보를 단순한 생성 질감으로 다시 제작하고 같은 품질 기준을 확인해야 한다. 예상 절감은 확보한 용량이 아니다.\n\n| 큰 파일 상위20 | 현재 KiB | 유지 이유 | 다음 후보 / 예상 KiB |\n|---|---:|---|---:|\n'
    trials={r['path'].removeprefix('res://'):r for r in json.loads((ARCHIVE/'compression_trials.json').read_text())}
    largest=sorted((p for p in (ROOT/'assets').rglob('*') if p.suffix in ['.webp','.png']),key=lambda p:p.stat().st_size,reverse=True)[:20]
    for p in largest:
        rel=str(p.relative_to(ROOT));row=trials.get(rel,{});reason='품질 게이트/현재 크기 조건 미달'
        if 'stars_tile' in rel:reason='재인코딩 후 거의 검은 가장자리 기준 미달'
        elif row:reason='RGB 평균 색차 >3 또는 절감 없음'
        size+=f'| {rel} |{p.stat().st_size/1024:.1f}|{reason}|질감/색 수 단순화 후 재검증 / {p.stat().st_size*.10/1024:.1f}|\n'
    (ROOT/'docs/SIZE_REPORT_KO.md').write_text(size)
    qa_marker='\n## 시야우와르샨 재제작 검증\n'
    qp=ROOT/'docs/SPRITE_QA_REPORT_KO.md';q=qp.read_text().split(qa_marker)[0]
    qp.write_text(q+qa_marker+'\n17클립109프레임: 프레임 오류0/리뷰1, 얼굴 오류0. 전체482클립 오류0/리뷰48, 알파651이미지 실패0, head ghost192클립 실패0. 최신 import 후 OpenGL 685단언/398비교 실패0. 저장 밀도≤2.0, 물리적 gutter2px, 기존 canonical 앵커 유지. 원문 이름 변경 스캔과 Korean UI 샨 글리프 검증을 포함한다. 정확한 치아 개수와 귀/의상 의미는 docs/SIYAVASH_LOOK_KO.md의 수동 확대 검수로 보완한다.\n\n전체 추출 테스트 결과: '+status+'\n')
    rp=ROOT/'README_KO.txt';s=rp.read_text().split('\n[시야우와르샨 외형 재제작]')[0]
    rp.write_text(s+'\n[시야우와르샨 외형 재제작]\n17개 이동/자세 클립을 새 생성 이미지로 교체했습니다. 짧은 청흑색 머리, 작은 둥근 귀와 섬세한 쥐의 형질, 강한 장밋빛 뺨, 짧은 검은색/금색 아베스타 튜닉입니다. HP100·맨손·기존 이동/F5 초기화 규칙은 유지합니다. 기준 이미지와 원본은 archive에만 보존하며 배포에는 포함하지 않습니다.\n검수: python tools/check_siyavash_face.py --self-test\n문서: docs/STAGE13_REPORT_KO.md, docs/SIYAVASH_LOOK_KO.md, docs/SIZE_REPORT_KO.md\n')
    print('REPORTS: sheets',new_bytes,'runtime assets',sum(current.values()),'verified',args.verified)

if __name__=='__main__':main()
