NIMROD — 5단계: 방향 공격 캔슬·인간형 구르기·도심 통로8층·집 가는 길
Godot 4.3 / GDScript / GL Compatibility / 1280x720 / 외부 애드온 없음

실행
ZIP 전체를 새 폴더에 압축 해제하고 Godot 4.3에서 project.godot을 가져옵니다.
최초 이미지·음원 임포트가 끝나면 F5로 실행합니다. 게임에는 Python이 필요하지
않습니다. Windows용 PLAY_WITH_GODOT.bat는 보존했습니다.
현재 20개 레벨. 대화·스토리 분기·최종 엔딩은 후속 작업입니다.

조작
A/D 또는 좌우 화살표: 이동 / S: 수그리기 / S+A/D: 수그린 채 이동120px/s
Space: 점프 / S+Space: 일방향 발판에서 내려가기
J: 도끼4연격 / 공중J: 4타 내려찍기
공격 중 반대 방향+A/D를 누른 채 J: 즉시 방향 전환 후 다음 콤보.
  공중 방향 캔슬 최대2회. 히트스톱 중 입력은0.12초까지 예약.
사슬에 끌릴 때0.15초 후 K: 구르기로 탈출(좌우 입력 방향 적용).
K: 구르기·공격 캔슬. 좌우 입력 방향, 입력이 없으면 바라보는 방향.
E: 가까운 문 / 토사물 섭취(+30HP, 최대180). NPC 대화 없음.
완전히 열린 대문 입구에 걸어 들어가면 E 없이 자동 이동합니다.
F1: 플레이어·괴수 판정/감지 범위 / R: 태초부터 다시 시작

보존 수치
HP180 / 도끼20,20,20,22 / 이동360 / 점프-695 / 중력1750
플레이어 배율0.30, 서기36x124, 수그리기36x90, 구르기46x48
콤보 리셋0.8초 / 히트스톱0.05초
구르기0.48초 = 선딜0.03 + 무적0.25 + 후딜0.20
사망1.6초 뒤 진행 플래그 초기화, HP180, RearGate 시작점x260으로 복귀.
플레이어는 Main에 하나만 있으며 층 이동 중 HP·전투 상태를 유지합니다.

레벨 연결
RearGate ↔ CastleF1 ↔ CastleFront ↔(대문 포탈)↔ CastleOutskirts
CastleF1 ↔ CastleF2 ↔ CastleF3 ↔ CastleF4 ↔ CastleF5
RearGate ↔ VillaF1 ↔ VillaF2 ↔ VillaF3

RearGate: 너비5400. 왼쪽 후문→루갈성1층, 오른쪽 별장 대문→별장1층.
  x<=350, x>=4950 안전 구역. 기존 괴수·지형 유지.
CastleF1: 루갈반다·닌순, 왼쪽 정문→성 안쪽 앞뜰, 위층 문·후문 유지.
CastleF2: 샴하트. CastleF3: 요리사3명. CastleF4: 인안나·여성 팝수칼.
CastleF5: 옥상 비행 괴수. 1~4층에는 괴수가 없습니다.
CastleFront: 너비2600, 전체 안전. 대문x600, 안쪽 문지기x880,
  정문x2200→CastleF1. 괴수와 도심 통로는 별도 황무지로 이동했습니다.
CastleOutskirts: 너비10000. 대문x9600↔CastleFront, 도심 문x520→DowntownPassage_F8.
  9080px 길에 광장·계단·협곡 위아래 두 길·폐허2단 통로·잔해·테라스.
  근접10·원거리5마리, x>=8850 안전. 협곡에도 바닥이 있습니다.
VillaF1: 하인x520/1480, 중앙x1000 문→2층, 오른쪽x1850 후문은 잠김.
VillaF2: 너비2200. 재사용 요리사4명, 넓은 식탁, 오른쪽 문→3층.
VillaF3: 샤마쉬·아야. 왼쪽 문→2층, 위층 문은 잠김.

