# NIMROD 6단계 작업 보고

이 문서는 최초 6단계 배포 기록입니다. 2026-10-11 공격 오류·괴수 크기·구조물 정렬 수정의 현재 값과 검증은 [STAGE6_FIX_REPORT_KO.md](STAGE6_FIX_REPORT_KO.md)를 확인하세요.

6단계 게임플레이, 새 레벨5개, 숲 괴수5종과 보스, 샴하트 축복·대화, 크기·접지·클립 안전장치를 구현했다. 기존5단계 브랜치를 이어 수정했으며 main은 변경하지 않는다. 기존 니므롯 모션 PNG와 일반 우루크 괴수·비행 괴수 PNG는 유지했다.

## 레벨 연결과 사용자 결정

```
HomeRoad ↔ NimrodHome
VillaF1 ↔ VillaBackyard ↔ CedarForest_F1 ↔ CedarForest_F2 ↔ CedarBossRoom
```

기존 RearGate·루갈성·대문 밖·통로8층·별장3층 연결을 포함해25개 레벨이다. 사망은 항상 RearGate/Spawn_Start(x260)와 HP180으로 돌아간다. 층 이동으로 축복과 HP가 지워지지 않는다.

사용자는 “격자를 늘려14개 이상 방으로 구성”을 선택했다. 그래서 원문의3×4/12방과14셀 조건 충돌을4×5/20방으로 해결했다. 층당4800×3400, 셀1200×640, 상단 여백128, 바닥3328, 최단 경로16방, 실제 갈림길4곳과 막다른 길4곳이다. 두 막다른 길에 +30HP 토사물 픽업을 배치했다. 수직 체인은80px씩8단, 폭280, 셀 안 x+60/+140 교대이며 수평 빈틈0~200 이하다. 벽80px, 연결된 방 통로의 높이는500px로 해골 거수440px와 여유가 들어간다. 층간 비연결 바닥은 고체 충돌로 막아 드롭스루 우회를 차단했다.

## 변경 파일과 구조

전체 경로는 [STAGE6_FILES_KO.txt](STAGE6_FILES_KO.txt)에 기록했다.

- `scripts/enemy_base.gd`: size_multiplier 변환, 별칭·idle·첫 클립 대체, 위협 표시, 드랍 금지, 방 범위 제한.
- `scripts/threat_marker.gd`, `surface_accent.gd`: F2/F3, 선딜 색과 매복 알파, 지면 레이캐스트 그림자, 일방향 점선.
- `scripts/dialogue_system.gd`: 항상 처리되는 UI·줌 카메라, 자동 타자·음성 틱, 일시 정지·복원, 이동 시 취소·복원.
- `scripts/player_modifiers.gd`, `player.gd`, `npc_base.gd`, `game_hud.gd`: 이름 있는 합산 수정자, 샴하트 E, 최대HP·공격속도, 실제 갑피 접촉점, 보스 HP 바.
- `scripts/enemy_cedar.gd`와5종 얇은 스크립트, `enemy_kala_ushumgal.gd`, `cedar_hazard.gd`, `cedar_fx.gd`: 숲 전투·보스·PNG 판정 효과.
- `scenes/NimrodHome.tscn`, `VillaBackyard.tscn`, `CedarForest_F1/F2.tscn`, `CedarBossRoom.tscn`: 공용 LevelBase와 JSON으로 구성.
- `data/levels.json`, `enemies.json`, `npcs.json`, `enemy_markers.json`, `surface_accent.json`, `cedar_forest_layout.json`, `dialogue.json`, `player_modifiers.json`, `stage6_fx.json`, `audio_stage6.json`: 모든 새 레벨·패턴·UI·음원 설정.
- `tools/build_stage6_*`, `fit_stage6_clearance.py`, `finalize_stage6_layout.py`, 신규 감사 도구4개와 이동 경로 도구 확장; `tests/stage6_*.gd`7개와 렌더 캡처, 기존 연결·크기 기대값 갱신.
- 생성 이미지·시트·매니페스트, 새 효과음44개·BGM3개, README와 이 보고서·스크린샷.

6단계 시작 시5단계 시스템은 실제로 존재했다. 처음부터 다시 만든 대체 기반 시스템은 없다. 신규13개 스크립트를 추가하고 기존 공용 구조를 확장했다.

