NIMROD — 우루크 루갈성 후문 구간 (Godot 4.3)

첨부 Nimrod_Godot_v7_1_Import_Fixed 프로젝트를 기반으로 확장했습니다.
이번 단계는 후문 밖 첫 전투 구간입니다. 도입 문구와 별장 방향 출구를
구현했으며, 후문 E는 프롬프트만 표시합니다. 별장 지역·스토리 분기·
최종 엔딩은 후속 단계입니다.

실행
1. ZIP 전체를 새 폴더에 압축 해제합니다.
2. Godot 4.3 프로젝트 관리자에서 project.godot을 가져옵니다.
3. 최초 이미지·음원 임포트가 끝난 뒤 F5로 실행합니다.
4. GL Compatibility, 1280x720, 외부 애드온 없음.
   Windows에서는 기존 PLAY_WITH_GODOT.bat도 사용할 수 있습니다.

조작
A/D 또는 좌우 화살표: 이동
S: 수그리기
Space: 점프 / S+Space: 일방향 발판에서 내려가기
J: 도끼 4연격 (입력 버퍼) / 공중 J: 4타 내려찍기
K: 구르기·공격 캔슬 (선딜/활성/후딜 모두)
   누르고 있는 좌우 방향 사용. 입력이 없으면 현재 바라보는 방향.
E: 후문 근처 프롬프트 자리만 표시 (문 열기 기능 없음)
F1: 플레이어 공격 판정, 적 hurtbox·공격 판정·감지 범위 표시/숨김
R: 현재 씬 재시작

보존한 수치
HP180 / 도끼20,20,20,22 / 콤보 리셋0.8초 / 히트스톱0.05초
구르기0.48초 = 선딜0.03 + 무적0.25 + 후딜0.20
일반 피격 경직·유예0.45초 / 사망 후1.6초에 처음부터 다시 시작
원본 플레이어 이동·점프·스프라이트18개도 보존했습니다.

변경 사항
- 입력 방향 구르기, 즉시 flip, 캔슬 콤보/공격 판정 초기화 수정
- 점프3종 랜덤 효과음(피치0.96~1.04), 착지음, BGM/SFX 버스
- Audio autoload, 전투 효과음13종, 48초 반복 BGM
- 데이터 기반 데미지·넉백·경직과 화염11틱 피해 경로
- 근접HP95 박치기 괴수 / 원거리HP63 화염 괴수, 느린 회전·후딜·인터럽트
- 적 이동 범위±250px, 경직 상한, 플레이어/적 몸체 충돌 예외
- 폭3600 맵, 단차2·일방향 발판2·괴수5, 안전 후문 구역과 별장 출구
- 실제 이미지 생성 PNG30종, manifest, 파랄랙스4겹, 휴대 가능한 한글 폰트
- 가까운 적이 플레이어 쪽으로 밀리던 넉백 방향 추가 수정
- 기존 jump.wav는 assets/audio/legacy/jump.wav로 원본 그대로 이동

데이터와 아트
data/player_attacks.json: 도끼·충격파 수치와 기존 판정 타이밍
data/enemies.json: 적 스탯·공격·효과 설정
scripts/game_constants.gd, rear_gate_layout.gd: 플레이어·맵·UI 상수
assets/art_manifest.json, 괴수 manifest: PNG 규격·프레임·앵커
assets/source_art/: 실제 이미지 생성 원본과 후처리 기록
assets/image_prompts/: 에셋별 완성 프롬프트30개
그림은 PNG만 사용합니다. _draw는 F1 디버그 판정만 그립니다.
이미지가 없으면 회색 MISSING_TEXTURE 사각형과 MISSING 라벨을 표시합니다.
최종 제공본에 누락된 요청 아트는 없습니다.

도구 (게임 실행에는 Python 설치가 필요하지 않음)
python -m pip install -r requirements-tools.txt
python tools/make_jump_sfx.py
python tools/make_sfx.py
python tools/make_bgm.py
python tools/build_beast_assets.py
python tools/build_map_assets.py
python tools/validate_assets.py
아트 명령: tools/ART_PIPELINE_KO.md
음원은 동일 경로에 덮어쓰면 됩니다. 반복 여부는 Audio에서 설정합니다.

자동 검사 (프로젝트 루트에서 Godot 4.3 사용)
godot --headless --editor --path . --import
godot --headless --path . --script tests/regression.gd
godot --headless --path . --quit-after 180
Godot4.3 회귀 검사169개/실패0, 생성 PNG30개/누락0/오류0 확인.
GL Compatibility 시작·중간(화염)·출구를1280x720로 렌더링 검증했습니다.
새 폴더의 ZIP 최초 임포트·회귀 검사도 통과했습니다.
--quit-after 강제 종료는 코드0으로 끝나지만 Godot4.3에서 대기 중인
오디오 객체의 ObjectDB 종료 경고가 남습니다. 일반 회귀·렌더 검사는
이 경고 없이 종료합니다.
실제 스피커 청감, 장시간 직접 플레이, 애니메이션의 체감 자연스러움은
사람이 직접 확인할 항목입니다. Windows 배치는 Linux에서 실행하지 않았습니다.

가정·선택 수치·전체 변경 파일 목록: docs/IMPLEMENTATION_REPORT_KO.md