문·대문
일반 문: E→열림0.6초→걸어 들어가기0.4초→페이드 각0.25초.
도착 문은 열린 상태로 시작해 한 걸음 나온 뒤 닫힙니다.
성 대문: 300px 접근→안쪽 문지기3번째 프레임→열림1.2초.
  대문 밖에서는 문지기 없이 열림. 열린 입구±40px에서 자동 이동.
  600px 이탈→닫힘1.0초. 닫힌 문에는 충돌 벽이 있습니다.
  도착 직후 재개방 방지를 위해 접근 범위에서 벗어난 후 재감지합니다.
별장 대문: 기존 열림1.0초·닫힘0.8초·자동 VillaF1 이동 유지.
잠긴 집 정문/별장 후문/별장4층 문은 메시지만 표시합니다.

니므롯 모션
이미지 생성한 새18종 시트 적용. 서 있는 키363px, 프레임640x640,
발 앵커[320,600], 8px 이상 여백. 기존 시트는 assets/sprites/_legacy_player/.
이 폴더는 .gdignore로 제외되며 필요 없으면 폴더째 삭제해도 됩니다.
기존 공격 길이0.33/0.33/0.40/0.56초 유지. 4타7프레임0.34초 시작.
5단계에서 구르기만 인간의 어깨 구르기12프레임으로 교체했습니다.
프레임당0.04초, 총0.48초. 머리·몸통·팔다리가 구분되는 접지 모션.
이전 구르기: assets/sprites/_legacy_player/roll_prev.png. 다른17개 시트 유지.
docs/motion_review/에18개 GIF·18개 접촉 시트가 있습니다.
F1 판정과 넓은3타 이미지의 도달 범위 차이는 보고서를 참고하세요.

NPC
왕족·호위7명은 좌/정면/우: |dx|<=140 정면, >=220 측면,
중간은 현재 방향 유지, 재전환 유예0.5초, 크로스페이드0.12초.
700px 이상 멀어지면4~8초마다 정면과 초기 측면을 오가며 둘러봅니다.
루갈반다·닌순은 서로 보는 방향으로 시작. 토인·문지기는 기존 좌우 방식.
이전 대화에서 생성한5명 디자인의 정면을 그대로 재사용했습니다.
인안나는 기존3번 은빛 라벤더 디자인, 팝수칼은 여성 호위입니다.
샤마쉬·아야는 황금빛 머리와 현대 실용 코트로 새로 생성했습니다.
모든 NPC 이름표는 발 아래 독립 노드라 뒤집히지 않습니다.
가독성5종: 의상 대비·내부 림라이트·생성 빛 웅덩이/접지 그림자·
  배경만 톤다운·220px 근접 밝기1.12/이름 알파1.0(0.15초).
토인 표시 배율0.39(기존×1.30) 유지. 이름표 외곽선 없이 그림자 사용.
재사용 토인7곳의 평균 배경 대비 경고와 권고는 보고서에 있습니다.

아트·오디오
인물·배경·지형·문·소품은 이미지 생성 PNG. _draw는 F1 디버그 전용.
바위·풀 Foreground를 모든 레벨에서 제거했고 생성 underground_fill
타일을 카메라 하단까지 반복해 지면 아래를 채웁니다.
누락 이미지는 회색 MISSING_TEXTURE+MISSING 라벨만 사용. 현재 누락0.
프롬프트: assets/image_prompts/stage4_*.md, stage5_*.md
원본·요청·패킹: assets/source_art/stage4/, stage5/
BGM: 후문uruk_rear_gate, 실내성castle_hall, 옥상uruk_sky,
  앞뜰castle_front, 황무지uruk_wasteland, 별장 전층villa_calm,
  도심 통로 전층passage_descent, 집 가는 길uruk_home_road.
새 곡48초 루프, WAV44100Hz/모노/16bit. BGM -10dB / SFX 0dB.
기존 음원 유지. 새 효과음48종과 BGM2곡 추가.
기존 맵 드랍 유지; 통로1~3층은 폭발 투사체만7%, 4~8층은 전체5%.

