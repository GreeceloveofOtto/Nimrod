# NIMROD 2단계 구현 보고서

루갈성 후문 밖을 폭 5400으로 확장하고 루갈성 1~5층, 별장 1층을 문 포탈로 연결했습니다. `Main.tscn` 아래 플레이어 한 개를 유지하며 `LevelRoot` 아래 레벨만 교체합니다. 층 이동 중 HP·전투 행동·타이머는 유지하고, 사망하면 시도 플래그를 초기화한 뒤 HP 180으로 후문 시작점에 복귀합니다.

현재 범위는 탐험 연결, 문 연출, NPC 배치·동작, 비행 괴수 전투입니다. NPC 대화·별장 2층·스토리 분기·최종 엔딩은 후속 개발 범위입니다. 1단계 기록은 [기존 보고서](IMPLEMENTATION_REPORT_KO.md)에 보존했습니다.

## 구현 내용

| 영역 | 동작 |
|---|---|
| 레벨 등록 | `RearGate`, `CastleF1`~`CastleF5`, `VillaF1` 총 7개. 레벨·스폰·배경·지형·NPC·문·괴수 수를 JSON으로 관리 |
| 플레이어 유지 | `Main/Player` 한 개, `Main/LevelRoot`의 레벨만 교체. HP·행동·구르기 타이머를 층 이동 중 보존 |
| 전환 | 입력·피해 잠금 → 페이드아웃 0.25초 → 레벨 교체·스폰·카메라·BGM → 페이드인 0.25초 → 도착 연출 → 잠금 해제 |
| 일반 문 | E 이미지 표시, 가장 가까운 문만 처리, 열림 0.6초·진입 0.4초, 도착 시 열린 문에서 0.3초 걸어 나온 뒤 0.5초 닫힘 |
| 잠긴 문 | 흔들림·잠김 효과음·한국어 사유 토스트, 이동 없음 |
| 진행 상태 | `GameState.run_flags`, `first_time(key)`, `reset_run()`. 사망 후 1.6초에 초기화·HP 180·RearGate `Spawn_Start` x=260 |
| 후문 확장 | 폭 5400, 기존 괴수 5마리에 근접 2·원거리 1 추가. x≤350 / x≥4950 안전 구역, 단차·발판·별장 외관·대문 |
| 루갈성 내부 | 1층 군주 부부, 2층 샴하트, 3층 요리사 3명, 4층 인안나·팝수칼, 5층 비행 괴수. 1~4층에는 괴수 없음 |
| NPC | 충돌 없는 인물 11명, 플레이어 공통 배율 0.30. 시선은 120px·회전 유예 0.5초. 요리·청소는 무작위 시작 위상 |
| 별장 대문 | 300px 접근 → 문지기 `open_gate` 세 번째 프레임에서 1초 열림 → 완전 개방 시 ±40px 자동 진입. 600px 이탈 시 0.8초 닫힘 |
| 별장 안전장치 | 닫힌 대문 충돌 벽, 열린 뒤 벽 해제, 도착 직후 자동 재진입 방지. `gate_requires_dialogue=true`이면 열지 않는 향후 연결 지점 |
| 비행 괴수 | HP 110, 고도 180~260px 배회, 고정 목표 급강하 속도 520px/s·피해 8 한 번·최대 활성 0.9초, 후딜 0.6초·턴 0.25초·쿨다운 1.2초 |
| 비행 피격·사망 | 선딜/돌진 타격 시 즉시 취소·경직 0.25초, 지상 넉백의 40%, 히트스톱·스파크·효과음. 사망 시 나선 낙하 후 바닥에서 사라짐 |
| 회복 드랍 | 비행 괴수 사망 시 5% 확률의 토사물. E로 HP 30 회복, HP 180 상한 |
| 오디오 | 새 효과음 9종·48초 BGM 3곡. 루갈성 1~4층 이동은 같은 `castle_hall`을 이어 재생 |

