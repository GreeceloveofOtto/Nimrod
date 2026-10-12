NIMROD — 8단계: 끼임·접지·이미지 수정·스토리 대화·용량 절감
Godot 4.3 stable / GDScript / GL Compatibility / 1280×720 / 외부 애드온 없음

실행
ZIP 가져오기 오류 수정본: Nimrod_stage8_import_fixed_2026-10-11.zip.
Godot 프로젝트 관리자의 ZIP 가져오기에 필요한 폴더 항목을 포함합니다.
권장: 탐색기에서 ZIP 전체를 새 폴더에 풀고 Nimrod/project.godot을 선택합니다.
이전에 가져오기에 실패한 불완전한 폴더에는 덮어쓰지 말고 새 폴더를 사용합니다.
압축을 새 폴더에 모두 풀고 Godot 4.3으로 project.godot을 가져온 뒤 F5를 누릅니다.
PNG/WebP/OGG의 첫 임포트가 끝날 때까지 기다립니다. 실행에는 Python이 필요 없습니다.
Windows: PLAY_WITH_GODOT.bat. 엔진을 못 찾으면 GODOT_BIN을 설정합니다.
현재 25개 레벨입니다. 전체 스토리 엔딩·세이브포인트·멜람무 보상은 후속 작업입니다.

시작과 무기 획득
새 게임·사망·F5·GameState.reset_run()은 모두 니므롯의 집 Spawn_Start(x330),
오른쪽을 보는 맨손으로 시작합니다. 맨손에서 J는 공격하지 않습니다.
집 선반 옆 x620의 삼나무 지팡이: 100px 이내 E → 지팡이 3타(18/18/24).
루갈성 1층 부모님 둘 중심에서 140px 이내 E: 첫 대화 후 도끼를 받습니다.
도끼는 지팡이를 교체합니다. 이후 부모님 E는 닌순의 한 줄 인사이며 도끼는 다시 주지 않습니다.
모든 대화는 자동 진행하며 게임 시간을 완전히 멈춥니다.
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
F5: 태초부터 다시 시작 / F1: 피격·공격·감지 판정
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
샴하트: 첫 대화5줄은 버프 없음. 두 번째 “네가 자꾸 신경쓰여.” 이후 공격력/공격속도/최대HP+50%, 런당 한 번. 축복 후 E 숨김.

에셋과 검증
아트는 이미지 생성 도구의 PNG/WebP입니다. 코드 아트는 없으며 UI 보조·디버그만 그립니다.
괴수16종167클립, 맨손14/지팡이17클립과 FX14클립을 새로 생성하고 QA했습니다.
8단계: 표시 크기에 맞춘 해상도 축소+트림+WebP. 알파 bbox 유지, 알파 평균오차≤1.5/255, 보이는 RGB 평균오차≤3/255. 정밀 타일/UI는 PNG 또는 무손실 WebP.
RGB 서브샘플링 오차가 큰 파일은 RGB의 손실을 제한하고 원래 알파를 복원한 WebP로 저장합니다. 원본은 archive/에 보존. 오디오는 OGG Vorbis입니다.
원본/이전 시트/디자인 시트/WAV는 cloud workspace archive/에 보관합니다.
archive/.gdignore로 엔진에서 제외하며 archive/, 접촉 시트/GIF는 GitHub·다운로드 ZIP에 없습니다.
런타임 시트로 접촉 시트·GIF를 다시 만들 수 있습니다. 원본 재패킹은 archive/가 필요합니다.

개발 도구
Python 의존성: requirements-tools.txt(Pillow/numpy/scipy/fontTools), 오디오: ffmpeg/ffprobe.
GODOT_BIN은 Godot4.3 실행 파일 경로. Linux cloud는 /workspace/tools/godot43.
python tools/run_headless_checks.py : 전체 임포트·59스크립트·48테스트(로그 오류/경고 하나도 실패).
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
8단계 용량 목표: assets≤75MiB, 슬림ZIP≤90MiB. 최종 실측은 docs/SIZE_REPORT_KO.md 참조.
수정/가정/QA/미실행 범위: docs/STAGE8_REPORT_KO.md, SPRITE_QA_REPORT_KO.md,
SIZE_REPORT_KO.md, STAGE8_FILES_KO.txt. 최종 검사 결과는 보고서에 기록합니다.

8단계 버그 수정과 대화
- 일방향 발판은 천장 검사에서 제외. 낮은 52px 발판 아래에서도 구르기 후 서기·점프가 가능합니다.
- 고체 천장은 그대로 막습니다. 구르기 종료 시 최대24px 뒤로 밀기 → 웅크린90px → 구르기48px 기어가기 순으로 복원합니다.
- 벽에 붙어도 0.8초/3px 이동 정체를 검사하고 실제 마지막 안전 위치로 복구합니다. 동일 안전 위치로의 무의미한 복구는 기록하지 않습니다.
- 삼나무 벽은 검은 배경 없는 껍질 이미지로 재생성. 7마귀 모두 실제 가지 발판과 줄기 소품 위에 배치합니다.
- 대화 중 게임 시간 완전 정지. 화면 우측 중앙 대화창과 발화자 이름 칩, 글자당0.04초 자동 진행.
- 엔키두아, 통로8층 혼잣말, 바깥 문지기, 부모님, 샴하트, 요리사cook_a, 인안나/팝수칼, 별장 문지기 대사 구현.
- 루갈성 바깥 대문과 별장 대문은 첫 대화 후 열림. 이후 접근 개방. 사망하면 대화 플래그 초기화.
- 대화 종료 후 E는0.2초 동안 무시. 1/2 순간이동은 진행된 대화 플래그 유지.
- tools/measure_assets.py, downscale_assets.py, check_enemy_grounding.py로 크기·저장밀도·접지를 점검합니다.
- 원본 재인코딩 검사는 archive/ 원본이 필요. ZIP은 원본을 제외하며 내장 픽셀 표본·런타임 검사로 독립 검증합니다.

