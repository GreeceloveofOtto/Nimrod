# NIMROD 이미지 에셋 제작·검증

괴수·배경·지형·장식·타격 이펙트의 원본은 이미지 생성 도구로 제작한다. 아래 Python 도구는 이미 생성된 이미지의 크로마키, 분리, 크기 조절, 앵커 정렬, 시트 패킹만 수행한다. 그림이나 괴수 포즈를 생성하지 않는다. 필요한 Python 패키지는 Pillow와 numpy다.

각 에셋의 생성 프롬프트, 최종 경로, 크기, 배경 처리 방법은 `assets/image_prompts/*.md`에 있다. 기존 `assets/sprites/idle.png`, `attack_4.png`를 이미지 생성 도구에 스타일 참조로 전달한다. 투명 에셋은 원본 배경을 완전 단색 `#FF00FF`로 요청한다. 하늘과 바닥 타일은 불투명이다.

## 괴수 시트 재패킹

저장된 생성 원본과 실제 생성 결과의 행 구간은 `assets/source_art/beast_provenance.json`과 `tools/build_beast_assets.py`에 기록한다. 프레임은 원본의 연결된 그림 픽셀로 분리하므로 가로 방향으로 일부 겹쳐 배치된 그림도 보존한다. 모든 클립은 첫 idle 프레임에서 구한 하나의 공통 배율을 사용하며 각 프레임의 하단 중앙을 `[320,600]`에 정렬한다. 가장 큰 포즈도 너비 620px·높이 600px 안에 들어오도록 공통 배율을 제한한다.

```bash
python tools/build_beast_assets.py
python tools/build_beast_assets.py --beast melee_beast
python tools/build_beast_assets.py --beast ranged_beast
```

근접 괴수 생성 원본에는 recovery 행이 빠져 있다. 생성된 네 windup 포즈의 순서를 반대로 패킹해 낮춘 몸을 일으키는 recovery를 만들었다. 이 과정을 원본·재빌드 스크립트·출처 기록에 남긴다.

원거리 괴수는 세운 목 원본과 같은 괴수를 참조해 생성한 접은 목 원본(flame_loop/death)을 사용한다. 후자는 원본 해상도가 더 크므로 몸통·다리 크기를 기준으로 원본 전체에 0.56 배율 보정을 적용한 뒤 모든 클립의 공통 배율 3.2631578947을 적용한다. 프레임마다 배율을 바꾸거나 가로·세로 비율을 다르게 늘리지 않는다. 세운 목 idle 높이는 약 552px이며 게임의 visual_scale 0.36에서 약 199px다. turn의 두 번째 생성 포즈가 왼쪽 기준으로 나와 해당 포즈만 좌우 반전해 오른쪽 기준으로 맞췄다. 엔진의 실제 방향 전환은 세 번째 프레임에서 수행한다.

새 생성 결과가 규칙적인 8열 8행인 경우 다음처럼 직접 패킹할 수 있다. `--row`와 `--column`은 0부터 시작한다. 근접 순서는 idle/walk/windup/attack/recovery/turn/hurt/death, 프레임 수는 6/8/4/3/4/4/2/6이다. 원거리 순서는 idle/walk/windup/flame_loop/recovery/turn/hurt/death, 프레임 수는 6/8/4/4/4/4/2/6이다.

```bash
python tools/pack_sprites.py sheet raw.png idle.png --grid-cols 8 --grid-rows 8 --row 0 --frames 6 --fit 460,300
```

원거리의 `--fit`은 `380,600`이다. 원본의 첫 idle 프레임을 계속 배율 기준으로 쓰면 행마다 같은 배율이 유지된다. 원본이 불규칙한 행 간격을 가진 경우 `--crop x,y,w,h --components --frames N --scale SCALE`을 사용하고 첫 idle에서 출력된 `shared_scale`을 모든 클립에 전달한다. `--boxes '[[x,y,w,h],...]'`로 프레임 구간을 직접 지정할 수도 있다. 몸 비율을 바꾸기 위해 가로·세로를 서로 다르게 늘리면 안 된다.