## 가정값·수치와 선택

기본 플레이어 HP180, 속도360, 점프−695, 중력1750, 구르기780/0.48초와 무적0.25초, 도끼20/20/20/22, 콤보 리셋0.8초, 히트스톱0.05초를 보존했다. 니므롯 시트는 교체하지 않았다.

샴하트의 축복은 한 런 동안 영구이며 사망·R 재시작 때 지워진다. 공격30/30/30/33, 최대HP270, 현재HP+90(최대치 클램프), 공격속도1.5배, 향후 합산 공격속도 상한2배. 공격 시계만 배율을 적용하므로 active 구간과 모션이 함께 빨라지고 실제 콤보 리셋·구르기 시간은 유지된다.

집 외관은 원본1300×720 재사용, y160→233(+73). 측정한 마지막 고체 행648을 적용하면 바닥881로 지면880과+1px 차이다. 수정 후 캡처에서 원래 지면 위 노이즈 띠가 사라져 시차 배경을 재생성하거나 하단 색보정을 추가하지 않았다. 전 레벨 접지는113개 대상0실패이며 벽 램프·선반·매달린 덩굴·고가도로 시각은 접지 대상에서 제외했다.

통로8개 층은 큰 몸체에 맞춰 카메라 상단−560/높이1500, 천장−500과 배경 렌더 크기를 확장했다(원본 배경 PNG 재사용). 3층은 중단y300/상단y−40과90px 체인, 5층 높은 통로y300과 접근 체인, 7층100px 터널에는 지상·가스 괴수를 두지 않고 높은 방으로 이동했다. 6층은1400px 직선 통로 두 개,8층 사슬 수인은x1900±350를 유지하고 옆 발판을 전투 몸체 밖으로 옮겼다. 일부 순찰 폭은 장애물 여유 안으로 줄였으며 HP·피해·시간·속도는 보존했다. 최종 스폰·순찰·판정 전체 값의 기준은 `data/levels.json`과 `data/enemies.json`이다.

신규 괴수 수치:

| id | HP | 몸(px) | 표시 배율 | 회전(초) | 핵심 피해 |
|---|---:|---|---:|---:|---|
| cedar_sentinel | 85 | [140, 250] | 0.45 | 0.3 | thrust:12, slash:12 |
| cedar_colossus | 165 | [300, 440] | 0.5 | 0.6 | slam:22, sweep:16, rear_poke:8 |
| cedar_archer | 58 | [150, 260] | 0.45 | 0.2 | shoot:14 |
| cedar_wisp | 32 | [120, 170] | 0.45 | 0.15 |  |
| cedar_demon | 90 | [220, 280] | 0.45 | 0.25 | claws:3, land_stab:18 |
| kala_ushumgal | 1200 | [520, 560] | 0.5 | 0.7 | whip:16, slam:22, summon:0, roar:2, spines:12, final:30 |

석궁 사수 이동100px/s·후퇴 점프 높이80px·잔류 가시10피해/0.6초, 거수 충격파는 피해 없이 넉백220, 후방 견제 후딜0.3초를 가정했다. 보스 이동80px/s, 마지막 발악30피해, 뒤 가시 후딜0.3초, 기본 바닥800, 소환 발판 중심180/1420·y500·폭280이다. 보스의 실제 이동 중심800±200은 양 끝 발판과 겹치지 않게 정했다. 후방 견제는 방향을 바꾸지 않고 실행한 뒤 후딜과 TURN을 거친다.

엔키두아는 성인 여성, 투박한 얼굴·각진 턱·거친 피부·흉터·헝클어진 갈색 땋은 머리·이끼색 실용복으로 생성했고 정면/측면 키는363×1.04≈378px로 맞췄다. 기존 NPC 정면 첨부 이미지를 다시 매핑하거나 다른 NPC 시트를 바꾸지 않았다.

## 클립 감사와 이미지

벽면 강하 `idle`4프레임/0.8초, `windup`4/0.35초를 생성했다. `walk→crawl`. 다른 표준 클립 누락은 매니페스트 aliases로 해당 몸의 실제 클립에 연결했다. 가스의 death→death_swell, 시체의 death→explode 등 기존 죽음 PNG를 재사용했으며 별도 death 재생성은 하지 않았다. 정적 감사0누락이며 강제 상태·특수 phase 테스트는 MISSING이 보이지 않는지 확인한다. 의미 없는 강제 phase 조합은 경고와 idle 대체를 허용한다.

