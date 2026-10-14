# 13단계 추가: 흐와니라의 영웅과 천륜의 단검

## 가정·재량 값 (맨 앞 요약)

- 키 비율: 라오다스타흐마 1.28, 투사 **1.22**, 바라자 1.18, 가에바니·파리부르즈 1.08, 구다르즈 1.02. “투사가 라오다스타흐마 다음으로 큼”을 우선해 제안표의 투사 1.15를 조정했다. 기준은 기존 363px 정규화 실루엣이며 표시 배율 0.30과 새 영웅의 visual_scale_multiplier1.0을 사용한다(플레이어 화면상 약109px).
- 좌표: 투사1560, 구다르즈1740, 라오다스타흐마2010, 가에바니2240, 파리부르즈2420, 바라자2600. 모두 y880. 최소 중심 간격180px이며 실루엣 사각형 비중첩을 검사한다.
- 배경 영웅5명은 idle4프레임/2.4초, 정면 시트 없이 좌우 flip. 라오다스타흐마는 idle6·idle_front6/2.4초, give_dagger4/.6초. 무기·발이 고정된 대기 자세로 재생성했다.
- 가려진 하체는 같은 갑주의 바지·금속 정강이 보호대·부츠로 설계했다. 구다르즈는 붉은 비늘 긴 상의/허리 검, 가에바니는 청금 겉옷, 파리부르즈는 상아·감청 하의, 투사·바라자·라오다스타흐마는 가죽 띠와 갑주를 유지한다. 막사·코끼리·배경 인물은 가져오지 않았다.
- 무기 이름 **천륜의 단검**. 비공격 때는 보이지 않고 기존 이동 시트를 그대로 사용한다. 2회차는 원문 4번째 줄 한 줄 반복, 자불리스탄 이동은 연결하지 않는다.
- 원문에 타별 수치 표가 없어 14/14/16/18/22(합84), 지속 .24/.24/.28/.30/.42초로 정했다. 파동20 포함104. 히트스톱.04, 파동 사거리160·넉백80·경직.15. 도끼의 콤보 유지.8초/공중 방향 캔슬2회는 그대로.
- 단검 전달 클립.6초 뒤 아이콘 이동.6초, 획득·조작 도움말 각각1.8초. 기존 발밑 광원을 손의 펄스/아이템 이동 광원으로 재사용한다. 공격 칼날 색은 생성 프레임+PIL 색보정으로 이동한다.

## 구현

6명 모두 이름표/기존 npc_light_pool/접지를 사용하고, 라오다스타흐마만 E120px 상호작용이 가능하다. 대화5줄은 원문 그대로이며 “자불리스탄이 가볼 수 있는”도 수정하지 않았다. 대화 중 시간정지·E넘기기·고정 창·활성 플레이어 이름 칩을 유지한다.

대화가 닫힌 뒤 `give_dagger`가 입력을 잠그고 전달 클립·아이콘 이동을 실행한다. 중복 실행 가드와 `dagger_acquired`가 있어 E 연타/반복 대화로 재지급되지 않는다. 자동 장착·스토리21·별도 캐릭터 체크포인트 저장 후 입력을 돌려준다.

`GameState.set_weapon`은 시야우와르샨의 무기를 `siyavash_progress.weapon`에 저장한다. 기존 `run_flags.weapon`과 니므롯의 의수/무기는 바꾸지 않는다. 저장 복원도 활성 캐릭터의 무기를 읽는다. 구 stage20 세이브는 무기 없음으로 복원된다. F6/F7에21단계, Shift+F9에 스승 앞 이동(20단계) 추가. F5의 저장 포함 완전 초기화는 유지한다.

`player_attacks.json`의 `shockwave_step`으로 4타/5타 후 파동을 선택한다. 단검 파동은 같은 적에게 5타와 별도 피해를 주되 도끼 전용 충격파 기믹은 발동하지 않는다. 공격5개만 새 `siyavash_dagger`에 있고 비공격17개는 manifest aliases로 기존 시트 경로를 사용한다. ResourceLoader의 동일 Texture2D 캐시를 테스트한다. 단검이 있어도 아누르/포식/폭주와 니므롯 HP 보정은 비활성이다.

## 수치와 생성 이미지

| NPC | 키 비율 | 위치 | 클립 |
|---|---:|---|---|
| 투사 | 1.22 | [1560, 880] | idle |
| 구다르즈 | 1.02 | [1740, 880] | idle |
| 라오다스타흐마 | 1.28 | [2010, 880] | idle, idle_front, give_dagger |
| 가에바니 | 1.08 | [2240, 880] | idle |
| 파리부르즈 | 1.08 | [2420, 880] | idle |
| 바라자 | 1.18 | [2600, 880] | idle |

| 타 | 피해 | 지속 | active | 넉백 | 전진 impulse | 판정(px) |
|---|---:|---:|---|---:|---:|---|
| 1 | 14 | 0.24 | 0.06~0.12 | 80 | 60 | {'offset_x': 6, 'top': -115, 'width': 65, 'height': 95} |
| 2 | 14 | 0.24 | 0.06~0.12 | 80 | 60 | {'offset_x': 6, 'top': -115, 'width': 68, 'height': 95} |
| 3 | 16 | 0.28 | 0.08~0.16 | 80 | 60 | {'offset_x': 6, 'top': -115, 'width': 82, 'height': 95} |
| 4 | 18 | 0.3 | 0.09~0.18 | 80 | 60 | {'offset_x': 6, 'top': -115, 'width': 75, 'height': 95} |
| 5 | 22 | 0.42 | 0.14~0.24 | 120 | 80 | {'offset_x': 6, 'top': -115, 'width': 78, 'height': 95} |

