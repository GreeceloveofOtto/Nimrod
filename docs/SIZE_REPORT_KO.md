# 용량 보고 — 14단계

기능 검증과 용량 목표는 별개이다. 신규 아트는 362,546B (0.346 MiB), 새 이동은 134,874B이며 모든 신규 예산을 만족했다. 기존 상위30시트+해골 시트를 RGB≤3/255·알파≤0.5/255·SSIM≥.93·bbox 동일 조건으로 재검사했다. 재인코딩/팔레트 후보는 추가 절감이 없어 원본을 유지했다. 거대 해골4클립의 추가 밀도 조정으로67,664B를 줄였고 새로운 벽 매달리기 인접 프레임 병합도 적용했다. 소스·실패 후보는 archive/에 남겼다.

|단계|assets MiB|실행 ZIP MiB|
|---|---:|---:|
|11 (이전 보고)|미측정|약69.4|
|12 (이전 보고)|약60.54|약60.93|
|13 최신 단검 실제 기준|65.638|66.143|
|14 현재|65.935|67.113 MiB|

|카테고리|13단계 MiB|14단계 MiB|차이 MiB|
|---|---:|---:|---:|
|sprites|48.008|48.078|+0.070|
|backgrounds|6.717|6.717|+0.000|
|props|6.873|6.873|+0.000|
|tiles|1.904|1.904|+0.000|
|audio|1.793|1.793|+0.000|
|world|0.000|0.217|+0.217|
|fonts|0.126|0.129|+0.003|


## 구역별 신규 아트

|구역|KiB|상한 KiB|
|---|---:|---:|
|forest|12.30|358.4|
|mine|7.13|358.4|
|fortress|10.71|358.4|
|village|9.43|358.4|
|landing|9.13|358.4|
|ridge|9.52|358.4|
|crystal|8.40|358.4|
|skywalk|11.64|358.4|
|marsh|14.80|358.4|
|deep|7.03|358.4|

공유 소품: 122.24KiB. 이동4클립: 131.71KiB/409.6KiB. 전체 신규 합계 상한5MiB. 기존 괴수·보스·음원 신규 추가0B.

방 데이터 4,223,461B, DEFLATE 107,116B. 전체 메타데이터를 공백 없는 JSON으로 배포하고 읽기 가능한 빌더/설계 파일을 함께 둔다. 이미지와 오디오가 용량을 지배하므로600방 증가는 주로 압축 가능한 텍스트다.

미사용 탐지0, 해시 중복0. 기존 음원167개는 이미 모노 OGG이며 BGM48kbps/효과음 기존 정책을 유지했다. 자불리스탄 BGM은 cedar_forest/cedar_boss/deathsea_drone/villa_calm만 재사용했다. 실행 ZIP은 archive·tests/artifacts·캡처·pack_source·__pycache__·.import/.godot를 제외하고 독립 가져오기/테스트를 실행한다.

## 목표 및 미적용 사유

65MiB 1차/62MiB 확장 목표는 현재 기준으로 미달이다. 기준 ZIP 자체가 지시서의 약65.5가 아닌66.143MiB였다. 기존 에셋의 대부분은 이전 단계에서 이미 RGB 오차 허용치에 근접한 상태다. 이번에도 허용치를 낮추지 않고 원본을 보관했다. 검증 실패 후보를 무리하게 적용하지 않았다. 다음 표의 고용량 이미지에 대해 원본 재생성/캐릭터별 시트 재설계나 사용 빈도에 따른 선택 배포를 검토하면 효과가 크다. 이는 이번 단계에서 실행하지 않은 후속 후보다.

|파일|KiB|이유/다음 후보|
|---|---:|---|
|assets/props/doors/castle_great_gate.webp|868.9|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/backgrounds/hwanira/plaza.webp|702.7|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/backgrounds/deathsea/stars_tile.webp|529.4|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/gugalanna/walk.webp|518.3|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/gugalanna/idle.webp|489.1|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/gugalanna/death.webp|469.8|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/backgrounds/cedar/mid_trunks_tile_2d.webp|468.6|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/kala_ushumgal/phase_transition.webp|452.4|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/kala_ushumgal/death.webp|441.4|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/kala_ushumgal/collapse.webp|417.4|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/kala_ushumgal/walk.webp|388.3|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/kala_ushumgal/whip_recovery.webp|373.5|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/kala_ushumgal/turn.webp|365.3|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/gugalanna/turn.webp|361.8|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/backgrounds/homeroad/mid_district_tile.webp|359.7|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/gugalanna/rake_windup.webp|356.5|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/kala_ushumgal/idle.webp|355.7|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/kala_ushumgal/summon.webp|351.8|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/gugalanna/rake.webp|346.6|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|
|assets/sprites/enemies/kala_ushumgal/roar_loop.webp|334.8|현재 재인코딩은 RGB≤3 또는 SSIM≥.93/더 작은 크기를 함께 만족하지 못함. 원본 참조 확인 후 추가 재설계·선택적 프레임 병합 검토.|

