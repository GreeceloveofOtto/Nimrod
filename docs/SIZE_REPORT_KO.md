# NIMROD 8단계 용량 보고

런타임 assets: **263.54 → 60.32MiB** (77.1% 절감). 전체75MiB와 모든 폴더 예산을 충족합니다. `.godot`의 임포트 캐시는 측정에서 제외합니다.

| 폴더 | 변환 전 MiB | 변환 후 MiB | 예산 MiB | 결과 |
|---|---:|---:|---:|---|
| sprites | 200.42 | 40.87 | 45 | 통과 |
| backgrounds | 35.09 | 6.98 | 14 | 통과 |
| props | 20.94 | 7.83 | 8 | 통과 |
| tiles | 4.31 | 1.93 | 3 | 통과 |
| audio | 1.88 | 1.88 | 2 | 통과 |
| 기타(UI/폰트/프롬프트/매니페스트/FX) | 0.89 | 0.84 | 3 | 통과 |
| 합계 | 263.54 | 60.32 | 75 | 통과 |

## 적용 순서와 화질

- 변경 전 파일별 상위40개와 저장/게임 픽셀 밀도를 측정했습니다. 모든 변환 전 파일은 archive/stage8_before, stage8_density_before, stage8_encoding_before, stage8_unused에 보존했습니다.
- 288개 시트의 해상도를 표시 배율과 밀도 한도로 조정했습니다. 시트 부분집합은214.66→90.74MiB(그 단계 직후 실측). 각 프레임을 축소 후 확대해 비교하고 SSIM이0.93 미만이면 한도를0.2씩 높여 다시 검사했습니다.
- 나머지 이미지의 WebP 변환 부분집합은52.72→17.51MiB. 기본 품질은 투명RGB86/배경82, alpha95/method6입니다. 평균 색차를 넘은 파일은 무손실로 되돌렸습니다. 품질94 개별 예외44개를 추가해10.44MiB를 더 줄였습니다.
- YUV 색차가 큰 파일은 RGB near-lossless 후 원래 알파 복원, 또는 RGB를10/12단위로 제한하는 변환을 사용하고 무손실 WebP 컨테이너로 저장했습니다. 사용자 허용한 손실 색 저장이며 이미지 생성/도형 그림이 아닙니다. 모든 파일은 같은 RGB/알파/bbox 기준을 통과해야 합니다. 마지막 bounded RGB 단계는272파일에서7.61MiB 추가 절감했습니다.
- UI는 PNG, 정밀 타일은 PNG 또는 완전히 같은 화소의 WebP를 유지합니다. 일부 불투명 반복 타일은 별도 검증된 bounded near-lossless로 저장하며 가장자리 차이는2/255 이하입니다.
- 미사용 타일5개(0.39MiB)를 archive로 이동했습니다. 활성 매니페스트와 코드가 요청하는2페이즈/별칭 클립은 보존했습니다. 연속 동일 프레임 제거 기준을 만족한 것은0개여서 논리/저장 프레임은 모두1,512개입니다. 재생 시간은 바꾸지 않았습니다.
- 저장 규격과 게임 규격을 분리했습니다. 논리 프레임/앵커/충돌 좌표는 보존하고 stored_frame_size, stored_anchor_px, storage_scale, storage_trim을 사용해 표시 배율을 보정합니다. NPC와 플레이어 초기화 순서도 검사했습니다.

프레임별 리샘플 최소SSIM **0.930792**. 압축 전 픽셀과 실제 파일을 전수 재비교한428이미지: 최대RGB 평균오차 **2.999505/255**, 최대알파 평균오차 **0.115440/255**, 알파bbox 차이0, 실패0. 품질 지표는 기록값만 읽지 않고 보존 원본과 실제 인코딩 파일로 재계산했습니다.

네이티브 Godot WebP 디코더는 원본에서 뽑은39개 이미지의 화소 표본으로 별도 검사합니다. 전체 이미지 평균3/255 기준과 작은 패치의 국소 오차는 구분하며 패치는 실제 인코더의 측정 오차와 일치해야 합니다. 원본 없는 슬림ZIP도 이 검사를 실행합니다.

화질 비교: docs/size_compare/stage8_1.jpg(보스),2(플레이어),3(인안나),4(근접),5(마귀),6(숲배경). 각각 변환 전/후의 게임 줌1.0·1.35입니다. 표시 크기는 유지되고, 확대 시 얇은 선과 머리카락은 약간 부드러워집니다. 원본과 최종 결과를 직접 열어 실루엣·발 앵커·검은 배경·축소 가독성을 확인했습니다. 무손실 화소 동일성으로 표현하지 않습니다.

