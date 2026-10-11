# 작업 지시 6단계: NIMROD (Godot 4.3, GDScript) — 괴수 확대·인식 표시, 구조물 표시, 버그 수정, 니므롯의 집 내부, 샴하트 버프, 삼나무 숲과 보스

## 0. 전제와 공통 규칙

### 0-1. 확인된 현재 상태 (직접 다시 확인하고 다르면 실제 값을 따른 뒤 보고)
- 먼저 프로젝트 전체를 읽는다: `project.godot`, `scripts/*.gd`(특히 `enemy_base.gd`, `enemy_stage5.gd`, `level_base.gd`, `player.gd`, `npc_base.gd`, `door_portal.gd`, `scene_manager.gd`, `game_state.gd`, `game_hud.gd`, `asset_visual.gd`), `data/*.json`(`levels.json`, `enemies.json`, `npcs.json`, `player_attacks.json`, `pickups.json`), `assets/sprites/enemies/*/manifest.json`, `tools/*.py`, `tests/*.gd`, `docs/STAGE5_REPORT_KO.md`.
- 5단계 결과의 사실(검증됨):
  - `data/enemies.json`의 `enemies` 항목은 `body_size`, `visual_scale`, `frame_size`, `anchor`, `detect_range`, `attacks` 등을 가진다. 현재 `body_size`(px)는 explosive_spitter [110,86], wall_diver [90,60], root_spewer [74,80], boar_charger [155,94], gas_sac [88,90], wraith_ray [98,48], shell_scorpion [134,80], corpse_bomber [62,88], chain_beastman [180,178]이고, 모두 `visual_scale 0.3`이다. 플레이어 서 있는 키는 약 109px(363px × 0.30)이다.
  - `enemy_base.gd`는 생성 시 `_show_clip("idle", 0.0)`을 호출하고 상태별로 `idle/walk/windup/attack/recovery/turn/hurt/death`를 요청한다. 클립이 없으면 `MISSING_TEXTURE`(회색 사각형 + "MISSING")가 표시된다.
  - `wall_diver`의 클립은 `perch_ceiling, perch_wall, tell, dive, claw, recovery, crawl, turn, hurt, death`뿐이라 `idle`, `walk`, `windup`이 없다. 시작 시점의 `idle` 요청과, 지상 모드 할퀴기 선딜의 `windup` 요청에서 MISS가 표시된다.
  - 같은 종류의 누락 가능성이 다른 괴수에도 있다(표준 클립 기준 누락): gas_sac(idle, walk, windup, attack, recovery, death), wraith_ray(idle, walk, windup, attack, recovery), corpse_bomber(walk, windup, attack, recovery, death), root_spewer(walk, attack), boar_charger(windup, attack), chain_beastman(windup, attack, recovery), shell_scorpion(windup, attack, recovery), explosive_spitter(attack), ranged_beast(attack), sky_beast(idle, walk, attack). 일부는 `enemy_stage5.gd`가 이름을 바꿔 요청하지만 `death`, 초기 `idle` 등 모든 경로가 보장되지는 않는다.
  - 니므롯 집 외관 `assets/props/nimrod_home_exterior.png`는 1300x720이고 불투명 영역이 y=35~655(실제 건물 하단은 y≈647)에서 끝난다. `HomeRoad`의 `backgrounds`에서 `position [0,160]`에 놓여 있어, 건물 바닥이 `floor_y 880`보다 약 65~73px 위에 떠 있다.
  - `LevelBase`에는 `_make_surface(x,y,w,h,one_way)`(충돌 면 생성), `_fill_underground`, `_make_backgrounds`, `_make_npcs`, `_make_doors`, `_spawn_enemies`, `is_point_safe` 등이 있다. 이름표·가독성 처리(빛 웅덩이, 접지 그림자), 3방향 NPC(`idle` + `idle_front`)가 구현돼 있다.
  - 플레이어 점프 높이 약 138px, 공중 수평 이동 약 286px, 달리기 360px/s, 구르기 780px/s(0.48초, 무적 0.25초). 실내 `floor_y 620`, 야외 `floor_y 880`.
- 기존 수치·조작은 명시적 지시 없이 바꾸지 않는다. 수치는 `data/*.json`으로 관리한다. 매 단계 후 프로젝트가 오류 없이 실행돼야 하고 `godot --headless`로 `tests/*.gd`를 통과시킨다(구조가 바뀌는 테스트는 갱신하고 `tests/stage6_*.gd`를 추가한다).

### 0-2. 아트 에셋 규칙 (최우선)
- **괴수, NPC, 배경, 지형, 문, 소품, 효과(FX) 이미지는 코드(`_draw()`, 도형, 폴리곤, 절차적 생성)로 그리지 않는다.** 이미지 생성 도구로 만든 PNG만 사용한다. 렌더 설정(모듈레이트, 블렌드)과 PIL을 이용한 크로마키·정렬·시트 합성·색보정은 허용한다.
- 단, **이번에 요청한 "괴수 인식 표시"(§1-3)와 "구조물 구별 표시"(§1-4)는 이미지가 아니라 간단한 코드로 만든다**(UI/렌더 보조 효과이며 캐릭터·배경 아트가 아니다).
- 스프라이트는 배경을 단색 마젠타 `#FF00FF`로 요청해 생성하고 `tools/pack_sprites.py`로 투명 처리 → 앵커 정렬 → 한 줄 시트로 합성한다. `tools/validate_assets.py`로 검증한다.
- **이미지 생성 도구를 쓸 수 없으면 코드로 대체하지 않는다.** `assets/image_prompts/<에셋>.md`에 프롬프트를 쓰고, MISSING_TEXTURE 폴백(디버그용)만 두며, 최종 보고에 미생성 목록을 적는다.
- 공통 문구
  - 괴수·배경·소품·FX: `2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere with advanced space-civilization undertones, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark`
  - 인물(NPC): `2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, soft warm rim light on the light-facing edge, no black outline, no text, no watermark`
  - 인물 네거티브: `ancient costume, toga, loincloth, royal crown, mythological robe, veil, altar, excessive jewelry, glamour, halo, divine aura, black outline`
- 화면 하단 바위·풀 전경 장식 레이어는 만들지 않는다(삭제된 항목). 지면 아래는 `assets/tiles/underground_fill.png`로 채운다.
- **이미 생성된 에셋은 최대한 재활용**한다(문 시트, 소품, 타일, 가로등·울타리·관목 등). 새로 만드는 것은 아래 에셋 목록(§5)에 있는 것만이다.

## 1. 수정 사항

### 1-1. 5단계 괴수 크기 3배 확대
- 대상: 5단계에서 추가한 괴수 전부(`explosive_spitter, wall_diver, root_spewer, boar_charger, gas_sac, wraith_ray, shell_scorpion, corpse_bomber, chain_beastman`). `enemies.json`에 `size_multiplier: 3.0`을 두고 항목별로 `1.0`으로 되돌릴 수 있게 한다(근접·원거리 우루크 괴수와 비행 괴수는 변경하지 않는다).
- **배율을 적용하는 값**
  - `visual_scale`(예: 0.30 → 0.90), `body_size`, 피격 판정(hurtbox), 충돌 박스, 접지 그림자 폭.
  - 근접 공격 판정 박스의 크기와 오프셋(칼날·발톱이 시각적으로 닿는 범위와 일치해야 한다), 투사체 충돌 크기.
  - 범위 효과 반경(폭발, 가스 지대, 자폭)은 **×2.0**(×3은 화면을 덮으므로) 적용하고 FX 이미지는 그 반경에 맞춰 표시한다.
  - 감지·센서·선호 거리 같은 거리형 수치는 **×1.5**(최대 1100px)로 키운다(사슬 사거리 520 → 780, 벽면 강하 센서 등 포함). 돌진 최대 거리 800은 그대로 둔다.
