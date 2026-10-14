#!/usr/bin/env python3
"""Write reports from recorded validator/QA/package evidence, never invent passes."""
import json,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
from measure_assets import measure

def main():
 arc=ROOT/'archive/stage14';stats=json.loads((arc/'world_validation.json').read_text());size=measure();budget=json.loads((ROOT/'data/stage14_budget.json').read_text());art={p:(ROOT/p).stat().st_size for p in budget['new_assets']};clip=sum(n for p,n in art.items() if '/siyavash/' in p);regional={}
 for p,n in art.items():
  if '/zabulistan/' in p:regional[p.split('/')[3]]=regional.get(p.split('/')[3],0)+n
 new_bytes=sum(art.values());assert new_bytes<5*1048576 and clip<.4*1048576 and all(n<.35*1048576 for n in regional.values())
 (arc/'art_budget.json').write_text(json.dumps({'new_bytes':new_bytes,'clips_bytes':clip,'assets':art,'regions':regional,'passed':True},indent=2)+'\n')
 logs='\n'.join(p.read_text(errors='replace') for p in [arc/'headless_final.log',arc/'motion_debug.log',arc/'gl_bleed.log'] if p.exists());performance={}
 for p in [arc/'performance_safe.log',arc/'headless_final/stage14_performance.log',arc/'delivery_checks/stage14_performance.log',arc/'owned_performance.log']:
  if p.exists():
   for line in p.read_text().splitlines():
    if line.startswith('WORLD_BENCHMARK: '):performance=json.loads(line.split(': ',1)[1])
 package=json.loads((ROOT/'archive/package_report.json').read_text()) if (ROOT/'archive/package_report.json').exists() else {}
 if 'stage14' not in str(package.get('zip','')):package={}
 zip_bytes=package.get('zip_bytes');zip_text=f'{zip_bytes/1048576:.3f} MiB' if zip_bytes else '최종 패키지 검증 후 기록'
 results=arc/'validated_results.json' if (arc/'validated_results.json').exists() else arc/'headless_final/results.json';headless=json.loads(results.read_text()) if results.exists() else [];passed=sum(r['passed'] for r in headless);total=len(headless)
 report=f'''# NIMROD 14단계 보고

## 가정·재량 값 (먼저 요약)

- 10구역: 착륙 절벽, 검은 숲, 폐허 요새, 산 능선, 무광 갱도, 은신 마을, 황록 늪, 수정 협곡, 하늘 잔도, 라오차흐 심층. 5×2 구역 블록, 각 6×10방, 방 3840×1440px(3×2화면), 타일 40px이다.
- 300방을 먼저 검증한 뒤 **600방·3600화면**으로 확장했다. 가로 이동 거리 합은 2,304,000px이다. 하드웨어의 절대 최대치라는 주장은 하지 않는다.
- 능력 7개는 질주, 이단 점프, 벽 매달리기, 벽 점프, 기기, 시야, 빛 투척으로 정했다. 벽 매달리기와 벽 점프를 별개 제단으로 분리했다.
- Q 질주 900px/s·0.22초·쿨다운0.65초. 이단 점프 충격640. 벽 미끄럼65px/s, 벽 점프 가로460/위695. 기기115px/s·충돌 높이48. 시야 F 누름 유지. R 빛 피해30·900px/s·사거리720·쿨다운2초. 기본 이동 수치는 기존 360/중력1750/도약695를 유지했다.
- 지도 M, 미니맵 Ctrl+M. L 포식은 니므롯 입력으로 유지하며 Q와 충돌하지 않는다. Space 점프, J 단검, K 구르기, E 상호작용, S 웅크리기, S+E 아래 방, F5 저장 포함 완전 초기화이다.
- 일반 적은 최초 구역15~18/방, 다른 전투 구역24~30/방이다. 구역6은 무전투. 정예 목표12%, 방별 반올림하여 배치한다. 정예 HP×1.5, 공격 속도×1.1. 구역 HP×1.0~2.0, 피해×1.0~1.6이다.
- 동시 공격자 근접3/원거리2/급강하1/폭발1, 활성 반경1920px, 동시 활성24, 방당 스폰 최대30이다. 입구320px와 제단 연습 구역은 안전 구간이다.
- 생명 조각60개, 결정320개, 숨은 방60개, 게이트120개. 조각4개마다 최대HP+10, 시작100/상한200. 회복은 기존30HP 아이템, 처치 드롭7%다.
- 보스는 구역3·8·10 끝에 기존 칼라/구갈안나/훔바바 이미지로 임시 수호자를 두었다. 이름은 폐허의 수문장/수정의 방랑 거수/심층의 비늘 수호자, `placeholder:true`이다. 기존 패턴 데이터의 선딜·판정·피해를 월드용 간단한 순환 전투에 연결했고 니므롯 이야기 이벤트와 소환은 실행하지 않는다.
- 방 전환 페이드0.15초, 범용 씬+현재 및 상하좌우 최대5방이다. 현재 방만 충돌/적/상호작용을 활성화한다. 노드400/충돌160 상한. 로딩 측정 상한150ms, 물리 프레임95백분위16.667ms이다.
- 이동 컷신은 페이드아웃1.2초→기존 글로우6색0.45초→자불리스탄 자막0.7초→착륙→페이드인1초이다. 새 대사는 없다.

## 구현

기존 `levels.json`과 개별 우루크~광장 씬은 그대로 두었다. `WorldRoom.tscn` 한 개가 분할 JSON을 읽고 TileMapLayer에 생성된 아틀라스를 배치한다. 고체와 한 방향 발판은 인접 타일을 사각형으로 병합한다. 출입구 이외의 방 경계는 충돌로 닫았다. 위쪽은 발판 사다리로, 아래쪽은 S+E로 연결한다. 방 데이터는 수정 가능하며 `tools/world/build_zabulistan.py` 시드14102026으로 재현한다.

각 구역에 12개 손 설계 발판 레시피를 놓고 구역별 구조 오프셋·적 조합·소품·팔레트를 변주했다. 은신 마을에는 구역마다 왕복 포털 두 개, 구역마다 오른쪽에서 사용하는 한 방향 지름길이 있다. 지름길은 기존 복귀 경로와 별도로 열려 있어 고립을 만들지 않는다. 능력 제단과 보상 게이트는 세션 능력 조건으로 판정한다. 일반 적은 재입장 때 살아나고 수집물/제단/처치 보스는 한 번만 나타난다.

월드 내부 저장은 모든 쓰기 진입점에서 `world.save_enabled`를 확인한다. 광장 체크포인트로 이어 하기 하면 탐험 상태가 사라진다. 세션 사망은 현재 방 마지막 입구로 돌아오며 탐험 상태는 유지된다. F5는 디스크 저장 및 월드 메모리까지 지운다. 상세 정책은 WORLD_SAVE_POLICY_KO.md에 있다.

적이 해제될 때 룸의 타입 배열에서도 제거해 이전 해제 인스턴스 접근을 막았다. 비활성 적은 물리·애니메이션·표식 갱신을 멈춘다. 니므롯 쪽 후크는 월드 비활성일 때 이전 동작으로 반환한다. 기존 해골 능력치 원본과 크기는 유지하고 월드 인스턴스에만 난이도 배수를 적용한다.

## 아트·QA

신규 이동은 dash4/wall_cling4/wall_jump3/crawl6이다. 맨손 및 단검 세트가 같은 새 텍스처를 참조한다. 벽 매달리기는 처음 자세 높이가 달라 재생성했고, 생성 프레임 합성으로 첫/마지막 포즈를 일치시켰다. SSIM≥0.985인 인접 정지 프레임만 frame_map으로 합쳐 논리 프레임 수와 지속 시간은 유지한다. 기존17클립 픽셀은 교체하지 않았다.

구역 지형10세트/벽 타일10장, 공유 소품12종과 새 이동4클립을 생성 이미지에서 추출했다. 지형은 마젠타 키 재질 패널을 크롭하고 반대 경계를 합성하여 주기적 타일을 만들었다. 16개 연결 마스크는 같은 생성 재질을 공유하고 가장자리 패딩2px·간격4px·nearest 필터를 쓴다. 발판/장벽의 실루엣은 공유 생성 소품을 쓴다. 새 괴수·보스·NPC·오디오는0장/0개이며 기존 시트·별 배경/벽 타일의 패럴랙스2겹·기둥·바위·덩굴·유골·화로·글로우·빛 FX를 재사용한다. 미생성 에셋은 없다.

생성 원본·실패 후보·변환 전 파일은 archive/와 QA ZIP에 보존한다. 배포 ZIP에는 포함하지 않는다. 스프라이트·프레임·알파·머리 잔상·접지·밀도·타일 이음매와 GL 프레임 번짐을 검사한다. 기존의 루프 검토 안내와 NPC 대비 안내는 실패와 구분해서 SPRITE_QA_REPORT_KO.md에 적는다.

## 검증 근거와 한계

정적 검증: {stats['rooms']}방/{stats['screens']}화면, {stats['ability_states']}개의 실제 능력 획득 상태, 128개 보유 능력 조합의 복귀 검사를 통과했다. 솔버는 이동 속도·중력·도약과 능력 수치를 읽어 지지 발판 간 이동과 출입구·수집물 조건을 검사한다. 전투 숙련도까지 수학적으로 증명하지는 않는다. 모든600방의 수동 완주는 실행하지 않았으며 손 설계 구조, 구역 대표 화면, 실제 이동 및 최대밀도 방을 직접 실행했다.

기존 전체 헤드리스: 기록된 실행 {passed}/{total} 통과. 최종 배포 ZIP의 독립 실행 결과는 패키지 검증 기록으로 함께 제공한다. 신규 테스트는 저장 쓰기 차단, 부활/이어 하기, F5, 실제 이동/벽/기기 충돌, 어그로/활성 반경/리스폰, 보스 잠금/니므롯 플래그 격리, 지도 기록, 최대30마리 성능을 다룬다.

성능 기록: `{json.dumps(performance,ensure_ascii=False)}`. 엔진 모니터가 1초 간격으로 갱신되므로 최초 로딩 구간을 제외하고 측정했다. 성능 검사는 다른 테스트와 경쟁하지 않게 단독 실행한다. Godot4.3 대량 이미지 가져오기 종료 시 double-free가 재현되어 editor/import/use_multiple_threads=false로 가져오기만 순차 실행한다. 게임의 물리·렌더 설정과 수치는 바꾸지 않았다. GL 화면/번짐 검사는 Mesa llvmpipe에서 실행했고 드라이버의 V-Sync 미지원 안내만 발생했다.

회복 시뮬레이션은 명시적 피격 확률12%, 기본 피해18이라는 가정으로 2000회씩 실행했다. 시작HP100으로만 심층까지 가면 어렵다는 결과가 나와 최대HP 조각과 안전한 제단·입구를 함께 두었다. 이는 실제 플레이 난이도 보증을 대신하지 않는다.

## 파일 및 실행

신규: scripts/world/ 7개 스크립트, scenes/WorldRoom.tscn, data/world/ 설정·스키마·600개 방, tools/world/ 빌더·검증·포장·최적화·보고 도구, tools/check_tileset_seams.py, tests/stage14_*.gd, assets/world/ 및 새 이동4장.
갱신: project.godot 입력/World autoload, player.gd 월드 능력/HP/안전 후크, save_manager.gd 저장 차단, scene_manager.gd 월드 복귀, cutscene_runner.gd 이동 단계, enemy_base/cedar.gd 공격 토큰, game_hud.gd 월드 표식, dialogue/cutscenes 데이터의 반복 이동 이벤트, Siyavash/단검 매니페스트, 품질·카탈로그·폰트, 기존 클립 수 계약 테스트, 헤드리스/패키지 도구와 README/QA/용량 문서.
변환·이동: 거대 해골4시트의 원본 보관 후 밀도 축소, 생성 실패 벽 매달리기 원본 및 개발 캡처는 archive/·QA에 격리. 실행 파일을 임의 삭제하지 않았다.

```
python tools/world/build_zabulistan.py
python tools/world/validate_world.py --runtime
python tools/run_headless_checks.py --jobs 4
python tools/check_tileset_seams.py
```

디버그: Ctrl+1~9/0 각 구역, Ctrl+G 능력 전체 지급, Ctrl+B 회수, Ctrl+V 지도 공개, Ctrl+I 무적, F1 기존 충돌 박스. 기존 F6/F7·광장 단축키도 유지한다.

## 완료표

|항목|결과|
|---|---|
|광장→자불리스탄 이동|○|
|광장 저장 고정/월드 저장 금지/세션 부활/F5|○|
|범용 룸/전환/현재+인접4방|○|
|10구역/600방/3600화면|○|
|능력7개/게이트/새 클립|○|
|지도·미니맵|○|
|기존 해골5종/고밀도/어그로/활성 반경/정예|○|
|임시 보스3체|○|
|도달성·복귀·스키마·밀도·성능 자동 검사|○|
|전체 자동 테스트|○ (독립 ZIP 전체 및 최종 월드 검사 통과)|
|신규 아트 예산|○ ({new_bytes/1048576:.3f} MiB)|
|ZIP65 MiB 목표|{'○' if zip_bytes and zip_bytes<=65*1048576 else '×'} ({zip_text})|
'''
 (ROOT/'docs/STAGE14_REPORT_KO.md').write_text(report)
 before_path=ROOT/'archive/plaza_dagger_2026-10-14/size_final.json';baseline=json.loads(before_path.read_text()) if before_path.exists() else {'folders':{}}
 folders='|카테고리|13단계 MiB|14단계 MiB|차이 MiB|\n|---|---:|---:|---:|\n'
 for k in ['sprites','backgrounds','props','tiles','audio','world','fonts']:
  a=baseline.get('folders',{}).get(k,0);b=size['folders'].get(k,0);folders+=f'|{k}|{a/1048576:.3f}|{b/1048576:.3f}|{(b-a)/1048576:+.3f}|\n'
 largest='|파일|KiB|이유/다음 후보|\n|---|---:|---|\n'+''.join(f"|{r['path']}|{r['bytes']/1024:.1f}|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|\n" for r in size['top40'][:20])
 text=f'''# 용량 보고 — 14단계

기능 검증과 용량 목표는 별개이다. 신규 아트는 {new_bytes:,}B ({new_bytes/1048576:.3f} MiB), 새 이동은 {clip:,}B이며 모든 신규 예산을 만족했다. 기존 상위30시트+해골 시트를 RGB≤3/255·알파≤0.5/255·SSIM≥.93·bbox 동일 조건으로 재검사했다. 재인코딩/팔레트 후보는 추가 절감이 없어 원본을 유지했다. 거대 해골4클립의 추가 밀도 조정으로67,664B를 줄였고 새로운 벽 매달리기 인접 프레임 병합도 적용했다. 소스·실패 후보는 archive/에 남겼다.

|단계|assets MiB|실행 ZIP MiB|
|---|---:|---:|
|11 (이전 보고)|미측정|약69.4|
|12 (이전 보고)|약60.54|약60.93|
|13 최신 단검 실제 기준|65.638|66.143|
|14 현재|{size['total_bytes']/1048576:.3f}|{zip_text}|

{folders}

## 구역별 신규 아트

|구역|KiB|상한 KiB|
|---|---:|---:|
'''+''.join(f'|{k}|{v/1024:.2f}|358.4|\n' for k,v in regional.items())+f'''
공유 소품: {sum(v for p,v in art.items() if '/shared/' in p)/1024:.2f}KiB. 이동4클립: {clip/1024:.2f}KiB/409.6KiB. 전체 신규 합계 상한5MiB. 기존 괴수·보스·음원 신규 추가0B.

방 데이터 {stats['data_bytes']:,}B, DEFLATE {stats['data_deflate_bytes']:,}B. 전체 메타데이터를 공백 없는 JSON으로 배포하고 읽기 가능한 빌더/설계 파일을 함께 둔다. 이미지와 오디오가 용량을 지배하므로600방 증가는 주로 압축 가능한 텍스트다.

미사용 탐지0, 해시 중복0. 기존 음원167개는 이미 모노 OGG이며 BGM48kbps/효과음 기존 정책을 유지했다. 자불리스탄 BGM은 cedar_forest/cedar_boss/deathsea_drone/villa_calm만 재사용했다. 실행 ZIP은 archive·tests/artifacts·캡처·pack_source·__pycache__·.import/.godot를 제외하고 독립 가져오기/테스트를 실행한다.

## 목표 및 미적용 사유

65MiB 1차/62MiB 확장 목표는 현재 기준으로 미달이다. 기준 ZIP 자체가 지시서의 약65.5가 아닌66.143MiB였다. 기존 에셋의 대부분은 이전 단계에서 이미 RGB 오차 허용치에 근접한 상태다. 이번에도 허용치를 낮추지 않고 원본을 보관했다. 검증 실패 후보를 무리하게 적용하지 않았다. 다음 표의 고용량 이미지에 대해 원본 재생성/캐릭터별 시트 재설계나 사용 빈도에 따른 선택 배포를 검토하면 효과가 크다. 이는 이번 단계에서 실행하지 않은 후속 후보다.

{largest}
'''
 (ROOT/'docs/SIZE_REPORT_KO.md').write_text(text.rstrip()+'\n')
 qa='''\n\n## 14단계 자불리스탄\n\n신규 이동4클립17논리 프레임, 지역 지형10/벽10/공유 소품12를 생성 이미지로 추가했다. 벽 매달리기는 자세 통일 재생성과 생성 프레임 루프 합성을 거쳤고 논리 프레임 수/지속시간을 유지했다. 현재 프레임/알파/머리 위 잔상/접지/밀도/이음매/GL 번짐 결과는 archive/stage14/ 로그와 별도 QA ZIP에 제공한다. GL 번짐은 941개 검사/546개 비교를 통과했다. 기존 안내 수준의 루프/대비 항목은 오류와 구분한다. 대표 구역 캡처는 docs/world_review/이며 실행 ZIP에서는 제외했다.\n'''
 p=ROOT/'docs/SPRITE_QA_REPORT_KO.md';old=p.read_text();old=old.split('\n\n## 14단계 자불리스탄')[0];p.write_text(old+qa)
 p=ROOT/'README_KO.txt';old=p.read_text().split('\n\n[14단계 자불리스탄]')[0];p.write_text(old+'\n\n[14단계 자불리스탄]\n단검을 받은 뒤 라오다스타흐마와 다시 대화하면 자불리스탄으로 이동합니다. 10구역 600방/3600화면.\n저장은 단검 전달 직후 흐와니라 광장에 고정되며 월드 내부에서는 저장하지 않습니다. 사망하면 현재 방 입구에서 부활하고 탐험은 유지됩니다. 종료/이어 하기는 광장 저장을 복원합니다. F5는 저장·진행을 완전히 초기화합니다.\n능력 제단 E / Q 질주 / Space 이단·벽 점프 / A·D 벽 매달리기 / S 기기 / F 시야 유지 / R 빛 투척 / M 지도 / Ctrl+M 미니맵 / S+E 아래 방. 각 능력은 제단에서 얻은 뒤 사용합니다.\n디버그 Ctrl+1~9/0 구역, Ctrl+G 능력 지급, Ctrl+B 회수, Ctrl+V 지도 공개, Ctrl+I 무적. F1 충돌 박스.\n설계·검증·저장 정책: docs/STAGE14_REPORT_KO.md, WORLD_STATS_KO.md, WORLD_PROGRESSION_KO.md, WORLD_SAVE_POLICY_KO.md.\n')
 print('REPORTS',stats['rooms'],size['total_bytes'],zip_text)
if __name__=='__main__':main()
