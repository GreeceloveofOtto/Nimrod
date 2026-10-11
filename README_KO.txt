NIMROD — 7단계: 공격 크래시 수정·괴수 재제작·발판 정비·맨손/지팡이/도끼
Godot 4.3 stable / GDScript / GL Compatibility / 1280×720 / 외부 애드온 없음

실행
압축을 새 폴더에 모두 풀고 Godot 4.3으로 project.godot을 가져온 뒤 F5를 누릅니다.
PNG/WebP/OGG의 첫 임포트가 끝날 때까지 기다립니다. 실행에는 Python이 필요 없습니다.
Windows: PLAY_WITH_GODOT.bat. 엔진을 못 찾으면 GODOT_BIN을 설정합니다.
현재 25개 레벨입니다. 전체 스토리 엔딩·세이브포인트·멜람무 보상은 후속 작업입니다.

시작과 무기 획득
새 게임·사망·R·GameState.reset_run()은 모두 니므롯의 집 Spawn_Start(x330),
오른쪽을 보는 맨손으로 시작합니다. 맨손에서 J는 공격하지 않습니다.
집 선반 옆 x620의 삼나무 지팡이: 100px 이내 E → 지팡이 3타(18/18/24).
루갈성 1층 부모님 둘 중심에서 140px 이내 E: 첫 대화 후 도끼를 받습니다.
도끼는 지팡이를 교체하며, 다음 상호작용은 발생하지 않습니다.
부모님 대화는 data/dialogue.json의 use_scripted_dialogue로 생략할 수 있습니다.
사망·R은 무기/축복/런 플래그를 초기화하고 지팡이를 집에 다시 배치합니다.

조작
A/D 또는 좌우 화살표: 이동 / S: 수그리기 / S+A/D: 낮은 자세 이동(120px/s)
Space: 점프 / S+Space: 일방향 발판에서 내려가기
J: 현재 무기의 콤보(맨손은 없음). 공중에서 도끼 4타 또는 지팡이 3타.
공격 중 반대 방향+A/D+J: 즉시 방향을 바꿔 다음 콤보. 공중 최대 2회.
히트스톱 중 방향 캔슬은 0.12초까지 예약합니다.
K: 구르기·공격 캔슬. 누른 좌우 방향, 입력이 없으면 바라보는 방향.
사슬에 끌릴 때 0.15초 후 K: 탈출.
E: 가장 가까운 문/회복 픽업(+30HP)/지팡이/부모님/샴하트.
완전히 열린 대문 트리거에 들어가면 E 없이 이동합니다.
R: 태초부터 다시 시작 / F1: 피격·공격·감지 판정
F2: 괴수 인식 표식·접지 그림자 / F3: 구조물 표시 / F4: 충돌·이미지 윗면 비교
디버그 1: CastleF1/Spawn_Debug(x760), 2: VillaF1/Spawn_FromGate(x200).
디버그 이동은 페이드/문/효과음 없이 HP·무기·런 플래그를 보존합니다.
대화·시간 정지·씬 전환 중 디버그 키는 무시됩니다.

디버그 순간이동 삭제
scripts/debug_teleport.gd와 project.godot의 DebugTeleport autoload 한 줄을 삭제합니다.
일시적으로 끄려면 GameConstants.ENABLE_DEBUG_TELEPORT=false.
F4 비교는 GameConstants.DEBUG_SURFACE=false로 끕니다.

보존 수치
HP180 / 도끼20·20·20·22 / 이동360 / 점프-695 / 중력1750
표시 배율0.30 / 키363px×0.30≈109px / 서기36×124 / 수그리기36×90 / 구르기46×48
콤보 리셋0.8초 / 도끼 히트스톱0.05초 / 구르기 속도780
구르기0.48초=선딜0.03+무적0.25+후딜0.20. 사망 후 1.6초 뒤 집으로 복귀.
지팡이 길이0.28/0.28/0.40초, 히트스톱0.03초, 충격파 없음.
Main의 플레이어 하나를 유지해 일반 문 이동 중 HP·무기·축복이 보존됩니다.