생성 완료: 신규 숲5종51개 시트, 보스30개(2페이즈10개 포함), 벽면 강하2개, 엔키두아2개, FX6개, 새 문4개, 집·뒤뜰·숲·보스방 배경과 지형·소품. 생성 원본과 생성 프롬프트도 보존했다. 미생성 에셋은 없다. 모든 게임 아트는 이미지 생성 원본을 크로마키·크기 조정·앵커 정렬·시트 합성한 PNG이며, NPC 숨쉬기는 허용된 정지 이미지 파생을 썼다.

보스 idle/idle_p2는8포즈 전용 고해상도 아틀라스로 다시 생성해 대기 화면의 확대 흐림을 줄였다. 보스 TURN은 전용6프레임 아틀라스를 재생성해3번째 프레임이 정면에 가깝도록 보완했다. 새 괴수 대표 키는 몸체와±15% 안으로 맞췄다. 일부 공격 자세는 프레임 안에 긴 무기를 넣기 위해 클립별 축소가 필요해 재생 중 크기 변화·흐림이 남을 수 있다. 고해상도 클립별 원본과 수동 프레임 검토를 권장한다.

기존 확대 아트의 비율 경고(재생성하지 말라는 지시에 따라 보존):

```
WARNING sky_beast: clip=fly_idle, painted=248.0px, body=88.0px, difference=+181.8%
WARNING explosive_spitter: clip=idle, painted=154.8px, body=258.0px, difference=-40.0%
WARNING root_spewer: clip=idle, painted=155.7px, body=240.0px, difference=-35.1%
WARNING boar_charger: clip=idle, painted=140.4px, body=282.0px, difference=-50.2%
WARNING gas_sac: clip=float, painted=75.6px, body=270.0px, difference=-72.0%
WARNING shell_scorpion: clip=idle, painted=75.6px, body=240.0px, difference=-68.5%
WARNING chain_beastman: clip=idle, painted=416.7px, body=534.0px, difference=-22.0%
```

PNG 크기·알파·프레임 수·앵커·NPC 키 검증은399개/누락0/오류0. NPC 대비 경고7개는 기존 NPC·배경 조합이며 실패로 취급하지 않는다. 엔키두아 휘도 차이는65.9로 통과했다.

```
WARNING: NPC contrast below 30: RearGate/gatekeeper
WARNING: NPC contrast below 30: VillaF1/servant_a
WARNING: NPC contrast below 30: CastleFront/castle_gatekeeper_inner
WARNING: NPC contrast below 30: VillaF2/cook_a
WARNING: NPC contrast below 30: VillaF2/cook_b
WARNING: NPC contrast below 30: VillaF2/cook_c
WARNING: NPC contrast below 30: VillaF2/cook_c
```

## 보스 처치 연출과 대화

갑피는 플레이어 발 좌표뿐 아니라 실제 공격 사각형과 보스 몸의 겹침 위치로 상·하체를 판단한다. 충격파는 상체 감쇄 없이 하체 공격으로 취급한다. HP600 도달 시 현재 공격 후딜을 마친 뒤2초 전환을 시작해 공격 후딜 보장을 유지한다. 화염은14틱×2=28, 경직·무적 부여 없이 구르기 무적을 적용한다.

HP0 후 붕괴1초 → 마지막 예고0.8초 → 일격0.2초까지 전투가 끝나지 않는다. 이후 문 잠금을 풀고 보스 몸은1.5초에 페이드한다. 자동 발화5줄은 타자와1.6초 유지에1.5초보다 긴 시간이 필요하므로, 몸이 사라진 뒤에도 보이지 않는 발화 위치 앵커를 출력 완료까지 보존한다. 이동·사망으로 레벨을 바꾸면 대화를 취소하고 카메라·정지·UI를 복원한다. 플래그는 사용자 지정 GameState 런 기준이다. 멜람무 보상과 폭주 시스템은 구현하지 않았다.

## 테스트와 스크린샷