- **배율을 적용하지 않는 값**: HP, 데미지, Turn Delay, 이동·돌진·투사체 속도, 선딜·active·후딜 등 모든 시간 값, 쿨다운, 넉백 표.
- 스프라이트 해상도: 표시 배율이 0.3→0.9가 되어도 원본 프레임은 1:1에 가깝게 표시되므로 재생성은 하지 않는다. 확대로 인한 흐림이나 비율 어긋남이 눈에 띄면 보고한다.
- **레벨 호환 재점검(필수)**: 괴수가 커졌으므로 도심 방향 통로 8개 층의 스폰 위치를 다음 기준으로 다시 맞춘다. `tools/check_enemy_clearance.py`(신규)로 검증한다.
  - 지상 괴수의 스폰·순찰 구간은 천장까지 여유가 `body_size.y × 1.05` 이상, 가로 여유가 `body_size.x + 40` 이상이어야 한다. 부유 괴수(가스 주머니, 환령)도 같은 기준을 적용하되 환령은 지형을 관통하므로 예외다.
  - 7층 저천장 터널(천장 간격 100px)에는 지상 괴수를 둘 수 없다. 터널 안에 있던 자폭 시체·방어 갑피·독가스는 터널 밖의 높은 방으로 옮기고, 터널은 환령과 수그리기 이동 구간으로만 남긴다.
  - 뿌리 화염 괴수가 서는 발판의 폭은 `body_size.x + 60` 이상(= 약 280px)으로 넓힌다. 발판 간격 규칙(수평 ≤200, 수직 ≤110)은 유지한다.
  - 8층 수직 통로 방과 대형 수인(body 약 540x534)이 서는 방은 천장 높이 700px 이상으로 키우고(카메라 한계·배경 확장 포함), 괴수의 활동 구간은 방 폭 안으로 제한한다.
  - 4층 다리, 6층 돌진 회랑 등 폭이 부족한 곳은 폭을 늘린다. 돌진 직선 구간은 괴수 몸 폭 + 800px 이상.
  - 변경 사항은 `data/levels.json`에 반영하고 `tools/check_level_reachability.py`를 다시 통과시킨다.
- 시각 크기 검증: `tools/check_enemy_visual_bounds.py`(신규)가 각 괴수 `idle`(또는 대표 클립)의 비투명 영역 높이 × `visual_scale`을 `body_size.y`와 비교해 ±15%를 벗어나면 경고한다.
- 테스트: `tests/stage5_*`의 크기 기대값을 갱신한다. 스크린샷에 플레이어와 같은 프레임으로 크기 비교를 남긴다.

### 1-2. 클립 누락(MISS) 수정 (이미지 수정 + 안전장치)
**원인**: §0-1대로 상태가 요청하는 클립이 시트에 없다.
- **이미지로 해결(벽면 강하 괴수, 최우선)**: `assets/sprites/enemies/wall_diver/`에 아래 클립을 추가 생성하고 `manifest.json`에 등록한다(오른쪽 기준, 640x640, 앵커 `[320,320]`, 기존 벽면 강하 시트와 같은 디자인 일관성).
  - `idle`: 4프레임, 0.8초, 루프. 착지 후 지상에서 잠시 멈춘 자세(박쥐 날개를 접고 지네 몸을 웅크림).
  - `windup`: 4프레임, 0.35초, 비루프. 지상 할퀴기 선딜(앞발톱을 들고 몸을 뒤로 젖힘). 지상 모드 선딜 0.35초와 일치시킨다.
  - `walk`는 만들지 않고 `crawl`의 별칭으로 처리한다(아래 별칭 규칙).
- **전 괴수 감사**: `tools/check_enemy_clips.py`(신규)로 모든 괴수에 대해 (a) 정적으로 코드가 요청할 수 있는 클립 이름을 수집하고 (b) 매니페스트와 비교해 누락 목록을 출력한다. `tests/stage6_clip_coverage.gd`는 모든 괴수를 생성해 IDLE/CHASE/WINDUP/ACTIVE/RECOVERY/TURN/STUN/DEAD와 각 `phase`를 강제로 돌려 보고, 어느 상태에서도 `MISSING_TEXTURE` 노드가 보이지 않는지 단언한다.
- **별칭과 대체 규칙**(이미지가 따로 필요 없는 경우): `manifest.json`에 `aliases` 객체를 지원한다. 예) wall_diver `{"walk":"crawl"}`, gas_sac `{"idle":"float","walk":"float","windup":"bump","attack":"bump","recovery":"float"}`, wraith_ray `{"idle":"glide","walk":"glide"}`, corpse_bomber `{"walk":"run","death":"explode"}`, root_spewer `{"walk":"idle","attack":"spew"}`, ranged_beast `{"attack":"flame_loop"}`, sky_beast `{"idle":"fly_idle","walk":"fly_idle"}`. `_show_clip()`은 요청 클립 → 별칭 → `idle` → 첫 클립 순으로 대체하고, 어떤 경로에서도 MISSING 표시가 나오지 않게 한다(경고 로그만).
- 가스 주머니·자폭 시체의 `death`는 별칭만으로 어색하면(죽음 연출 구간이 비어 보임) 해당 클립을 이미지로 추가 생성하고 보고한다. 이미지 생성이 필요한 클립은 §5-1 목록에 기록한다.

### 1-3. 괴수 인식 표시 (이미지 없이 간단한 코드, 이름표·테두리 금지)
플레이어가 괴수를 한눈에 알아보게 하는 가벼운 표시를 **모든 괴수**(우루크 근접/원거리, 비행 괴수, 5단계 괴수, 삼나무 숲 괴수, 보스)에 적용한다. 배경과 동떨어진 외곽선, 이름표, 화려한 아이콘은 쓰지 않는다.
- **A. 접지 위협 그림자**: 괴수 발밑에 어두운 적갈색의 부드러운 타원 그림자(`Color(0.35,0.04,0.04,0.50)`, 가장자리로 갈수록 투명한 방사 그라데이션, 폭 = `body_size.x × 0.95`, 높이 16~22px). 이미지 대신 `scripts/threat_marker.gd`의 `_draw()`로 정점 색을 보간한 폴리곤을 그린다. 공중에 뜬 괴수(벽면 강하 비행 중, 가스 주머니, 환령, 비행 괴수, 부유령)는 아래 지면까지 레이캐스트해서 지면 위에 투영하고, 높이가 높을수록 알파와 크기를 줄인다(지면이 600px 안에 없으면 그리지 않는다).
- **B. 머리 위 위협 표식**: 몸 hurtbox 상단 +14px 위에 작은 **진홍색 역삼각형(▼)** 하나(기본 높이 14px, 폭 18px, 색 `#C8473B` 알파 0.85, 아래로 갈수록 어두워지는 정점 색, 외곽선 없음, 은은한 어두운 그림자 1겹). 위아래 ±3px로 1.2Hz로 부드럽게 흔들린다. 크기는 `clamp(body_size.x × 0.06, 14, 30)`로 몸 크기에 비례한다. 보스는 크게(높이 30px).
  - 표시 조건: 살아 있고, 화면 안에 있고, 플레이어와 같은 레벨이며 안전 구역 밖일 때. 죽으면 즉시 페이드아웃(0.15초).
  - **선딜(WINDUP) 상태**에서는 표식이 밝은 적색(`#FF5A44`)으로 바뀌고 흔들림이 2배 빨라진다(공격 예고를 읽기 쉽게). 자폭 시체의 퓨즈 중에는 표식이 점멸 가속한다.
  - 매복형(벽면 강하 `perch`, 삼나무 마귀의 나무 위 대기)도 표식이 보여 위치를 알 수 있다. 단, 이 경우 표식 불투명도를 0.55로 낮춰 "숨어 있지만 존재함"을 암시한다.
