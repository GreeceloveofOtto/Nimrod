# Nimrod

Godot 4.3 / GDScript로 구현한 우루크 루갈성 후문 전투 구간입니다.
첨부 v7.1 프로젝트의 조작·전투 수치를 유지합니다.

project.godot을 가져온 뒤 F5로 실행하세요.
[조작·도구 안내](README_KO.txt)와
[한국어 구현 보고서](docs/IMPLEMENTATION_REPORT_KO.md)에 변경·검증 결과가 있습니다.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/regression.gd
python tools/validate_assets.py
```
