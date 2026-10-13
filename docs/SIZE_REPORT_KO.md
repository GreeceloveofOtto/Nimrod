# 13단계 용량 측정

| 단계 | assets | 실행용 ZIP |
|---|---:|---:|
| 11 | 61.15MiB | 69.42MiB |
| 12 | 60.54MiB | 60.93MiB |
| 13 | 65.13MiB | 65.58MiB |

신규 이미지 총 4.62MiB. 신규 개별 예산은 모두 통과했으나, 전체 ZIP 62MiB 목표는 미달이다. 기능 검증과 용량 판정은 별도로 기록한다.

| 신규 항목 | 사용 | 상한 |
|---|---:|---:|
| siyavash | 0.95MiB | 2.0MiB |
| ninazu_mother | 0.84MiB | 1.2MiB |
| lilith | 0.68MiB | 1.2MiB |
| zu | 0.86MiB | 1.2MiB |
| backgrounds | 0.91MiB | 1.5MiB |
| props_tiles | 0.38MiB | 0.4MiB |

| 카테고리 | 12단계 | 13단계 |
|---|---:|---:|
| sprites | 43.99MiB | 47.35MiB |
| backgrounds | 5.90MiB | 6.81MiB |
| props | 6.99MiB | 7.01MiB |
| tiles | 1.55MiB | 1.90MiB |
| audio | 1.85MiB | 1.79MiB |
| fonts | 0.12MiB | 0.13MiB |

13단계 sprites 세부: fx 0.91MiB, npcs 1.77MiB, enemies 30.55MiB, player 14.13MiB

적용과 되돌림:

- 신규 보스 저장 밀도는 0.9를 시작값으로 삼고 SSIM 0.93 이상을 통과한 밀도만 적용했다. 앵커와 게임 표시 크기는 유지했다.
- 흐와니라 배경은 원본 생성 이미지의 측면 건축 영역을 합성해 3200×896으로 저장했다(4000×1120 표시, 밀도 0.8). 항성이 잘리던 구도는 이미지 생성으로 수정했다.
- 배경의 낮은 휘도는 색보정으로 정리하고 게임에서는 modulate로 어둡게 했다. 단색 검은 테두리를 덧그리지 않았다.
- 배경의 채널별 색 양자화는 원본 대비 RGB 평균 ≤3/255, 알파 불변, SSIM ≥0.93인 결과만 채택했다.
- 기존 상위 30개 시트를 낮은 밀도, WebP RGB 품질 82/86/90/94/98, 채널별 색 양자화와 near-lossless 0/20/40/60으로 검사했다. 현재 파일보다 작고 품질 게이트를 통과하는 경우만 적용했다. 대부분은 색차가 3/255를 넘거나 기존 파일보다 커서 유지했다.
- 인접 프레임은 SSIM ≥0.985일 때 frame_map으로 병합했다. 논리 프레임 수와 총 재생 길이는 그대로다. 회전 클립은 최소 3개 저장 프레임을 유지한다.
- BGM mono 32kbps 후보 중 샘플 수, 루프 이음새(기존+0.01 이내), 피크(<0.99), 파일 크기를 모두 통과한 5곡을 채택해 0.0575MiB 줄였다. 44.1kHz/24kbps는 libvorbis가 거부해 적용하지 않았다.
- 미사용 이미지/오디오 0개, 해시가 동일한 중복 파일 0개. 활성 클립·폴더를 삭제해 예산을 맞추지 않았다.
- 변환 전 파일과 실패 후보는 archive/stage13 및 기존 archive/pack_source 계열에 보존했다. archive에는 .gdignore를 두고 실행 ZIP에서 제외했다.

상위 20개 큰 파일과 다음 후보(예상 절감은 재검증 전 추정):

| 파일 | 현재 | 유지 이유 | 다음 후보 / 예상 |
|---|---:|---|---|
| assets/props/doors/castle_great_gate.webp | 0.85MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.13MiB |
| assets/backgrounds/hwanira/plaza.webp | 0.69MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.10MiB |
| assets/backgrounds/deathsea/stars_tile.webp | 0.52MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.08MiB |
| assets/sprites/enemies/gugalanna/walk.webp | 0.51MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.08MiB |
| assets/sprites/enemies/gugalanna/idle.webp | 0.48MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.07MiB |
| assets/sprites/enemies/gugalanna/death.webp | 0.46MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.07MiB |
| assets/backgrounds/cedar/mid_trunks_tile_2d.webp | 0.46MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.07MiB |
| assets/sprites/enemies/kala_ushumgal/phase_transition.webp | 0.44MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.07MiB |
| assets/sprites/enemies/kala_ushumgal/death.webp | 0.43MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.06MiB |
| assets/props/doors/villa_gate.webp | 0.43MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.06MiB |
| assets/sprites/enemies/kala_ushumgal/collapse.webp | 0.41MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.06MiB |
| assets/sprites/enemies/kala_ushumgal/walk.webp | 0.38MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.06MiB |
| assets/sprites/enemies/kala_ushumgal/whip_recovery.webp | 0.36MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.05MiB |
| assets/sprites/enemies/kala_ushumgal/turn.webp | 0.36MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.05MiB |
| assets/sprites/enemies/gugalanna/turn.webp | 0.35MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.05MiB |
| assets/backgrounds/homeroad/mid_district_tile.webp | 0.35MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.05MiB |
| assets/sprites/enemies/gugalanna/rake_windup.webp | 0.35MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.05MiB |
| assets/sprites/enemies/kala_ushumgal/idle.webp | 0.35MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.05MiB |
| assets/sprites/enemies/kala_ushumgal/summon.webp | 0.34MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.05MiB |
| assets/sprites/enemies/gugalanna/rake.webp | 0.34MiB | 기존 압축보다 작은 후보가 품질 기준을 통과하지 못함 또는 신규 예산 통과 | 원본 재생성으로 색·질감을 단순화한 뒤 재검사 / 약 0.05MiB |