- 설정: `data/enemy_markers.json`(`enabled`, 색, 크기 계수, 괴수별 `marker_offset`/`shadow_width` 재정의). 디버그 키 `F2`로 켜고 끈다.
- 구현: `EnemyBase._ready()`에서 `ThreatMarker` 자식 노드를 하나 만들고 `body_size`/상태를 읽는다. 괴수 몸체의 `flip_h`와 무관하게 표식은 뒤집히지 않는다. 렌더 순서는 괴수 몸체 아래(그림자), 몸체 위(표식), HUD 아래.
- 테스트: `tests/stage6_threat_marker.gd`(모든 괴수 생성 시 표식이 있다, 사망 시 사라진다, WINDUP에서 색이 바뀐다).

### 1-4. 구조물 구별 표시 (이미지 없이 간단한 코드)
플레이어가 **서 있을 수 있는 면**(바닥, 단차, 발판, 돌출부)과 배경 그림을 구별하도록, 충돌 면에 은은한 표시를 자동으로 붙인다. 테두리를 그리지 않고, 위쪽 가장자리의 빛과 아래쪽 그림자로 "두께 있는 물체"처럼 읽히게 한다.
- `LevelBase._make_surface()`가 만든 모든 면에 `SurfaceAccent`(자식 `Node2D`, `_draw()` 사용)를 붙인다.
  - **윗면 하이라이트**: 면 윗변을 따라 2px 두께의 따뜻한 백색 선(`Color(1.0,0.92,0.78,0.55)`)과 그 아래로 8px 동안 알파 0.25→0으로 사라지는 부드러운 그라데이션(정점 색 보간). 선은 윗변 양 끝에서 6px 안쪽으로 짧게 그려 외곽선처럼 보이지 않게 한다.
  - **일방향 발판**은 같은 규칙에 **차가운 청백색**(`Color(0.78,0.90,1.0,0.55)`)을 쓰고 윗변 하이라이트를 점선(12px 선, 8px 간격)으로 그려 "통과 가능"을 구분한다.
  - **밑면 그림자**: 발판·돌출부의 아랫변 아래로 14px, 알파 0.35→0의 어두운 그라데이션(지면 `floor`의 아랫변은 그리지 않는다).
  - 측면 모서리 하이라이트는 그리지 않는다.
- 레벨별 조정: `data/surface_accent.json`에 전역 설정과 레벨 재정의(`color`, `intensity`, `enabled`). 배경이 밝은 레벨은 강도를 낮추고, 어두운 실내는 높인다. `F3` 키로 켜고 끈다(비교용).
- 레벨 장식 소품(배경 그림)에는 붙이지 않는다. 오직 충돌 면에만 붙어서 "붙은 곳이 서 있을 수 있는 곳"이 되게 한다.
- 이 표시는 NPC·괴수·플레이어 아래, 배경 타일 위에 그린다.
- 테스트: `tests/stage6_surface_accent.gd`(모든 `_make_surface` 호출에 `SurfaceAccent`가 붙는다, 일방향 면은 청백색).

### 1-5. 니므롯 집 외형이 공중에 뜬 문제와 접지 점검
- `HomeRoad`의 `HomeExterior`를 지면에 닿게 고친다. 이미지 하단의 투명 여백 때문에 뜬 것이므로 **이미지를 다시 만들지 않고** 위치를 맞춘다: 불투명 영역의 하단 고체 행(y≈647)이 `floor_y 880`에 오도록 `position.y`를 `880 − 647 = 233`(기존 160 대비 +73)으로 바꾼다. 건물 윗부분이 화면 위로 너무 올라가거나 시차 배경과 어긋나면 보고한다.
- 지면 바로 위 높이 약 75px의 띠에서 **노이즈처럼 깨져 보이는 블록**이 보인다(스크린샷). 원인(뜬 건물 때문에 드러난 `mid_district_tile`/`far_tile`의 하단 영역일 가능성)을 확인하고, 위치 수정 후에도 남으면 해당 시차 레이어 하단 25%를 지면선까지 어둡고 매끄러운 안개로 이어지게 처리한다(PIL 색보정 허용) 또는 `assets/image_prompts/`에 재생성 프롬프트를 남기고 보고한다.
- **전 레벨 접지 점검**: `tools/check_ground_contact.py`(신규)가 `levels.json`의 모든 배치 장식·배경 구조물에 대해 이미지의 하단 고체 행(알파>200이 폭의 30% 이상인 가장 아랫 행)과 배치 y를 구해, 지면에 닿아야 하는 구조물(문, 집, 담장, 기둥, 좌판 등, 항목에 `ground_contact: true`)이 해당 x의 지면 높이 ±6px 안에 있는지 검사하고 결과를 `docs/STAGE6_GROUND_CONTACT.txt`로 남긴다. 어긋난 항목은 `position.y` 조정으로 고친다.

## 2. 니므롯의 집 내부 (`NimrodHome`)

### 2-1. 연결
- `HomeRoad`의 집 정문(`nimrod_home_gate`, x=400)의 `locked`를 해제하고 `target_level = NimrodHome`, `target_spawn = Spawn_FromGate`, `arrival_spawn = Spawn_FromHome`(HomeRoad x=520, exit_direction +1)로 연결한다(E → 열림 → 이동 → 도착 문 닫힘, 기존 `DoorPortal` 규칙).
- `NimrodHome`: 실내(`floor_y 620`), 너비 1800, 괴수 없음, 전체가 안전 구역, `display_name "니므롯의 집"`, BGM `nimrod_home`(§6).
- 집 문(`home_exit`, x=1650): 오른쪽 끝, `nimrod_home_inner_door.png`(§5), `target_level = HomeRoad`, `target_spawn = Spawn_FromHome`. `Spawn_FromGate`(집 안 도착) = x=1560.
- 이 레벨을 시작 지점으로 바꾸지는 않는다(사망 시 재시작 위치는 기존 그대로).

### 2-2. 구성
- 실내 구성(왼쪽 → 오른쪽): 침대 구역(x 120~520), 작업대와 선반(x 600~1100), 식탁(x 1150~1500), 문(x 1650). 소품은 이미지(§5)로 배치하고 벽면 선반·램프는 배경에 포함한다.
- **엔키두아**: x=1000에 서 있다. 숨쉬는 `idle`과 정면 `idle_front`(3방향 규칙, §3-3)가 있다. **대화·상호작용은 만들지 않는다**(`interact()` 빈 함수, E 프롬프트 없음). 이름표 "엔키두아", 빛 웅덩이·접지 그림자·근접 하이라이트는 기존 NPC와 동일.

### 2-3. 엔키두아 외형 (여성, 엔키두 모티브, 예쁘게 설정하지 않음)
- 엔키두(점토로 빚어진 야생의 동료)를 모티브로 한 **여성**. 야성적이고 억센 인상. **미화하지 않는다**: 화장기 없는 투박한 이목구비(각진 턱, 굵은 눈썹), 햇볕에 그을린 거친 피부, 얼굴과 팔의 작은 흉터와 주근깨, 단단하고 넓은 체격. 매력을 강조하는 포즈·옷차림·표정을 쓰지 않는다. 성인.
- 머리: 길고 숱 많은 헝클어진 짙은 갈색 머리, 일부를 거칠게 땋아 뼈 조각·점토 구슬로 묶음.
- 복장(이 세계관의 실용 복식, 고대풍 금지): 덧댄 자국이 많은 가죽 조끼와 털 장식 어깨 망토, 활동하기 편한 긴 소매 셔츠와 바지, 두꺼운 벨트와 도구 주머니, 거친 장갑과 부츠. 색은 이끼 녹색과 점토 갈색, 뼈색을 주로 쓰고(실내 따뜻한 배경과 구별되도록 이끼 녹색을 우세하게) 금색은 쓰지 않는다. 목에 점토로 빚은 작은 부적 하나.
- 키 비율 1.04(기존 `height_ratio` 기준 363px × 1.04).
- 제작: 디자인 시트(`assets/reference/enkidua_design.png`, 정면·측면·얼굴 클로즈업) → 오른쪽 측면 정지 이미지 + 정면 정지 이미지 → `tools/make_breathing_sheet.py`로 `idle`, `idle_front`(각 6프레임, 2.4초, 루프) 생성. 림라이트 4~6px(`#FFE8C4`, 35~45%)와 의상 색 대비 규칙, `validate_assets.py`의 NPC 대비 점검을 통과한다.
- `data/npcs.json`: `enkidua`(`display_name "엔키두아"`, `three_way: true`, `interactable: false`).

