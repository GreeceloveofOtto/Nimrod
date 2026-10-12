# 11단계 용량 보고

기능 검사와 용량 판정은 별개다. 저장 밀도 하한(보스0.9/인물·일반괴수0.8), SSIM0.93, RGB평균오차3, 알파평균오차0.5/255와 bbox동일 기준을 유지했다. 기준을 넘긴 후보는 적용하지 않았다.

| 폴더 | 10단계 MiB | 11단계 MiB | 목표 MiB |
|---|---:|---:|---:|
| sprites | 33.858 | 44.726 | 34 |
| backgrounds | 5.382 | 5.899 | 6.5 |
| props | 6.275 | 6.706 | 6.5 |
| tiles | 1.648 | 1.551 | 1.8 |
| audio | 1.869 | 1.962 | 1.9 |
| 기타 | 0.212 | 0.308 | 1 |
| 합계 | 49.244 | 61.153 | 50 |

**에셋50MiB 목표 미달.** 보스·일반 괴수의 낮았던 저장 밀도를 올리고 투구·형태 세트를 추가한 영향이 크다. 구갈안나 새 고해상도 원본은 최초 무손실 패킹 약19MiB에서 품질 게이트를 통과한 재패킹으로 약5MiB로 줄였다. 추가 콘텐츠 개별 예산도 일부 미달이다.

| 새 콘텐츠 | MiB | 예산 MiB |
|---|---:|---:|
| helmet | 1.893 | 1.5 |
| onearm | 0.231 | 0.15 |
| r40 | 1.915 | 1.0 |
| r50 | 1.413 | 1.3 |
| r90 | 1.800 | 1.4 |
| shimati | 0.170 | 0.35 |
| urshanabi | 0.093 | 0.25 |
| props_fx | 0.225 | 0.8 |
| sea | 0.693 | 0.6 |
| audio | 0.093 | 0.5 |
| gugalanna_increase | 3.979 | 1.6 |

## 적용·거부한 방법

- 원본으로부터 밀도를 한 번 계산하고 저장 칸별2px 여백을 추가했다. 높은 밀도는 하한까지 재검토하되 SSIM실패 파일은 더 높은 밀도를 유지한다.
- 이전 투구 없는 의수 세트와 사용하지 않는 정규화 PNG22개를 archive로 이동했다. 원본·패킹 전 시트는 보존한다.
- RGB품질80과 bounded RGB양자화 후보 중 색차·알파·크기를 통과한 파일을 적용했다.
- 64/128/256색 적응 팔레트 및 잔차 복구 후보596개는 품질 또는 크기 게이트를 통과하지 못해 적용하지 않았다.
- 느린 루프만 지각적 SSIM0.985 이상을 병합한다. 동작 클립을 줄이지 않았고 새 시마티 숨쉬기 두 클립은 논리6프레임/저장5프레임으로 재생 길이를 유지했다. 전체 추가 절감 약0.009MiB였다.
- 해시 동일 중복0그룹, 참조되지 않는 런타임 파일0개. 개발용 원본·PNG·부속 저장 메타데이터는 archive에 둔다.
- 오디오는 모노 OGG q3/48kbps를 사용한다. 새 오디오는 약0.093MiB다.
- 별 배경은 거의 검은 경계 검사를 통과하도록 명도를 보정한 뒤 무손실 예외를 적용했다. 손실 재인코딩은 검은 경계를 재도입해 사용하지 않았다.

## 화면 비교

docs/size_compare/stage11_*.jpg 6장: 구갈안나, tier4 니므롯, 닌순, 근접·원거리 괴수, 배경. SOURCE는 허용된 편집을 거친 패킹 전 원본이고 RUNTIME은 압축·축소 후다. 각각1.0/1.35배 표시한다. 재디자인 전후를 같은 그림의 SSIM처럼 비교하지 않는다.

## 큰 파일과 추가 절감 후보