신규 생성: 영웅8시트(6명), 단검 공격5시트, 단검64×64아이콘1장. 각 영웅 기준 이미지6장 및 실패 후보/원본은 archive에 보관하고 실행 ZIP에서 제외한다. 이미지 생성 실패/미생성 목록: 없음. 코드로 스프라이트를 그리지 않았다. 새 캐릭터 이미지의 미세 장식은 밀도 상한 안에서 PIL 리샘플링으로 정규화했으며 원본도 보존했다.

재사용: 시야우와르샨17클립, 광장 배경·바닥·화로, E프롬프트·한국어 폰트, anur_light_projectile 파동, 기존 타격/충격파 효과음(공격 재생 피치1.25), npc_light_pool, 이름표·대화UI.

## 검증과 제한

- 전체 헤드리스: 179/179. 압축 해제한 배포본도179/179와12개 검증 명령이 모두 통과했다.
- 단검 통합92검사: 원문/스킵/1회지급/장착/플래그/지상5타/같은적22+20/넉백80/공중2회/별도저장/구세이브·니므롯 복귀.
- 전체 프레임495클립 오류0, 얼굴109프레임 오류0. 새13클립 오류0. 기존을 포함한 루프/모션 육안 참고 경고49개는 자동 실패 항목과 구분한다.
- 알파665이미지 오류0, 머리위/경계205클립 오류0. 인코딩·원본 대조659이미지/2762프레임 오류0(SSIM≥.93, RGB≤3/255, 알파≤.5/255, bbox동일).
- OpenGL 선형필터 atlas/단일셀 비교514회,885검사 차이0. 광장·공격 캡처6검사0실패. X11 드라이버 VSync 비지원 경고는 엔진 스크립트 경고와 별도로 남긴다.
- 에셋검증 missing0. 원시 NPC/배경 평균휘도 차이 참고 경고15개(기존9+신규6)는 광원·이름표/강조를 제외한 측정이다. 실제 화면에서 6명이 보이고 실루엣·접지가 유지됨을 확인했다.
- QA 이미지: `docs/plaza_dagger_review/plaza_heroes.png`, `dagger_attack_1~5.png`, `all_new_frames.jpg`. 실행 ZIP 제외, QA ZIP 포함. 표정·장식의 완전한 해부학적 동일성은 자동 수치 검사로 보장하지 않으며 접촉 시트의 육안 검토를 함께 사용했다.

## 완료 체크 (기능·용량 분리)

| 항목 | 결과 |
|---|---|
| 영웅6명 생성·참고 반영·배치 | ○ |
| 스승만 상호작용·대사5줄 원문 | ○ |
| 단검 전달·장착·5연타·5타 파동 | ○ |
| 공격5개 신규·17개 텍스처 재사용 | ○ |
| 별도 저장·구 세이브·F5 초기화 | ○ |
| 프레임·알파·머리위·접지·필터 QA | ○ |
| 전체 자동 테스트 | ○ (179/179, 독립 ZIP 재검증 별도 기록) |
| 신규1.7MiB 예산 | ○ |
| ZIP62MiB/확장60MiB | × (품질 게이트를 지키며 목표 미달) |

---

## 이전 13단계 구현 기록

# 13단계 시야우와르샨 외형 재제작 — 2026-10-14

가정·재량 값(이번 수정이 이전 외형 설명보다 우선한다):

- 귀는 작고 얇은 인간 귀를 기본으로 하며, 짧은 머리 사이로 보이는 쪽 상부와 둥근 귓바퀴 윤곽을 노출했다. 거대한 설치류 귀·꼬리·수염은 넣지 않았다.
- 앞니 노출은 hurt/death에만 지정했다. roll/land/drop_through도 입을 다물도록 정했다. hurt/death의 귀는 약간 뒤로 눕는 목표 포즈다.
- 미세 흉터는 목·손등·팔뚝 각 한 곳, 총 3곳을 생성 프롬프트에 지정했다. 매우 작은 게임 표시에서는 각 흉터의 수를 판독하기 어렵다.
- 튜닉은 허벅지 중간에서 끝나고 무릎을 덮지 않는다. 뒤로 늘어지는 천·망토·투구·장갑·무기는 없다. 가벼운 사슬·관절 보호대와 미세한 발광선을 사용했다.
- 머리는 귀를 덮고 위쪽 목덜미에서 끝나는 약한 굴곡의 청흑색, 이마는 노출한다. 회녹색 홍채와 눈 바깥 보랏빛 문양을 유지했다.
- 뺨 원본 코어 HSV 채도 하한은 평상시 185/255(0.725), hurt/death 210/255(0.824)로 정했다. 런타임 ROI 평균 하한은 0.42다. 마지막 death의 뺨 밝기는 190/255 이하로 내려 광택을 없앴다.
- 표기 변경 위치: data/siyavash.json, README_KO.txt, docs/STAGE13_REPORT_KO.md, docs/SPRITE_QA_REPORT_KO.md, tools/write_stage13_reports.py. scripts/dialogue_system.gd는 현재 캐릭터 표시 이름을 사용하게 했다. ID·폴더명 siyavash는 그대로다.

