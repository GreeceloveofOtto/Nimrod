#!/usr/bin/env python3
"""Materialize measured Korean reports; never turn incomplete checks into passes."""
import json,subprocess,hashlib
from pathlib import Path
from collections import defaultdict
R=Path(__file__).resolve().parents[1]
def load(p):return json.loads((R/p).read_text())
def mib(n):return f'{n/1048576:.2f}'
def main():
 inventory=load('data/stage13_asset_inventory.json');new=defaultdict(int);folders=defaultdict(int);all_files=[]
 for p in (R/'assets').rglob('*'):
  if not p.is_file() or p.suffix in ['.import','.uid']:continue
  folders[p.relative_to(R/'assets').parts[0]]+=p.stat().st_size
  if p.suffix in ['.webp','.png','.ogg']:all_files.append(p)
 for path in inventory['generated']:
  category=next((v for v in ['siyavash','ninazu_mother','lilith','zu'] if '/'+v+'/' in path),'backgrounds' if '/backgrounds/' in path else 'props_tiles');new[category]+=(R/path).stat().st_size
 archive=R/'archive/stage13';baseline=63482603;assets=sum(folders.values());zip_path=R/'downloads/Nimrod_stage13_2026-10-13.zip';zip_bytes=zip_path.stat().st_size if zip_path.exists() else 0
 from check_sprite_frames import frame_images,paths
 m=R/'assets/sprites/player/siyavash/manifest.json';c=load(str(m.relative_to(R)))['clips'][0];bbox=frame_images(paths(m,c),c)[0].getchannel('A').point(lambda a:255 if a>12 else 0).getbbox();height=bbox[3]-bbox[1]
 size=['# 13단계 용량 측정','', '| 단계 | assets | 실행용 ZIP |','|---|---:|---:|',f'| 11 | 61.15MiB | 69.42MiB |',f'| 12 | 60.54MiB | 60.93MiB |',f'| 13 | {mib(assets)}MiB | {mib(zip_bytes)}MiB |','','신규 이미지 총 '+mib(sum(new.values()))+'MiB. 신규 개별 예산은 모두 통과했으나, 전체 ZIP 62MiB 목표는 미달이다. 기능 검증과 용량 판정은 별도로 기록한다.','','| 신규 항목 | 사용 | 상한 |','|---|---:|---:|']
 budgets={'ninazu_mother':1.2,'lilith':1.2,'zu':1.2,'siyavash':2.,'backgrounds':1.5,'props_tiles':.4}
 for k,v in new.items():size.append(f'| {k} | {mib(v)}MiB | {budgets[k]}MiB |')
 size+=['','| 카테고리 | 12단계 | 13단계 |','|---|---:|---:|']
 before={'sprites':46129796,'backgrounds':6185204,'props':7326386,'tiles':1626750,'audio':1940060,'fonts':128064}
 for k,v in before.items():size.append(f'| {k} | {mib(v)}MiB | {mib(folders[k])}MiB |')
 sub=defaultdict(int)
 for p in (R/'assets/sprites').rglob('*'):
  if p.is_file() and p.suffix not in ['.import','.uid']:sub[p.relative_to(R/'assets/sprites').parts[0]]+=p.stat().st_size
 size+=['','13단계 sprites 세부: '+', '.join(f'{k} {mib(v)}MiB' for k,v in sub.items()),'', '적용과 되돌림:', '', '- 신규 보스 저장 밀도는 0.9를 시작값으로 삼고 SSIM 0.93 이상을 통과한 밀도만 적용했다. 앵커와 게임 표시 크기는 유지했다.', '- 흐와니라 배경은 원본 생성 이미지의 측면 건축 영역을 합성해 3200×896으로 저장했다(4000×1120 표시, 밀도 0.8). 항성이 잘리던 구도는 이미지 생성으로 수정했다.', '- 배경의 낮은 휘도는 색보정으로 정리하고 게임에서는 modulate로 어둡게 했다. 단색 검은 테두리를 덧그리지 않았다.', '- 배경의 채널별 색 양자화는 원본 대비 RGB 평균 ≤3/255, 알파 불변, SSIM ≥0.93인 결과만 채택했다.', '- 기존 상위 30개 시트를 낮은 밀도, WebP RGB 품질 82/86/90/94/98, 채널별 색 양자화와 near-lossless 0/20/40/60으로 검사했다. 현재 파일보다 작고 품질 게이트를 통과하는 경우만 적용했다. 대부분은 색차가 3/255를 넘거나 기존 파일보다 커서 유지했다.', '- 인접 프레임은 SSIM ≥0.985일 때 frame_map으로 병합했다. 논리 프레임 수와 총 재생 길이는 그대로다. 회전 클립은 최소 3개 저장 프레임을 유지한다.', '- BGM mono 32kbps 후보 중 샘플 수, 루프 이음새(기존+0.01 이내), 피크(<0.99), 파일 크기를 모두 통과한 5곡을 채택해 0.0575MiB 줄였다. 44.1kHz/24kbps는 libvorbis가 거부해 적용하지 않았다.', '- 미사용 이미지/오디오 0개, 해시가 동일한 중복 파일 0개. 활성 클립·폴더를 삭제해 예산을 맞추지 않았다.', '- 변환 전 파일과 실패 후보는 archive/stage13 및 기존 archive/pack_source 계열에 보존했다. archive에는 .gdignore를 두고 실행 ZIP에서 제외했다.','','상위 20개 큰 파일과 다음 후보(예상 절감은 재검증 전 추정):','','| 파일 | 현재 | 유지 이유 | 다음 후보 / 예상 |','|---|---:|---|---|']
 for p in sorted(all_files,key=lambda p:p.stat().st_size,reverse=True)[:20]:
  size.append(f'| {p.relative_to(R)} | {mib(p.stat().st_size)}MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 {mib(int(p.stat().st_size*.15))}MiB |')
 size+=['','62MiB를 맞추려면 약 '+mib(max(0,zip_bytes-62*1048576))+'MiB 추가 절감이 필요하다. 현재 품질 기준을 그대로 유지하는 자동 변환에서는 이만큼의 여유가 확인되지 않았다. 큰 보스 원본의 세부 질감을 줄여 재생성하는 작업이 가장 큰 후보이며, 단순한 품질 하향이나 활성 모션 삭제는 적용하지 않았다.']
 (R/'docs/SIZE_REPORT_KO.md').write_text('\n'.join(size)+'\n')
 assumptions='''## 가정·재량 값 요약

- `home_11days` 직후에는 임종 전 마지막 대화를 유지한다. `enkidua_gone` 이후에는 어느 시간 경과·저장 복원에서도 엔키두아가 없고 침대 피 흔적은 계속 남는다.
- 폭주 컷신과 보스전은 100/r90 및 폭주 즉사 정지를 유지한다. 보스 3체를 처치한 뒤에만 90으로 낮추고 예외를 해제한다. HP 0의 일반 사망은 막지 않는다.
- 이동 속도: 니나즈의 어미 55, 릴리스 280, 괴물새 주 130px/s. 주요 패턴 간 대기 0.8초, 도착 페이드 후 전투 준비 1.2초. 별도 보스 대사 원문이 없으므로 대사를 추가하지 않고 이 준비 구간 뒤 전투를 시작한다.
- 패턴 쿨다운: 어미 독액 5.8/꼬리 3.2초, 릴리스 기습 5.5/매혹 6.0초, 주 깃털 4.8/잡기 7.0초. 엔키두아 잔상은 4.5초에 준비되며 이미 진행 중인 큰 패턴이 끝날 때까지 겹치지 않게 지연한다.
- 회복: 기존 +30 HP 아이템을 x=450/1050/1700/2650, y=880에 배치하고 소비된 지점만 18초마다 보충한다.
- 아레나 3200px, 티아마트 붕괴 구역 3000px, 광장 4000px. 가지 높이는 지면 위 90/180/270px, 체인 수평 간격은 180~220px(발판 폭 220으로 간극은 200 이내).
- 시야우와르산은 성년 초입 20세, 곧고 맑은 표정, 인간형(동물 특징 없음), 미세한 SF 금빛 반사로 정했다. 장밋빛 양 뺨은 종족 설정을 반영했다. 안내 문구는 `아직 무기가 없다`.
- 광장 소품은 기존 성 앞 화로를 재사용한다. BGM은 `villa_calm`, 아레나는 `cedar_boss`, 티아마트는 `deathsea_drone`을 재사용한다.
- 노인 피 웅덩이는 (1450,862), 400×18px, 화면이 돌아오면 접지된 납작한 형태로 보인다. 난도질은 기존 완전한 4타 클립을 2회 재생해 약 3.24초, 페이드아웃 2.5/페이드인 1.2초다.
- 릴리스의 기습 방향은 준비 중 턴 클립으로 맞춘다. 조작 반전은 A/D 이동 및 그 축을 사용하는 구르기·방향 공격 입력에 적용하며 W/S 선택 메뉴에는 적용하지 않는다.
- 티아마트 접근 트리거 x=2380, 본체 x=2760(거리 380px), 대화 종료 뒤 10초, 암흑 3초. 맥동은 생성 이미지의 scale/modulate와 알파 렌더링으로 표현한다.
- 저장 아이콘이 12단계에 없으므로 새 월드 이미지를 만들지 않고 화면 우하단에 작은 코드 UI `저장` 표시를 0.6초 띄웠다. 선택 메뉴는 키보드만 지원한다.
'''
 report='# NIMROD 13단계 보고서\n\n'+assumptions+'''\n## 원인과 수정

12단계에는 이미 레벨 로드 시뿐 아니라 Story.changed에서도 NPC 존재 조건을 갱신하는 코드가 있었다. 동일 레벨 `go_to`도 실제로는 레벨을 재생성했다. 따라서 제시된 원인 가설 중 “갱신 자체가 없음”은 현재 코드와 달랐다. 재현된 확실한 버그는 `home_after_loss`가 `bed_blood=false`를 설정한다는 점이다. 이를 제거하고 `enkidua_gone`이면 피 플래그를 항상 유지했다. NPC 처리는 `LevelBase.reconcile_presence()`로 정리했으며 레벨 갱신·이동·저장 복원에 적용했다. 이미 생성된 부적합 NPC는 registry와 scene에서 즉시 제거한다. 일반 엔키두아(1000,620), 침대 인스턴스, 인안나 및 모든 presence NPC에 적용된다. 침대 피의 위치는 prop_contacts.json을 그대로 사용했다.

컷신 복구에서 해제된 일시 효과 노드를 키로 가진 Dictionary를 직접 순회하면 대기가 끝나지 않는 경우도 재현됐다. actor_states.keys()의 목록을 복사해 순회하고 일시 효과를 최종 정리한다. 오디오·대화의 같은 종류 복구 순회도 목록을 사용한다.

## 이야기와 저장

`TiamatZone → 우트나피쉬팀 대화/폭주 → 훌루푸 E → HuluppuCrown → TiamatCollapsed → 티아마트 대화 → 10초 자유 조작 → 암흑/선택 대기 자동 저장 → 라오차차흐라 선택 → HwaniraPlaza`.

우트나피쉬팀 6줄과 티아마트 2줄은 독립 문자열 fixture와 문자 단위로 비교한다. 대화는 기존 시간 정지·E 건너뛰기·이름 칩·우측 중앙 창을 사용한다. 티아마트 배경만 대화 연출의 렌더 맥동을 수행하고 AI·위험 지대·전투 타이머는 정지한다.

stage19는 `utnapishtim_done/huluppu_boss_done/tiamat_talk_done`, stage20은 `system_laochachahra_selected/siyavash_started`다. stage20 진행은 siyavash_progress에 두고 기존 니므롯 run_flags를 보존한다. 저장에는 active_character, siyavash_progress, nimrod_status, choice_pending, selected_system, story_stage를 추가했다. 구 12단계 저장은 새 필드가 없어도 기본값으로 복원된다. 선택 대기 저장은 장면을 반복하지 않고 검은 선택 메뉴로 바로 돌아온다. 컷신 완료와 선택 암전·캐릭터 도착에만 조용한 체크포인트 저장을 한다. 보스전 저장은 차단한다.

시야우와르산 HP는 data/siyavash.json의 100이고 니므롯의 HP 보정·의수·폭주·멜람무·L·R을 비활성화한다. 무기는 없고 J는 안내만 한다. 17개 모션의 논리 프레임 수와 길이는 unarmed와 같다. 앉기 세트도 생략하지 않았다. F5는 저장/백업/임시 파일과 두 캐릭터 상태를 모두 지우고 니므롯의 집으로 초기화한다.

디버그: F6/F7 단계 19/20 포함, Shift+F10 노인 대화 직전, F10 아레나, F11 티아마트, F12 선택 메뉴, Shift+F11 시야우와르산 광장. 기존 F8/F9(승선 전/후), 1/2 이동은 유지한다.

## 전투

세 보스의 지정 HP/데미지/Turn Delay/스턴/주기 값은 data/enemies.json에 기록했고 직접 비교하는 테스트가 있다. 큰 패턴은 Arena의 소유권으로 겹치지 않는다. 어미는 4타 충격파에 1초 기절하며 분사 중 독액 효과를 취소한다. 릴리스는 준비 턴 후 0.1초 기습과 3×10 할퀴기, 2.5초 A/D 반전, 4.5초 잔상을 쓴다. 주는 기존 bone_arrow 이미지를 5×11 부채꼴로 발사하고 경고선 뒤 잡기 33을 쓴다. 공중 도끼 4타를 맞으면 가지 충돌을 잠시 제외해 지상으로 추락한 뒤 2초 기절한다. HP 0 사망 시 입구에서 세 보스 합계 5860 HP로 재시작한다.

주요 재량 판정: 어미 꼬리 320×220, 독액 반경160/높이65/5초/0.25초마다2; 릴리스 할퀴기150×160, 파동100×70/속도480/거리700; 주 잡기150×150/강하720/운반0.5초, 깃털 속도450/각도60도. 상세 위치·쿨다운·박스는 data/enemies.json과 data/odyssey.json이 기준이다.

## 이미지·용량

'''
 report+=f'신규 이미지 {len(inventory["generated"])}개, {mib(sum(new.values()))}MiB. 시야우와르산 첫 idle의 비투명 높이(α>12, canonical 복원)는 {height}px, 앵커 [320,600], 표시 배율0.30이다.\n\n'
 report+='새 이미지 전체:\n\n'+'\n'.join('- '+p for p in inventory['generated'])+'\n\n재사용: 훌루푸 줄기(붕괴 구역에서90도 회전), 별/땅, 노인·엔키두아·r90, 화로, 가스/타격/뼈 화살/불씨 오라/회복 아이템. 미생성 이미지 0개, MISSING_TEXTURE 0개. 삼나무 숲에서 삭제한 벽 줄기를 다시 넣지 않았다.\n\n'
 report+=f'assets {mib(assets)}MiB, 예비 ZIP {mib(zip_bytes)}MiB. 신규 개별 예산은 모두 충족했으나 ZIP 62MiB 목표는 미달이다. 상세 측정·실패 후보·상위20 파일은 SIZE_REPORT_KO.md에 있다.\n\n'
 report+='## 검증 및 한계\n\n- 신규 기능 통합 검사, 원문 비교, NPC 사망/피 유지, 저장·구 세이브·F5 복귀를 실행했다.\n- 전체 기존 테스트의 달라진 기대값은 지침에 맞게 갱신했다(피 흔적 유지, 폭주100 예외, 노인 상호작용). 공유 보스 스크립트는 ID별 진입 스크립트를 두어 일반 클립 감사도 통과한다.\n- 프레임·알파·접지·도달성·머리 잔상 검사와 실제 GL atlas/단독 렌더 비교를 실행했다. 최종 패키지는 별도 압축 해제 후 검증한다.\n- 스크린샷은 docs/screenshots/stage13_*.png, 상세 로그는 archive/stage13이다. 화면 자료는 QA ZIP에 별도 제공한다.\n- 기존 NPC 대비 경고9개와 기존 동적 포즈의 검토용 경고는 실패로 숨기지 않고 별도로 기록한다. 헤드리스 GDScript 경고·오류와 검사 실패는 0이 완료 조건이다.\n- 가상 X11의 V-Sync 지원 경고는 플랫폼 제약이며 실제 GL 픽셀 비교 결과와 분리한다.\n\n## 완료 체크\n\n'
 checks=['엔키두아 침대 버그/피 유지','우트나피쉬팀 원문 일치','폭주100/r90/난도질/암전/노인 무사','훌루푸 오르기','3체 수치와 전투','붕괴 줄기/티아마트 이미지','티아마트 원문/10초 암흑','자동 저장/4개 선택지','시야우와르산17모션/HP100/무기 없음','흐와니라 광장','저장/구 세이브 호환','자동 테스트 전체','ZIP62MiB 목표']
 report+='| 항목 | 결과 |\n|---|---|\n'+'\n'.join('| '+c+' | '+('×' if i==12 else '검증 결과 갱신 예정' if i==11 else '○')+' |' for i,c in enumerate(checks))+'\n'
 (R/'docs/STAGE13_REPORT_KO.md').write_text(report)
 changes=subprocess.check_output(['git','diff','--name-status','HEAD'],cwd=R,text=True);new_files=subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=R,text=True)
 (R/'docs/STAGE13_FILES_KO.txt').write_text('변경/이동/삭제(git diff)\n'+changes+'\n추가\n'+new_files)
 (archive/'size_summary.json').write_text(json.dumps({'asset_bytes':assets,'zip_bytes':zip_bytes,'new_categories':new,'folders':folders,'player_height':height},indent=2))
 print('REPORT assets',mib(assets),'new',mib(sum(new.values())),'player height',height)
if __name__=='__main__':main()