| 파일 | MiB | 후보 및 한계 | 예상 MiB |
|---|---:|---|---:|
| assets/props/doors/castle_great_gate.webp | 0.849 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.085 |
| assets/backgrounds/deathsea/stars_tile.webp | 0.517 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.052 |
| assets/sprites/enemies/gugalanna/walk.webp | 0.506 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.051 |
| assets/sprites/enemies/gugalanna/idle.webp | 0.478 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.048 |
| assets/sprites/enemies/gugalanna/death.webp | 0.468 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.047 |
| assets/backgrounds/cedar/mid_trunks_tile_2d.webp | 0.458 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.046 |
| assets/sprites/enemies/kala_ushumgal/phase_transition.webp | 0.442 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.044 |
| assets/sprites/enemies/kala_ushumgal/death.webp | 0.431 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.043 |
| assets/props/doors/villa_gate.webp | 0.427 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.043 |
| assets/sprites/enemies/kala_ushumgal/collapse.webp | 0.408 | 다음 제작에서 원본 질감·광택 노이즈를 단순화해 같은 밀도·프레임·실루엣으로 재생성. 현재 바이트를 더 줄이면 RGB/SSIM 기준을 넘긴 후보가 많음. | 0.041 |

최종 ZIP 크기와 독립 압축 해제 검증 결과는 패키지 작성 후 아래에 추가한다. 용량 도구는 목표 미달 시 종료코드1을 반환하며 다운로드 가능한 파일은 남긴다.

## 패키지 용량 목표 미달 후보

- assets/props/doors/castle_great_gate.webp: 0.85MiB, 참조/SSIM 재검토 후 예상 0.08MiB 절감.
- assets/backgrounds/deathsea/stars_tile.webp: 0.52MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/walk.webp: 0.51MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/idle.webp: 0.48MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/death.webp: 0.47MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/backgrounds/cedar/mid_trunks_tile_2d.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/kala_ushumgal/phase_transition.webp: 0.44MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/death.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/props/doors/villa_gate.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/collapse.webp: 0.41MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.

기능: 독립 추출본 전체143/143 및 추가 검증 통과. 용량: 목표 미달. 최종 ZIP의 정확한 바이트 크기는 다운로드 안내에 기록한다. 압축 검사 도구는 용량 미달 종료코드1을 반환한다.

## 패키지 용량 목표 미달 후보

- assets/props/doors/castle_great_gate.webp: 0.85MiB, 참조/SSIM 재검토 후 예상 0.08MiB 절감.
- assets/backgrounds/deathsea/stars_tile.webp: 0.52MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/walk.webp: 0.51MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/idle.webp: 0.48MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/death.webp: 0.47MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/backgrounds/cedar/mid_trunks_tile_2d.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/kala_ushumgal/phase_transition.webp: 0.44MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/death.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/props/doors/villa_gate.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/collapse.webp: 0.41MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.

최종 공유 ZIP: 약69.42MiB (목표52MiB 미달). 런타임은 독립 검증본과 해시 차이0이며, CRC·Godot ZIP 디렉터리 검사가 통과했다. 문서 이미지는 최신8장만 포함한다.

## 패키지 용량 목표 미달 후보

- assets/props/doors/castle_great_gate.webp: 0.85MiB, 참조/SSIM 재검토 후 예상 0.08MiB 절감.
- assets/backgrounds/deathsea/stars_tile.webp: 0.52MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/walk.webp: 0.51MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/idle.webp: 0.48MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/death.webp: 0.47MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/backgrounds/cedar/mid_trunks_tile_2d.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/kala_ushumgal/phase_transition.webp: 0.44MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/death.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/props/doors/villa_gate.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/collapse.webp: 0.41MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.

## 패키지 용량 목표 미달 후보

- assets/props/doors/castle_great_gate.webp: 0.85MiB, 참조/SSIM 재검토 후 예상 0.08MiB 절감.
- assets/backgrounds/deathsea/stars_tile.webp: 0.52MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/walk.webp: 0.51MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/idle.webp: 0.48MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/gugalanna/death.webp: 0.47MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/backgrounds/cedar/mid_trunks_tile_2d.webp: 0.46MiB, 참조/SSIM 재검토 후 예상 0.05MiB 절감.
- assets/sprites/enemies/kala_ushumgal/phase_transition.webp: 0.44MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/death.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/props/doors/villa_gate.webp: 0.43MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
- assets/sprites/enemies/kala_ushumgal/collapse.webp: 0.41MiB, 참조/SSIM 재검토 후 예상 0.04MiB 절감.
