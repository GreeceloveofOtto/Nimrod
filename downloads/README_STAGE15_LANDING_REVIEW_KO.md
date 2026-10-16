# NIMROD 15단계 — 착륙 절벽 중간 검토본

이번 버전은 `ZABULISTAN_MAP_REWORK_SPEC_KO.md` §10의 3번 중간 확인 지점입니다. 착륙지 한 지역만 암반 굴착 지형으로 바꿨습니다. 나머지 9지역과 전체 최적화는 승인 대기입니다.

- 실행용: `Nimrod_stage15_landing_review_2026-10-16.zip`
- QA·소스·캡처: `Nimrod_stage15_landing_review_QA_2026-10-16.zip`
- 검토 보고서: `Nimrod/docs/STAGE15_MAP_REWORK_REPORT_KO.md`
- 비교 이미지: QA ZIP의 `docs/stage15_map_review/landing_before_after.png`

실행 ZIP을 풀고 Godot 4.3에서 `Nimrod/project.godot`를 불러옵니다. `HwaniraPlaza`에서 기존 라오다스타흐마 재대화를 통해 자불리스탄으로 이동합니다. 기존 개발 디버그 이동도 유지합니다. 입력·전투 수치·저장·사망 귀환·F5 완전 초기화 규칙은 변경하지 않았습니다.

QA JSON은 실행 ZIP에 포함하지 않습니다. 별도 QA ZIP의 `data/world/zabulistan/art_quality.json`을 `check_world_art.py`와 `check_carved_art.py`의 `--quality-file` 인자로 넘기면 동일한 SHA/품질 검사를 실행할 수 있습니다. 실제 배포본을 새 폴더에서 추출하여 전체 Godot 테스트 및 Python 검사를 수행했습니다. 자세한 결과는 보고서와 QA의 `archive/stage15_map/package_report.json`을 확인하세요.

현재 ZIP은 전체 71/66/63MiB 목표를 아직 달성하지 못했습니다. 보호 대상 시트와 다른 9지역을 유지한 중간 검토본이며, 승인 뒤 전체 맵과 프로젝트 최적화를 진행합니다.