## 3. 샴하트 상호작용, 버프, 대화 연출 시스템

### 3-1. 대화 연출 시스템 (`scripts/dialogue_system.gd`, autoload `Dialogue`)
- `Dialogue.play(lines: Array, speaker: Node2D, options := {})`. 각 줄은 `{text, speaker(optional), hold_seconds(optional)}`.
- 연출 순서(샴하트 버프 대화가 기본 연출):
  1. **시간 정지**: `get_tree().paused = true`. 대화 UI, 카메라 줌, 말풍선 노드는 `process_mode = ALWAYS`.
  2. **카메라 줌인**: 플레이어 `Camera2D`의 `zoom`을 `1.0 → 1.6`으로 0.35초(ease-out)에 보간하고, 화면 중심을 NPC 머리 위쪽(NPC 키의 80% 높이)으로 옮긴다. 레벨 카메라 한계는 유지한다.
  3. **말풍선**: NPC 머리 위에 월드 좌표를 따라가는 말풍선(CanvasLayer의 `Control`). 스타일은 `StyleBoxFlat`(배경 `(0.06,0.07,0.11,0.93)`, 모서리 12px, 내부 여백 14/10, 가는 금색 테두리 `(0.82,0.68,0.40,0.9)` 2px, 프로젝트 한국어 폰트·크기 22), 아래쪽에 꼬리 삼각형(코드 폴리곤)이 NPC 머리를 가리킨다. 텍스트는 한 글자 0.04초로 타자 효과(`speech_blip` 효과음 약하게)로 표시하고, 다 나오면 1.4초 유지 후 자동으로 닫힌다. **플레이어 조작 입력 없이 자동 진행**된다(여러 줄이면 줄마다 말풍선을 교체).
  4. 대화가 끝나면 카메라가 0.35초에 원래 줌·위치로 돌아오고 `paused = false`.
  5. 대화 중에는 이름표를 숨기고, E 프롬프트와 HUD 토스트를 숨긴다.
- 월드와 카메라 연출 중 플레이어의 입력과 적 AI가 모두 멈춘 상태여야 한다(일시 정지).
- 이 시스템은 이후 다른 NPC 대화에도 쓰일 수 있게 `speaker`와 `lines`만 바꿔 호출 가능하게 한다. 다른 NPC의 대화는 이번에 만들지 않는다.

### 3-2. 샴하트 버프
- `CastleF2`의 샴하트를 상호작용 가능하게 한다: `data/npcs.json`의 `shamhat`에 `interactable: true`, `interaction: "shamhat_blessing"`. 플레이어가 120px 이내일 때만 기존 E 프롬프트가 뜬다.
- E 입력 → `Dialogue.play([{text: "당신이 자꾸 신경쓰여요."}], shamhat)` → 대화가 끝나면 버프 적용.
- **버프**: 공격력, 공격속도, 최대 HP를 각각 **+50%**. 이번 한 번의 런(= 사망 전까지) 동안 영구 유지(가정, 보고서에 명시). 한 런에 한 번만 받을 수 있다: `GameState.run_flags["shamhat_blessing"]`로 관리하고, 받은 뒤에는 샴하트 E 프롬프트를 숨긴다. 사망 시 `reset_run()`으로 초기화된다.
- 수치 시스템: `scripts/player_modifiers.gd`를 만든다. 이름 있는 수정자들을 합산한다(`{"attack": +0.5, "attack_speed": +0.5, "max_hp": +0.5}` 형식의 백분율 증가를 더해 `1 + 합계`로 곱함). 향후 멜람무(+3% 누적) 등과 합산될 수 있게 만든다.
  - 공격력: 도끼 데미지 `round(base × (1+Σattack))`(20 → 30, 4타 22 → 33). 괴수에 가는 데미지에만 적용된다.
  - 공격속도: 공격 클립 길이와 `active_start/active_end`, 선·후딜을 `1/(1+Σattack_speed)`로 줄인다(상한 **×2.0**, 즉 최대 +100%). 구르기 속도·시간에는 영향 없음. 콤보 리셋 0.8초는 실제 초 기준 유지.
  - 최대 HP: `round(180 × (1+Σmax_hp))`(180 → 270). **늘어난 만큼 현재 HP도 회복**한다(+90). HUD의 HP 바 최대치가 갱신된다.
- 버프 적용 시 HUD에 1.8초짜리 토스트 "샴하트의 축복: 공격력 · 공격속도 · 최대 HP +50%"를 표시한다.
- 테스트: `tests/stage6_shamhat_buff.gd`(E 입력 시 일시 정지·줌·말풍선, 종료 후 정지 해제, 수치 +50%, 재상호작용 불가, 사망 후 초기화).

### 3-3. 3방향 NPC 확장
- `three_way` 규칙(좌/정면/우, `idle` + `idle_front`)이 `enkidua`에도 적용되게 한다. 대화 연출 중에는 NPC가 정면(FRONT)을 바라본다.

## 4. 샤마쉬와 아야의 별장 후문 밖, 삼나무 숲, 보스

### 4-1. 레벨 연결
`VillaF1(후문) → VillaBackyard → (포탈, 400px) → CedarForest_F1 ⇄(포탈)⇄ CedarForest_F2 → (맨 위 포탈) → CedarBossRoom`
- 전부 `DoorPortal`/포탈 규칙(E → 열림 → 이동 → 도착 문 닫힘)을 쓴다. 역방향(되돌아가기)도 가능하다. 사망 시 시작 지점 복귀 규칙은 기존 그대로.

### 4-2. 별장 후문 밖 (`VillaBackyard`)
- `VillaF1`의 후문(`villa_back_door`)의 `locked`를 해제하고 `target_level = VillaBackyard`, `target_spawn = Spawn_FromBackDoor`로 연결한다.
- 야외(`floor_y 880`), 너비 1500, **괴수 없음, 전체가 안전 구역**, `display_name "샤마쉬와 아야의 별장 뒤뜰"`, BGM `villa_calm`.
- 후문 바깥쪽 문(`villa_back_door_exterior`)이 x=300, **삼나무 숲 포탈(`cedar_forest_portal`)이 x=700**(문에서 400px). 도착 스폰 `Spawn_FromBackDoor` x=360(exit_direction +1). 포탈 도착 스폰 `Spawn_FromForest` x=640(exit_direction −1).
- 지형은 평지(단차 없음). 별장 뒷면 외관을 배경(§5)으로, 가로등·울타리·관목은 기존 소품을 재활용한다.
- 숲 포탈 문: `cedar_forest_portal.png` 320x460, 6프레임(오래된 삼나무 뿌리가 얽힌 아치형 입구, 안쪽에서 녹색 빛, 첫 프레임 닫힘/마지막 열림), `target_level = CedarForest_F1`, `target_spawn = Spawn_FromVilla`.

