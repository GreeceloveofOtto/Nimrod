# Stage14 연속 월드 재작업 검토본

가정: 640×360타일, 32px 타일, 64×36타일 청크 100개, 메모리 상한 9청크. 일반 괴수는 99마리이며 낮은 밀도를 우선했다. 사망 후 능력·생명 조각·문·지도·보스 처치를 유지하고 결정·임시 전승 수집품은 잃는다.

**미완료:** 전체 ZIP 63MiB 목표에 미달했으며, 짧은 공중 발판 중심의 지형은 데드 셀식 벽·복도·갱도의 시각적 완성도에 부족하다. 기능 통과를 전체 요구 완료로 표시하지 않았다. 전체 256화면의 수동 완주도 미실행이다.

검증: 새 폴더에 추출한 패키지의 헤드리스 검사 193/193, 패키지 검증 명령 15/15, 실제 GL HUD 검사 12/12, 시트 번짐 검사 941/941(GL 비교 546). 빈 하늘과 암반을 포함한 24×14 창 중복 0건, 능력·문 131,072상태 실패 0건. 실제 사망 복귀 2.58초, 프레임 P95 8.48ms, 분할 생성 최대 24.11ms.

실행용 ZIP을 풀어 Godot 4.3에서 Nimrod/project.godot을 연다. 기존 세이브 스키마 1은 마이그레이션한다. F5는 저장과 영구 진행까지 완전히 초기화한다.

| 파일 | 크기 | SHA-256 |
| --- | --- | --- |
| [Nimrod_stage14_rework_2026-10-15.zip](Nimrod_stage14_rework_2026-10-15.zip) | 72.33 MiB | `e185f47f570bc9e05b3c57ecdbe275cb835bd2f70080c218e380989a08e1900a` |
| [Nimrod_stage14_rework_QA_2026-10-15.zip](Nimrod_stage14_rework_QA_2026-10-15.zip) | 15.27 MiB | `5f88d7be8ee88013caf127639c0884972f94b14015a45f0caba2563afe7cf649` |
| [Nimrod_stage14_rework_ArtSources_2026-10-15.zip](Nimrod_stage14_rework_ArtSources_2026-10-15.zip) | 83.16 MiB | `d238fd65472010d29d1124da30d6b0586bb5e2b465fd07d5c1edb5fb6187d62d` |

QA ZIP에는 보고서, 전체 좌표·파일 명세, 독립 검증 로그와 비교 캡처, ASCII 빌드 입력이 있다. ArtSources ZIP에는 이미지 생성 원본과 품질 비교용 정본이 있다. 원본·캡처·개발 캐시는 실행용 ZIP에서 제외했다.

상세 보고서: [stage14_rework_report.md](../docs/stage14_rework_report.md). 기존 니므롯 레벨·대사·공격 수치와 project.godot은 유지했다. 메인 브랜치를 변경하지 않고 codex/nimrod-stage14-continuous-rework 브랜치에서 제공한다.