새 기준 시트를 먼저 생성해 17개 클립 109프레임을 모두 새로 그렸다. 이전 캐릭터를 리컬러하거나 수정한 시트는 사용하지 않았다. 재생성한 클립은 idle/walk/run/crouch_enter/crouch_idle/crouch_exit/jump_start/jump_rise/fall/land/roll/drop_through/hurt/death/sit_down/sit_idle/stand_up이다. 잘린 run, 얕은 crouch_idle, 반복되는 walk, 착지 자세가 섞인 fall은 새 이미지로 다시 생성했다.

생성 이미지의 크로마키는 배경과 연결된 마젠타만 제거해 장밋빛 뺨과 보랏빛 문양을 보존한다. 상태별 뺨 색과 생성 시 따뜻하게 변한 홍채는 PIL 색 보정으로 처리했으며, 홍채 보정은 눈 주변의 좁은 영역으로 제한했다. 런타임 modulate로 뺨의 상태 색을 바꾸지 않는다. 셀에는 물리적 2px 투명 테두리를 두고 기존 [320,600] 앵커를 유지한다.

프로젝트에서 363px는 canonical 시트의 몸 높이 기준이다. 기존 표시 배율 0.30에서 화면 몸 높이는 약 109px이며, 니므롯/unarmed와 같은 크기를 유지했다. 저장 해상도를 게임 표시 키로 혼동해 확대하지 않았다. HP100·맨손·이동·폭주 비활성·R/L 비활성·F5 초기화는 기존 로직을 유지한다. 새 이름의 ‘샨’ 글리프가 기존 폰트에 없어 Korean UI 폰트 서브셋을 갱신하고 실제 glyph 존재 테스트를 추가했다.

| 클립 | 프레임 | 길이(s) | 이전→새 밀도 | 이전→새 KiB |
|---|---:|---:|---:|---:|
| idle | 10 | 2.2 | 1.8→2.0 | 100.2→74.8 |
| walk | 10 | 1.05 | 1.6→1.6 | 98.7→84.8 |
| run | 10 | 0.82 | 1.8→1.6 | 95.2→91.9 |
| crouch_enter | 4 | 0.14 | 1.4→1.6 | 36.4→33.3 |
| crouch_idle | 6 | 0.8 | 1.6→2.0 | 49.7→53.8 |
| crouch_exit | 4 | 0.13 | 1.6→1.6 | 44.7→33.5 |
| jump_start | 4 | 0.13 | 1.2→1.6 | 45.0→27.9 |
| jump_rise | 6 | 0.42 | 1.6→1.6 | 61.2→38.1 |
| fall | 6 | 0.36 | 1.6→1.6 | 71.6→45.8 |
| land | 5 | 0.24 | 1.4→1.6 | 53.1→37.0 |
| drop_through | 5 | 0.22 | 1.4→1.6 | 49.1→40.9 |
| hurt | 5 | 0.32 | 1.6→2.0 | 63.8→67.2 |
| death | 8 | 0.6 | 1.0→2.0 | 39.9→78.1 |
| roll | 12 | 0.48 | 1.2→1.4 | 64.0→65.1 |
| sit_down | 4 | 0.35 | 1.4→1.6 | 30.3→26.7 |
| sit_idle | 6 | 2.0 | 1.8→1.8 | 45.1→36.0 |
| stand_up | 4 | 0.35 | 1.4→1.8 | 27.3→33.3 |

시트 합계 998,546→889,148 B (10.96% 감소). 모든 프레임 수·duration_seconds는 unarmed와 같고 공격 클립은 없다. 밀도는 0.8에서 시작해 SSIM≥0.93을 만족하는 값을 선택했다. idle/hurt/death는 눈·앞니 보존을 위해 2.0을 사용했다. run은 1.8→1.6으로 낮췄으며 일부 클립은 얼굴 보존/SSIM 기준 때문에 이전보다 높은 밀도가 필요했지만 전부 상한2.0 이내이고 전체 바이트 예산은 감소했다.

최종 추출 실행 ZIP: 헤드리스177/177(경고·오류0), 에셋·알파·도달성·프레임·얼굴·접지 등11개 명령 모두 종료코드0. 크기 목표 미달은 기능 실패와 별도로 기록한다.

변경 파일 전체: docs/STAGE13_SIYAVASH_FILES_KO.txt.

검증 및 한계:

- 신규 17클립: 오류0, sit_idle 루프 이음새 리뷰1. 전체482클립: 오류0, 기존 포함 리뷰48. 이는 GDScript 경고가 아니라 육안 검토 안내다. sit_idle의 미세 호흡·옷 변화는 유지했다.
- 얼굴109프레임: 오류0. 흐려진 뺨·평상시 입의 흰 픽셀·잘못된 부상 색을 넣은 QA fixture는 모두 거부됐다. 기존 idle 뺨 ROI 평균 채도0.457→0.562로 증가했다.
- 픽셀 검사는 HSV·영역·흰 하이라이트 검사다. 정확히 두 앞니인지, 귀의 아름다움이나 의상 의미는 자동으로 증명하지 않는다. 원본/저장 확대4장과 전체109프레임 접촉 시트로 별도 검수했다.
- 최종 OpenGL: 685 단언/398 비교, 실패0. 최신 atlas 크기·선형 필터·양옆 이웃 프레임 번짐을 비교했다. 광장 1.0/1.35 줌8캡처,8단언 실패0. X11 드라이버의 VSync 지원 경고1은 런타임 코드 경고와 분리한다.
- 알파651이미지·머리 위 잔상192클립·괴수 접지119스폰·크기23종·소품 접촉16검사: 실패0. 새 캐릭터 접지는 기존 collider와 발 앵커를 런타임에서 확인했다.
- 이미지 인코딩 parity646이미지/2704프레임: 실패0. SSIM≥0.93, RGB 평균≤3, alpha 평균≤0.5, 인코딩 bbox 불변을 확인했다.
- 미사용0·해시 중복0. crouch_idle/sit_idle 병합 후보는 SSIM0.985 기준과 절감 조건을 충족하지 않아 유지했고, idle의 시선 변화는 병합하지 않았다.167개 OGG는 모두 모노로 확인했다.

새 파일: data/gayomaretan_style.json, data/siyavash_face_qa.json, assets/image_prompts/gayomaretan_common.md, assets/image_prompts/siyavash_reference.md 및 17클립 프롬프트, tools/build_siyavash_redesign.py, tools/check_siyavash_face.py, tools/optimize_siyavash_delivery.py, tools/write_siyavash_review.py, tools/write_siyavash_reports.py, tests/stage13_siyavash_redesign.gd, tests/stage13_siyavash_look_capture.gd, docs/SIYAVASH_LOOK_KO.md. 저장/불러오기 ID는 변경하지 않았다.

이전 시트·기준 그림·실패 후보·변환 전 폰트·PNG 원본은 archive/siyavash_redesign_2026-10-14 및 archive/pack_source에 보존했다. archive/.gdignore와 배포 제외 규칙을 유지한다. 생성 불가/MISSING_TEXTURE 에셋은 없다.

| 완료 항목 | 결과 |
|---|---|
| 17클립 전체 재생성 | ○ |
| 코·귀·앞니·회녹색 눈(수동 검수 포함) | ○ |
| 뺨 강화/상태별 색/사망 광택 소멸 | ○ |
| 짧은 청흑색 머리 | ○ |
| 짧은 아베스타/SF 의상 | ○ |
| 날렵한 체형과 맨손 | ○ |
| 표기 전체 반영 및 폰트 glyph | ○ |
| 공통 종족 데이터·프롬프트 | ○ |
| 기존 게임 규칙 유지 | ○ |
| 전체 테스트·추출 패키지 검증 | ○ |
| 교체 시트 기존 바이트 예산 | ○ |
| ZIP62/60MiB 목표 | × |

---

이전13단계 구현 기록(외형·용량은 위 최신 수치를 따른다):

# NIMROD 13단계 보고서

## 가정·재량 값 요약

