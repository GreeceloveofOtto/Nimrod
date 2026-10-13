# 용량 측정 — 시야우와르샨 재제작

기능 검증과 용량 판정은 별도로 기록한다.

| 단계 | assets MiB | 실행 ZIP MiB |
|---|---:|---:|
| 11 |61.15|69.42|
| 12 |60.54|60.93|
| 13 훔바바 수정 |65.13|65.596|
| 13 외형 재제작 |65.080|65.549|

기존 ZIP68,782,059 B. 새 ZIP은 약65.55MiB이며 정확한 바이트·SHA256은 별도 배포 README에 기록한다. 교체 시트 998,546→889,148 B, 기존 998,546B 한도 통과. 기준 시트·구 시트·원본·QA 캡처는 runtime ZIP에 없다. 새 보스·FX·배경 이미지는 만들지 않았다.

| 클립 | 프레임 | 길이(s) | 이전→새 밀도 | 이전→새 KiB |
|---|---:|---:|---:|---:|
| idle | 10 | 2.2 | 1.8→2.0 | 100.2→74.8 |
| walk | 10 | 1.05 | 1.6→1.6 | 98.7→84.8 |
| run | 10 | 0.82 | 1.8→1.6 | 95.2→91.9 |
| crouch_enter | 4 | 0.14 | 1.4→1.6 | 36.4→33.3 |
| crouch_idle | 6 | 0.8 | 1.6→2.0 | 49.7→53.8 |
| crouch_exit | 4 | 0.13 | 1.6→1.6 | 44.7→33.5 |
| jump_start | 4 | 0.13 | 1.2→1.6 | 45.0→27.9 |
| jump_rise | 6 | 0.42 | 1.6→1.6 | 61.2→38.1 |
| fall | 6 | 0.36 | 1.6→1.6 | 71.6→45.8 |
| land | 5 | 0.24 | 1.4→1.6 | 53.1→37.0 |
| drop_through | 5 | 0.22 | 1.4→1.6 | 49.1→40.9 |
| hurt | 5 | 0.32 | 1.6→2.0 | 63.8→67.2 |
| death | 8 | 0.6 | 1.0→2.0 | 39.9→78.1 |
| roll | 12 | 0.48 | 1.2→1.4 | 64.0→65.1 |
| sit_down | 4 | 0.35 | 1.4→1.6 | 30.3→26.7 |
| sit_idle | 6 | 2.0 | 1.8→1.8 | 45.1→36.0 |
| stand_up | 4 | 0.35 | 1.4→1.8 | 27.3→33.3 |

| 카테고리 | 이전 MiB | 새 MiB | 변화 KiB |
|---|---:|---:|---:|
| sprites/player |14.127|14.033|-96.6|
| sprites/npcs |1.766|1.766|+0.0|
| sprites/enemies |30.545|30.545|+0.0|
| sprites/fx |0.908|0.908|+0.0|
| backgrounds |6.810|6.810|+0.0|
| props |7.010|7.010|+0.0|
| tiles |1.904|1.904|+0.0|
| audio |1.793|1.793|+0.0|
| fonts |0.125|0.125|+0.3|
| image_prompts |0.000|0.041|+42.2|

상위30시트+배경/소품12개를 source archive와 비교해 WebP74·128색 팔레트를 시험했다. Homeroad mid_district_tile 후보는 처음에 평균 색차를 통과했지만, 좌우 가장자리 색차와 정확한 반복 열 검사를 추가하자 실패해 원본으로 복원했다. deathsea stars_tile과 underground_fill 후보는 RGB/SSIM/bbox를 통과했어도 거의 검은 가장자리 알파 기준을 넘겨 원본으로 복원했다. stars는82/90, mid는82/90/94도 재검사했지만 정확한 타일 이음새까지 통과하는 절감 후보가 없어 유지했다. 나머지는 RGB평균3/255 초과, 현재 파일보다 큼 또는 품질 기준 미달이다. 실패 후보는 archive/.../compression_trials.json에 기록했다. 167 OGG가 모두 모노이며 이전 단계의 32kbps 변환을 유지했다.

최종ZIP62MiB/60MiB 목표는 미달이다. 필요한 클립을 삭제하거나 품질/밀도 하한을 낮춰 맞추지 않았다. 추가 절감은 다음 후보를 단순한 생성 질감으로 다시 제작하고 같은 품질 기준을 확인해야 한다. 예상 절감은 확보한 용량이 아니다.

| 큰 파일 상위20 | 현재 KiB | 유지 이유 | 다음 후보 / 예상 KiB |
|---|---:|---|---:|
| assets/props/doors/castle_great_gate.webp |868.9|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 86.9|
| assets/backgrounds/hwanira/plaza.webp |702.7|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 70.3|
| assets/backgrounds/deathsea/stars_tile.webp |529.4|재인코딩 후 거의 검은 가장자리 기준 미달|질감/색 수 단순화 후 재검증 / 52.9|
| assets/sprites/enemies/gugalanna/walk.webp |518.3|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 51.8|
| assets/sprites/enemies/gugalanna/idle.webp |489.1|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 48.9|
| assets/sprites/enemies/gugalanna/death.webp |469.8|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 47.0|
| assets/backgrounds/cedar/mid_trunks_tile_2d.webp |468.6|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 46.9|
| assets/sprites/enemies/kala_ushumgal/phase_transition.webp |452.4|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 45.2|
| assets/sprites/enemies/kala_ushumgal/death.webp |441.4|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 44.1|
| assets/props/doors/villa_gate.webp |437.2|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 43.7|
| assets/sprites/enemies/kala_ushumgal/collapse.webp |417.4|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 41.7|
| assets/sprites/enemies/kala_ushumgal/walk.webp |388.3|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 38.8|
| assets/sprites/enemies/kala_ushumgal/whip_recovery.webp |373.5|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 37.4|
| assets/sprites/enemies/kala_ushumgal/turn.webp |365.3|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 36.5|
| assets/sprites/enemies/gugalanna/turn.webp |361.8|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 36.2|
| assets/backgrounds/homeroad/mid_district_tile.webp |359.7|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 36.0|
| assets/sprites/enemies/gugalanna/rake_windup.webp |356.5|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 35.6|
| assets/sprites/enemies/kala_ushumgal/idle.webp |355.7|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 35.6|
| assets/sprites/enemies/kala_ushumgal/summon.webp |351.8|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 35.2|
| assets/sprites/enemies/gugalanna/rake.webp |346.6|RGB 평균 색차 >3 또는 절감 없음|질감/색 수 단순화 후 재검증 / 34.7|

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