레벨 연결
NimrodHome ↔ HomeRoad ↔ DowntownPassage_F1 ↔ … ↔ F8 ↔ CastleOutskirts
CastleOutskirts ↔(대문)↔ CastleFront ↔ CastleF1 ↔ RearGate
CastleF1 ↔ CastleF2 ↔ CastleF3 ↔ CastleF4 ↔ CastleF5
RearGate ↔ VillaF1 ↔ VillaF2 ↔ VillaF3
VillaF1(후문) ↔ VillaBackyard ↔ CedarForest_F1 ↔ CedarForest_F2 ↔ CedarBossRoom
삼나무 숲은 이전 사용자 결정대로 4열×5행,20개 방이며 최단 경로16개 방입니다.
1층 파수꾼12·무두 해골4, 2층 사수8·부유령8·네 팔 마귀7.
숲 괴수는 토사물5% 드랍. 보스와 소환 사수는 드랍하지 않습니다.
보스 HP1200, 50% 이하 2페이즈. 최종 전체 스토리 엔딩은 아직 연결하지 않았습니다.

가독성과 구조물
NPC 이름표, 의상 대비/림라이트/빛 웅덩이/그림자/배경 톤 다운/근접 하이라이트 유지.
통로 9종은 원래1.5배(6단계3배의 절반), 범위효과1.3배, 감지1.2배(최대900).
일반 우루크 두 종의 몸체/배율 및 비행 괴수의 기존 배율은 보존했습니다.
숲 해골은 NPC와 비슷한 키, 대형 무두 해골1.6배, 보스2.6배입니다.
이미지 알파 윗면과 충돌·SurfaceAccent를 연결하고 구조물312개를 ±4px로 검사합니다.
모든 발판은 일방향이며, 56px 이하 지면 단차 자동 오르기/모서리 보정/끼임 복구를 적용했습니다.
화면 하단 바위·풀 foreground 장식은 없으며 지면 아래는 타일로 채웁니다.
샴하트: “네가 자꾸 신경쓰여.” 이후 공격력/공격속도/최대HP+50%, 런당 한 번.

에셋과 검증
아트는 이미지 생성 도구의 PNG/WebP입니다. 코드 아트는 없으며 UI 보조·디버그만 그립니다.
괴수16종167클립, 맨손14/지팡이17클립과 FX14클립을 새로 생성하고 QA했습니다.
무손실 트림+투명 WebP, 불투명 배경은 색차 검사 후 품질90 WebP, 정밀 타일/UI는 PNG.
알파 또는 색차 검사에 실패한 배경은 원래 PNG를 유지합니다. 오디오는 OGG Vorbis입니다.
원본/이전 시트/디자인 시트/WAV는 cloud workspace archive/에 보관합니다.
archive/.gdignore로 엔진에서 제외하며 archive/, 접촉 시트/GIF는 GitHub·다운로드 ZIP에 없습니다.
런타임 시트로 접촉 시트·GIF를 다시 만들 수 있습니다. 원본 재패킹은 archive/가 필요합니다.

개발 도구
Python 의존성: requirements-tools.txt(Pillow/numpy/scipy/fontTools), 오디오: ffmpeg/ffprobe.
GODOT_BIN은 Godot4.3 실행 파일 경로. Linux cloud는 /workspace/tools/godot43.
python tools/run_headless_checks.py : 전체 임포트·54스크립트·32테스트(로그 오류/경고 하나도 실패).
python tools/validate_assets.py
python tools/check_sprite_parity.py
python tools/check_alpha_cleanliness.py
python tools/check_enemy_visual_bounds.py
python tools/check_surface_alignment.py
python tools/check_level_reachability.py
python tools/check_enemy_clearance.py
python tools/review_sprite_sheets.py assets/sprites/player/staff/manifest.json
패킹: slice_strip/pack_sprites → pack_enemy_sprites/pack_player_weapons → QA → trim_sheets
→ convert_images_webp (--dry-run 후 --apply). 기존 클립 길이·앵커·프레임 수를 보존합니다.
python tools/make_slim_zip.py --verify : archive·캐시 등을 제외하고 새 폴더에 풀어 전체 검사.
현재 무손실 규칙을 유지한 패키지는 용량 목표120MB를 넘습니다. SIZE_REPORT_KO.md 참조.
수정/가정/QA/미실행 범위: docs/STAGE7_REPORT_KO.md, SPRITE_QA_REPORT_KO.md,
SIZE_REPORT_KO.md, STAGE7_FILES_KO.txt. 최종 검사 결과는 보고서에 기록합니다.