- `home_11days` 직후에는 임종 전 마지막 대화를 유지한다. `enkidua_gone` 이후에는 어느 시간 경과·저장 복원에서도 엔키두아가 없고 침대 피 흔적은 계속 남는다.
- 폭주 100에서는 기존 훔바바 보스 이미지 그 자체로 변신한다. 일반 구간의 폭주90 초과 즉사는 유지한다. 우트나피쉬팀 컷신에서는 변신→할퀴기→암전→니므롯/폭주60 복귀, 훌루푸 전투에서는 변신 후25초 및 탈진2초를 적용한다. HP0 사망은 정상 처리한다.
- 훔바바 폼: 지속25초, 받는 피해0.5배, 이동306px/s(360×0.85), 점프 높이70%(충격량−695×√0.7), 할퀴기22/물기60/숨6×16틱/꼬리35. 기존 폭주 공격 배율을 곱하지 않는다. 재진입 대기15초, 종료값60, 탈진 중 받는 피해2배.
- 폼 시각 배수1.0: 모든 공유 시트의 최소 밀도0.900032px/게임 px. 요청 기본1.4배는 최소밀도가0.64288로 내려가 하한0.9를 위반하므로 적용하지 않았다. 환경 충돌은 기존36×124(낮은 고체 공간의 안전 복원은 기존 규칙), 피격 영역162×186(몸270×310의60%)이다.
- 실제 입력은 move_left(A/←), move_right(D/→), jump(Space), attack(J), roll(K), skill_light(R), interact(E), restart(F5), skill_devour(L)이다. 폼은J 3회 할퀴기+4번째 물기, K 꼬리, R 숨. S 웅크리기/내려가기·L·아누르의 빛은 비활성이다. F4는 디버그 폼 진입, Shift+F4 강제 종료(일반 탈진 적용).
- 카메라의 실제 줌아웃은 Godot zoom을 원래 값/1.15로 설정했다. 포효1.8초, 진입 히트스톱0.15초·섬광0.3초, BGM−3dB, 기존 humbaba_roar/claw/bite/tail/breath_loop 및 rampage_heartbeat_loop를 재사용한다.
- 강화 보스 HP는19,300/20,500/18,800(합계58,600), 공격은전부1.5배이다. 소수피해16.5/49.5는 누적 소수분을 보관해 두 번 명중하면33/99가 된다. 피격 거부·무적에는 소수분을 추가하지 않는다.
- 이동 속도: 니나즈의 어미 55, 릴리스 280, 괴물새 주 130px/s. 주요 패턴 간 대기 0.8초, 도착 페이드 후 전투 준비 1.2초. 별도 보스 대사 원문이 없으므로 대사를 추가하지 않고 이 준비 구간 뒤 전투를 시작한다.
- 패턴 쿨다운: 어미 독액 5.8/꼬리 3.2초, 릴리스 기습 5.5/매혹 6.0초, 주 깃털 4.8/잡기 7.0초. 엔키두아 잔상은 4.5초에 준비되며 이미 진행 중인 큰 패턴이 끝날 때까지 겹치지 않게 지연한다.
- 회복: 기존 +30 HP 아이템을 x=450/1050/1700/2650, y=880에 배치하고 소비된 지점만 18초마다 보충한다.
- 아레나 3200px, 티아마트 붕괴 구역 3000px, 광장 4000px. 가지 높이는 지면 위 90/180/270px, 체인 수평 간격은 180~220px(발판 폭 220으로 간극은 200 이내).
- 시야우와르샨은 성년 초입 20세, 곧고 맑은 표정, 인간에 가까운 체형과 섬세한 쥐의 형질(최신 외형 지시 적용), 미세한 SF 금빛 반사로 정했다. 장밋빛 양 뺨은 종족 설정을 반영했다. 안내 문구는 `아직 무기가 없다`.
- 광장 소품은 기존 성 앞 화로를 재사용한다. BGM은 `villa_calm`, 아레나는 `cedar_boss`, 티아마트는 `deathsea_drone`을 재사용한다.
- 노인 피 웅덩이는 (1450,862), 400×18px, 화면이 돌아오면 접지된 납작한 형태로 보인다. 난도질은 공유 훔바바 claw_windup/claw_swipe를0.6배 시간으로4회 반복해 약3.24초, 페이드아웃 2.5/페이드인 1.2초다.
- 릴리스의 기습 방향은 준비 중 턴 클립으로 맞춘다. 조작 반전은 A/D 이동 및 그 축을 사용하는 구르기·방향 공격 입력에 적용하며 W/S 선택 메뉴에는 적용하지 않는다.
- 티아마트 접근 트리거 x=2380, 본체 x=2760(거리 380px), 대화 종료 뒤 10초, 암흑 3초. 맥동은 생성 이미지의 scale/modulate와 알파 렌더링으로 표현한다.
- 저장 아이콘이 12단계에 없으므로 새 월드 이미지를 만들지 않고 화면 우하단에 작은 코드 UI `저장` 표시를 0.6초 띄웠다. 선택 메뉴는 키보드만 지원한다.

## 원인과 수정

12단계에는 이미 레벨 로드 시뿐 아니라 Story.changed에서도 NPC 존재 조건을 갱신하는 코드가 있었다. 동일 레벨 `go_to`도 실제로는 레벨을 재생성했다. 따라서 제시된 원인 가설 중 “갱신 자체가 없음”은 현재 코드와 달랐다. 재현된 확실한 버그는 `home_after_loss`가 `bed_blood=false`를 설정한다는 점이다. 이를 제거하고 `enkidua_gone`이면 피 플래그를 항상 유지했다. NPC 처리는 `LevelBase.reconcile_presence()`로 정리했으며 레벨 갱신·이동·저장 복원에 적용했다. 이미 생성된 부적합 NPC는 registry와 scene에서 즉시 제거한다. 일반 엔키두아(1000,620), 침대 인스턴스, 인안나 및 모든 presence NPC에 적용된다. 침대 피의 위치는 prop_contacts.json을 그대로 사용했다.

컷신 복구에서 해제된 일시 효과 노드를 키로 가진 Dictionary를 직접 순회하면 대기가 끝나지 않는 경우도 재현됐다. actor_states.keys()의 목록을 복사해 순회하고 일시 효과를 최종 정리한다. 오디오·대화의 같은 종류 복구 순회도 목록을 사용한다.

## 이야기와 저장

`TiamatZone → 우트나피쉬팀 대화/폭주 → 훌루푸 E → HuluppuCrown → TiamatCollapsed → 티아마트 대화 → 10초 자유 조작 → 암흑/선택 대기 자동 저장 → 라오차차흐라 선택 → HwaniraPlaza`.

우트나피쉬팀 6줄과 티아마트 2줄은 독립 문자열 fixture와 문자 단위로 비교한다. 대화는 기존 시간 정지·E 건너뛰기·이름 칩·우측 중앙 창을 사용한다. 티아마트 배경만 대화 연출의 렌더 맥동을 수행하고 AI·위험 지대·전투 타이머는 정지한다.

stage19는 `utnapishtim_done/huluppu_boss_done/tiamat_talk_done`, stage20은 `system_laochachahra_selected/siyavash_started`다. stage20 진행은 siyavash_progress에 두고 기존 니므롯 run_flags를 보존한다. 저장에는 active_character, siyavash_progress, nimrod_status, choice_pending, selected_system, story_stage를 추가했다. 구 12단계 저장은 새 필드가 없어도 기본값으로 복원된다. 선택 대기 저장은 장면을 반복하지 않고 검은 선택 메뉴로 바로 돌아온다. 컷신 완료와 선택 암전·캐릭터 도착에만 조용한 체크포인트 저장을 한다. 보스전 저장은 차단한다.

