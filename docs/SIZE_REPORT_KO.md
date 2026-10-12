# 용량 보고 — 12단계 (2026-10-13)

기준: 11단계 assets 61.153MiB / ZIP 69.420MiB. 현재 런타임 assets 60.542MiB. 슬림 ZIP 검증본은 60.926140MiB. 최종 문서 재패키지의 정확한 크기·SHA256은 downloads의 .sha256과 기록 JSON에 기재한다. 65MiB 기본 목표와11단계 대비 감소를 달성했고,60MiB 확장 목표는 아직 넘는다.

| 분류 | 11단계 MiB | 12단계 MiB | 변화 MiB |
|---|---:|---:|---:|
| 배경 | 5.899 | 5.899 | 0.000 |
| 스프라이트 | 44.726 | 43.993 | -0.733 |
| 소품·문 | 6.706 | 6.987 | 0.281 |
| 지형 | 1.551 | 1.551 | 0.000 |
| 오디오 | 1.962 | 1.850 | -0.112 |
| 폰트 | 0.121 | 0.122 | 0.001 |
| assets 전체 | 61.153 | 60.542 | -0.611 |

## 신규3종 예산

| 파일 | KiB |
|---|---:|
| assets/props/huluppu_trunk.webp | 253.02 |
| assets/props/utnapishtim_hut.webp | 44.19 |
| assets/sprites/npcs/utnapishtim/idle.webp | 66.38 |

합계 363.59KiB ≤500KiB. 원본과 모든 후보는 archive/에 보존.

## 적용·거부한 절감

- 이미지 참조 전체 재검토: 미사용 실행 이미지0개. 통합 완료된 개발용 stage2 manifest2개는 archive로 이동. 개발 캡처·tests/artifacts·pack_source·import/uid 캐시·archive는 슬림 ZIP 제외.
- 신규 노인 idle은 SSIM0.997865로6논리 프레임을5저장 프레임으로 병합(frame_map), 총2.4초 유지. 기존·새 투구 시트의 다른 완만한 루프도 재검토했으나 기준 미달/절감 없는 후보는 유지.
- 의수·투구74시트를 불변 canonical 원본에서 밀도 하한0.8(보스 기존0.9)을 지켜 재검토. SSIM0.93 아래는 다시 해상도를 올려 최저 허용값에 정착하므로 무조건 축소하지 않았다. WebP YUV80 또는 제한 RGB 양자화 중 RGB 평균≤3, 알파 평균≤0.5, bbox불변인 작은 후보만 사용.
- 신규3종의64/128/256색 팔레트 재검토: 집만 적용, 약37.9KiB 감소. 나무·노인은 더 작지 않거나 품질 한도를 통과하지 못해 원래 인코딩 유지.
- BGM14곡을 불변 WAV에서 모노36kbps로 재검토해5곡만 적용, 약114.6KiB 절감. 나머지는 길이·샘플 수·루프 이음/피크·용량 기준을 통과하지 않아 원본 유지. SFX109개 무음 꼬리를 점검해 explosion_boom의-80dB 이하 뒤쪽만20ms 여유를 남겨 다듬음.
- assets JSON을 공백 없이 저장해 약200KiB 감소. 픽셀·타이밍과 무관.
- ZIP은 최대 deflate9와 Godot용 명시적 디렉터리 엔트리를 쓴다. Godot 압축 가져오기 실패 파일0. 별도 QA ZIP은 개발 비교용이며 슬림 예산과 분리.

## 추가 절감 후보 상위20개

60MiB 이하를 더 줄이려면 아래 큰 파일의 밀도·색/시간 변화부터 다시 검토해야 한다. 이미 SSIM/밀도 하한/색차 한도에 가까워 단순 품질 하향은 적용하지 않았다. 예상치는 조건부이며 검증 없이 반영하지 않는다.

