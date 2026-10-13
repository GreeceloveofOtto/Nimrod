# NIMROD 13단계 보고서

## 가정·재량 값 요약

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

## 원인과 수정

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

신규 이미지 49개, 4.62MiB. 시야우와르산 첫 idle의 비투명 높이(α>12, canonical 복원)는 365px, 앵커 [320,600], 표시 배율0.30이다.

새 이미지 전체:

- assets/sprites/player/siyavash/jump_rise.webp
- assets/sprites/player/siyavash/run.webp
- assets/sprites/player/siyavash/drop_through.webp
- assets/sprites/player/siyavash/sit_idle.webp
- assets/sprites/player/siyavash/walk.webp
- assets/sprites/player/siyavash/idle.webp
- assets/sprites/player/siyavash/fall.webp
- assets/sprites/player/siyavash/sit_down.webp
- assets/sprites/player/siyavash/land.webp
- assets/sprites/player/siyavash/hurt.webp
- assets/sprites/player/siyavash/stand_up.webp
- assets/sprites/player/siyavash/crouch_exit.webp
- assets/sprites/player/siyavash/roll.webp
- assets/sprites/player/siyavash/crouch_idle.webp
- assets/sprites/player/siyavash/death.webp
- assets/sprites/player/siyavash/jump_start.webp
- assets/sprites/player/siyavash/crouch_enter.webp
- assets/sprites/enemies/ninazu_mother/idle.webp
- assets/sprites/enemies/ninazu_mother/hurt.webp
- assets/sprites/enemies/ninazu_mother/tail_attack.webp
- assets/sprites/enemies/ninazu_mother/tail_windup.webp
- assets/sprites/enemies/ninazu_mother/poison_windup.webp
- assets/sprites/enemies/ninazu_mother/death.webp
- assets/sprites/enemies/ninazu_mother/turn.webp
- assets/sprites/enemies/ninazu_mother/move.webp
- assets/sprites/enemies/ninazu_mother/poison_attack.webp
- assets/sprites/enemies/lilith/ambush_attack.webp
- assets/sprites/enemies/lilith/idle.webp
- assets/sprites/enemies/lilith/ambush_windup.webp
- assets/sprites/enemies/lilith/hurt.webp
- assets/sprites/enemies/lilith/death.webp
- assets/sprites/enemies/lilith/charm_windup.webp
- assets/sprites/enemies/lilith/charm_attack.webp
- assets/sprites/enemies/lilith/turn.webp
- assets/sprites/enemies/lilith/move.webp
- assets/sprites/enemies/zu/grab_attack.webp
- assets/sprites/enemies/zu/idle.webp
- assets/sprites/enemies/zu/hurt.webp
- assets/sprites/enemies/zu/grab_windup.webp
- assets/sprites/enemies/zu/feathers_windup.webp
- assets/sprites/enemies/zu/feathers_attack.webp
- assets/sprites/enemies/zu/death.webp
- assets/sprites/enemies/zu/turn.webp
- assets/sprites/enemies/zu/move.webp
- assets/backgrounds/hwanira/plaza.webp
- assets/backgrounds/tiamat/entity.webp
- assets/tiles/hwanira/plaza.png
- assets/tiles/huluppu/branch.png
- assets/props/utnapishtim_blood.webp

재사용: 훌루푸 줄기(붕괴 구역에서90도 회전), 별/땅, 노인·엔키두아·r90, 화로, 가스/타격/뼈 화살/불씨 오라/회복 아이템. 미생성 이미지 0개, MISSING_TEXTURE 0개. 삼나무 숲에서 삭제한 벽 줄기를 다시 넣지 않았다.

assets 65.13MiB, 최종 ZIP 약 65.58MiB. 신규 개별 예산은 모두 충족했으나 ZIP 62MiB 목표는 미달이다. 상세 측정·실패 후보·상위20 파일은 SIZE_REPORT_KO.md에 있다.

## 검증 및 한계

- 신규 기능 통합 검사, 원문 비교, NPC 사망/피 유지, 저장·구 세이브·F5 복귀를 실행했다.
- 전체 기존 테스트의 달라진 기대값은 지침에 맞게 갱신했다(피 흔적 유지, 폭주100 예외, 노인 상호작용). 공유 보스 스크립트는 ID별 진입 스크립트를 두어 일반 클립 감사도 통과한다.
- 프레임·알파·접지·도달성·머리 잔상 검사와 실제 GL atlas/단독 렌더 비교를 실행했다. 최종 패키지를 별도 압축 해제했고 전체 헤드리스 검사169/169를 통과했다.
- 스크린샷은 docs/screenshots/stage13_*.png, 상세 로그는 archive/stage13이다. 화면 자료는 QA ZIP에 별도 제공한다.
- 기존 NPC 대비 경고9개와 기존 동적 포즈의 검토용 경고는 실패로 숨기지 않고 별도로 기록한다. 헤드리스 GDScript 경고·오류와 검사 실패는 0이 완료 조건이다.
- 가상 X11의 V-Sync 지원 경고는 플랫폼 제약이며 실제 GL 픽셀 비교 결과와 분리한다.

## 완료 체크

| 항목 | 결과 |
|---|---|
| 엔키두아 침대 버그/피 유지 | ○ |
| 우트나피쉬팀 원문 일치 | ○ |
| 폭주100/r90/난도질/암전/노인 무사 | ○ |
| 훌루푸 오르기 | ○ |
| 3체 수치와 전투 | ○ |
| 붕괴 줄기/티아마트 이미지 | ○ |
| 티아마트 원문/10초 암흑 | ○ |
| 자동 저장/4개 선택지 | ○ |
| 시야우와르산17모션/HP100/무기 없음 | ○ |
| 흐와니라 광장 | ○ |
| 저장/구 세이브 호환 | ○ |
| 자동 테스트 전체 | ○ |
| ZIP62MiB 목표 | × |

최종 헤드리스: 169/169 통과(스크립트 파싱·기존12단계·13단계 전체), 엔진 경고·오류0. 실제GL은641단언/398비교 성공. 실행 ZIP 용량62MiB는미달이며 기능 검사 결과와분리했다.
