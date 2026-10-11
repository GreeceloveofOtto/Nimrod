# 8단계 ZIP 가져오기 오류 수정

이전 ZIP의 데이터와 CRC는 정상이었지만 하위 폴더를 선언하는 ZIP 항목이 없었습니다. Godot 4.3의 ProjectDialog는 명시적인 폴더 항목에서만 make_dir를 호출하고 파일 쓰기 시 부모 폴더를 자동 생성하지 않습니다. 따라서 루트 파일 7개는 성공하고 하위 파일 1,318개가 실패했습니다. 화면에 나온 처음 16개와 추가 1,302개가 이 결과와 정확히 일치합니다. 이전 Python extractall 검증은 부모 폴더를 자동 생성해서 문제를 놓쳤습니다.

tools/make_slim_zip.py는 이제 Nimrod/ 루트와 모든 부모 폴더를 자식 파일보다 먼저 ZIP에 기록합니다. ZIP을 만들 때마다 tools/check_zip_import.py로 Godot과 같은 비재귀 폴더 생성·파일 쓰기를 검사합니다. tools/check_zip_import.gd는 Godot의 ZIPReader, DirAccess, FileAccess로 실제 추출을 재현합니다. tests/test_zip_import.py는 이전 방식의 실패와 새 방식의 성공을 모두 확인합니다. 게임 소스와 에셋은 변경하지 않았습니다.

수정본: downloads/Nimrod_stage8_import_fixed_2026-10-11.zip.

사용법: ZIP 전체를 Windows 탐색기의 '압축 풀기'로 새 폴더에 풀고 Godot에서 Nimrod/project.godot을 가져오세요. ZIP 자체를 프로젝트 관리자에서 가져오는 방식도 지원합니다. 이전 오류로 일부만 풀린 폴더에 덮어쓰지 말고 새 폴더를 선택하세요.

최종 검사 기록과 체크섬은 docs/STAGE8_ZIP_IMPORT_TEST_RESULTS.json에 기록합니다. 게임 로직은 이전 94/94 검증 버전과 동일하며 이번에는 ZIP 구조, Godot 방식의 실제 추출, 새 위치의 임포트·실행을 추가 검증합니다. Linux에서 검증했으며 Windows 프로젝트 관리자 자체의 클릭 동작은 수행하지 않았습니다.