기존 구현에 없던 레벨 교체·진행 상태·NPC·문·비행 괴수·회복 드랍 기반은 이번 단계에서 추가했습니다. 기존 `Audio`, 플레이어, 지상 괴수 베이스·근접·원거리, 도끼/화염 피해 경로는 확장해 재사용했습니다.

## 보존한 조작·수치

A/D·좌우 화살표 이동, S 수그리기, Space 점프, S+Space 내려가기, J 도끼, K 구르기·공격 캔슬을 유지합니다. E는 문과 회복 아이템에 사용합니다. F1은 판정 디버그, R은 시도 초기화 후 시작점 복귀입니다.

HP 180, 도끼 20/20/20/22, 구르기 0.48초(선딜 0.03·무적 0.25·후딜 0.20), 콤보 리셋 0.8초, 히트스톱 0.05초, 일반 피격 경직·유예 0.45초, 사망 대기 1.6초를 유지합니다. 지상 괴수 HP 95/63, 화염 11틱·총 11 피해와 인터럽트·공격 후딜 보장·턴 세 번째 프레임 방향 전환도 유지합니다. 원본 플레이어 PNG 18개와 기존 점프 원본 `assets/audio/legacy/jump.wav`는 보존 대상입니다.

## 가정·임의로 정한 수치와 선택

| 항목 | 선택·근거 |
|---|---|
| 팝수칼 | 성별을 확정하지 않은 중성적인 아름다움의 성인 호위 시종. 고급 호위복·홀·단호한 표정 |
| NPC 높이 기준 | 플레이어 `idle.png` 첫 프레임의 알파 >12 비투명 bbox 높이 `H_p=359px`. 같은 배율 0.30, 프레임 640×640, 발 앵커 `[320,600]`. 검증 허용 오차 ±3% |
| 왕족 높이 비율 | 루갈반다 1.06, 닌순 0.98, 샴하트 0.96, 인안나 1.00, 팝수칼 1.02 |
| 토인 높이 비율 | 요리사 A/B/C=0.70/0.72/0.74, 하인 A/B=0.70/0.72, 문지기=0.74. 복장·머리·소품으로 구별 |
| NPC 방향 | 왕족은 오른쪽 기준 생성 후 플레이어 위치를 따라 전환. 요리사는 작업 방향 고정, 하인은 오른쪽/왼쪽, 문지기는 문 열기 직전 플레이어를 향함 |
| 도착 걸음 | 스폰이 문 중심과 다르면 문 중심에서 지정 스폰으로 이동. 같은 위치면 `exit_direction` 방향으로 40px 한 걸음 |
| 도착 문 위치 | CastleF1 후문 x=1850 → 도착 스폰 x=1800. RearGate 후문 x=150 → 복귀 x=260. 별장 대문 x=5200 → 복귀 x=5050. VillaF1 안쪽 문 x=150 → 스폰 x=200 |
| 문 프롬프트 | 생성 원본 64×64 PNG를 일반 문에서는 40×40으로 표시. 수직 판정 120px, 기본 E 거리 90px |
| 잠긴 문 흔들림 | 좌우 5px, 0.24초 동안 3회. 원위치로 복원 |
| 별장 재진입 방지 | 도착 직후 자동 진입을 해제하며 입구 중심에서 80px 이상 벗어나야 재활성 |
| 바닥 y | 후문 밖은 기존 880, 실내·옥상·별장은 배경 바닥선에 맞춘 620 |
| 첫 근접 괴수 | 요청 스폰 x=400은 유지하되 너비 150px 몸체가 x≤350 안전 구역을 침범하지 않도록 실제 중심을 x=425로 클램프 |
| 확장 단차 | x=4100, 폭 180, 높이 70px |
| 확장 발판 | x=4230/4590, y=700, 폭 240px. 일방향 충돌 두께 16px·그림 높이 48px |
| 별장 외관 배경 | 1500×720 이미지를 x=4450~5950에 1:1 배치. 이미지 안쪽 대문 중심 750px를 세계 x=5200에 정렬하고 맵 경계 밖은 화면에서 잘림 |
| 새 전경 | 2단계 명세의 4겹 시차 배경 요청에 맞춰 폭 5400용 원본을 새로 생성. 이전 삭제 요청의 전경 원본은 복원하지 않음 |
| 비행 괴수 기본 배치 | CastleF5에 1마리, x=1400·바닥 위 고도 220px. JSON 개체 수로 변경 가능 |
| 비행 괴수 이동 보정 | 수평 배회 82px/s, 수직 66px/s, 가속 240px/s², 흔들림 90px·주기 3.6초 |
| 비행 괴수 몸체·표시 | 판정 150×88px, 중앙 앵커 `[384,320]`, 시트 768×640, 표시 배율 0.45 |
| 비행 괴수 후딜 | 상승 120px/s, 감속 380px/s². 공격 중·후딜에는 facing을 바꾸지 않음 |
| 비행 괴수 사망 | 낙하 가속 640px/s², 최대 낙하 420px/s, 나선 반경 18px·속도 11·회전 0.32. 날갯짓 반복음 -16dB |
| 회복 아이템 | 기존 정의가 없어 최소 기반 추가. E 거리 72px, PNG 64×48, 프롬프트 32×32. 회복량 30·최대 HP 제한 |
| 새 BGM | 세 곡 모두 48초 주기. 저음 실내·높은 바람·현악풍 성격을 합성 파라미터로 구분 |