62MiB를 맞추려면 약 3.56MiB 추가 절감이 필요하다. 현재 품질 기준을 그대로 유지하는 자동 변환에서는 이만큼의 여유가 확인되지 않았다. 큰 보스 원본의 세부 질감을 줄여 재생성하는 작업이 가장 큰 후보이며, 단순한 품질 하향이나 활성 모션 삭제는 적용하지 않았다.

## 패키지 용량 목표 미달 후보

- assets/props/doors/castle_great_gate.webp: 0.85MiB, 참조/SSIM 재검토 후 예상 0.08MiB 절감.
- assets/backgrounds/hwanira/plaza.webp: 0.69MiB, 참조/SSIM 재검토 후 예상 0.07MiB 절감.
- assets/backgrounds/deathsea/stars_tile.webp: 0.52MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/walk.webp: 0.51MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/idle.webp: 0.48MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/death.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/backgrounds/cedar/mid_trunks_tile_2d.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/kala_ushumgal/phase_transition.webp: 0.44MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/death.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/props/doors/villa_gate.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/collapse.webp: 0.41MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/walk.webp: 0.38MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/whip_recovery.webp: 0.36MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/turn.webp: 0.36MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/gugalanna/turn.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/backgrounds/homeroad/mid_district_tile.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/gugalanna/rake_windup.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
- assets/sprites/enemies/kala_ushumgal/idle.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
- assets/sprites/enemies/kala_ushumgal/summon.webp: 0.34MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
- assets/sprites/enemies/gugalanna/rake.webp: 0.34MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.

## 패키지 용량 목표 미달 후보

- assets/props/doors/castle_great_gate.webp: 0.85MiB, 참조/SSIM 재검토 후 예상 0.08MiB 절감.
- assets/backgrounds/hwanira/plaza.webp: 0.69MiB, 참조/SSIM 재검토 후 예상 0.07MiB 절감.
- assets/backgrounds/deathsea/stars_tile.webp: 0.52MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/walk.webp: 0.51MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/idle.webp: 0.48MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/death.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/backgrounds/cedar/mid_trunks_tile_2d.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/kala_ushumgal/phase_transition.webp: 0.44MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/death.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/props/doors/villa_gate.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/collapse.webp: 0.41MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/walk.webp: 0.38MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/whip_recovery.webp: 0.36MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/turn.webp: 0.36MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/gugalanna/turn.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/backgrounds/homeroad/mid_district_tile.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/gugalanna/rake_windup.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
- assets/sprites/enemies/kala_ushumgal/idle.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
- assets/sprites/enemies/kala_ushumgal/summon.webp: 0.34MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
- assets/sprites/enemies/gugalanna/rake.webp: 0.34MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.

## 패키지 용량 목표 미달 후보

- assets/props/doors/castle_great_gate.webp: 0.85MiB, 참조/SSIM 재검토 후 예상 0.08MiB 절감.
- assets/backgrounds/hwanira/plaza.webp: 0.69MiB, 참조/SSIM 재검토 후 예상 0.07MiB 절감.
- assets/backgrounds/deathsea/stars_tile.webp: 0.52MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/walk.webp: 0.51MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/idle.webp: 0.48MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/death.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/backgrounds/cedar/mid_trunks_tile_2d.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/kala_ushumgal/phase_transition.webp: 0.44MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/death.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/props/doors/villa_gate.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/collapse.webp: 0.41MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/walk.webp: 0.38MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/whip_recovery.webp: 0.36MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/turn.webp: 0.36MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/gugalanna/turn.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/backgrounds/homeroad/mid_district_tile.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/gugalanna/rake_windup.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
- assets/sprites/enemies/kala_ushumgal/idle.webp: 0.35MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
- assets/sprites/enemies/kala_ushumgal/summon.webp: 0.34MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
- assets/sprites/enemies/gugalanna/rake.webp: 0.34MiB, 참조/SSIM 재검토 후 예상 0.03MiB 절감.