[9단계: 스토리 진행과 두 번째 조사]
별장3층 샤마쉬·아야에게 E → 별장2층 식탁 x1220에서 E(앉기) → 삼나무 숲 칼라-우쉬움갈 첫 처치 → 밤의 별장3층 보고 → 성1층 귀환 대화/암전/기상 → 엔키두아/부모님 대화 → 별장3층 아누르 축복 → 숲 보스방 훔바바.
R: 아누르의 빛(획득 후, 쿨다운5초, 관통2명). F5: 집에서 처음부터(무기·버프·스킬·스토리 초기화). F6/F7: 다음/이전 스토리 단계 디버그; 1/2 순간이동 유지. 대화·컷신 중 단축키를 무시한다.
스토리 단계 0시작 /1별장 첫 대화 /2저녁식사 /3칼라 첫 처치(밤) /4보고 /5성 귀환·기상 /6엔키두아·부모님 /7아누르의 빛 /8훔바바 처치.
모든 대화는 게임을 멈추고 우측 중앙 대화창에서 화자 이름과 함께 자동 진행한다. 식사 컷신은 무기 보유 상태를 바꾸지 않고 표시만 숨겼다가 복구한다. 밤에 별장1층은 비고, 식탁은 준비 상태이며, 기상 뒤 밤이 해제된다.
9단계 대사·조건·전체 흐름: docs/STAGE9_STORY_FLOW_KO.md. 구현·검증·파일: docs/STAGE9_REPORT_KO.md. 용량·화질: docs/SIZE_REPORT_KO.md.
ZIP은 Godot 프로젝트 가져오기를 위해 모든 폴더 항목을 먼저 기록한다. Godot에서 ZIP 직접 가져오기를 하거나, 폴더에 전체 압축 해제 후 project.godot을 열 수 있다.

추가 요청: 삼나무 숲1·2층의 교체 줄기 벽30개는 이미지와 충돌을 삭제했습니다. 배경 숲과 마귀 가지 발판은 유지합니다. 상세 변경은 docs/STAGE9_REPORT_KO.md 참조.


[10단계 — 팔 상실, 귀환, 구갈안나와 딜문]
훔바바 첫 일격에서 왼팔을 잃고 한 팔 도끼 세트를 사용한다. 멜람무를 E로 삼켜야 보스방을 떠날 수 있다. 집의 엔키두아/인안나 대화와 시간 경과 후 집 밖에서 구갈안나를 만난다. 투구 획득 뒤 별장3층에서 의수를 착용하고4층 우주정을 타고 딜문으로 간다. 딜문은 이번 단계의 마지막 자유 이동 구역이다. 사망/F5는 모든 상태를 지우고 집에서 맨손으로 시작한다. R 아누르의 빛, F5 재시작, F6/F7 디버그 단계0~15, 1/2 순간이동은 유지한다. 대화·컷신 중에는 재시작과 디버그 입력이 막힌다.
루갈성 귀환 후 기상하는 시간 경과에서 현재 최대HP까지 완전히 회복한다. 고정HP 증가(멜람무20/투구15/의수30)는 비율 버프보다 먼저 계산한다. 의수는 공격력20%/속도10% 증가다. 투구는 이번에는 외형에 표시하지 않는다. 삭제한 삼나무 줄기 벽은 다시 넣지 않았다.
상세 단계·원문 대사: docs/STAGE10_STORY_FLOW_KO.md
변경·검증·제약: docs/STAGE10_REPORT_KO.md, docs/STAGE10_FILES_KO.txt
용량과 압축 품질: docs/SIZE_REPORT_KO.md
신규 검사: python tools/run_headless_checks.py --jobs 4
신규 콘텐츠 예산: python tools/measure_assets.py --stage10-budget
슬림 ZIP에는 archive/·캐시·개발 원본이 없으므로 이미지 재패킹에는 별도 보존 원본이 필요하다.


[11단계 추가]
L: 포식(딜문 도착 후, 전방180px·150 고정 피해·쿨다운15초). 폭주가12 증가한다.
샴하트 첫 대화 후 E: 대화/저장/폭주 완화 주문 메뉴. W/S·방향키 선택, E 확인, Esc 닫기.
치료는HP30을 지불하고 폭주11을 낮춘다. 폭주91이상은 사망한다.
대화 중 E: 현재 한 줄 넘기기. 자동 진행도 유지한다.
저장 후 다음 실행은 자동 재개하며 사망은 저장 위치에서 최대HP로 복귀한다. F5는 저장을 남긴 채 새 런.
Y: 개발용 HP 최소1 토글(표시 없음); 폭주 사망은 막지 못한다.
딜문 시마티 → 종이 전달 → 오른쪽 이동 구역 → 죽음의 바다. 우르샤나비·배의 상호작용은 다음 단계 대상.
투구 장착 뒤에는 투구 세트를 사용하며 폭주 단계에 따라 의수·투구 형태가 변한다.
자세한 보고: docs/STAGE11_REPORT_KO.md, STAGE11_STORY_FLOW_KO.md, STAGE11_SAVE_FORMAT_KO.md, SIZE_REPORT_KO.md.
