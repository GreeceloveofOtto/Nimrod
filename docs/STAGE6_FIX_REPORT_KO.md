# 6단계 수정본 — 공격 오류·괴수 축소·구조물 정렬

## 변경 결과

플레이어 공격 판정에서 적의 `take_hit()`나 `attack_connected` 콜백이 플레이어를 피격·사망시키거나 새 공격으로 교체하면 이전 공격의 처리를 즉시 중단한다. 공격별 generation을 기록하고 타수·데이터를 판정 시작 시 고정한다. 따라서 초기화된 `attack_step=0`을 다시 조회하지 않으며, 취소된 4타의 충격파와 히트스톱이 뒤늦게 생기지 않는다. 기존 콤보·구르기 방향·HP·이동 수치는 유지했다.

## 크기

통로 신규9종: explosive_spitter, wall_diver, root_spewer, boar_charger, gas_sac, wraith_ray, shell_scorpion, corpse_bomber, chain_beastman.

- `size_multiplier`: 3.0 → 1.5; 스프라이트 배율0.90 → 0.45.
- 몸체·hurtbox·근접 공격 판정·투사체 충돌 크기·사슬 끌기 위치도 종전의 절반. 사슬 끌기 위치270 →135px.
- 기존 배율 계산식은 유지: 감지·선호 거리·센서는 원본×1.125(1100px 상한), 폭발·가스 반경/높이는 원본×1.25. 반경을 스프라이트처럼 무조건 절반으로 자르지는 않는다.
- HP·피해·이동 속도·공격 시간·회전 지연은 유지했다. 일반 우루크2종·비행 괴수·삼나무 숲 괴수·보스 크기도 유지했다.
- 3배 몸체에 맞춰 확장했던 통로 층의 지형과 카메라 범위는 유지한다. 작은 몸으로 공간이 더 넉넉해진다.

## 구조물 정렬

기존 생성 PNG만 크롭·크기 정렬했다. 새 그림이나 절차적 아트는 만들지 않았다. 보존 원본은 `assets/source_art/surface_alignment/`에 있다. 모든 게임 PNG 경로와 크기는 유지한다.

- 통로 `platform.png`, `bridge_plank.png`: 옆에 섞인 조각과 위쪽 빈 부분을 잘라 실제 지지면을 충돌 상단에 맞췄다.
- 통로 `low_tunnel_ceiling.png`: 옆 조각·아래 늘어진 부분을 잘라 통과 제한이 되는 아래쪽 면을 맞추고, 가로 이음새도 다시 정렬했다.
- 보스방 `boss_end_platform.png`: 서로 떨어진 두 줄 중 실제 발판 한 줄만 정렬했다.
- `large_rubble_b.png`: 빈 상단과 다른 조각을 잘라 충돌 블록과 크기를 맞췄다.
- `broken_overpass.png`: 실제 평평한 발판과 어긋나던 기울어진 도로를 잘라 지지대만 남겼다. 집 가는 길의 장식은(x2870,y786), 크기1100×94. 실제 발판은 기존 y730과 폭·위치를 유지한다.
- 발판 하단 음영은 충돌 두께16px 대신 실제 표시 이미지 높이(일반48px, 개별 설정 우선)에 맞춘다. 상단은 실제 충돌 상단에 유지한다.
- 이미지가 없는 맵 경계·기본 천장에는 구조물 표시를 만들지 않는다. 저천장 구간의 표시는 위쪽이 아닌 아래쪽 접촉면에 둔다.
- 큰 다리·통로·고가도로 장식은z−4로 내려 실제 발판(z−3)과 표시(z−2)를 덮지 않도록 했다. 구조물 표시 F3 기능은 유지한다.

정렬을 재현하려면 `python tools/align_surface_art.py`; 검증은 `--check`를 추가한다. 기준 영역과 알파 경계 수치는 `data/surface_art_alignment.json`에 모았다.

## 검증

공식 Godot4.3.77dcf97d8에서 테스트23개 모두 통과. 기존 크기를 전제로 한 시험 위치는 축소된 감지·공격 거리 안에 맞췄고, 판정 규칙의 검사는 유지했다. 적9종의 표시·몸체·hurtbox 크기도 각각 확인했다.