## 화염과 스파크

```bash
python tools/pack_sprites.py sheet flame_raw.png assets/sprites/enemies/ranged_beast/flame.webp --grid-cols 6 --frames 6 --frame-width 512 --frame-height 256 --anchor 16,128 --alignment left-center --fit 480,200
python tools/pack_sprites.py sheet spark_raw.png assets/sprites/fx/hit_spark.webp --grid-cols 5 --frames 5 --frame-width 256 --frame-height 256 --anchor 128,128 --alignment center --fit 220,220
```

화염은 왼쪽 방출점에서 오른쪽으로 뻗으며 입 위치에 맞춘다. 스파크는 중심에 정렬한다. 공통 배율 때문에 큰 포즈가 프레임을 벗어나면 도구가 오류를 내므로 원본 구간이나 모든 프레임의 공통 배율을 점검한다.

현재 생성 원본 전체는 `python tools/build_map_assets.py`로 재패킹한다. 화염 픽셀만 `--scale-xy 1.65,1.05`로 판정에 맞는 가로 이펙트 비율을 보정한다. 괴수 몸체에는 비균등 배율을 사용하지 않는다. 실제 알파 영역에서 계산한 `flame_art_size`를 enemies.json에 기록하고, 게임은 이 영역을 220x60 판정에 맞춰 표시한다. 스파크의 작은 첫 포즈와 큰 중간 포즈 차이는 유지한다.

## 배경·지형·장식

1단계에서 삭제한 전경 생성 원본 `assets/source_art/foreground_source.png`와 기존 프롬프트는 복원하지 않았다. 2단계 명세에 따라 새 원본 `assets/source_art/stage2_environment/rear_layers.png`에서 폭 5400에 맞는 전경을 새로 패킹했다. 현재 RearGate는 4겹 시차(0.05/0.20/0.45/0.80)를 사용한다. `build_map_assets.py`는 2단계 원본이 있으면 새 배경을 보존하며 기존 지형·소품·이펙트만 재패킹한다.

```bash
python tools/pack_sprites.py image generated.png assets/props/rear_gate_door.webp --crop 0,0,320,420 --size 320,420
python tools/pack_sprites.py image generated_sky.png assets/backgrounds/rear_gate/sky.webp --size 1536,720 --opaque
python tools/pack_sprites.py image generated_ground.png assets/tiles/rear_gate/ground_tile.png --size 512,220 --opaque --tile-x
```

`--crop`은 생성 아틀라스의 해당 이미지 구역만 분리한다. `--trim`은 단독 장식 이미지의 여백을 줄일 때 쓴다. 배경의 파랄랙스 배치나 지형 상단 정렬을 유지해야 할 때에는 여백을 임의로 제거하지 않는다. `--opaque`는 하늘·바닥처럼 불투명한 원본에만 사용한다. `--tile-x`는 원본의 양쪽 32px 경계 띠를 섞어 첫 열과 마지막 열의 RGBA를 같게 만든다. 석재나 노이즈를 새로 그리지 않는다. 다른 띠 너비는 `--tile-x 16`처럼 지정한다.

## 검사

```bash
python tools/validate_assets.py
```

기본 검사는 `assets/art_manifest.json`이 요구하는 105개 PNG 전체를 확인하며 하나라도 없으면 실패한다. PNG 형식, RGBA, 정확한 크기·프레임 수, 프레임별 비어 있지 않은 그림, 연속 복제 프레임 여부, 괴수·NPC 앵커, NPC 모든 프레임 높이 비율 ±3%, 비행 괴수 중앙 앵커·날개폭, 알파, manifest의 fps/길이, 레벨별 파랄랙스 이동을 덮는 너비, 바닥 타일 양쪽 경계의 일치를 확인한다. `--allow-missing`은 제작 도중 있는 파일만 검사하며 누락을 SKIPPED로 보고한다. PARTIAL PASS는 최종 아트 완료를 뜻하지 않는다.