## Stage14 연속월드재작업

| 항목 | 전MiB | 후MiB |
| --- | --- | --- |
| assets | 65.93 | 71.63 |
| ZIP | 67.11 | 72.33 |
| 자불리스탄전용아트(공통 오브젝트 제외) | 0.10 | 5.79 |
| archive이동 | 0 | 4.62 |
| 중복병합절감 | 0 | 0 |


현재 폴더 상위 10:

| 폴더 | MiB |
| --- | --- |
| assets/sprites/enemies | 30.42 |
| assets/sprites/player | 14.38 |
| assets/world/zabulistan_v2 | 5.79 |
| assets/props/doors | 3.89 |
| assets/sprites/npcs | 2.37 |
| assets/audio/bgm | 1.02 |
| assets/sprites/fx | 0.91 |
| assets/backgrounds/passage | 0.84 |
| assets/audio/sfx | 0.73 |
| assets/backgrounds/castle_front | 0.72 |


상위 20개 파일및후속후보(예상은조건부이며검증된절감이아님):

| 파일 | KiB | 미감량사유 / 다음후보 |
| --- | --- | --- |
| assets/props/doors/castle_great_gate.webp | 868.9 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/backgrounds/hwanira/plaza.webp | 702.7 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/backgrounds/deathsea/stars_tile.webp | 529.4 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/gugalanna/walk.webp | 518.3 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/gugalanna/idle.webp | 489.0 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/gugalanna/death.webp | 469.8 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/backgrounds/cedar/mid_trunks_tile_2d.webp | 468.6 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/kala_ushumgal/phase_transition.webp | 451.6 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/kala_ushumgal/death.webp | 441.3 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/kala_ushumgal/collapse.webp | 417.0 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/world/zabulistan_v2/forest/landmarks.webp | 405.7 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/world/zabulistan_v2/crystal/landmarks.webp | 388.6 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/kala_ushumgal/walk.webp | 388.3 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/kala_ushumgal/whip_recovery.webp | 373.2 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/world/zabulistan_v2/skywalk/landmarks.webp | 372.6 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/kala_ushumgal/turn.webp | 365.3 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/gugalanna/turn.webp | 361.4 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/backgrounds/homeroad/mid_district_tile.webp | 359.7 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/gugalanna/rake_windup.webp | 356.5 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |
| assets/sprites/enemies/kala_ushumgal/idle.webp | 355.7 | 현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부 |


안전 재압축 4,984B,프레임병합0B,동일해시/근사중복0B.보수적재인코딩실패목록은optimization.json의trials에있다.신규 아트 는6MiB내,전체ZIP63MiB는미달이다.기존필수에셋자체가상한을넘으며개발캐시·원본·비교캡처·구룸/아트는모두제외했다.오디오는이미모노 OGG여서추가음질손실없이큰감량은어렵다.

## 15단계 — 착륙 절벽 승인용 검토본 (2026-10-16)

이번 범위는 지시서 §10.3의 착륙지 중간 확인입니다. 전체 맵/프로젝트 목표는 미완료입니다. 음원과 캐릭터 시트는 건드리지 않았습니다.

| 항목 | 이전 | 현재 |
|---|---:|---:|
| ZIP | 72.32657 MiB | 72.23 MiB |
| assets | 71.62954 MiB | 71.50897 MiB |
| 자불리스탄 v2 아트 | 5.78611 MiB | 5.66368 MiB |
| 실행용 data/world | 0.51079 MiB | 0.15776 MiB |

| 이번 아트 | 크기 | 처리 |
|---|---:|---|
| shared/backwall.webp | 5,568 B | 생성 원본 후처리·공용 |
| shared/crust.webp | 6,564 B | 생성 원본 후처리·공용 |
| shared/fill.webp | 44 B | 생성 원본 후처리·공용 |
| shared/foreground.webp | 4,490 B | 생성 원본 후처리·공용 |
| shared/supports.webp | 11,602 B | 생성 원본 후처리·공용 |
| 착륙지 배경 0 | 14,172 B | 표시 크기 유지 축소, GL 렌더 품질 통과 |
| 착륙지 배경 1 | 16,734 B | 새 바다 이미지 |
| 착륙지 배경 2 | 13,146 B | 표시 크기 유지 축소, GL 렌더 품질 통과 |

| 카테고리 | 현재 |
|---|---:|
| sprites/enemies | 30.41749 MiB |
| sprites/player | 14.37648 MiB |
| props | 6.87264 MiB |
| backgrounds | 6.71668 MiB |
| world | 5.78306 MiB |
| sprites/npcs | 2.37154 MiB |
| tiles | 1.90365 MiB |
| audio | 1.79266 MiB |
| sprites/fx | 0.90817 MiB |
| fonts | 0.12887 MiB |
| art_manifest.json | 0.08666 MiB |
| image_prompts | 0.08082 MiB |
| fx | 0.04245 MiB |
| animation_manifest.json | 0.01543 MiB |
| ui | 0.01183 MiB |