시야우와르샨 HP는 data/siyavash.json의 100이고 니므롯의 HP 보정·의수·폭주·멜람무·L·R을 비활성화한다. 무기는 없고 J는 안내만 한다. 17개 모션의 논리 프레임 수와 길이는 unarmed와 같다. 앉기 세트도 생략하지 않았다. F5는 저장/백업/임시 파일과 두 캐릭터 상태를 모두 지우고 니므롯의 집으로 초기화한다.

디버그: F6/F7 단계 19/20 포함, Shift+F10 노인 대화 직전, F10 아레나, F11 티아마트, F12 선택 메뉴, Shift+F11 시야우와르샨 광장. 기존 F8/F9(승선 전/후), 1/2 이동은 유지한다.

## 전투

세 보스의 지정 HP/데미지/Turn Delay/스턴/주기 값은 data/enemies.json에 기록했고 직접 비교하는 테스트가 있다. 큰 패턴은 Arena의 소유권으로 겹치지 않는다. 어미는 4타 충격파에 1초 기절하며 분사 중 독액 효과를 취소한다. 릴리스는 준비 턴 후 0.1초 기습과 3×15 할퀴기, 2.5초 A/D 반전, 4.5초 잔상을 쓴다. 주는 기존 bone_arrow 이미지를 5×16.5 부채꼴로 발사하고 경고선 뒤 잡기49.5을 쓴다. 공중 도끼 4타를 맞으면 가지 충돌을 잠시 제외해 지상으로 추락한 뒤 2초 기절한다. HP 0 사망 시 입구에서 세 보스 합계58,600 HP로 재시작한다.

주요 재량 판정: 어미 꼬리 320×220, 독액 반경160/높이65/5초/0.25초마다3(초당12); 릴리스 할퀴기150×160, 파동100×70/속도480/거리700; 주 잡기150×150/강하720/운반0.5초, 깃털 속도450/각도60도. 상세 위치·쿨다운·박스는 data/enemies.json과 data/odyssey.json이 기준이다.

## 이미지·용량

신규 이미지 49개, 4.62MiB. 시야우와르샨 첫 idle의 비투명 높이(α>12, canonical 복원)는 365px, 앵커 [320,600], 표시 배율0.30이다.

새 이미지 전체:

- assets/sprites/player/siyavash/jump_rise.webp
- assets/sprites/player/siyavash/run.webp
- assets/sprites/player/siyavash/drop_through.webp
- assets/sprites/player/siyavash/sit_idle.webp
- assets/sprites/player/siyavash/walk.webp
- assets/sprites/player/siyavash/idle.webp
- assets/sprites/player/siyavash/fall.webp
- assets/sprites/player/siyavash/sit_down.webp
- assets/sprites/player/siyavash/land.webp
- assets/sprites/player/siyavash/hurt.webp
- assets/sprites/player/siyavash/stand_up.webp
- assets/sprites/player/siyavash/crouch_exit.webp
- assets/sprites/player/siyavash/roll.webp
- assets/sprites/player/siyavash/crouch_idle.webp
- assets/sprites/player/siyavash/death.webp
- assets/sprites/player/siyavash/jump_start.webp
- assets/sprites/player/siyavash/crouch_enter.webp
- assets/sprites/enemies/ninazu_mother/idle.webp
- assets/sprites/enemies/ninazu_mother/hurt.webp
- assets/sprites/enemies/ninazu_mother/tail_attack.webp
- assets/sprites/enemies/ninazu_mother/tail_windup.webp
- assets/sprites/enemies/ninazu_mother/poison_windup.webp
- assets/sprites/enemies/ninazu_mother/death.webp
- assets/sprites/enemies/ninazu_mother/turn.webp
- assets/sprites/enemies/ninazu_mother/move.webp
- assets/sprites/enemies/ninazu_mother/poison_attack.webp
- assets/sprites/enemies/lilith/ambush_attack.webp
- assets/sprites/enemies/lilith/idle.webp
- assets/sprites/enemies/lilith/ambush_windup.webp
- assets/sprites/enemies/lilith/hurt.webp
- assets/sprites/enemies/lilith/death.webp
- assets/sprites/enemies/lilith/charm_windup.webp
- assets/sprites/enemies/lilith/charm_attack.webp
- assets/sprites/enemies/lilith/turn.webp
- assets/sprites/enemies/lilith/move.webp
- assets/sprites/enemies/zu/grab_attack.webp
- assets/sprites/enemies/zu/idle.webp
- assets/sprites/enemies/zu/hurt.webp
- assets/sprites/enemies/zu/grab_windup.webp
- assets/sprites/enemies/zu/feathers_windup.webp
- assets/sprites/enemies/zu/feathers_attack.webp
- assets/sprites/enemies/zu/death.webp
- assets/sprites/enemies/zu/turn.webp
- assets/sprites/enemies/zu/move.webp
- assets/backgrounds/hwanira/plaza.webp
- assets/backgrounds/tiamat/entity.webp
- assets/tiles/hwanira/plaza.png
- assets/tiles/huluppu/branch.png
- assets/props/utnapishtim_blood.webp

재사용: 훌루푸 줄기(붕괴 구역에서90도 회전), 별/땅, 노인·엔키두아·훔바바17시트, 화로, 가스/타격/뼈 화살/불씨 오라/회복 아이템. 미생성 이미지 0개, MISSING_TEXTURE 0개. 삼나무 숲에서 삭제한 벽 줄기를 다시 넣지 않았다.