### 4-3. 삼나무 숲 구조 (미로형 수직 맵, 2층 + 보스방)
- **레벨**: `CedarForest_F1`, `CedarForest_F2`. 각각 너비 3600, 높이 2800의 **수직 이동 미로**. 야외 숲(`ceiling false`, 각 방 천장은 줄기와 가지로 구성). `display_name`은 "삼나무 숲 1층/2층". BGM `cedar_forest`.
- **미로 구성 방식**: 3열 × 4행 격자의 방(셀 크기 1200x640, 벽 두께 80)을 만들고 방 사이 통로(폭 200)를 데이터(`data/cedar_forest_layout.json`)로 정의한다. 셀 사이 수직 이동은 일방향 발판 체인(수직 간격 ≤110, 수평 ≤200)으로 만든다.
  - 입구 방은 왼쪽 아래, 출구 포탈 방은 오른쪽 위. 정답 경로 길이 14셀 이상, 갈림길 4곳 이상, 막다른 길 3곳 이상(막다른 길 중 2곳에는 `healing_vomit` 픽업 1개씩, 가정). 막다른 길과 정답 경로를 시각적으로 구분하지 않는다(미로).
  - 점프 한계 규칙(단차 ≤110, 발판 간격 ≤200)을 지키고 사망 구덩이는 없다. `tools/check_level_reachability.py`에 미로 검증을 추가해 입구 → 출구 경로 존재와 막다른 길 도달 가능성을 확인한다.
  - 괴수 크기에 맞는 여유(§1-1 clearance 기준, 몸 높이 ×1.05, 폭 +40)를 `tools/check_enemy_clearance.py`로 검증한다. 대형 무두 해골(몸 약 300x440)이 서는 방은 높이 560 이상, 폭 900 이상으로 만든다.
- **포탈**: `CedarForest_F1`의 출구 포탈(오른쪽 위 방)이 `CedarForest_F2`의 `Spawn_FromBelow`(왼쪽 아래 방)로 연결된다. `CedarForest_F2`의 맨 위(오른쪽 위 방) 포탈이 `CedarBossRoom`으로 연결된다. 각 층에 아래층으로 돌아가는 포탈이 입구 방에 있다. 문 이미지는 `cedar_portal.png`(층간용)를 쓴다.
- **괴수 배치**(스폰은 `levels.json` 데이터, 근처 문·포탈 좌우 250px에는 스폰하지 않는다):
  - 1층: 풍화된 삼나무 해골 파수꾼 7, 삼나무 대형 무두 해골 3(넓은 방에 배치).
  - 2층: 석궁 해골 사수 5(좁은 통로 양끝 발판과 높은 가지 위), 저주받은 유골 부유령 5, 삼나무 통곡의 해골 마귀 4(`perch` 마커를 줄기 상단과 가지에 배치).
- **토사물**: 삼나무 숲의 모든 해골 괴수는 5% 확률로 토사물(+30 HP, E로 먹음)을 드랍한다(`drop_rule: {"mode":"all","chance":0.05}`, 보스 제외).
- 배경: 시차 2겹(가로·세로 이음새 없는 2D 타일을 `Parallax2D.repeat_size`로 반복). 지면 아래·벽 바깥은 줄기와 뿌리 타일로 채운다. 화면 하단 전경 장식은 만들지 않는다. §1-4의 `SurfaceAccent`가 서 있을 수 있는 뿌리·가지 면에 적용된다.

### 4-4. 삼나무 숲 신규 괴수 5종 (이미지 생성 + 구현)
공통: `EnemyBase` 상속(공격 후딜 보장, 즉시 회전 금지·3프레임 이상 턴 애니메이션, 히트스톱 0.05초, 넉백/경직 표), **필수 클립 세트와 별칭 규칙(§1-2)**을 처음부터 지켜 MISS가 없어야 한다. 위협 표식(§1-3) 적용. 시각 배율은 `visual_scale 0.45`(보스는 0.50). 사용자가 지정하지 않은 값은 아래 가정값을 쓰고 보고서에 적는다.

| id | 이름·외형 | HP | 데미지 | Turn Delay | 몸 크기(px) |
|---|---|---|---|---|---|
| `cedar_sentinel` | 풍화된 삼나무 해골 파수꾼: 뿌리와 덩굴이 골격 틈새를 얽은 해골 병사, 녹슨 단검과 나무 방패 | 85 | 12 | 0.30 | [140, 250] |
| `cedar_colossus` | 삼나무 대형 무두 해골: 여러 해골의 유골이 융합된 4m 거대 해골, 삼나무 뿌리 몽둥이 | 165 | 내려치기 22, 횡치기 16, 후방 8 | 0.60 | [300, 440] |
| `cedar_archer` | 석궁 해골 사수: 뼈로 만든 대형 석궁을 든 해골, 늑골 중앙에 검붉은 기운 | 58 | 14(직격) | 0.20 | [150, 260] |
| `cedar_wisp` | 저주받은 유골 부유령: 다리 없이 척추와 두개골만 있는 푸른 인화성 해골 유령 | 32 | 접촉 9, 자폭 15 | 0.15 | [120, 170] |
| `cedar_demon` | 삼나무 통곡의 해골 마귀: 4개의 팔을 가진 기괴한 해골 | 90 | 낙하 18, 4연속 할퀴기 총 10 | 0.25 | [220, 280] |

**`cedar_sentinel` 패턴**
- 감지 700, 이동 130. 공격 A "전진 2타": 선딜 0.40 → 찌르기(전진 90px, 판정 150x80, 데미지 12) → 0.30 뒤 베기(판정 170x90, 데미지 12) → 후딜 0.70.
- 방패 가드: 플레이어 도끼가 정면에서 닿을 때 **50% 확률로 방패를 들어 올려**(0.6초 유지) 그 타격의 피해를 **60% 감소**(×0.4)시킨다. 같은 타격 이후 0.6초 동안 방패 유지, 가드 중 이동 불가. **도끼 4타 충격파**에 맞으면 방패 가드가 강제로 파괴되고 **경직 1초**, 이후 3초 동안 가드 불가.

**`cedar_colossus` 패턴**
- 감지 800, 이동 90. **내려치기**: 몽둥이를 1.0초 들어 올린 뒤 내려친다(판정 260x200, 데미지 22), 바닥 충격파가 좌우로 퍼지며 맞으면 넉백(충격파 판정 높이 40, 사거리 400, 0.5초 유지). 후딜 1.2. **횡치기**: 선딜 0.7, active 0.2(판정 360x140, 데미지 16), 후딜 0.9.
- **후방 견제**: 플레이어가 구르기로 등 뒤를 잡았을 때 Turn Delay 0.6초 동안 돌아서지 않고, **40% 확률로** 몽둥이 자루로 뒤를 밀치는 기습(선딜 0.25, active 0.15, 뒤쪽 판정 160x120, 데미지 8)을 쓴다. 나머지 60%는 정상적으로 돌아선다.

**`cedar_archer` 패턴**
- 감지 900, 선호 거리 500~800. 석궁: 선딜 0.50(겨눔) → 뼈 화살 1발(속도 900px/s, 직선, 직격 데미지 14) → 후딜 0.40, 쿨다운 1.8.
- **접근 대응**: 플레이어가 260px 이내로 접근하면(구르기 포함) 뒤로 짧게 점프(220px, 0.4초)하며 **바닥에 뼈 가시 하나를 뿌리고**(가시가 0.6초 동안 남아 접촉 데미지 10, 가정) 물러난다. 이 패턴 쿨다운 3초.

**`cedar_wisp` 패턴**
- 지형을 관통해 플레이어를 80px/s로 천천히 추적(경계 클램프, 지형 충돌 없음). **HP가 0이 되거나 플레이어와 접촉하면**(접촉 시 데미지 9) 0.5초 뒤 **푸른 불꽃으로 자폭**해 넓은 범위(반경 200)에 데미지 15를 준다. 자폭 모션이 시작될 때 K 구르기 무적으로 빠져나가는 것이 핵심이다. 자폭 모션 중에는 위협 표식이 점멸한다.

**`cedar_demon` 패턴**
- 줄기 상단과 가지의 `perch` 마커에 매달려 있다. 플레이어가 마커 아래 가로 ±160, 세로 700px 이내를 지나가면 **기습 낙하**한다(낙하 속도 900px/s, 착지 시 찌르기 첫 공격 데미지 **18**, 판정 120x160). 착지 후 선딜 0.25초 → **4연속 할퀴기**(0.6초, 총 데미지 10: 3+3+2+2) → 후딜 0.8.
- **4연속 할퀴기 도중에는 공격 후딜 보장 규칙에 따라 절대 뒤를 돌아보지 않는다**(K로 첫 타를 피한 뒤 등 뒤에서 도끼 4타 콤보가 성립해야 한다). 이후 지상 근접 모드로 전환(이동 150, 할퀴기 쿨다운 1.5초)하며 다시 매달리지 않는다.

