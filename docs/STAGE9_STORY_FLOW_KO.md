# 9단계 스토리 흐름과 대사

이야기·스킬·대화 방문은 GameState.run_flags에 저장하며 사망/F5 시 모두 초기화한다. 시작은 실제 8단계와 같은 NimrodHome/Spawn_Start(x=330), 맨손이다.

| 단계 | 완료 플래그 |
|---|---|
| 0 |  |
| 1 | villa_intro_done |
| 2 | villa_dinner_done |
| 3 | kala_first_defeat |
| 4 | report_done |
| 5 | castle_return_talk_done, time_skipped |
| 6 | castle_enkidua_done, castle_talks_done |
| 7 | anur_blessing_done |
| 8 | humbaba_defeated |

Story.is_flag/set_flag/stage를 사용한다. GDScript 예약어 is와 Object.set 충돌을 피한 이름이다. variants는 순서대로 조건을 평가하고 첫 일치만 사용한다. 완료된 variant의 repeat가 비어 있으면 이전 대화로 되돌아가지 않는다.

NPC 존재: 엔키두아는 report_done 전 집/후 성1층1120. 별장1층 하인은 밤에 없음. 별장3층 두 주인은 저녁식사 후 첫 칼라 처치 전 부재, 그 뒤 항상 존재한다. night=kala_first_defeat && !time_skipped. 낮은 흰색, 밤은 CanvasModulate(0.58,0.64,0.88); NPC 빛 웅덩이는 역보정한다.

그룹 연결: VillaF3 shamash/aya→villa_hosts(intro/report/anur 우선순위); CastleF1 lugalbanda/ninsun/enkidua→귀환 공유 variant. 기상 후 엔키두아 먼저, 부모님 다음. 뒷문은 time_skipped && !castle_talks_done일 때 잠긴다.

컷신: 별장 식사 → 도끼 표시 숨김/맨손 sit → 두 주인 하강/걷기/앉기 → 12줄 → 일어서 퇴장 → 무기 표시/입력 복원. 귀환 → 페이드1.5/암전1.0/페이드1.5 → CastleF1 Spawn_Wake760.

## villa_intro

조건: {"none": ["villa_intro_done"]}

- aya: 니므롯, 어서와, 기다리고 있었어.
- shamash: 니므롯, 너에게 거는 기대가 커. 너는 많은 것을 할 수 있을 거야.
- player: 샤마쉬, 아야, 언제나 고마워.
- aya: 니므롯, 식사를 준비했어. 함께 하면서 너의 업무를 전달할게.

이벤트: [{"event": "set_flag", "flag": "villa_intro_done"}]

## villa_dinner

조건: {"all": ["villa_intro_done"], "none": ["villa_dinner_done"]}

- shamash: 니므롯, 요즘 엔키두아와 관계는 어떤가?
- player: 언제나 그렇듯 좋습니다.
- aya: 엔키두아도 우리의 수칼루로 두고 싶은 마음이 있어요.
- aya: 엔키두아도 우리를 매료시켰죠.
- aya: 하지만, 아직 수칼루 2명을 임명할 권한이 없네요.
- shamash: 우린 곧 수칼루 2명을 임명할 수 있을 거야.
- shamash: 그건 그렇고, 오늘 니므롯이 할 업무는 다음과 같아.
- shamash: 삼나무 숲의 조사가 필요해. 삼나무 숲에서의 피해가 늘어나고 있는데, 어떤 변화가 있는지 철저하게 조사해서 우리에게 보고해주면 돼.
- aya: 샤마쉬, 우리 이제 떠나야 할 시간이에요.
- shamash: 니므롯, 우리는 시파르 행성에 일이 있어서 말이지.
- shamash: 그럼 돌아와서 보자고.
- shamash: 브란눈과 이디그나의 축복을 비네.

이벤트: []

## villa_report

조건: {"all": ["kala_first_defeat"], "none": ["report_done"]}

- shamash: 니므롯, 왔는가, 고생 꽤나 한 모양이군.
- shamash: 자네의 얼굴만 보아도 삼나무 숲에 큰 문제가 있는 것을 알 수 있어.
- shamash: 그래, 어떤가 삼나무 숲에 대해서 구체적으로 보고해주게.
- player: 확실히 이상하긴 하더군요.
- player: 우리가 모르는 곳으로 떠났어야 할 영혼들이 여전히 육체에 남아 있었습니다.
- player: 단 한 번의 조사로는 그 원인을 파악할 수 없었습니다.
- aya: 긴 시간 동안 고생했어, 니므롯. 집으로 돌아가도 좋아요.

이벤트: [{"event": "set_flag", "flag": "report_done"}]

## castle_return

조건: {"all": ["report_done"], "none": ["castle_return_talk_done"]}

- lugalbanda: 아들아, 수고했다. 다행히 별 탈 없이 돌아왔구나.
- ninsun: 오늘은 여기서 자고 가, 니므롯.
- enkidua: 수고했어, 니므롯.

이벤트: [{"event": "set_flag", "flag": "castle_return_talk_done"}, {"event": "time_skip"}]

## castle_enkidua

조건: {"all": ["time_skipped"], "none": ["castle_enkidua_done"]}

- player: 엔키두아, 축하해. 샤마쉬와 아야의 수칼루라니.
- enkidua: 너가 나를 추천한 거 아니야? 내가 고맙지.
- player: 아니야, 샤마쉬와 아야는 예전부터 너를 수칼루로 두고 싶어했어.

이벤트: [{"event": "set_flag", "flag": "castle_enkidua_done"}]

## castle_parents

조건: {"all": ["castle_enkidua_done"], "none": ["castle_talks_done"]}

- lugalbanda: 니므롯과 엔키두아, 너희가 정말 자랑스럽다.
- ninsun: 다치지 마, 니므롯, 엔키두아.

이벤트: [{"event": "set_flag", "flag": "castle_talks_done"}]

## shamhat_s5

조건: {"all": ["castle_talks_done"], "none": ["shamhat_s5_done"]}

- player: 샴하트, 축하해, 인안나의 두 번째 수칼루가 되었다고?
- shamhat: 고마워, 영광이지.
- shamhat: 그래서, 엔키두아와는 여전해?
- player: 당연한 걸.

이벤트: [{"event": "set_flag", "flag": "shamhat_s5_done"}, {"event": "set_flag", "flag": "dialogue_shamhat"}]

## inanna_s5

조건: {"all": ["castle_talks_done"], "none": ["inanna_s5_done"]}

- papsukkal: 감히, 인안나와 대화하려하느냐!
- inanna: 팝수칼, 이제 그만 좀 해. 니므롯이잖아.
- papsukkal: 그렇군, 오늘도 미안해, 니므롯.

이벤트: [{"event": "set_flag", "flag": "inanna_s5_done"}, {"event": "set_flag", "flag": "dialogue_inanna"}]

## villa_anur

조건: {"all": ["castle_talks_done"], "none": ["anur_blessing_done"]}

- shamash: 오늘은 삼나무 숲 재조사를 해주어야 해.
- aya: 너희를 아누르의 빛으로 축복할게.

이벤트: [{"event": "unlock_skill", "skill": "anur_light"}, {"event": "set_flag", "flag": "anur_blessing_done"}]