테스트 최종 결과는 아래 자동 기록을 따른다. 모든 검증은 공식 Godot4.3.77dcf97d8과 Python3/Pillow/numpy를 사용했다. 그래픽 캡처는 Linux Xvfb·Mesa llvmpipe·GL Compatibility,1280×720으로 수행했다.

- `regression`: exit0; NIMROD REGRESSION: 193 checks, 0 failures
- `stage2_interactions`: exit0; STAGE2_INTERACTIONS: 42 checks, 0 failures
- `stage2_sky`: exit0; Stage 2 sky/safe-zone checks: 66; failures: 0
- `stage2_transitions`: exit0; Stage 2 transition regression: 210 checks, 0 failures
- `stage3_front`: exit0; STAGE3_FRONT: 40 checks, 0 failures
- `stage4_gate`: exit0; STAGE4_GATE: 38 checks, 0 failures
- `stage4_npc_facing`: exit0; STAGE4_NPC_FACING: 73 checks, 0 failures
- `stage4_player_scale`: exit0; STAGE4_PLAYER_SCALE: 45 checks, 0 failures
- `stage4_terrain`: exit0; STAGE4_TERRAIN: 5 checks, 0 failures
- `stage4_villa`: exit0; STAGE4_VILLA: 19 checks, 0 failures
- `stage5_direction_cancel`: exit0; STAGE5_DIRECTION_CANCEL: 14 checks, 0 failures
- `stage5_enemies`: exit0; STAGE5_ENEMIES: 69 checks, 0 failures
- `stage5_homeroad`: exit0; STAGE5_HOMEROAD: 50 checks, 0 failures
- `stage5_passage`: exit0; STAGE5_PASSAGE: 209 checks, 0 failures
- `stage5_terrain`: exit0; STAGE5_TERRAIN: 18 checks, 0 failures
- `stage6_boss`: exit0; STAGE6_BOSS: 24 checks, 0 failures
- `stage6_cedar_enemies`: exit0; STAGE6_CEDAR_ENEMIES: 20 checks, 0 failures
- `stage6_clip_coverage`: exit0; STAGE6_CLIP_COVERAGE: 310 checks, 0 failures
- `stage6_levels`: exit0; STAGE6_LEVELS: 13 checks, 0 failures
- `stage6_shamhat_buff`: exit0; STAGE6_SHAMHAT_BUFF: 16 checks, 0 failures
- `stage6_surface_accent`: exit0; STAGE6_SURFACE_ACCENT: 88 checks, 0 failures
- `stage6_threat_marker`: exit0; STAGE6_THREAT_MARKER: 6 checks, 0 failures

최종 실행 기록은22개 테스트 모두 통과다(보존 기능과 새 기능을 합산). 오디오47개 WAV는44100Hz/모노/16bit이며 BGM3곡은48초, 루프 경계 기울기 검사를 통과했다(`STAGE6_AUDIO_CHECK.txt`).

Python 감사: 클립0실패, 접지113개0실패, 확대 몸체·순찰 통로11레벨0실패, 기존10개 이동 경로+숲2개 미로0실패(각94검사, 최단16방). 시각 비율·NPC 대비 경고는 위에 별도 기재했다.

스크린샷20개: `docs/screenshots/stage6_*.png`. 괴수9종 크기 비교, 선딜 표식, 구조물 표시, 집 수정 전후, NimrodHome/VillaBackyard/숲1·2층/보스방, 샴하트 줌 대화·축복 HUD가 포함된다. `stage6_home_before.png`는 비교를 위해 실행 중에만 집 외관을 기존y160으로 되돌려 찍은 것이며 배포 데이터는y233이다.

실행하지 못한 항목: Windows 실제 키보드·패드·오디오 장치 테스트, 모든 경로의 완전한 수동 클리어, 장시간 난이도·무기 시각 판정 비교. 클라우드 Linux 환경에서 자동 기능 테스트와 렌더 캡처로 대체했다. 자연스러운 모션의 미적 평가는 자동 검증 대상이 아니며 일부 아틀라스 확대 품질에 한계가 있다.

배포 ZIP은 Godot 프로젝트 소스이다. Windows 실행 파일·Godot 엔진 바이너리는 포함하지 않는다. `.godot` 캐시와 임포트 메타데이터를 제외하므로 새 폴더에서 다시 임포트해야 한다.