assets 65.13MiB, 최종 ZIP 약 65.58MiB. 신규 개별 예산은 모두 충족했으나 ZIP 62MiB 목표는 미달이다. 상세 측정·실패 후보·상위20 파일은 SIZE_REPORT_KO.md에 있다.

## 검증 및 한계

- 신규 기능 통합 검사, 원문 비교, NPC 사망/피 유지, 저장·구 세이브·F5 복귀를 실행했다.
- 전체 기존 테스트의 달라진 기대값은 지침에 맞게 갱신했다(피 흔적 유지, 폭주100 예외, 노인 상호작용). 공유 보스 스크립트는 ID별 진입 스크립트를 두어 일반 클립 감사도 통과한다.
- 프레임·알파·접지·도달성·머리 잔상 검사와 실제 GL atlas/단독 렌더 비교를 실행했다. 최종 패키지를 별도 압축 해제했고 전체 헤드리스 검사175/175를 통과했다.
- 스크린샷은 docs/screenshots/stage13_*.png, 상세 로그는 archive/stage13이다. 화면 자료는 QA ZIP에 별도 제공한다.
- 기존 NPC 대비 경고9개와 기존 동적 포즈의 검토용 경고는 실패로 숨기지 않고 별도로 기록한다. 헤드리스 GDScript 경고·오류와 검사 실패는 0이 완료 조건이다.
- 가상 X11의 V-Sync 지원 경고는 플랫폼 제약이며 실제 GL 픽셀 비교 결과와 분리한다.

## 완료 체크

| 항목 | 결과 |
|---|---|
| 엔키두아 침대 버그/피 유지 | ○ |
| 우트나피쉬팀 원문 일치 | ○ |
| 폭주100/실제 훔바바/난도질/암전/니므롯 복귀/노인 무사 | ○ |
| 훌루푸 오르기 | ○ |
| 3체 수치와 전투 | ○ |
| 붕괴 줄기/티아마트 이미지 | ○ |
| 티아마트 원문/10초 암흑 | ○ |
| 자동 저장/4개 선택지 | ○ |
| 시야우와르샨17모션/HP100/무기 없음 | ○ |
| 흐와니라 광장 | ○ |
| 저장/구 세이브 호환 | ○ |
| 자동 테스트 전체 | ○ |
| ZIP62MiB 목표 | × |

최종 헤드리스: 175/175 통과(스크립트 파싱·기존12단계·13단계 전체), 엔진 경고·오류0. 실제GL은641단언/398비교 성공. 실행 ZIP 용량62MiB는미달이며 기능 검사 결과와분리했다.


## 13단계 추가 수정 — 훔바바 폼 및 크래시

### 오류 원인과 수명 관리

`huluppu_arena.gd`의 HUD 행에 이미 해제된 Node를 보관한 채 `var boss: EnemyBase=row["boss"]`에 대입해 유효성 검사 전에 오류가 발생했다. HUD와 보스 명단을 WeakRef로 관리하고, 먼저get_ref()를 호출해 살아 있는 객체만 typed 변수에 넣는다. 표시 이름과 최대HP는 행 생성 시 별도로 보관한다. 사망 후0HP 표시를 유지하며 마지막 보스의 실제 사망에만 승리 연출을 실행한다. `_update_active`의 사용하지 않는delta 인수는 `_delta`로 변경했고 HUD의 혼합형 삼항식은 제거했다.

### 폼 상태·연동

`data/humbaba_form.json`과 autoload `HumbabaForm`에 inactive→transforming→active→exiting→exhausted→inactive를 구현했다. Rampage.set_value()만 진입을 결정한다. 기존 Rampage.sprite_set() 반환 규칙은 유지하며 플레이어 렌더링이 폼을 먼저 확인한다. ResourceLoader의 동일 res:// 경로를 사용하고 보스/플레이어 텍스처 객체 동일성17개를 검사했다. 새로운 환경 충돌 본체나 이미지 사본은 없다.

포효 중 세 보스의 AI·쿨다운은 정지하고 플레이어는 무적이다. 폼 중 스턴·넉백·끌어당기기는 면역이지만 릴리스의2.5초 조작 반전은 유효하다. 타격은step0으로 전달하고, 폼 중 도끼4타 전용 어미·주 약점은 발동하지 않는다. 방향 전환 공격은 선딜/active/후딜에 다음 콤보를 즉시 시작하고, 히트스톱에서는0.12초 버퍼 및 공중2회 제한을 유지한다. 일반 방향 전환은turn의 앞3프레임을0.12초에 재생한다. 같은 방향J의 선입력은0.15초, 콤보 리셋0.8초다.

활성25초 동안100→60으로 선형 감소하고, 공격을 중단한 뒤 섬광0.3초와 탈진2초 후 기존 r50으로 복귀한다. 폼 기간에는 기존 최대HP 보정을 고정해 게이지 표시가 HP를 재생성하지 않으며, 종료 후60의 정상 능력치를 다시 계산한다. 일반 HP0 사망은 공유death 클립을 재생하고 훌루푸 입구에서 폼해제·폭주0·세 보스 전체HP로 재시작한다. 회복 아이템은 기존대로 먹는다.

