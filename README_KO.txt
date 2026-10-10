NIMROD — 2단계: 루갈성 내부·별장·문 포탈·NPC·비행 괴수
Godot 4.3 / GDScript / GL Compatibility / 1280x720

기존 Nimrod_Godot_v7_1_Import_Fixed 기반 프로젝트의 조작과 전투 수치를
유지하며 확장했습니다. 현재 후문 밖, 루갈성 1~5층, 별장 1층 등
총 7개 레벨을 문으로 오갈 수 있습니다. 플레이어는 Main에 하나만 유지됩니다.
NPC 대화·별장 2층·스토리 분기·최종 엔딩은 후속 단계입니다.

실행
1. ZIP 전체를 새 폴더에 압축 해제합니다.
2. Godot 4.3 프로젝트 관리자에서 project.godot을 가져옵니다.
3. 최초 이미지·음원 임포트가 끝난 뒤 F5로 실행합니다.
4. 게임 실행에는 Python과 외부 애드온이 필요하지 않습니다.
   Windows에서는 기존 PLAY_WITH_GODOT.bat도 사용할 수 있습니다.

조작
A/D 또는 좌우 화살표: 이동
S: 수그리기
Space: 점프 / S+Space: 일방향 발판에서 내려가기
J: 도끼 4연격(입력 버퍼) / 공중 J: 4타 내려찍기
K: 구르기·공격 캔슬(선딜/활성/후딜 모두)
   누르고 있는 좌우 방향으로 구릅니다. 입력이 없으면 바라보는 방향입니다.
E: 가까운 문 이용 / 떨어진 토사물 섭취(+30 HP, 최대 HP 180)
   NPC는 대화하지 않습니다. 잠긴 문은 이유만 표시합니다.
   별장 대문은 완전히 열린 뒤 입구로 걸어 들어가면 자동으로 이동합니다.
F1: 플레이어·괴수 hurtbox/공격 판정/감지 범위 표시 또는 숨김
R: 진행 플래그를 초기화하고 HP 180으로 후문 시작점에서 다시 시작

보존한 수치
HP 180 / 도끼 20,20,20,22 / 콤보 리셋 0.8초 / 히트스톱 0.05초
구르기 0.48초 = 선딜 0.03 + 무적 0.25 + 후딜 0.20
일반 피격 경직·유예 0.45초 / 사망 후 1.6초에 태초부터 재시작
원본 플레이어 이동·점프와 플레이어 PNG 18개를 유지했습니다.

탐험 경로
- RearGate: 폭 5400. x=150 후문에서 E를 누르면 루갈성 1층으로 이동.
  기존 전투 구간 오른쪽에 근접 2마리·원거리 1마리, 단차·발판을 추가.
  x<=350, x>=4950은 괴수가 추적하거나 넉백으로 들어오지 못하는 안전 구역.
- CastleF1: 루갈반다·닌순. x=1450 문은 2층, x=1850 문은 후문 밖.
  x=150 정문은 잠겨 있으며 "정문은 지금 닫혀 있다"를 표시.
- CastleF2: 샴하트가 있는 제의실.
- CastleF3: 칼질·솥 젓기·음식 차리기를 하는 토인 요리사 3명.
- CastleF4: 인안나와 그 왼쪽 앞을 지키는 팝수칼.
- CastleF5: 비행 괴수가 있는 옥상 테라스. 왼쪽 문으로 4층에 복귀.
- VillaF1: 후문 밖 x=5200 대문으로 입장. 토인 하인 2명이 청소.
  왼쪽 문으로 후문 밖에 복귀하며 오른쪽 2층 문은 "아직 갈 수 없다"를 표시.

문과 진행
- 문 가까이에서 이미지 E 프롬프트를 표시하고, 가장 가까운 문 하나만 입력 처리.
- 열림 0.6초 -> 걸어 들어가기 0.4초 -> 페이드아웃/인 각 0.25초.
- 도착 문은 열린 상태로 시작하며 0.3초 걸어 나온 뒤 0.5초 동안 닫힘.
- 이동 중 입력과 피해를 잠그고 HP·진행 중 행동·전투 타이머를 유지.
- 별장 대문 300px 안으로 접근하면 문지기 동작의 3번째 프레임에서
  대문이 1초 동안 열림. 완전히 열리면 입구 +/-40px에서 자동 이동.
  닫혀 있을 때는 충돌 벽이 있으며 600px 이상 멀어지면 0.8초 동안 닫힘.
- 사망 시 GameState.run_flags 초기화 후 RearGate/Spawn_Start(x=260) 복귀.
  first_time(key)는 같은 시도 안에서 첫 호출에만 true를 반환.
- 루갈성 1~4층은 같은 castle_hall BGM을 끊지 않고 이어 재생.