새 게임 수치는 `data/levels.json`, `enemies.json`, `npcs.json`, `interactions.json`, `transitions.json`, `pickups.json`, `audio_stage2.json`에 모았습니다. 기존 플레이어 상수는 `scripts/game_constants.gd`에 유지합니다.

## 이미지 생성·검증

배경·지형·문·괴수·NPC 아트는 이미지 생성 PNG를 사용합니다. 공통 우루크 다크 판타지 프롬프트와 기존 니므롯 `idle.png`, `attack_4.png`를 스타일 기준으로 삼았습니다. 생성 원본·완성 프롬프트·후처리 기록을 `assets/source_art/`, `assets/image_prompts/`에 보존합니다.

투명 스프라이트는 단색 마젠타 생성 → `tools/pack_sprites.py` 크로마키 → 프레임별 앵커 정렬 → 지정 크기 한 줄 시트로 처리합니다. NPC 숨쉬기는 요청에서 허용한 정지 이미지의 미세 세로 변형·상하 이동을 사용하며 발 위치를 고정합니다. 요리·청소·문지기 동작과 비행 괴수·문은 여러 생성 포즈를 사용합니다. 배경 분할 합성은 기존 생성 픽셀을 이어 붙이고 이음새를 보정합니다.

캐릭터 패킹 결과는 NPC 12개 클립과 비행 괴수 7개 클립, 총 19개 PNG입니다. `tools/build_stage2_character_assets.py`로 재생성하며, 허용된 숨쉬기 파생은 `tools/make_breathing_sheet.py`가 담당합니다. 왕족·요리사·작업자·곧게 선 하인·비행·턴/사망의 6개 실제 생성 원본은 `assets/source_art/stage2_characters/`와 `generation_prompts.json`, `provenance.json`에 기록했습니다. 환경은 `tools/build_stage2_environment_assets.py`, 선택적 분할 합성은 `tools/stitch_background.py`로 재현하며 `assets/source_art/stage2_environment/generation.json`에 실제 생성 요청을 기록합니다.

`_draw()`는 F1 디버그 판정에만 사용합니다. 이미지가 빠지면 회색 사각형과 `MISSING` 라벨이 있는 `MISSING_TEXTURE`만 표시합니다. 플레이 가능한 최종 아트로 간주하지 않습니다.