**효과음**: 각 괴수 `<id>_windup/attack/hurt/death` + 특수음(`sentinel_shield_up`, `sentinel_shield_break`, `colossus_slam`, `colossus_shockwave`, `archer_shot`, `bone_spike_pop`, `wisp_wail_loop`, `wisp_explode`, `demon_screech`).

### 4-5. 보스방과 보스 칼라-우쉬움갈 (`CedarBossRoom`)
**방 구성**
- `CedarForest_F2` 맨 위 포탈 → `CedarBossRoom`(`Spawn_FromForest`). **좁은 공간**: 너비 1600, 높이 900(천장 있음), `display_name "삼나무 숲의 가장 깊은 곳"`, BGM `cedar_boss`. 괴수 크기 대비 좁게 느껴지도록 방 폭은 보스 몸 폭의 약 3배.
- 양 끝(x=180, x=1420)에 **높이 +300의 발판**(유골 사수 소환용, 폭 280)이 있다. 도착 스폰 x=250(포탈 문 x=200).
- **전투 시작**: 플레이어가 x≥450로 들어오면 도착 문이 잠기고(전투 종료 시 해제) 보스 HP 바가 나타난다. 보스 HP 바는 화면 위 중앙의 가는 바(HUD 스타일 재사용)에 이름 "칼라-우쉬움갈"과 HP를 표시한다. (HP 바는 이 요청의 "이름표 금지"에 해당하지 않는 보스 전용 UI다.)

**보스 능력치** (`kala_ushumgal`)
- 삼나무 숲의 통곡하는 유골 거수. 6m의 거대 기형 해골 거인: 상체는 수천 개의 두개골이 층층이 쌓인 형태, 가슴 중앙에 검붉게 박동하는 기운, 오른팔은 수십 개의 척추뼈가 꼬여 만들어진 대형 뼈 채찍·몽둥이, 왼쪽 어깨에서 뼈 가시가 돋은 거대한 참수도가 자라 있음. **크기는 일반적인 괴수의 2배**(몸 크기 [520, 560], 일반 삼나무 숲 괴수 높이 약 250~440 기준).
- HP 1,200. 회전 지연: 1페이즈 0.70초, 2페이즈 0.50초.
- **상체 뼈 갑피**: 보스 정면(상체)에서 맞은 플레이어의 기본 공격 데미지는 **30% 감쇄(×0.7)**된다. 등 뒤와 하체(후면 hurtbox)에는 감쇄가 없다. 구르기로 등 뒤를 잡아 4타 콤보를 온전히 넣는 플레이가 성립해야 한다. 감쇄가 적용된 타격은 `armor_hit` 스파크와 효과음으로 구분한다.
- 보스는 일반 경직을 받지 않지만(슈퍼아머) 히트스톱 0.05초는 적용된다. 넉백은 일반의 20%.

**1페이즈 "통곡의 골격" (HP 100% ~ 50%)**
- **뼈 채찍 횡치기(1~2타 콤보)**: 선딜 0.80 → 오른팔 뼈 채찍으로 전방 넓은 범위를 **좌에서 우로** 크게 휘두름(active 0.25, 판정 560x180, 데미지 16) → 이어서 0.5초 선딜 후 우에서 좌로 한 번 더(데미지 16, 콤보는 2타까지) → 후딜 1.0.
- **삼나무 뼈 가시 대지 찍기**: 선딜 0.90 → 왼손 참수도를 바닥에 내리찍음(active 0.15, 판정 240x160, 직격 **22**) → **0.3초 뒤** 바닥에서 앞쪽으로 **일렬로 3개의 뼈 가시**(보스 앞 260/460/660px 위치, 각 0.12초 간격)가 솟구침(가시 판정 90x200, 각 **14**) → 후딜 1.2.
- **유골 사수 소환**: 선딜 1.0(가슴의 해골들이 비명) → 삼나무 숲의 `cedar_archer` 2마리가 **양 끝 발판에 떨어져** 지원 사격(동시에 최대 2마리, 사수가 모두 죽으면 쿨다운 20초 후 재소환 가능, 소환 사수는 5% 토사물 드랍 없음) → 후딜 0.8.
- 패턴 선택: 거리와 쿨다운 기반으로 순환. 거리 700 이내 → 횡치기/대지 찍기를 번갈아, 소환은 보스 HP가 75%와 55%를 지날 때 우선 사용.

**2페이즈 "폭주하는 광골" (HP 600 이하)**
- 진입 연출 `phase_transition`(2.0초, 이 동안 무적, 시간 정지 아님): 가슴의 '멜람무의 핵'이 검붉게 폭주하며 보스가 스스로의 흉부를 찢어발김. 이후 전신에 붉은 핏줄 같은 기운이 감돈다(2페이즈 전용 스프라이트).
- **공격 속도 +20%**(모든 선딜·active·후딜 시간 ×0.833), **Turn Delay 0.50초**.
- 기존 1페이즈 패턴이 계속 쓰인다. 추가 패턴:
  - **원혼의 붉은 화염 포효(전방 광범위)**: 선딜 0.80 → 가슴 핵에서 **전방 60도 부채꼴, 사거리 700px**로 **1.5초간** 검붉은 원혼 화염 방사. 다단히트 **총 28**(0.107초 간격 14틱 × 2, 경직·무적 없는 틱 경로, 구르기 무적 유효) → 후딜 1.3. 중간에 보스가 방향을 바꾸지 않는다.
  - **기습 후방 뼈 가시 발사(뒤잡기 견제)**: 플레이어가 등 뒤에서 **2.5초 안에 2번 이상 타격**하면, 다음 Turn Delay 도중 등 뒤의 척추 가시들을 후방으로 흩뿌린다(선딜 0.30, active 0.15, 뒤쪽 판정 380x120, 데미지 **12**). 이 패턴 쿨다운 6초.

**처치 연출 "동귀어진의 발악"**
- HP가 0이 되면 보스가 무너지기 시작한다(`collapse` 1.0초, 이 동안 무적). 이어서 **마지막 발악**: 왼손의 거대한 참수도를 **니므롯을 향해 기습적으로 휘두름**(예고 `final_swing_windup` 0.8초(진홍색 점멸, 위협 표식 점멸) → active 0.2초, 판정 640x220 전방, 데미지 **30**(가정)). K 구르기 무적으로 피할 수 있어야 한다. 이 공격은 처치 후에도 발동하며, 플레이어가 맞지 않으면 보스는 이 일격을 마치고 쓰러져 사라진다(`death` 연출 1.5초, 페이드).
- **첫 시도 한정 발화**(`GameState.first_time("kala_death_lines")`): 쓰러지는 동안 보스 머리 위 말풍선으로 아래 5줄을 순서대로 자동 표시한다(시간 정지·줌 없이 `Dialogue`의 `freeze: false` 옵션, 한 줄 표시 후 1.6초 유지).
  1. "억울하구나, 억울해. 애초에 이곳을 개척했던 것이 잘못이었지."
  2. "나에게 운명을 바꿀 힘이 있었다면, 그랬다면!!"
  3. "헛되이 죽은 병사들 모두가 가족들과 행복한 삶을 살았을 것이다."
  4. "나는 비록 잠깐 사라지나, 기필코 다시 나타날 것이다."
  5. "본향의 형제들이 울부짖던 소리가 가슴을 찢는구나."
- 처치 후: 도착 문 잠금 해제(되돌아가기 가능). 보상(멜람무 등)은 이번에는 구현하지 않는다(폭주 시스템 미구현).

