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
