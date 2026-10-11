NIMROD — 6단계: 괴수 확대·가독성·집 내부·샴하트의 축복·삼나무 숲과 보스
Godot4.3 / GDScript / GL Compatibility / 1280x720 / 외부 애드온 없음

실행
ZIP 전체를 새 폴더에 압축 해제하고 Godot4.3에서 project.godot을 가져옵니다.
최초 PNG·WAV 임포트를 마친 뒤 F5로 실행합니다. 게임 실행에는 Python이
필요하지 않습니다. Windows용 PLAY_WITH_GODOT.bat도 포함되어 있습니다.
현재25개 레벨. 최종 스토리 엔딩·세이브포인트·멜람무 보상은 후속 작업입니다.

조작
A/D 또는 좌우 화살표: 이동 / S: 수그리기 / S+A/D: 수그린 채 이동120px/s
Space: 점프 / S+Space: 일방향 발판에서 내려가기(숲의 막힌 방 바닥은 통과 불가)
J: 도끼4연격 / 공중J: 4타 내려찍기
공격 중 반대 방향키+J: 즉시 방향 전환 후 다음 콤보. 공중 최대2회.
히트스톱 중 방향 캔슬 입력은0.12초까지 예약합니다.
K: 구르기·공격 캔슬. 좌우 입력 방향, 입력이 없으면 현재 바라보는 방향.
사슬에 끌릴 때0.15초 후 K: 구르기로 탈출.
E: 가장 가까운 문·포탈 / 토사물(+30HP) / 루갈성2층 샴하트의 축복.
완전히 열린 대문 입구에 걸어 들어가면 E 없이 자동으로 이동합니다.
F1: 공격·피격·감지 판정 / F2: 괴수 ▼ 표식·접지 그림자 / F3: 충돌 면 표시
R: 태초부터 다시 시작(축복·이번 런의 첫 대화 플래그 초기화)

보존 수치
기본 HP180 / 도끼20,20,20,22 / 이동360 / 점프-695 / 중력1750
플레이어 배율0.30 / 서기36x124 / 수그리기36x90 / 구르기46x48
콤보 리셋0.8초 / 히트스톱0.05초 / 구르기 속도780
구르기0.48초 = 선딜0.03 + 무적0.25 + 후딜0.20
사망1.6초 뒤 HP180, RearGate/Spawn_Start(x260)으로 복귀합니다.
Main의 플레이어 하나를 유지하며 층 이동 중 HP와 축복이 보존됩니다.

레벨 연결
RearGate ↔ CastleF1 ↔ CastleFront ↔(대문)↔ CastleOutskirts
CastleF1 ↔ CastleF2 ↔ CastleF3 ↔ CastleF4 ↔ CastleF5
CastleOutskirts ↔ DowntownPassage_F8 ↔ F7 ↔ … ↔ F1 ↔ HomeRoad ↔ NimrodHome
RearGate ↔ VillaF1 ↔ VillaF2 ↔ VillaF3
VillaF1(후문) ↔ VillaBackyard ↔ CedarForest_F1 ↔ CedarForest_F2 ↔ CedarBossRoom
별장 뒤뜰은 전체 안전 구역이며 후문x300에서 숲 포탈x700까지400px입니다.
집 내부는 괴수가 없는 안전 구역이고 엔키두아는 이름표·3방향 숨쉬기만 합니다.
다른 일반 NPC는 상호작용·대화가 없습니다.

샴하트의 축복
루갈성2층 샴하트에게120px 이내에서 E를 누르면 시간이 정지하고 카메라가
1.6배로 줌인합니다. “당신이 자꾸 신경쓰여요.”가 자동으로 표시된 뒤 돌아옵니다.
공격력·공격속도·최대 HP 각각+50%: 도끼30/30/30/33, 최대HP270, 현재HP+90.
한 런에 한 번, 사망 전까지 유지됩니다. 공격속도 합산 상한은2배입니다.
구르기·이동·콤보 리셋 실제 시간은 바뀌지 않습니다.