아트 전후 차이는 약 0.12MiB 감소입니다. 랜드마크는 316,156→316,034B(리사이즈 없음), 배경0은 29,694→14,172B, 배경2는 78,624→13,146B입니다. 새 바다 16,734B와 공용 재질 28,268B를 포함한 실제 합계입니다. 새 바다를 구 그림의 품질 손실 압축으로 계산하지 않았습니다.

변환 전 원본은 archive에 보존했습니다. 이번 검토본에서 다른 캐릭터·괴수·음원을 archive로 제거한 용량은 0B, 중복 이미지 병합 절감은 0B입니다. 자주 참조하는 불변 Shape/TileSet/재질 공유는 메모리 최적화이며 파일 감량으로 합산하지 않았습니다. 랜드마크가 이미 밀도 하한 0.9이므로 표시 크기를 유지한 단순 0.75배 축소는 하한을 위반해 적용하지 않았습니다. 후속 지역에서는 사용하지 않는 조각 수를 줄이는 방법을 우선 검토합니다.

| 품질 비교 | 결과 |
|---|---|
| 랜드마크 RGB/SSIM | 2.98958/255 / 0.99514 |
| 배경0·2 GL 6장 | RGB 최대 1.77110/255, SSIM 최소 0.96897 |
| 알파/bbox | 평균 0 / 동일 |
| 이음매 | 최대 RGB 0/255 (허용8) |

목표 미달 사유: 착륙지 1/10만 새 아트를 적용했으며 9지역은 승인 대기, 44.8MiB 규모 캐릭터/괴수 스프라이트는 지시서 §12.5에 따라 후속 단계입니다. 71/66/63MiB와 월드아트3.5MiB 목표를 현재 달성했다고 보지 않습니다. data/world 0.40MiB 목표는 실행 ZIP에서 달성했습니다.

다음 단계 후보는 아래 파일의 최대 표시 배율을 먼저 계측한 뒤 GL SSIM≥0.93, RGB≤3/255, 알파≤0.5/255, bbox 동일을 통과할 때만 적용합니다. 아직 측정하지 않은 감량량은 확정 수치로 쓰지 않았습니다.

| 큰 파일 상위20 | 현재 | 후속 후보 |
|---|---:|---|
| assets/props/doors/castle_great_gate.webp | 0.8485 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/backgrounds/hwanira/plaza.webp | 0.6863 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/backgrounds/deathsea/stars_tile.webp | 0.5170 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/gugalanna/walk.webp | 0.5062 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/gugalanna/idle.webp | 0.4775 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/gugalanna/death.webp | 0.4588 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/backgrounds/cedar/mid_trunks_tile_2d.webp | 0.4576 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/kala_ushumgal/phase_transition.webp | 0.4410 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/kala_ushumgal/death.webp | 0.4310 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/kala_ushumgal/collapse.webp | 0.4072 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/world/zabulistan_v2/forest/landmarks.webp | 0.3962 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/world/zabulistan_v2/crystal/landmarks.webp | 0.3795 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/kala_ushumgal/walk.webp | 0.3792 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/kala_ushumgal/whip_recovery.webp | 0.3644 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/world/zabulistan_v2/skywalk/landmarks.webp | 0.3639 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/kala_ushumgal/turn.webp | 0.3568 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/gugalanna/turn.webp | 0.3529 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/backgrounds/homeroad/mid_district_tile.webp | 0.3513 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/gugalanna/rake_windup.webp | 0.3481 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |
| assets/sprites/enemies/kala_ushumgal/idle.webp | 0.3474 MiB | 최대 표시 크기·참조·GL 품질 감사 후 결정 |

기존 추적 파일 archive 이동: source/maze.ascii 3,645B. 이 빌드 입력은 이전에도 실행 ZIP에서 제외되어 런타임 감량으로 합산하지 않았습니다. 초안 템플릿은 신규 작업 중 생성한 파일이라 기존 에셋 제거량에서 제외합니다.

### 15단계 폴더 크기 상위10 (하위 폴더 합산, 중첩 포함)

| 폴더 | 용량 |
|---|---:|
| assets/sprites | 48.07368 MiB |
| assets/sprites/enemies | 30.41749 MiB |
| assets/sprites/player | 14.37648 MiB |
| assets/props | 6.87264 MiB |
| assets/backgrounds | 6.71668 MiB |
| assets/sprites/enemies/kala_ushumgal | 6.34330 MiB |
| assets/world | 5.78306 MiB |
| assets/world/zabulistan_v2 | 5.66368 MiB |
| assets/sprites/enemies/gugalanna | 5.34614 MiB |
| assets/props/doors | 3.88511 MiB |