이미지 생성이 불가능한 환경에서는 `assets/image_prompts/`의 프롬프트를 사용자에게 전달하고 런타임의 회색 `MISSING` 폴백을 유지한다. 코드 도형이나 절차적 생성으로 최종 아트를 대체하지 않는다.

## 2단계 NPC·비행 괴수·환경 재패킹

```bash
python tools/build_stage2_character_assets.py
python tools/build_stage2_environment_assets.py
python tools/validate_assets.py
```

캐릭터 도구는 생성 포즈 6개 원본에서 NPC 12개 시트와 비행 괴수 7개 시트를 만든다. NPC 기준 높이는 플레이어 idle 첫 프레임의 alpha>12 bbox 359px다. 모든 NPC 프레임은 data/npcs.json의 높이 비율 ±3%, 발 앵커 [320,600]을 유지한다. 숨쉬기만 허용된 정지 이미지 변형을 tools/make_breathing_sheet.py로 파생한다. 요리·청소·문 열기 동작은 생성된 여러 포즈를 패킹한다. 비행 괴수는 768×640, 중앙 앵커 [384,320], 날개폭 최대 700px다.

환경 도구는 8개 생성 원본에서 정적 이미지 26개와 문 시트 6개를 만든다. 하늘 1536, 먼 도시 2112, 성벽 3136, 전경 4608px로 5400px 맵의 카메라 이동을 덮는다. 실내·테라스는 바닥선 y620에 맞춰 생성 픽셀을 정렬한다. 문 닫힘은 열림 시트를 역재생한다. E 프롬프트와 회복 드랍 이미지도 포함한다. tools/stitch_background.py는 여러 생성 이미지를 이어 붙일 때 사용하며 새 풍경을 코드로 그리지 않는다.

생성 기록은 assets/source_art/stage2_characters/provenance.json·generation_prompts.json 및 assets/source_art/stage2_environment/generation.json·packing.json에 있다. assets/stage2_character_manifest.json과 assets/stage2_environment_manifest.json의 항목은 최종 assets/art_manifest.json에 통합했다.

## 3단계 NPC 재디자인·정문 앞

```bash
python tools/build_stage3_assets.py
python tools/validate_assets.py
```

왕족·호위 5명은 NPC 전용 근미래 복식 프롬프트를 사용한다. 기존 다크 판타지 공통 문구는 배경·문·FX에만 사용한다. 디자인 시트(정면/오른쪽 측면/얼굴) → 디자인 참조 오른쪽 정지 이미지 → pack_sprites.py 크로마키/발 앵커 → add_rim_light.py 내부 5px/40% 빛 방향 밴드 → make_breathing_sheet.py 숨쉬기 6프레임으로 만든다. 인안나 디자인 후보 4개와 선택 3번은 assets/reference/에 보존한다. 생성 원본·전체 프롬프트·출처는 assets/source_art/stage3/에 있다. 이전 NPC 시트와 매니페스트는 assets/sprites/npcs/_legacy/에 보존한다.

토인 작업 포즈는 새로 생성하지 않는다. 기존 픽셀·알파·포즈를 재사용하고 허용된 림라이트 RGB 처리만 더한다. 재빌드는 반드시 _legacy 원본을 읽어 림라이트가 누적되지 않게 한다. 표시 배율은 데이터의 visual_scale_multiplier=1.30이다. source_height_ratio는 원본 픽셀 키, height_ratio는 표시 크기 비율이며 검증은 bbox×1.30을 한 번만 곱한다.

3단계는 기존 배경 PNG를 재생성하거나 수정하지 않는다. 새 CastleFront 시차 4겹·외관 2개, 문 4개, 타일 2개, 소품·성벽 5개, FX 2개만 생성 원본에서 패킹한다. 두 기존 성 타일의 작은 마젠타 윗여백도 기존 원본의 크롭만 보정한다. 불투명 타일의 키 색상 잔여와 양쪽 경계를 검사한다. Stage 2 재빌드 보호는 신규 왕족 시트를 덮어쓰지 않으며, 전체 재빌드 시 Stage 3 도구를 마지막에 실행한다.