괴수와 구조물 표시
5단계 괴수9종의 스프라이트·몸체·근접 판정은3배, 폭발·가스 반경은2배,
감지·선호 거리·센서는1.5배(최대1100)입니다. HP·피해·속도·시간은 보존합니다.
일반 우루크 괴수와 비행 괴수는 확대하지 않습니다.
모든 괴수 머리 위 진홍색 ▼가 선딜 때 밝아지고 발밑에 적갈색 그림자가 보입니다.
바닥·단차는 따뜻한 윗면 빛, 일방향 발판은 청백색 점선으로 구분합니다.
코드로 그리는 것은 이 UI 보조 표시와 디버그 판정·말풍선 꼬리뿐입니다.
모든 캐릭터·문·배경·지형·FX는 생성한 PNG를 사용합니다.

삼나무 숲
사용자 결정에 따라4열×5행,20개 방(4800×3400)으로 확장했습니다.
두 층 모두 최단 경로16개 방, 갈림길4곳, 막다른 길4곳, 회복 픽업2개입니다.
수직 발판 체인은80px 높이차·수평200px 이하입니다. 방 바닥은 연결된 곳만
구멍이 있어 막힌 층으로 S+Space를 사용해 우회할 수 없습니다.
1층: 파수꾼7·무두 해골3. 2층: 사수5·부유령5·네 팔 마귀4.
모든 숲 괴수는 토사물5% 드랍. 보스와 소환 사수는 드랍하지 않습니다.

칼라-우쉬움갈
HP1200. x450부터 전투 시작, 도착 문 잠금과 보스 HP 바 표시.
정면 상체 갑피는 피해0.7배, 하체·등 뒤는 정상 피해. 일반 경직 면역.
횡치기2타·대지 찍기와 가시3개·양 끝 사수2마리 소환.
HP600 이하에서2초 무적 전환 후 공격 속도+20%, 회전 지연0.5초.
화염 포효는14틱×2=28 피해. 구르기 무적으로 틱을 피할 수 있습니다.
HP0 뒤에도1초 붕괴 →0.8초 예고 → 마지막 참수도 일격30피해가 남습니다.
일격 종료 뒤 문이 열리고5줄의 발화가 시간 정지 없이 자동으로 이어집니다.

검증·아트 주의점
검증 결과와 변경 파일 전체 목록: docs/STAGE6_REPORT_KO.md, STAGE6_FILES_KO.txt.
기존 확대 에셋 일부는 그림 크기와 몸체 판정 차이가 남습니다. 상세 수치와
NPC 대비 경고를 보고서에 기록했습니다. 생성 아틀라스의 일부 공격 프레임은
확대 시 흐림·크기 흔들림이 있어 고해상도 재제작과 수동 모션 검토를 권장합니다.
게임 진행 검증은 자동 테스트와 Linux Compatibility 렌더러에서 수행했습니다.
Windows 입력 장치·장시간 전투 밸런스·완전한 수동 클리어는 별도 확인이 필요합니다.

개발 도구(Python3 + Pillow + numpy 필요)
python tools/validate_assets.py
python tools/check_enemy_clips.py
python tools/check_enemy_clearance.py
python tools/check_enemy_visual_bounds.py
python tools/check_ground_contact.py
python tools/check_level_reachability.py
Godot4.3 --headless --path . --script tests/stage6_boss.gd 등 tests/*.gd 실행.
렌더 캡처: DISPLAY=:99 godot --path . --audio-driver Dummy --script tests/render_stage6.gd
생성 원본: assets/source_art/stage6/, 생성 프롬프트: assets/image_prompts/stage6_*.md.
재패킹: python tools/build_stage6_assets.py all (원본 PNG 사용, 아트를 코드로 만들지 않음).
레벨 재빌드: build_stage6_data.py → fit_stage6_clearance.py → finalize_stage6_layout.py
→ check_ground_contact.py --fix. 원본 자산을 삭제하면 재패킹할 수 없습니다.
BGM·효과음 재합성: make_bgm.py --stage6-only / make_sfx.py --stage6-only.