**보스 이미지 (이미지 생성)**
- 프레임 1536x1280, 앵커 `[768,1200]`, `visual_scale 0.50`, 오른쪽 기준, 투명 PNG. 클립과 길이: `idle` 8프레임 1.6초(루프), `walk` 8 / 1.4(루프), `whip_windup` 5 / 0.8, `whip_swing` 4 / 0.25, `whip_swing_back` 4 / 0.25, `whip_recovery` 5 / 1.0, `slam_windup` 5 / 0.9, `slam` 3 / 0.15, `slam_recovery` 5 / 1.2, `summon` 6 / 1.8, `turn` 6 / 0.7(2페이즈는 0.5로 재생), `hurt_flash`는 만들지 않고 모듈레이트 플래시로 대체, `phase_transition` 8 / 2.0, `roar_windup` 5 / 0.8, `roar_loop` 4 / 0.4(루프), `roar_recovery` 5 / 1.3, `spines_back` 4 / 0.45, `collapse` 6 / 1.0, `final_swing_windup` 5 / 0.8, `final_swing` 4 / 0.2, `death` 8 / 1.5.
- 2페이즈 변형 시트(`*_p2`): `idle, walk, turn, whip_windup, whip_swing, whip_swing_back, whip_recovery, slam_windup, slam, slam_recovery`(전신에 붉은 핏줄 같은 기운, 가슴이 찢어져 붉게 드러난 핵, 눈이 붉게 빛남). 클립 요청이 없으면 별칭으로 1페이즈 클립을 쓰되 MISSING이 표시되지 않아야 한다.
- 별도 FX 시트(투명): `assets/sprites/fx/bone_spike.png`(128x256, 4프레임), `soul_flame_cone.png`(768x384, 6프레임 루프, 검붉은 원혼 화염), `bone_arrow.png`(96x24), `bone_spike_ground.png`(128x128, 3프레임), `blue_flame_explosion.png`(256x256, 6프레임, 푸른 불꽃), `armor_hit_spark.png`(192x192, 5프레임).
- 보스방에서 소환되는 사수는 `cedar_archer` 시트를 재사용한다.

## 5. 이미지 에셋 목록 (전부 이미지 생성, 규격은 투명 PNG·오른쪽 기준)

### 5-1. 괴수 시트 (한 줄 시트, 매니페스트 필수)
- **벽면 강하 추가 클립**: `wall_diver/idle.png`(4프레임), `windup.png`(4프레임)(§1-2). 필요 시 `gas_sac/death.png`(6프레임, 0.7초), `corpse_bomber/death.png`(4프레임, 0.4초)도 추가 생성(§1-2 별칭이 어색한 경우).
- **삼나무 숲 괴수**: 프레임 768x768, 앵커 `[384,720]`, `visual_scale 0.45` (colossus 1024x1024, 앵커 `[512,980]`, `0.50`; wisp 768x768, 앵커 중앙 `[384,384]`). 클립(이름 프레임수 길이초): 
  - `cedar_sentinel`: idle 6 1.0 · walk 8 0.9 · windup 4 0.4 · thrust 3 0.2 · slash 3 0.2 · attack_recovery 4 0.7 · shield_up 3 0.2 · shield_hold 2 0.2(루프) · shield_break_stun 4 1.0 · turn 4 0.3 · hurt 2 0.2 · death 6 0.8
  - `cedar_colossus`: idle 6 1.4 · walk 8 1.4 · slam_windup 6 1.0 · slam 3 0.2 · slam_recovery 5 1.2 · sweep_windup 5 0.7 · sweep 3 0.2 · sweep_recovery 5 0.9 · rear_poke 4 0.4 · turn 6 0.6 · hurt 2 0.2 · death 8 1.2
  - `cedar_archer`: idle 6 1.0 · walk 8 0.9 · windup 4 0.5 · shoot 3 0.2 · recovery 4 0.4 · hop_back 5 0.4 · turn 4 0.2 · hurt 2 0.2 · death 6 0.7
  - `cedar_wisp`: float 6 1.0(루프) · contact 3 0.2 · fuse 5 0.5 · explode 6 0.3 · turn 4 0.15 · hurt 2 0.2 (`idle`, `walk`은 `float` 별칭, `death`는 `explode` 별칭)
  - `cedar_demon`: perch 4 1.0(루프) · tell 3 0.2 · fall 3 0.25(루프) · land_stab 4 0.3 · claw_windup 4 0.25 · claws 6 0.6 · recovery 4 0.8 · idle 6 1.0 · walk 8 0.8 · turn 4 0.25 · hurt 2 0.2 · death 6 0.7
  - 턴 클립 규칙: 오른쪽 기준, 프레임 1 원래 방향 → 2 몸 비틀기 → 3 정면에 가까운 대칭형 → 4 새 방향, 엔진이 프레임 3 시작에서 `flip_h` 전환. 총 길이 = Turn Delay.
  - 외형 프롬프트 핵심어: sentinel `weathered cedar skeleton soldier entangled with roots and vines, rusted dagger, wooden shield`; colossus `4 meter giant fused skeleton of many skeletons, huge cedar-root club`; archer `skeleton with heavy bone crossbow, dark crimson glow in ribcage`; wisp `legless floating spine and skull ghost with blue flammable flame`; demon `skeleton fiend with four arms hanging from cedar branches`.
- **보스**: §4-5의 클립과 `_p2` 변형 시트.
- **엔키두아**: 디자인 시트, `idle`, `idle_front`(§2-3).

### 5-2. 니므롯의 집 내부
- `assets/backgrounds/nimrod_home/home_interior_bg.png` 1800x720(실용적이고 아늑한 우주 문명의 가옥 내부, 따뜻한 조명, 고대풍 아님, 바닥선 y≈620).
- 소품(투명): `home_bed.png` 420x200, `home_table.png` 360x180, `home_shelf.png` 300x420, `home_lamp.png` 120x260, `home_rug.png` 420x60. 타일: `assets/tiles/home/home_floor_tile.png` 512x180(이음새 없음).
- 문: `assets/props/doors/nimrod_home_inner_door.png` 256x384, 6프레임(첫 프레임 닫힘, 마지막 열림).

### 5-3. 별장 뒤뜰
- `assets/backgrounds/villa_backyard/backyard_bg.png` 1500x720(별장 뒷면 외관과 정원, 저녁 빛), 문: `assets/props/doors/villa_back_door_exterior.png` 320x420, 6프레임(후문 바깥쪽), `cedar_forest_portal.png` 320x460, 6프레임. 가로등·울타리·관목·지면 타일은 기존(`HomeRoad`/별장) 에셋을 재활용한다.

### 5-4. 삼나무 숲 (층 2개 + 보스방)
- 시차 타일(가로·세로 이음새 없음, 불투명): `assets/backgrounds/cedar/far_tile_2d.png` 1024x1024(안개 낀 삼나무 숲 먼 실루엣, 비율 0.10), `mid_trunks_tile_2d.png` 1024x1024(굵은 줄기, 비율 0.35). 보스방 배경 `assets/backgrounds/cedar/boss_bg.png` 1600x960(수만 년간 죽은 이들의 해골과 거대한 삼나무 뿌리가 얽힌 좁은 공동, 검붉은 빛).
- 지형 타일(가로 이음새 없음): `assets/tiles/cedar/root_floor_tile.png` 512x180(뿌리와 흙), `root_platform.png` 256x48, `branch_platform.png` 320x48, `wall_trunk_tile.png` 160x512(세로 이음새 없음, 벽용 줄기), `canopy_top_tile.png` 512x160, `bone_floor_tile.png` 512x180(보스방 바닥), `boss_end_platform.png` 280x56.
- 소품(투명): `cedar_stump.png` 240x200, `skeleton_remains.png` 280x120, `hanging_vines.png` 200x360, `bone_pile.png` 220x130, `cedar_branch_perch.png` 360x120(마귀가 매달리는 가지).
- 문/포탈: `assets/props/doors/cedar_portal.png` 256x384, 6프레임(숲 층간 포탈, 첫 프레임 닫힘).
- 이미 있는 타일·문 시트, 괴수 FX는 그대로 재활용한다.