| 파일 | MiB | 제약/후보 | 조건부 예상 절감 MiB |
|---|---:|---|---:|
| assets/props/doors/castle_great_gate.webp | 0.849 | RGB/알파·SSIM 품질 게이트 유지; 부드러운 중복 프레임 재검토 | 0.085 |
| assets/backgrounds/deathsea/stars_tile.webp | 0.517 | RGB/알파·SSIM 품질 게이트 유지; 부드러운 중복 프레임 재검토 | 0.052 |
| assets/sprites/enemies/gugalanna/walk.webp | 0.506 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.051 |
| assets/sprites/enemies/gugalanna/idle.webp | 0.478 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.048 |
| assets/sprites/enemies/gugalanna/death.webp | 0.468 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.047 |
| assets/backgrounds/cedar/mid_trunks_tile_2d.webp | 0.458 | RGB/알파·SSIM 품질 게이트 유지; 부드러운 중복 프레임 재검토 | 0.046 |
| assets/sprites/enemies/kala_ushumgal/phase_transition.webp | 0.442 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.044 |
| assets/sprites/enemies/kala_ushumgal/death.webp | 0.431 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.043 |
| assets/props/doors/villa_gate.webp | 0.427 | RGB/알파·SSIM 품질 게이트 유지; 부드러운 중복 프레임 재검토 | 0.043 |
| assets/sprites/enemies/kala_ushumgal/collapse.webp | 0.408 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.041 |
| assets/sprites/enemies/kala_ushumgal/walk.webp | 0.379 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.038 |
| assets/sprites/enemies/kala_ushumgal/whip_recovery.webp | 0.365 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.036 |
| assets/sprites/enemies/kala_ushumgal/turn.webp | 0.357 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.036 |
| assets/sprites/enemies/gugalanna/turn.webp | 0.353 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.035 |
| assets/backgrounds/homeroad/mid_district_tile.webp | 0.351 | RGB/알파·SSIM 품질 게이트 유지; 부드러운 중복 프레임 재검토 | 0.035 |
| assets/sprites/enemies/gugalanna/rake_windup.webp | 0.348 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.035 |
| assets/sprites/enemies/kala_ushumgal/idle.webp | 0.347 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.035 |
| assets/sprites/enemies/kala_ushumgal/summon.webp | 0.344 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.034 |
| assets/sprites/enemies/gugalanna/rake.webp | 0.338 | 보스/대형 밀도 하한·SSIM; 동작을 유지하는 인접 프레임만 추가 병합 | 0.034 |
| assets/backgrounds/castle_front/downtown_passage_facade.webp | 0.334 | RGB/알파·SSIM 품질 게이트 유지; 부드러운 중복 프레임 재검토 | 0.033 |

### 원본을 유지한 BGM 후보

| 파일 | 기존 이음 차 | 후보 이음 차 | 이유 |
|---|---:|---:|---|
| assets/audio/bgm/castle_front.ogg | 0.02047 | 0.03749 | 루프 이음이 기존보다0.01 이상 커져 거부·원본 유지 |
| assets/audio/bgm/cedar_boss.ogg | 0.01979 | 0.03981 | 루프 이음이 기존보다0.01 이상 커져 거부·원본 유지 |
| assets/audio/bgm/cedar_forest.ogg | 0.02607 | 0.03890 | 루프 이음이 기존보다0.01 이상 커져 거부·원본 유지 |
| assets/audio/bgm/deathsea_drone.ogg | 0.01325 | 0.04729 | 루프 이음이 기존보다0.01 이상 커져 거부·원본 유지 |
| assets/audio/bgm/dilmun_wind.ogg | 0.00198 | 0.02383 | 루프 이음이 기존보다0.01 이상 커져 거부·원본 유지 |
| assets/audio/bgm/home_sorrow.ogg | 0.02112 | 0.05128 | 루프 이음이 기존보다0.01 이상 커져 거부·원본 유지 |
| assets/audio/bgm/uruk_home_road.ogg | 0.01187 | 0.05947 | 루프 이음이 기존보다0.01 이상 커져 거부·원본 유지 |
| assets/audio/bgm/uruk_rear_gate.ogg | 0.01906 | 0.03112 | 루프 이음이 기존보다0.01 이상 커져 거부·원본 유지 |
| assets/audio/bgm/villa_calm.ogg | 0.01882 | 0.05454 | 루프 이음이 기존보다0.01 이상 커져 거부·원본 유지 |

신규 이미지 팔레트 후보: 나무·노인은 파일이 더 작지 않거나 품질/색차 한도를 넘어서 유지. 집만 적용. 밀도 후보의 낮은 해상도는 SSIM0.93 미만일 때 자동으로 한 단계씩 되돌려 저장했다.

### 패키지 기능/용량 검증

기능: 새 폴더에서150/150 헤드리스 검사 통과, 추가 정적 QA 전부 통과. 용량: assets11단계 대비 감소, 슬림ZIP65MiB 이하 PASS.60MiB 확장 목표는 약0.93MiB 초과해 미달. 기존 sprites가44MiB 가까이 차지하며 더 낮은 밀도/품질은 보장한 한도를 넘으므로 적용하지 않았다. 별도 QA ZIP21.40MiB는 선택 다운로드용 개발 비교 자료이며 슬림 예산에 포함하지 않는다.