데이터
levels.json: 20레벨·지형·스폰·문·NPC·안전구역·카메라
npcs.json: 3방향·키·클립·가독성; 재사용 토인의 원본 키 기준359px 보존
player_visuals.json: 키363·프레임·앵커·18종 규격
player_attacks.json / enemies.json: 전투
interactions.json / transitions.json: 문·대문·페이드·HUD
audio_stage4.json: 황무지 BGM 합성; audio_stage5.json: 신규 오디오
passage_floors.json: 층별4종 창 구성; stage5_fx.json: 이미지FX

검사 (프로젝트 루트, Godot4.3)
python -m pip install -r requirements-tools.txt
godot --headless --editor --path . --quit
python tools/run_tests.py --godot godot --report docs/STAGE5_TEST_RESULTS.json
python tools/validate_assets.py
python tools/check_player_scale.py
python tools/check_level_reachability.py
python tools/check_player_motion.py

5단계 연결과 지역
CastleOutskirts(도심 문x520) ↔ DowntownPassage_F8 ↔ F7 ↔ … ↔ F1
  ↔ HomeRoad(통로 출구x10400) … 집 정문x400(아직 들어갈 수 없다).
통로8개 층은 모두 너비3600, 실내 floor_y620. 오른쪽→왼쪽 진행.
층별: 로비·계단 홀·3단 캣워크·심연 교량·기계 지주 숲·돌진 회랑·
  저천장 수그리기 터널·수직 통로. 위층으로 되돌아갈 수도 있습니다.
HomeRoad 너비10800, 출구→집 정문 거리10000px. 주거지·수로·시장·
  언덕·고가 도로·정원 등8구간, 기존 근접14/원거리8만 배치.
  x<=900 안전, x>=10000 괴수 스폰 없음. 집 문은 잠김.
천장100px 터널을 통과하도록 수그린 채 이동120px/s를 추가했습니다.

신규 괴수
폭발 투사체(HP76): 직격7→목표 도착0.3초 뒤 폭발14.
벽면 강하(36): 천장/벽 매복→급강하→지상 추격.
뿌리 화염(55): 위쪽10틱 피해. 선딜/방사 중 도끼로 공격 취소.
돌진(110): 슈퍼아머 돌진, 벽에 부딪치면0.8초 기절.
독가스 주머니(40): 죽은 뒤1초 팽창→2초 가스,0.2초마다1 피해.
환령(18): 지형 관통 추적. 도끼1타에 사망.
방어 갑피(75): 정면 공격·충격파 가드, 뒤쪽 공격 유효.
자폭 시체(30): 감지 후1.5초 또는 HP0에 폭발18.
사슬 수인(160): 꼬리10, 끌어당긴 뒤 찍기16. K 탈출 가능.
가드는 피해·히트스톱 없이 PNG 스파크/효과음/플레이어50px 후퇴.
화염·가스 중첩은 다른 소스의 같은 틱 그룹을0.2초마다 제한합니다.

검증 결과
Godot4.3 테스트15개·1081검사 통과. PNG281개 누락0·오류0.
플레이어 크기301검사, 지형 규칙438검사, 오디오154검사 통과.
통로8층과 HomeRoad를 실제 플레이어로 양방향 이동한18검사 포함.
기존 재사용 토인 평균 대비 경고7개는 실패가 아니며 보고서에 명시.
렌더 스크린샷30장+구르기 접촉 시트1장; roll.gif 미리보기 제공.
전체 파일: docs/STAGE5_FILES_KO.txt
구현·수치·아트·가정·한계: docs/STAGE5_REPORT_KO.md
테스트: docs/STAGE5_TEST_RESULTS.json
세부 판정·속도·좌표: docs/STAGE5_NUMERICAL_SPEC_KO.json
PNG 보존 비교: docs/STAGE5_PLAYER_PNG_HASHES.json
재생성: tools/ART_PIPELINE_KO.md, tools/build_stage5_assets.py,
  tools/build_passage_backgrounds.py (보관한 생성 원본으로 재합성).
추가 검사: python tools/check_stage5_audio.py
현재 모든 필수 이미지 생성 완료; 미생성 에셋 없음.
Windows 실행·실제 스피커 청감·장시간 사람의 직접 전투 플레이는 미실행.