- 공격 중 콜백 피격/사망/같은1타 재시작 및 충격파 취소:13검사/0실패.
- 5단계 괴수9종:78검사/0실패.
- 구조물 상단·하단·저천장·비표시 경계:118검사/0실패.
- PNG399개:누락0/오류0. 기존 NPC 대비 경고7개는 이전과 같다.
- 통로8개 층과 숲/보스방의 몸체·순찰 통로 여유:11레벨/0실패.
- 기존10개 레벨 이동 가능성 및 숲2개 미로:0실패.
- 접지113개:0실패. 정렬한 지지면5개는 첫/끝 행의 유효 픽셀 범위가80.6~95.0%이며, 도로 지지대는 장식이라 이 기준을 적용하지 않는다.

Linux GL Compatibility에서 수정 장면16개를 다시 캡처했다. `docs/screenshots/stage6_size_*.png`9종과 `stage6_surface_accents.png`를 갱신했고, `stage6_fix_bridge`, `fix_ceiling`, `fix_boss_platform`, `fix_outskirts_bridge`, `fix_overpass`, `fix_rubble`6장을 추가했다. 실제 캡처에서 통로·천장·다리·고가도로·잔해를 확인했다.

Windows 및 사용자 화면의 Godot4.7.2는 직접 실행하지 못했다. 모든 배경에 그려진 장식이 충돌 구조물인 것은 아니며, 이번에는 실제 충돌 발판/블록과 겹쳐 혼동을 주던 아트와 표시를 수정했다. 새 수정에서도 기존 아트의 세부 모션·몸체 비율 한계와 NPC 대비 경고는 남는다.

## 전체 테스트

- regression: NIMROD REGRESSION: 193 checks, 0 failures
- stage2_interactions: STAGE2_INTERACTIONS: 42 checks, 0 failures
- stage2_sky: Stage 2 sky/safe-zone checks: 66; failures: 0
- stage2_transitions: Stage 2 transition regression: 210 checks, 0 failures
- stage3_front: STAGE3_FRONT: 40 checks, 0 failures
- stage4_gate: STAGE4_GATE: 38 checks, 0 failures
- stage4_npc_facing: STAGE4_NPC_FACING: 73 checks, 0 failures
- stage4_player_scale: STAGE4_PLAYER_SCALE: 45 checks, 0 failures
- stage4_terrain: STAGE4_TERRAIN: 5 checks, 0 failures
- stage4_villa: STAGE4_VILLA: 19 checks, 0 failures
- stage5_direction_cancel: STAGE5_DIRECTION_CANCEL: 14 checks, 0 failures
- stage5_enemies: STAGE5_ENEMIES: 78 checks, 0 failures
- stage5_homeroad: STAGE5_HOMEROAD: 50 checks, 0 failures
- stage5_passage: STAGE5_PASSAGE: 209 checks, 0 failures
- stage5_terrain: STAGE5_TERRAIN: 18 checks, 0 failures
- stage6_attack_reentrancy: STAGE6_ATTACK_REENTRANCY: 13 checks, 0 failures
- stage6_boss: STAGE6_BOSS: 24 checks, 0 failures
- stage6_cedar_enemies: STAGE6_CEDAR_ENEMIES: 20 checks, 0 failures
- stage6_clip_coverage: STAGE6_CLIP_COVERAGE: 310 checks, 0 failures
- stage6_levels: STAGE6_LEVELS: 13 checks, 0 failures
- stage6_shamhat_buff: STAGE6_SHAMHAT_BUFF: 16 checks, 0 failures
- stage6_surface_accent: STAGE6_SURFACE_ACCENT: 118 checks, 0 failures
- stage6_threat_marker: STAGE6_THREAT_MARKER: 6 checks, 0 failures

일부 강제 상태·렌더 테스트의 엔진 종료 시 AudioStreamWAV/Playback 객체 정리 경고가 남는다. 상세 로그 확인 결과 오디오 믹서 종료 리소스이며, 테스트 실패나 플레이 중 스크립트 오류는 아니다.