check_npc_contrast는 플레이어 크기 기준 NPC 상자와 bg_dim 적용 배경 크롭의 평균 휘도 차이를 비교한다. 30 미만은 경고이며 실패가 아니다. FX·근접 밝기·소품은 제외한 보수적인 검사다. 재사용 작업자 4곳의 남은 대비 경고와 권고는 docs/STAGE3_REPORT_KO.md에 기록했다.

## 4단계 재생성 순서

이전 명령은 역사적 재생성용입니다. 최종4단계 데이터·플레이어를 유지하려면 아래 순서를 마지막에 실행합니다.

```bash
python tools/build_stage4_levels.py
python tools/build_stage4_assets.py
python tools/build_stage4_player.py
# 스테이징 검증 성공 후에만 교체:
python tools/build_stage4_player.py --apply
python tools/write_stage4_prompts.py
python tools/check_player_scale.py
python tools/check_player_motion.py
python tools/check_level_reachability.py
python tools/validate_assets.py
```

모든 풍경·포즈 원본은 이미지 생성 PNG이며 도구는 크롭·크로마키·균등 리사이즈·앵커·시트 합성만 합니다. 새18종을 모두 검증한 후 적용하며 기존 파일은 _legacy_player에 한 번만 보관합니다. 중간 source_art/stage4/player_staged는 재생성 가능하여 배포에서 제외합니다. 실제 요청은 generation_prompts.json, 포즈 선택·축척은 player_packing.json, 최종 경로별 요청은 image_prompts/stage4_*.md에 있습니다.

5명 정면은 이전 대화의 디자인 첫 열을 재사용합니다. 새 샤마쉬·아야는 같은 디자인에서 정면/측면을 가져옵니다. 숨쉬기·내부 림라이트만 허용된 이미지 파생입니다. 새 플레이어 기준363px, 재사용 토인만 원래 제작 기준359px를 데이터에 보존하며 배율1.30 유지. Foreground는 모든 레벨·재빌드 목록에서 제거했습니다. 지하 채움은 양방향 이음새를, 반복 배경은 타일 이음새와 repeat_size를 검사합니다. 대비 경고7곳은 STAGE4_REPORT_KO.md를 참고하세요.

## 5단계 재합성

4단계 결과에 이어 아래 순서를 사용합니다. 저장한 원본을 재패킹하며 새로운
아트를 코드로 그리지 않습니다. 원본 생성 요청과 SHA256은
assets/source_art/stage5/*generation_prompts.json 및 provenance.json에 있습니다.

```bash
python tools/build_stage5_data.py
python tools/build_stage5_levels.py
python tools/build_stage5_assets.py all
python tools/build_passage_backgrounds.py
python tools/make_sfx.py --stage5-only
python tools/make_bgm.py --stage5-only
python tools/check_player_motion.py roll
python tools/validate_assets.py
python tools/check_player_scale.py
python tools/check_level_reachability.py
python tools/check_stage5_audio.py
godot --headless --editor --path . --quit
python tools/run_tests.py --godot godot --report docs/STAGE5_TEST_RESULTS.json
```

구르기 후보가 크기 검사를 통과한 뒤에만 roll.png를 교체하며 이전 적용본은
_legacy_player/roll_prev.png에 한 번만 보존합니다. 다른17개 PNG는 건드리지 않습니다.
괴수9종은 클립별 PNG와 manifest를 생성하고 지상/부유 앵커·지정 프레임 크기를
유지합니다. 월드 아틀라스는 가로세로 비율을 보존한 크롭 후 크기 조절하고,
통로 배경은 생성 타일의 색보정과 생성 세트피스 합성으로 구성합니다.
사슬 찍기·방어 후딜·돌진 기절의 추가 생성 원본도 재합성에 사용합니다.
원본 아틀라스와 최종 개별 에셋 프롬프트는 최종 PNG와 함께 배포합니다.

이전 단계 전용 재빌드 명령은 해당 단계의 데이터/아트를 복원하는 용도입니다.
5단계를 유지하려면 위5단계 순서를 마지막에 적용해야 합니다.
