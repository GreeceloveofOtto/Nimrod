# 능력 진행과 복귀 검증

점프 높이 138.01px. 플랫폼 그래프는 중력·도약·속도를 읽으며 120px 간격 계단을 검증한다. 128개 능력 조합에서 접근 가능한 모든 방의 착륙 지점 복귀 경로를 검사한다. 전투 승리 가능성은 그래프 솔버 범위 밖이며 런타임 전투 테스트로 분리한다.

landing_01 → landing_02 → landing_03 → landing_03 [acquire dash] → landing_04 → landing_05 → forest_00 → forest_01 → forest_02 → forest_03 → forest_03 [acquire double_jump] → forest_04 → forest_05 → fortress_00 → fortress_01 → fortress_02 → fortress_03 → fortress_03 [acquire wall_cling] → fortress_04 → fortress_05 → ridge_00 → ridge_01 → ridge_02 → ridge_03 → ridge_03 [acquire wall_jump] → ridge_04 → ridge_05 → mine_00 → mine_01 → mine_02 → mine_03 → mine_03 [acquire crawl] → mine_02 → mine_01 → mine_00 → village_00 → village_01 → village_02 → village_03 → village_03 [acquire vision] → village_02 → village_01 → village_00 → marsh_00 → marsh_01 → marsh_02 → marsh_03 → marsh_03 [acquire light_throw]