새 캐릭터 묶음 19개(NPC 시트 12개·비행 괴수 7개)와 환경 묶음 32개(정적 이미지 26개·문 시트 6개)를 생성·패킹했습니다. 기존 배경 3개는 새 크기로 교체했습니다. 통합 `assets/art_manifest.json` 검증 결과는 **PNG 77개·누락 0·오류 0**입니다. 모든 NPC 프레임의 키 비율 ±3%, 앵커, 비행 괴수 특수 규격, 레벨별 시차 너비와 타일 이음새를 검사했습니다. **이미지 미생성 에셋 목록: 없음.**

## 테스트 결과

Godot **4.3.stable.official.77dcf97d8**에서 모든 최종 PNG를 가져온 후 아래 네 기능 검사를 다시 실행했습니다. **513개 통과·실패 0**, 스크립트 오류·MISSING 경고가 없었습니다.

| 검사 | 통과 | 실패 | 주요 검증 |
|---|---:|---:|---|
| `tests/regression.gd` | 196 | 0 | 기존 구르기·전투·화염·충돌·지상 AI, 확장 맵·안전 구역 |
| `tests/stage2_transitions.gd` | 210 | 0 | 7개 레벨·층간 왕복·단일 플레이어·HP/상태 보존·입력/피해 잠금·BGM 연속·시도 초기화 |
| `tests/stage2_interactions.gd` | 41 | 0 | NPC 시선·회전 유예·무충돌·대화 없음·작업 클립, 잠긴 문·가장 가까운 문, 문지기 세 번째 프레임·대문 충돌·자동 입장·재진입 방지 |
| `tests/stage2_sky.gd` | 66 | 0 | 비행·급강하 단일 피해·선딜/활성 인터럽트·후딜/턴·6타 처치·사망·회복 드랍 |
| 합계 | **513** | **0** | 기능 검사 |

- Godot 4.3 최초 에디터 가져오기 및 GDScript `--check-only` 검사를 실행했습니다.
- 새 합성 음원 9개와 BGM 3개는 44100Hz·모노·16bit·피크 ≤-3dBFS이며 BGM 길이는 48초입니다. 반복 경계를 검사했습니다.
- NPC·문 검사는 실제 SceneManager로 레벨을 오가며 실행합니다. 문이 완전히 열리기 전 자동 진입이 불가능하고, 600px 이탈 후 닫힘·300px 재접근 후 열림·향후 대화 요구 훅 차단을 확인했습니다.
- 비행 괴수 5% 드랍은 제어된 확률 입력으로 양쪽 결과를 검사하며, 사람의 플레이에서 정확히 20마리마다 한 번 나온다는 의미는 아닙니다.

- GL Compatibility 실제 렌더링은 Mesa llvmpipe/Xvfb에서 실행했습니다. 7개 레벨과 후문 밖 별장 대문까지 **8개 1280×720 화면**을 `docs/screenshots/stage2_*.png`에 보존했습니다. NPC·요리사·청소 하인·문·비행 괴수와 새 배경을 확인했습니다. 가상 디스플레이의 VSync 미지원 경고 외 오류가 없었습니다.
- 배포는 `main`을 변경하지 않고 `codex/nimrod-rear-gate-godot43` 브랜치에 저장합니다. GitHub 커밋 ZIP을 실제 다운로드하고 CRC·커밋 파일 바이트 일치·캐시 제외를 확인합니다. 새 폴더에 압축 해제한 후 Godot 4.3 최초 임포트·메인 실행과 PNG 검증을 수행해 전달합니다.

검사 명령:

```sh
godot --headless --editor --path . --quit
python tools/validate_assets.py
godot --headless --path . --script res://tests/regression.gd
godot --headless --path . --script res://tests/stage2_transitions.gd
godot --headless --path . --script res://tests/stage2_interactions.gd
godot --headless --path . --script res://tests/stage2_sky.gd
```