대화·컷신에서는 지속 타이머를 정지한다. 문/레벨 전환에는 폼과 줌을 유지한다. 승리 후 폼이 남아 있어도 새 레벨로 이어지고, 종료 후 체크포인트를 저장한다. 선택 암전에 도달할 때 아직 폼이 남으면 암전 상태에서 정상 종료를 기다린 뒤 저장·선택 메뉴를 진행한다. 모든 저장 경로는 폼이 비활성일 때만 기록한다. 폼 상태는 저장 파일에 넣지 않는다. 예전 폭주100 저장은 로드 시60으로 정규화하고,12단계의18단계 이하 진행 플래그는 그대로 복원한다.

우트나피쉬팀 컷신은 실제 보스 폼으로 난도질하고 암전 중 탈진 없이 니므롯/60으로 돌아온다. 노인은 계속 서 있고 기존 피 웅덩이는 그대로 접지한다. 취소 시 변신 타이머와 대기 코루틴도 즉시 정리한다. 신규 이미지는0장, 기존 이미지 바이트 변경은0이다.

### 추가 완료표

| 항목 | 결과 |
|---|---|
| 해제된 보스 HUD 크래시·회귀 검사 | ○ |
| 강화 HP·모든 공격1.5배·소수 누적 | ○ |
| 100=실제 훔바바·포효·J/K/R·25초·탈진·60 | ○ |
| 기존 환경 충돌 유지·큰 피격 영역·슈퍼아머 | ○ |
| 컷신 복귀·취소·문 이동·저장 차단·구 저장 | ○ |
| 니므롯 도끼 기믹/시야우와르샨 예외 | ○ |
| 공유17텍스처·신규이미지0·밀도0.9 이상 | ○ |
| ZIP62MiB 목표 | × |


### 추가 검증 결과

Godot4.3의 스크립트 파싱 및 기존/신규 전체175/175 통과. 엔진 스크립트 경고·오류0. 추가로 실제 입력(J/K/R)·일방향52px 발판·반전·정확한소수피해·25초복귀·15초재진입·실제HP0부활·구저장100→60·컷신취소를 검사했다. 실제 훔바바 공유17텍스처 및 최소밀도를 단언했다. 세 보스 중 첫 번째와 두 번째를 실제해제한 뒤 HUD를120회갱신하고 마지막사망승리까지 검사했다.

정적QA: 알파651/0실패, 머리192/0실패, 프레임482/0오류·기존육안검토경고48, 괴수23종크기/밀도0실패, 접지119/0실패, 프롭16/0실패, 도달성통과. 이미지검증은누락0/오류0이며 기존NPC대비검토경고9는실패와구분했다. GL278단언/174픽셀비교0실패. 가상디스플레이의 V-Sync설정미지원 메시지1종은플랫폼경고이며 헤드리스 검사에는없다. Godot4.7.2는이환경에없어4.3에서검증했다.

화면: docs/screenshots/stage13_form_idle.png, stage13_form_breath.png, stage13_form_cutscene_after.png. 폼/입력/수명회귀: tests/test_humbaba_form.gd, test_humbaba_form_physics.gd, test_humbaba_cutscene.gd, test_huluppu_freed_hud.gd, test_humbaba_frame_bleed.gd. 전체파일목록: docs/STAGE13_FORM_FILES_KO.txt.


### 훔바바 폼 조작·수치 표

| 키 | 실제 액션 | 폼 동작 |
|---|---|---|
| A/D·←/→ | move_left/move_right | 306px/s 걷기, 방향전환0.12초 |
| Space | jump | 기본점프높이70%, 충격량에√0.7 적용 |
| J | attack | 할퀴기22×3입력 뒤 물기60, 보스모션시간0.6배 |
| K | roll | 꼬리35, 0.15초·360px/s 후퇴, 무적없음 |
| R | skill_light | 숨6×16틱, 사거리600/45도, 재사용6초 |
| E | interact | NPC/문 상호작용 허용 |
| F5 | restart | 저장·백업·스킬·폼까지 완전 초기화 |
| S/L | crouch/skill_devour | 폼 중 비활성 |

불길은600px/45도, 할퀴기260×150, 물기220×140, 꼬리240×80이다. 폼HP는기존플레이어HP이며 환경충돌은늘리지않는다. 받는피해0.5배/스턴·잡기·넉백면역, 탈진은2초/피해2배다. 남은시간바/붉은잔상0.3초·α0.5/가장자리UI비네트/기존박동을재사용한다.

진입: 일반90초과→기존사망 / 즉사정지+100→섬광→공유idle→포효1.8→active25초→게이지60→니므롯섬광0.3→탈진2초→r50·조작권. 컷신은시간정지→변신→할퀴기→암전중즉시니므롯60→밝아짐이며탈진을생략한다.

압축해제 최종검증: 새 임시폴더의전체175/175통과, 에셋·프레임·알파·접지·도달성·프롭·머리 등10개명령모두성공. 코드/씬/데이터/자산/project.godot를검증본과바이트비교해동일함을확인하고 문서만최종갱신했다. 크기미달때문에패키징종료코드는1이고, 기능검증은PASS로구분했다.

F4디버그는새니므롯런에서도폭주해금조건을자동부여해변신을검사할수있다. 시야우와르샨에서는F4를무시해니므롯플래그도변경하지않는다. 이분기는정상게임진행의해금조건을바꾸지않는다.
