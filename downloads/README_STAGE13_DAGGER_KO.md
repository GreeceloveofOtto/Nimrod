# 흐와니라 영웅·천륜의 단검 — 검증된 다운로드

실행 ZIP: `Nimrod_stage13_dagger_2026-10-14.zip` — 69354704B / 66.142MiB

QA ZIP: `Nimrod_stage13_dagger_QA_2026-10-14.zip` — 원본·기준이미지·실패후보·확대캡처·검증 기록. 실행 프로젝트가 아니며 필요한 경우 실행 ZIP의 Nimrod 폴더에 합쳐 사용한다.

Godot4.3에서 실행 ZIP을 풀고 Nimrod/project.godot를 연다. ZIP 프로젝트 가져오기에 필요한 디렉터리 항목도 검증했다.

- 전체 헤드리스179/179, 독립 압축해제 후12개 검증 명령 모두 통과.
- 단검 통합92검사, OpenGL885검사/514비교 오류0.
- 신규 이미지842,238B(0.803MiB), 모든1.7MiB/개별 예산 통과.
- ZIP62MiB 목표는 미달. 원인·실패 후보·상위20파일은 docs/SIZE_REPORT_KO.md.
- codex/nimrod-stage13-plaza-dagger 브랜치, main 변경 없음.

SHA-256:

b1a7658830f2cf4355cc09c66d3dc70acd6f61eb2d38d2a5cdce749b2681264a  실행

5ef1bd2cc8a9dca1e16bcafaf436185f3efbb8b98d1554cb0abc4464452f3691  QA