## 파일별 상위40개와 밀도

### 변환 전

| 파일 | MiB | 저장/게임 픽셀 밀도 |
|---|---:|---:|
| `assets/sprites/enemies/kala_ushumgal/walk.webp` | 4.219 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/walk_p2.webp` | 3.891 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/phase_transition.webp` | 3.878 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/idle_p2.webp` | 3.752 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/death.webp` | 3.705 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/collapse.webp` | 3.617 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/turn.webp` | 3.265 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/idle.webp` | 3.224 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/slam_recovery_p2.webp` | 3.215 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/summon.webp` | 3.116 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/turn_p2.webp` | 2.961 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/roar_recovery.webp` | 2.960 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/roar_windup.webp` | 2.868 | 3.333 |
| `assets/props/doors/castle_great_gate.webp` | 2.812 | — |
| `assets/sprites/enemies/kala_ushumgal/slam_windup_p2.webp` | 2.775 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/slam_recovery.webp` | 2.757 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/slam_windup.webp` | 2.724 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/whip_recovery.webp` | 2.695 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/whip_recovery_p2.webp` | 2.656 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/whip_windup.webp` | 2.651 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/whip_windup_p2.webp` | 2.625 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/slam_p2.webp` | 2.607 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/whip_swing_p2.webp` | 2.516 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/whip_swing.webp` | 2.511 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/final_swing.webp` | 2.494 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/whip_swing_back_p2.webp` | 2.450 | 3.333 |
| `assets/backgrounds/cedar/boss_bg.png` | 2.379 | — |
| `assets/sprites/enemies/kala_ushumgal/whip_swing_back.webp` | 2.355 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/roar_loop.webp` | 2.348 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/final_swing_windup.webp` | 2.344 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/spines_back.webp` | 2.286 | 3.333 |
| `assets/sprites/enemies/kala_ushumgal/slam.webp` | 2.275 | 3.333 |
| `assets/backgrounds/villa/villa_f2_dining.png` | 2.219 | — |
| `assets/backgrounds/villa/villa_f1_hall.png` | 2.095 | — |
| `assets/sprites/enemies/cedar_colossus/walk.webp` | 1.991 | 3.333 |
| `assets/backgrounds/villa/villa_f3_chamber.png` | 1.961 | — |
| `assets/sprites/enemies/chain_beastman/death.webp` | 1.848 | 2.222 |
| `assets/backgrounds/castle/castle_f4_boudoir.png` | 1.812 | — |
| `assets/sprites/enemies/cedar_colossus/death.webp` | 1.811 | 3.333 |
| `assets/backgrounds/castle/castle_f1_hall.png` | 1.792 | — |
### 변환 후