NPC와 비행 괴수
- NPC 11명은 충돌이 없으며, 모든 인물은 플레이어와 같은 배율 0.30 사용.
  왕족 5명은 숨쉬기, 요리사 3명은 서로 다른 작업, 하인 2명은 빗자루질.
  문지기는 대기와 문 열어 주기 클립을 사용.
- 시선을 따라가는 NPC는 좌우 120px를 넘었을 때 방향을 바꾸며 0.5초 유예.
  대화는 없고 interact(player) 빈 함수와 interacted 신호만 준비.
- 비행 괴수: HP 110, 급강하 피해 8, 선딜 0.4초, 속도 520px/s,
  활성 최대 0.9초, 후딜 0.6초, 회전 0.25초, 쿨다운 1.2초.
  목표 위치를 고정해 돌진하며 한 번의 돌진에는 한 번만 피해.
  도끼 타격 시 0.25초 경직, 지상 괴수 넉백의 40%, 선딜·돌진 취소.
  4연격 82 + 다음 1·2타 40 = 총 6타로 처치.
  5% 확률로 토사물을 떨어뜨리며 E로 HP 30 회복.

데이터
- data/levels.json: 7개 레벨, 배경·카메라·스폰·문·NPC·안전 구역·지형.
- data/enemies.json: 지상 괴수와 비행 괴수의 스탯·공격·비행·드랍 수치.
- data/player_attacks.json: 기존 도끼·충격파 수치와 판정 타이밍.
- data/npcs.json: 인물 11명의 키 비율·클립·시선·공통 배율.
- data/interactions.json: 문 크기·열림·걷기·잠김·대문·E 이미지 설정.
- data/transitions.json: 시작 레벨·페이드·토스트·HUD.
- data/pickups.json: 회복 아이템 이름·수치·판정·PNG 경로.
- data/audio_stage2.json: 문·비행 괴수 효과음 9종과 BGM 3곡의 합성 설정.

아트와 오디오
배경·지형·문·괴수·NPC는 이미지 생성 PNG를 사용합니다.
_draw는 F1 디버그 판정용이며 월드 그림을 코드로 그리지 않습니다.
누락 이미지는 회색 MISSING_TEXTURE 상자와 MISSING 라벨로만 표시합니다.
마젠타 원본은 크로마키 처리 후 앵커를 맞춰 한 줄 시트로 합성합니다.
NPC 숨쉬기만 생성 정지 이미지에서 허용된 미세 변형으로 6프레임을 파생합니다.
요리·청소·문지기 동작과 비행 괴수·문은 생성된 여러 포즈를 사용합니다.
assets/image_prompts/는 생성 프롬프트, assets/source_art/는 생성 원본과 기록입니다.
이번 명세에 따라 폭 5400용 후문 전경을 새로 제작했습니다.
앞서 삭제한 전경 원본을 되살리는 작업은 아닙니다.

BGM: RearGate=uruk_rear_gate, CastleF1~4=castle_hall,
CastleF5=uruk_sky, VillaF1=villa_calm. 새 곡은 각 48초 반복입니다.
효과음은 WAV 44100Hz·모노·16bit로 합성합니다. 동일 경로에 덮어써 교체할 수 있습니다.
BGM 버스 -10dB / SFX 버스 0dB. 기존 jump.wav는 audio/legacy/에 보존했습니다.

도구 (개발·재생성·검사 시에만 Python 필요)
python -m pip install -r requirements-tools.txt
python tools/make_jump_sfx.py
python tools/make_sfx.py
python tools/make_bgm.py
python tools/build_stage2_character_assets.py
python tools/build_stage2_environment_assets.py
python tools/validate_assets.py
아트 재생성 명령과 원본 기록은 tools/ART_PIPELINE_KO.md를 참고하세요.

자동 검사 (프로젝트 루트, Godot 4.3 사용)
godot --headless --editor --path . --quit
python tools/validate_assets.py
godot --headless --path . --script res://tests/regression.gd
godot --headless --path . --script res://tests/stage2_transitions.gd
godot --headless --path . --script res://tests/stage2_interactions.gd
godot --headless --path . --script res://tests/stage2_sky.gd

현재 기능 검사: 기존 회귀 196, 전환 210, NPC·문 41, 비행 괴수 66개,
합계 513개 통과. 최종 아트 검증·화면·배포 ZIP 결과는
아래 2단계 보고서에 기록합니다.
실제 스피커 청감, Windows 실행, 장시간 사람의 직접 플레이는 별도 확인이 필요합니다.

전체 변경 영역·선택 수치·이미지 상태·검증·미실행 항목:
docs/STAGE2_REPORT_KO.md
1단계 이력: docs/IMPLEMENTATION_REPORT_KO.md
