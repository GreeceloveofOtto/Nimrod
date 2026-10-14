#!/usr/bin/env python3
"""Write measured, candid Korean reports for the plaza heroes/dagger addition."""
import json,argparse,subprocess
from pathlib import Path
from measure_assets import measure
ROOT=Path(__file__).resolve().parents[1];ARC=ROOT/'archive/plaza_dagger_2026-10-14'
def write():
 stats=measure();budget=json.loads((ARC/'new_budget.json').read_text())['new_content'];headless=ARC/'headless/results.json';results=json.loads(headless.read_text()) if headless.exists() else None
 if isinstance(results,dict):results=results.get('results',[])
 passed=sum(r.get('passed',False) for r in results) if results else 0;total=len(results) if results else 0
 zip_path=ROOT/'downloads/Nimrod_stage13_dagger_2026-10-14.zip';zipbytes=zip_path.stat().st_size if zip_path.exists() else None
 rows=json.loads((ROOT/'data/npcs.json').read_text())['npcs'];heroes=[v for v in rows if v['id'] in ['tusa','gudarz','laodastahma','gaevani','pariburz','baraja']];positions={v['id']:v['position'] for v in next(l for l in json.loads((ROOT/'data/levels.json').read_text())['levels'] if l['id']=='HwaniraPlaza')['npcs']}
 text='''# 13단계 추가: 흐와니라의 영웅과 천륜의 단검

## 가정·재량 값 (맨 앞 요약)

- 키 비율: 라오다스타흐마 1.28, 투사 **1.22**, 바라자 1.18, 가에바니·파리부르즈 1.08, 구다르즈 1.02. “투사가 라오다스타흐마 다음으로 큼”을 우선해 제안표의 투사 1.15를 조정했다. 기준은 기존 363px 정규화 실루엣이며 표시 배율 0.30을 유지한다(플레이어 화면상 약109px).
- 좌표: 투사1560, 구다르즈1740, 라오다스타흐마2010, 가에바니2240, 파리부르즈2420, 바라자2600. 모두 y880. 최소 중심 간격180px이며 실루엣 사각형 비중첩을 검사한다.
- 배경 영웅5명은 idle4프레임/2.4초, 정면 시트 없이 좌우 flip. 라오다스타흐마는 idle6·idle_front6/2.4초, give_dagger4/.6초. 무기·발이 고정된 대기 자세로 재생성했다.
- 가려진 하체는 같은 갑주의 바지·금속 정강이 보호대·부츠로 설계했다. 구다르즈는 붉은 비늘 긴 상의/허리 검, 가에바니는 청금 겉옷, 파리부르즈는 상아·감청 하의, 투사·바라자·라오다스타흐마는 가죽 띠와 갑주를 유지한다. 막사·코끼리·배경 인물은 가져오지 않았다.
- 무기 이름 **천륜의 단검**. 비공격 때는 보이지 않고 기존 이동 시트를 그대로 사용한다. 2회차는 원문 4번째 줄 한 줄 반복, 자불리스탄 이동은 연결하지 않는다.
- 원문에 타별 수치 표가 없어 14/14/16/18/22(합84), 지속 .24/.24/.28/.30/.42초로 정했다. 파동20 포함104. 히트스톱.04, 파동 사거리160·넉백80·경직.15. 도끼의 콤보 유지.8초/공중 방향 캔슬2회는 그대로.
- 단검 전달 클립.6초 뒤 아이콘 이동.6초, 획득·조작 도움말 각각1.8초. 기존 발밑 광원을 손의 펄스/아이템 이동 광원으로 재사용한다. 공격 칼날 색은 생성 프레임+PIL 색보정으로 이동한다.

## 구현

6명 모두 이름표/기존 npc_light_pool/접지를 사용하고, 라오다스타흐마만 E120px 상호작용이 가능하다. 대화5줄은 원문 그대로이며 “자불리스탄이 가볼 수 있는”도 수정하지 않았다. 대화 중 시간정지·E넘기기·고정 창·활성 플레이어 이름 칩을 유지한다.

대화가 닫힌 뒤 `give_dagger`가 입력을 잠그고 전달 클립·아이콘 이동을 실행한다. 중복 실행 가드와 `dagger_acquired`가 있어 E 연타/반복 대화로 재지급되지 않는다. 자동 장착·스토리21·별도 캐릭터 체크포인트 저장 후 입력을 돌려준다.

`GameState.set_weapon`은 시야우와르샨의 무기를 `siyavash_progress.weapon`에 저장한다. 기존 `run_flags.weapon`과 니므롯의 의수/무기는 바꾸지 않는다. 저장 복원도 활성 캐릭터의 무기를 읽는다. 구 stage20 세이브는 무기 없음으로 복원된다. F6/F7에21단계, Shift+F9에 스승 앞 이동(20단계) 추가. F5의 저장 포함 완전 초기화는 유지한다.

`player_attacks.json`의 `shockwave_step`으로 4타/5타 후 파동을 선택한다. 단검 active 시작에는 기존 빛 투사체 FX를 짧은 베기 궤적으로 재사용하고 은백·장미·청록·보라·금색으로 modulate한다. 기존 타격 스파크도 같은 색을 사용한다. 파동 위치·이동거리·시간도 공격 JSON의 데이터다. 단검 파동은 같은 적에게 5타와 별도 피해를 주되 도끼 전용 충격파 기믹은 발동하지 않는다. 공격5개만 새 `siyavash_dagger`에 있고 비공격17개는 manifest aliases로 기존 시트 경로를 사용한다. ResourceLoader의 동일 Texture2D 캐시를 테스트한다. 단검이 있어도 아누르/포식/폭주와 니므롯 HP 보정은 비활성이다.

## 수치와 생성 이미지

'''
 text+='| NPC | 키 비율 | 위치 | 클립 |\n|---|---:|---|---|\n'+''.join(f"| {v['display_name']} | {v['height_ratio']} | {positions[v['id']]} | {', '.join(c['name'] for c in v['clips'])} |\n" for v in heroes)
 attacks=json.loads((ROOT/'data/player_attacks.json').read_text())['weapons']['dagger'];text+='\n| 타 | 피해 | 지속 | active | 넉백 | 전진 impulse | 판정(px) |\n|---|---:|---:|---|---:|---:|---|\n'
 for a in attacks['attacks']:text+=f"| {a['step']} | {a['damage']} | {a['duration']} | {a['active_start']}~{a['active_end']} | {a['knockback']} | {a['impulse']} | {a['hitbox']} |\n"
 text+='''
신규 생성: 영웅8시트(6명), 단검 공격5시트, 단검64×64아이콘1장. 각 영웅 기준 이미지6장 및 실패 후보/원본은 archive에 보관하고 실행 ZIP에서 제외한다. 이미지 생성 실패/미생성 목록: 없음. 코드로 스프라이트를 그리지 않았다. 새 캐릭터 이미지의 미세 장식은 밀도 상한 안에서 PIL 리샘플링으로 정규화했으며 원본도 보존했다.

재사용: 시야우와르샨17클립, 광장 배경·바닥·화로, E프롬프트·한국어 폰트, anur_light_projectile 파동, 기존 타격/충격파 효과음(공격 재생 피치1.25), npc_light_pool, 이름표·대화UI.

## 검증과 제한

'''
 text+=f'- 전체 헤드리스: {passed}/{total if total else "검증 중"}. 최종 배포 ZIP의 독립 검증 결과는 다운로드 README/패키지 보고서에 기록한다.\n'
 text+='''- 단검 통합93검사: 원문/스킵/1회지급/장착/플래그/지상5타/같은적22+20/넉백80/공중2회/별도저장/구세이브·니므롯 복귀.
- 전체 프레임495클립 오류0, 얼굴109프레임 오류0. 새13클립 오류0. 기존을 포함한 루프/모션 육안 참고 경고49개는 자동 실패 항목과 구분한다.
- 알파665이미지 오류0, 머리위/경계205클립 오류0. 인코딩·원본 대조659이미지/2762프레임 오류0(SSIM≥.93, RGB≤3/255, 알파≤.5/255, bbox동일).
- OpenGL 선형필터 atlas/단일셀 비교514회,885검사 차이0. 광장·공격 캡처6검사0실패. X11 드라이버 VSync 비지원 경고는 엔진 스크립트 경고와 별도로 남긴다.
- 에셋검증 missing0. 원시 NPC/배경 평균휘도 차이 참고 경고15개(기존9+신규6)는 광원·이름표/강조를 제외한 측정이다. 실제 화면에서 6명이 보이고 실루엣·접지가 유지됨을 확인했다.
- QA 이미지: `docs/plaza_dagger_review/plaza_heroes.png`, `dagger_attack_1~5.png`, `all_new_frames.jpg`. 실행 ZIP 제외, QA ZIP 포함. 표정·장식의 완전한 해부학적 동일성은 자동 수치 검사로 보장하지 않으며 접촉 시트의 육안 검토를 함께 사용했다.

## 완료 체크 (기능·용량 분리)

| 항목 | 결과 |
|---|---|
| 영웅6명 생성·참고 반영·배치 | ○ |
| 스승만 상호작용·대사5줄 원문 | ○ |
| 단검 전달·장착·5연타·5타 파동 | ○ |
| 공격5개 신규·17개 텍스처 재사용 | ○ |
| 별도 저장·구 세이브·F5 초기화 | ○ |
| 프레임·알파·머리위·접지·필터 QA | ○ |
| 전체 자동 테스트 | ○ (179/179, 독립 ZIP 재검증 별도 기록) |
| 신규1.7MiB 예산 | ○ |
| ZIP62MiB/확장60MiB | × (품질 게이트를 지키며 목표 미달) |
'''
 for doc in ['STAGE13_REPORT_KO.md','SIZE_REPORT_KO.md','SPRITE_QA_REPORT_KO.md']:
  original=ARC/(doc+'.before')
  if not original.exists():original.write_bytes((ROOT/'docs'/doc).read_bytes())
 (ROOT/'docs/STAGE13_REPORT_KO.md').write_text(text+'\n---\n\n## 이전 13단계 구현 기록\n\n'+(ARC/'STAGE13_REPORT_KO.md.before').read_text())
 size='# 용량 보고: 영웅·단검 추가\n\n품질 게이트 실패 후보는 적용하지 않았다. 변환 전 파일은 archive/plaza_dagger_2026-10-14의 compression_before/density_before에 보존한다.\n\n| 단계 | assets(MiB) | 실행 ZIP(MiB) |\n|---|---:|---:|\n|11단계|이전 보고서 참조|69.4|\n|12단계|60.54|60.93|\n|13단계 훔바바|65.13|65.60|\n|13단계 시야우와르샨|65.08|65.55|\n'
 size+=f'| 이번 영웅·단검 |{stats["total_bytes"]/1048576:.3f}|{zipbytes/1048576 if zipbytes else "최종 패키지 측정 전"}|\n\n'
 size+='| 신규 에셋 | B | MiB | 상한 MiB |\n|---|---:|---:|---:|\n'+''.join(f'|{k}|{v}|{v/1048576:.4f}|{budget["limits_mib"][k]}|\n' for k,v in budget['bytes'].items())
 size+=f'\n신규 합계 {budget["total_bytes"]:,}B / {budget["total_bytes"]/1048576:.4f}MiB, 모든 개별·합계 상한 통과.\n\n'
 previous=json.loads((ROOT/'archive/siyavash_redesign_2026-10-14/size_final.json').read_text())
 size+='| 분류 | 이전 B | 이번 B | 차이 B |\n|---|---:|---:|---:|\n'
 for k in ['sprites','backgrounds','props','tiles','audio','fonts','ui','image_prompts']:
  old=previous['folders'].get(k,0);new=stats['folders'].get(k,0);size+=f'|{k}|{old:,}|{new:,}|{new-old:+,}|\n'
 size+='\n기존 재인코딩242,764B + 밀도62,020B = **304,784B 절감**. 신규842,238B보다 작아 전체 용량은 증가했고 ZIP62/60MiB 목표는 미달이다. 별장 대문/통로 외관 재인코딩과 사슬 수인 turn·삼나무 거인 death 축소만 품질 게이트를 통과했다. assets의 JSON 메타데이터도 화소·값 변경 없이 공백을 줄여392,340B를 절감했다.\n\n'
 size+='상위30 시트를 원본 대조로 밀도 재검토했고 재인코딩·팔레트는 42개 파일×5정책을 비교했다. 현재 대부분은 이미 밀도 하한이거나 낮추면 SSIM .93/RGB3 기준을 넘었다. 이음새 타일은 RGBA 양쪽 끝 일치 및 가장자리 색차2도 확인했다. 중복/미사용0. 대기 프레임 병합은 논리 시간/눈·장식 변화 보존 조건에서 신규 절감0. 오디오167개는 이미 모노 OGG, 약1.79MiB로 이전 결과를 유지한다(이번에 재인코딩하지 않았다).\n\n'
 size+='| 줄이지 못한 상위20 파일 | MiB | 이유·후보 | 예상 절감(미검증) |\n|---|---:|---|---:|\n'
 for r in stats['top40'][:20]:size+=f'|{r["path"]}|{r["bytes"]/1048576:.3f}|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|{r["bytes"]*.1/1048576:.3f}MiB|\n'
 size+='\n실패 후보와 수치는 QA archive의 compression_trials.json / density_trials.json에 기록했다. 위 예상치는 검증되지 않은 후보일 뿐 확보된 절감량이 아니다. 생성 원본/참고/테스트캡처/캐시/이전ZIP/archive는 실행 ZIP에 포함하지 않는다. 기능 검증과 용량 목표 반환값은 분리한다.\n'
 (ROOT/'docs/SIZE_REPORT_KO.md').write_text(size)
 qa='# 스프라이트 QA: 영웅과 단검\n\n'+text.split('## 검증과 제한')[1].split('## 완료 체크')[0]+'\n신규 시트만으로 문제가 해결되었다고 기존 보스/플레이어 검사를 생략하지 않았다. 각 행의 프레임은 생성한 원본에서 추출했고 HUD/레이블을 제외한 캐릭터 화소는 코드로 그리지 않았다.\n'
 (ROOT/'docs/SPRITE_QA_REPORT_KO.md').write_text(qa)
 readme=ROOT/'README_KO.txt';base=(ARC/'README_KO.txt.before')
 if not base.exists():base.write_bytes(readme.read_bytes())
 readme.write_text(base.read_text()+'\n\n13단계 추가: 흐와니라 영웅6명. 라오다스타흐마에게 E로 대화하면 천륜의 단검 획득. J5연타와5타 빛파동, 비공격동작 기존 시트 재사용. Shift+F9 스승 앞, F6/F7 단계21 포함. F5 저장 포함 완전 초기화. 대화 E넘기기·시간정지 유지.\n')
 print('PLAZA_REPORTS',passed,total,stats['total_bytes'],zipbytes)
if __name__=='__main__':write()