| 파일 | MiB | 저장/게임 픽셀 밀도 |
|---|---:|---:|
| `assets/props/doors/castle_great_gate.webp` | 1.277 | — |
| `assets/backgrounds/rear_gate/villa_exterior.webp` | 0.784 | — |
| `assets/backgrounds/castle_front/castle_facade.webp` | 0.745 | — |
| `assets/sprites/enemies/kala_ushumgal/walk.webp` | 0.588 | 1.401 |
| `assets/sprites/enemies/kala_ushumgal/walk_p2.webp` | 0.541 | 1.401 |
| `assets/sprites/enemies/kala_ushumgal/phase_transition.webp` | 0.506 | 1.4 |
| `assets/sprites/enemies/kala_ushumgal/death.webp` | 0.492 | 1.399 |
| `assets/sprites/enemies/kala_ushumgal/idle_p2.webp` | 0.490 | 1.399 |
| `assets/sprites/enemies/kala_ushumgal/collapse.webp` | 0.464 | 1.4 |
| `assets/backgrounds/cedar/mid_trunks_tile_2d.webp` | 0.458 | — |
| `assets/sprites/enemies/kala_ushumgal/slam_recovery_p2.webp` | 0.427 | 1.401 |
| `assets/backgrounds/castle_front/downtown_passage_facade.webp` | 0.425 | — |
| `assets/sprites/enemies/chain_beastman/death.webp` | 0.416 | 1.399 |
| `assets/sprites/enemies/kala_ushumgal/turn.webp` | 0.409 | 1.401 |
| `assets/sprites/enemies/kala_ushumgal/summon.webp` | 0.398 | 1.399 |
| `assets/sprites/enemies/kala_ushumgal/idle.webp` | 0.397 | 1.399 |
| `assets/sprites/enemies/explosive_spitter/walk.webp` | 0.377 | 2.003 |
| `assets/sprites/enemies/kala_ushumgal/roar_recovery.webp` | 0.370 | 1.4 |
| `assets/sprites/enemies/kala_ushumgal/turn_p2.webp` | 0.368 | 1.399 |
| `assets/sprites/enemies/kala_ushumgal/slam_windup_p2.webp` | 0.362 | 1.401 |
| `assets/sprites/enemies/kala_ushumgal/slam_windup.webp` | 0.360 | 1.401 |
| `assets/sprites/enemies/kala_ushumgal/roar_windup.webp` | 0.359 | 1.399 |
| `assets/sprites/enemies/kala_ushumgal/slam_recovery.webp` | 0.354 | 1.399 |
| `assets/backgrounds/homeroad/mid_district_tile.webp` | 0.351 | — |
| `assets/props/doors/castle_front_door_exterior.webp` | 0.346 | — |
| `assets/sprites/enemies/chain_beastman/walk.webp` | 0.342 | 1.401 |
| `assets/sprites/enemies/kala_ushumgal/whip_windup_p2.webp` | 0.337 | 1.401 |
| `assets/sprites/enemies/kala_ushumgal/slam_p2.webp` | 0.337 | 1.4 |
| `assets/sprites/enemies/kala_ushumgal/whip_recovery_p2.webp` | 0.332 | 1.4 |
| `assets/sprites/enemies/kala_ushumgal/whip_recovery.webp` | 0.324 | 1.4 |
| `assets/sprites/enemies/kala_ushumgal/whip_windup.webp` | 0.324 | 1.4 |
| `assets/sprites/enemies/kala_ushumgal/whip_swing_p2.webp` | 0.310 | 1.4 |
| `assets/sprites/enemies/kala_ushumgal/whip_swing.webp` | 0.306 | 1.399 |
| `assets/sprites/enemies/kala_ushumgal/final_swing.webp` | 0.303 | 1.401 |
| `assets/sprites/enemies/explosive_spitter/idle.webp` | 0.302 | 2.003 |
| `assets/sprites/enemies/kala_ushumgal/whip_swing_back_p2.webp` | 0.299 | 1.399 |
| `assets/sprites/enemies/kala_ushumgal/slam.webp` | 0.294 | 1.401 |
| `assets/sprites/enemies/kala_ushumgal/roar_loop.webp` | 0.291 | 1.399 |
| `assets/props/doors/villa_back_door.webp` | 0.290 | — |
| `assets/sprites/enemies/cedar_colossus/death.webp` | 0.288 | 1.6 |

## 패키지와 기능 검증

ZIP은 deflate level9. archive/.godot/*.import/*.uid/테스트 캡처/예전 화면과 접촉시트/GIF를 제외합니다. 최신 화면8장과 용량 비교6JPEG를 포함합니다. `tools/make_slim_zip.py --verify`는 만든 파일을 새 임시 폴더에 풀어 전체 headless·에셋·알파·도달성을 재검사합니다. 기능 결과와75/90MiB 용량 결과를 분리하고 하나라도 실패하면 종료코드1입니다.

최종 ZIP 크기는 아래 완료 기록에 기입하며 SHA256과 독립 검증 결과는 저장소의 STAGE8_PACKAGE_TEST_RESULTS.json을 참조합니다. 용량 목표90MiB 미달 시 상위10개 후보와 예상 절감을 기록하도록 패키징 도구를 보강했습니다. 현재 전체/폴더 예산은 모두 통과하여 추가 화질 손실은 필요 없습니다.

## 최종 용량 완료 기록

| 항목 | 이전 MiB | 8단계 MiB | 목표 |
|---|---:|---:|---|
| assets | 263.54 | 60.32 | ≤75, 통과 |
| 공유용 슬림 ZIP | 264.73 | 61.92 | ≤90, 통과 |

전체와 폴더 예산은 모두 충족했습니다. 원본과 이전 ZIP은 클라우드 작업 공간에 보존합니다. 최종 독립 검증 결과와 정확한 바이트 수/SHA256은 저장소의 STAGE8_PACKAGE_TEST_RESULTS.json에 기록합니다.
