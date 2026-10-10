# NIMROD

Godot 4.3 / GDScript로 만드는 우루크 배경의 횡스크롤 메트로배니아입니다.
현재 3단계에는 루갈성 후문 밖, 루갈성 1~5층, 별장 1층을 문으로 연결하고,
루갈성 정문 앞을 추가하고 NPC 13명과 지상 괴수 2종·비행 괴수 1종을 구현했습니다.

ZIP 전체를 압축 해제한 뒤 Godot 4.3에서 `project.godot`을 가져와 F5로 실행하세요.
GL Compatibility, 1280×720이며 외부 애드온은 필요하지 않습니다.

[한국어 실행·조작 안내](README_KO.txt) · [3단계 구현·검증 보고서](docs/STAGE3_REPORT_KO.md)

```sh
godot --headless --editor --path . --quit
python tools/validate_assets.py
godot --headless --path . --script res://tests/regression.gd
godot --headless --path . --script res://tests/stage2_transitions.gd
godot --headless --path . --script res://tests/stage2_interactions.gd
godot --headless --path . --script res://tests/stage2_sky.gd
godot --headless --path . --script res://tests/stage3_front.gd
```

문은 E로 이용하며, 문지기가 열어 준 별장 대문은 안으로 걸어 들어가면 이동합니다.
층 이동은 HP와 전투 상태를 유지합니다. 사망하거나 R을 누르면 HP 180으로 후문 앞에서 다시 시작합니다.
NPC 대화·별장 2층·스토리 분기·최종 엔딩은 후속 개발 범위입니다.

이름표·근접 하이라이트·근미래 NPC 재디자인과 자동 개폐하는 성 대문을 구현했습니다.
`tests/stage3_front.gd`를 포함한 기능 검사572개와 PNG105개가 통과했습니다.
재사용 NPC의 평균 대비 경고4개는 한국어 보고서에 기록했습니다.