## 실행하지 못한 항목과 이유

- 실제 스피커 청감: 자동 실행은 Dummy 오디오 드라이버를 사용하므로 음질·볼륨 균형의 청취 평가는 하지 않았습니다.
- Windows 배치와 실제 Windows GPU 실행: 작업 환경이 Linux입니다.
- 장시간 사람이 직접 조작하는 플레이, 애니메이션의 미적 자연스러움, 장기 난이도: 자동 입력·물리·프레임·정지화면 검증과 별도로 사람이 평가할 항목입니다.
- NPC 대화·별장 2층·엔딩: 이번 단계의 구현 범위가 아닙니다. NPC는 빈 상호작용 연결 지점만 가지며, 별장 2층 문은 잠금 메시지를 표시합니다.

## 변경·추가 파일 영역

| 영역 | 주요 파일 |
|---|---|
| 프로젝트·메인 | `project.godot`, `scenes/Main.tscn`, `scripts/main.gd`, `scripts/player.gd`, `scripts/game_hud.gd` |
| 레벨 전환·진행 | `scripts/scene_manager.gd`, `scripts/game_state.gd`, `scripts/level_base.gd`, `scripts/interior_level.gd`, `data/levels.json`, `data/transitions.json` |
| 레벨 씬 | `scenes/RearGate.tscn`, `scenes/CastleF1.tscn`~`CastleF5.tscn`, `scenes/VillaF1.tscn`, `scripts/rear_gate.gd`, `scripts/rear_gate_layout.gd` |
| 문·대문 | `scripts/door_portal.gd`, `scripts/villa_gate.gd`, `scenes/props/DoorPortal.tscn`, `data/interactions.json` |
| NPC | `scripts/npc_base.gd`, `scripts/villa_gatekeeper.gd`, `data/npcs.json`, `assets/sprites/npcs/<id>/`의 PNG·manifest |
| 적·회복 | `scripts/enemy_base.gd`, `scripts/enemy_melee_beast.gd`, `scripts/enemy_ranged_beast.gd`, `scripts/enemy_sky_beast.gd`, `scripts/healing_pickup.gd`, `data/enemies.json`, `data/pickups.json` |
| 비행 괴수 아트 | `assets/sprites/enemies/sky_beast/`의 7개 클립 PNG·manifest |
| 환경 아트 | `assets/backgrounds/rear_gate/`, `assets/backgrounds/castle/`, `assets/backgrounds/villa/`, `assets/tiles/castle/`, `assets/props/doors/`, 신규 실내·주방·별장 소품, `assets/ui/prompt_e.png` |
| 아트 원본·검증 | `assets/art_manifest.json`, `assets/stage2_environment_manifest.json`, `assets/source_art/`, `assets/image_prompts/`, `tools/pack_sprites.py`, `tools/validate_assets.py`, 아트 빌드·숨쉬기·배경 합성 도구 |
| 오디오 | `scripts/audio_manager.gd`, `data/audio_stage2.json`, `tools/make_sfx.py`, `tools/make_bgm.py`, `assets/audio/sfx/`의 신규 9종, `assets/audio/bgm/`의 신규 3곡 |
| 한글·문서 | `assets/fonts/NimrodUIKorean-Regular.otf`, `README.md`, `README_KO.txt`, 이 보고서, `tools/ART_PIPELINE_KO.md` |
| 검사 | `tests/regression.gd`, `tests/stage2_transitions.gd`, `tests/stage2_interactions.gd`, `tests/stage2_sky.gd`, 렌더 캡처 도구·화면 |

배포 기준 전체 변경·추가 파일 목록은 [STAGE2_FILES_KO.txt](STAGE2_FILES_KO.txt)에 있습니다. 비교 기준은 1단계 전경 삭제 완료 커밋 `e65e09df3cbbfa2fcf881693d7927a08449be63c`입니다.