## 6. 오디오 (`tools/make_sfx.py`, `tools/make_bgm.py` 확장, 합성 WAV 44100Hz 모노)
- 효과음: 4-4 목록, 보스용 `boss_whip_swing`, `boss_slam`, `boss_spike_rise`, `boss_roar_loop`(루프), `boss_phase_roar`, `boss_core_throb`(루프), `boss_collapse`, `boss_final_swing`, `armor_hit`, 대화용 `speech_blip`(아주 짧고 부드러운 틱, 20ms), `buff_chime`(샴하트 버프 적용 시).
- BGM(40~60초 이음새 없는 루프, 시작·끝 위상 일치): `nimrod_home`(조용하고 따뜻한 저음 패드), `cedar_forest`(습한 숲의 스산한 드론과 먼 목관), `cedar_boss`(무겁고 느린 타악과 낮은 합성 금관, 2페이즈 강도 변화 없음 단일 곡).

## 7. 데이터·문서·테스트
- `data/levels.json`: `NimrodHome`, `VillaBackyard`, `CedarForest_F1`, `CedarForest_F2`, `CedarBossRoom` 추가, `HomeRoad`의 집 정문 해제, `VillaF1` 후문 연결, 통로 층 스폰 재배치. `data/enemies.json`: `size_multiplier`와 삼나무 숲 괴수 5종·보스 추가. `data/npcs.json`: `enkidua` 추가, `shamhat` 상호작용. 신규 `data/enemy_markers.json`, `data/surface_accent.json`, `data/cedar_forest_layout.json`.
- `README_KO.txt` 갱신, `docs/STAGE6_REPORT_KO.md`, `docs/STAGE6_FILES_KO.txt`(레벨 연결도, 가정값 목록, 미생성 에셋 목록 포함).
- 테스트: 기존 `tests/*.gd` 갱신 + `tests/stage6_clip_coverage.gd`, `tests/stage6_threat_marker.gd`, `tests/stage6_surface_accent.gd`, `tests/stage6_shamhat_buff.gd`, `tests/stage6_cedar_enemies.gd`(방패 확률과 충격파 파괴, 후방 견제 40%, 석궁 후퇴, 부유령 자폭, 마귀 낙하·4연속), `tests/stage6_boss.gd`(갑피 ×0.7, 2페이즈 전환 600, 화염 총 28, 후방 가시, 동귀어진), `tests/stage6_levels.gd`(`NimrodHome`, `VillaBackyard` 400px 거리, 삼나무 숲 연결).
- 스크린샷 `docs/screenshots/stage6_*.png`: 크기 비교(플레이어 + 괴수 9종), 괴수 위협 표식, 구조물 표시(바닥과 일방향 발판), 집 외관 수정 전후, `NimrodHome`, `VillaBackyard`, 삼나무 숲 1·2층, 보스방, 샴하트 대화 연출.

## 8. 완료 기준 (수동 테스트)
- [ ] 5단계 괴수 9종이 이전보다 3배 크게 보이고(플레이어 109px 대비), 판정과 공격 범위가 시각과 맞는다. HP·데미지·Turn Delay·속도·시간은 그대로다. `check_enemy_visual_bounds.py` 경고가 없거나 보고돼 있다.
- [ ] 도심 방향 통로 8개 층에서 모든 괴수가 끼이거나 천장에 박히지 않고(`check_enemy_clearance.py` 통과), 모든 층이 여전히 클리어 가능하다(`check_level_reachability.py` 통과). 7층 터널에는 지상 괴수가 없다.
- [ ] 벽면 강하 괴수를 포함한 모든 괴수가 어떤 상태에서도 MISS/MISSING_TEXTURE 표시가 나오지 않는다(`stage6_clip_coverage.gd` 통과). 벽면 강하의 `idle`, `windup` 이미지가 추가됐다.
- [ ] 모든 괴수 발밑에 적갈색 접지 그림자, 머리 위에 진홍색 ▼ 표식이 보이고, 선딜 중 밝은 적색으로 바뀐다. 이름표나 외곽선은 없다. 죽으면 사라지고 F2로 껐다 켤 수 있다.
- [ ] 서 있을 수 있는 면에 윗면 하이라이트·밑면 그림자가 붙어 구별되고, 일방향 발판은 청백색 점선으로 구분된다. 장식 배경에는 붙지 않는다. F3으로 켜고 끈다.
- [ ] 니므롯의 집 외형이 더 이상 공중에 뜨지 않는다. 지면 바로 위 띠의 노이즈 블록이 없거나 보고돼 있다. `docs/STAGE6_GROUND_CONTACT.txt`에 접지 점검 결과가 있다.
- [ ] `HomeRoad`의 집 정문에서 E로 `NimrodHome`에 들어가고 나올 수 있다. 엔키두아가 있고(여성, 투박하고 야성적인 외형, 미화 없음, 대화 없음), 3방향으로 바라본다.
- [ ] 샴하트에게 E를 누르면 시간이 정지되고 카메라가 줌인되며 머리 위 말풍선에 "당신이 자꾸 신경쓰여요."가 타자 효과로 나온 뒤 자동으로 닫히고 원래대로 돌아온다. 공격력·공격속도·최대 HP가 +50%(공격속도 상한 ×2.0)가 되고 HP 바 최대치가 270이 된다. 같은 런에서 한 번만 받는다.
- [ ] `VillaF1` 후문에서 `VillaBackyard`로 나가면 괴수가 없고, 후문에서 숲 포탈까지 약 400px이다. 숲 포탈로 `CedarForest_F1`에 간다.
- [ ] 삼나무 숲 1·2층이 3열×4행 미로형 수직 맵이고, 입구에서 출구 포탈까지 경로가 있으며 점프 한계 안이다. 1층에는 파수꾼·대형 무두 해골, 2층에는 석궁 사수·부유령·통곡의 마귀만 나온다. 모든 해골 괴수가 5% 토사물을 드랍한다. 층간은 포탈로 이동한다.
- [ ] 2층 맨 위 포탈로 보스방에 들어가 칼라-우쉬움갈과 싸운다. 정면 상체 타격 ×0.7, 등 뒤 타격 100%, Turn Delay 0.70초(2페이즈 0.50). 1페이즈(횡치기, 대지 찍기+가시 3개, 사수 2마리 소환)와 2페이즈(HP 600 이하 연출, 공격 +20%, 화염 포효 총 28, 후방 가시)가 동작한다. 처치 시 동귀어진 발악(피할 수 있음)과 첫 시도 한정 발화 5줄이 나온다.
- [ ] 코드로 괴수·NPC·배경·지형·문·FX 이미지를 그리는 부분이 없다(위협 표식·구조물 표시·말풍선 같은 UI 보조 효과 제외, 디버그 히트박스 제외). `validate_assets.py`와 모든 테스트가 통과한다. 미생성 에셋은 `assets/image_prompts/`와 보고서에 목록이 있다.

## 9. 보고 형식
작업이 끝나면 한국어로 정리한다: 변경·추가·이동한 파일 목록, 임의로 정한 값(삼나무 괴수의 몸 크기·판정·속도, 석궁 사수의 뼈 가시 데미지 10, 동귀어진 데미지 30, 샴하트 버프의 런 단위 영구 적용, 미로 막다른 길 픽업, 각 거리·시간 값), 5단계 괴수 크기 확대 시 조정한 레벨 목록, 클립 누락 감사 결과(어떤 클립을 이미지로 추가했고 어떤 것을 별칭으로 처리했는지), 집 외형 위치 변경 값, 이미지 생성 여부와 미생성 목록, 테스트 결과와 스크린샷 경로, 실행하지 못한 항목과 이유.