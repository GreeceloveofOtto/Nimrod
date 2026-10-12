# 11단계 스프라이트 QA

활성 매니페스트 437클립. 오류 0, 검토 경고 94.

저장 칸의 네 가장자리2px은 완전 투명이다. LINEAR와 region_filter_clip_enabled를 함께 사용한다. 문은 프레임 전체에 이어지는 건축 이미지이므로 원래 캔버스 가장자리까지 채울 수 있으나, 저장 칸의2px 투명 여백 검사는 그대로 적용한다. 비행 날개·연기·몸을 숙이는 공격·붕괴하는 사망은 큰 자세 변화로 분류하고 앵커·빈 프레임·잘림·원본 대비 검사도 함께 적용한다.

GL Compatibility 실제 렌더링: X11/Mesa llvmpipe, 1배·2배 비교4942회, 전체7851단언, 차이0/실패0. 헤드리스는 별도로 칸 여백과 리소스 로딩만 검사한다. GL실행은 플랫폼의 V-Sync 지원 경고1종을 남겼다.

경고는 분리된 도끼·효과 조각과 루프 이음의 차이에 대한 육안 검토 항목이다. 실패 항목을 경고로 바꾸지 않았다. 몸통·다리의 높이가 달라지는 클립은 자세의 변화와 저장 크기 변화를 구분한다.

| 매니페스트 | 클립 | 프레임 | 오류 | 검토 경고 |
|---|---|---:|---:|---|
| assets/sprites/enemies/melee_beast/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/melee_beast/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/melee_beast/manifest.json | windup | 4 | 0 |  |
| assets/sprites/enemies/melee_beast/manifest.json | attack | 3 | 0 |  |
| assets/sprites/enemies/melee_beast/manifest.json | recovery | 4 | 0 |  |
| assets/sprites/enemies/melee_beast/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/melee_beast/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/melee_beast/manifest.json | death | 6 | 0 |  |
| assets/sprites/enemies/ranged_beast/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/ranged_beast/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/ranged_beast/manifest.json | windup | 4 | 0 |  |
| assets/sprites/enemies/ranged_beast/manifest.json | flame_loop | 4 | 0 | loop seam difference 19.646 >1.3 average 14.356 |
| assets/sprites/enemies/ranged_beast/manifest.json | recovery | 4 | 0 |  |
| assets/sprites/enemies/ranged_beast/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/ranged_beast/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/ranged_beast/manifest.json | death | 6 | 0 |  |
| assets/sprites/fx/manifest.json | hit_spark | 5 | 0 |  |
| assets/sprites/fx/manifest.json | anur_light_projectile | 4 | 0 |  |
| assets/sprites/fx/manifest.json | anur_light_cast | 4 | 0 |  |
| assets/sprites/fx/manifest.json | anur_light_impact | 5 | 0 |  |
| assets/sprites/fx/manifest.json | humbaba_flame_cone | 6 | 0 |  |
| assets/sprites/fx/manifest.json | humbaba_ember_aura | 6 | 0 |  |
| assets/sprites/fx/manifest.json | humbaba_bite_spark | 4 | 0 |  |
| assets/sprites/fx/manifest.json | gugalanna_shockwave | 4 | 0 |  |
| assets/sprites/fx/manifest.json | gugalanna_lightning | 4 | 0 |  |
| assets/sprites/fx/manifest.json | gugalanna_rake_arc | 5 | 0 |  |
| assets/sprites/fx/manifest.json | gugalanna_dust | 5 | 0 |  |
| assets/sprites/fx/manifest.json | severed_arm | 4 | 0 |  |
| assets/sprites/npcs/lugalbanda/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/lugalbanda/manifest.json | idle_front | 6 | 0 |  |
| assets/sprites/npcs/ninsun/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/ninsun/manifest.json | idle_front | 6 | 0 |  |
| assets/sprites/npcs/shamhat/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/shamhat/manifest.json | idle_front | 6 | 0 |  |
| assets/sprites/npcs/inanna/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/inanna/manifest.json | idle_front | 6 | 0 |  |
| assets/sprites/npcs/papsukkal/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/papsukkal/manifest.json | idle_front | 6 | 0 |  |
| assets/sprites/npcs/cook_a/manifest.json | chop | 6 | 0 |  |
| assets/sprites/npcs/cook_b/manifest.json | stir | 6 | 0 |  |
| assets/sprites/npcs/cook_c/manifest.json | arrange | 6 | 0 | loop seam difference 2.772 >1.3 average 2.118 |
| assets/sprites/npcs/servant_a/manifest.json | sweep | 8 | 0 |  |
| assets/sprites/npcs/servant_b/manifest.json | sweep | 8 | 0 |  |
| assets/sprites/npcs/gatekeeper/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/gatekeeper/manifest.json | open_gate | 5 | 0 |  |
| assets/sprites/enemies/sky_beast/manifest.json | fly_idle | 6 | 0 |  |
| assets/sprites/enemies/sky_beast/manifest.json | windup | 4 | 0 |  |
| assets/sprites/enemies/sky_beast/manifest.json | dive | 3 | 0 |  |
| assets/sprites/enemies/sky_beast/manifest.json | recovery | 4 | 0 |  |
| assets/sprites/enemies/sky_beast/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/sky_beast/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/sky_beast/manifest.json | death | 6 | 0 |  |
| assets/props/doors/manifest.json | castle_rear_door_exterior | 6 | 0 |  |
| assets/props/doors/manifest.json | castle_interior_door | 6 | 0 |  |
| assets/props/doors/manifest.json | castle_rear_door_interior | 6 | 0 |  |
| assets/props/doors/manifest.json | villa_gate | 8 | 0 |  |
| assets/props/doors/manifest.json | villa_inner_door | 6 | 0 |  |
| assets/props/doors/manifest.json | castle_front_gate_locked | 1 | 0 |  |
| assets/props/doors/stage3_manifest.json | castle_front_door_interior | 6 | 0 |  |
| assets/props/doors/stage3_manifest.json | castle_front_door_exterior | 6 | 0 |  |
| assets/props/doors/stage3_manifest.json | downtown_passage_door | 1 | 0 |  |
| assets/props/doors/stage3_manifest.json | castle_great_gate | 8 | 0 |  |
| assets/sprites/npcs/shamash/manifest.json | idle_front | 6 | 0 |  |
| assets/sprites/npcs/shamash/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/shamash/manifest.json | walk | 8 | 0 |  |
| assets/sprites/npcs/shamash/manifest.json | sit_down | 4 | 0 |  |
| assets/sprites/npcs/shamash/manifest.json | sit_idle | 6 | 0 |  |
| assets/sprites/npcs/shamash/manifest.json | stand_up | 4 | 0 |  |
| assets/sprites/npcs/aya/manifest.json | idle_front | 6 | 0 |  |
| assets/sprites/npcs/aya/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/aya/manifest.json | walk | 8 | 0 |  |
| assets/sprites/npcs/aya/manifest.json | sit_down | 4 | 0 |  |
| assets/sprites/npcs/aya/manifest.json | sit_idle | 6 | 0 |  |
| assets/sprites/npcs/aya/manifest.json | stand_up | 4 | 0 |  |
| assets/props/doors/stage4_manifest.json | villa_back_door | 6 | 0 |  |
| assets/props/doors/stage5_manifest.json | passage_door | 6 | 0 |  |
| assets/props/doors/stage5_manifest.json | downtown_passage_door_anim | 6 | 0 |  |
| assets/props/doors/stage5_manifest.json | nimrod_home_gate | 6 | 0 |  |
| assets/sprites/fx/stage5_manifest.json | root_flame | 6 | 0 |  |
| assets/sprites/fx/stage5_manifest.json | spit_projectile | 4 | 0 |  |
| assets/sprites/fx/stage5_manifest.json | explosion | 6 | 0 |  |
| assets/sprites/fx/stage5_manifest.json | gas_cloud | 6 | 0 |  |
| assets/sprites/fx/stage5_manifest.json | guard_spark | 5 | 0 |  |
| assets/sprites/fx/stage5_manifest.json | chain_segment | 1 | 0 |  |
| assets/sprites/fx/stage5_manifest.json | chain_hook | 1 | 0 |  |
| assets/sprites/enemies/explosive_spitter/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/explosive_spitter/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/explosive_spitter/manifest.json | windup | 4 | 0 |  |
| assets/sprites/enemies/explosive_spitter/manifest.json | spit | 3 | 0 |  |
| assets/sprites/enemies/explosive_spitter/manifest.json | recovery | 4 | 0 |  |
| assets/sprites/enemies/explosive_spitter/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/explosive_spitter/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/explosive_spitter/manifest.json | death | 6 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | perch_ceiling | 4 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | perch_wall | 4 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | tell | 3 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | dive | 3 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | claw | 4 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | recovery | 4 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | crawl | 8 | 0 | loop seam difference 3.632 >1.3 average 2.747 |
| assets/sprites/enemies/wall_diver/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | death | 6 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | idle | 4 | 0 |  |
| assets/sprites/enemies/wall_diver/manifest.json | windup | 4 | 0 |  |
| assets/sprites/enemies/root_spewer/manifest.json | idle | 6 | 0 | loop seam difference 3.943 >1.3 average 2.183 |
| assets/sprites/enemies/root_spewer/manifest.json | windup | 4 | 0 |  |
| assets/sprites/enemies/root_spewer/manifest.json | spew | 4 | 0 |  |
| assets/sprites/enemies/root_spewer/manifest.json | recovery | 4 | 0 |  |
| assets/sprites/enemies/root_spewer/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/root_spewer/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/root_spewer/manifest.json | death | 6 | 0 |  |
| assets/sprites/enemies/boar_charger/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/boar_charger/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/boar_charger/manifest.json | telegraph | 4 | 0 |  |
| assets/sprites/enemies/boar_charger/manifest.json | charge | 4 | 0 |  |
| assets/sprites/enemies/boar_charger/manifest.json | crash_stun | 4 | 0 |  |
| assets/sprites/enemies/boar_charger/manifest.json | recovery | 4 | 0 |  |
| assets/sprites/enemies/boar_charger/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/boar_charger/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/boar_charger/manifest.json | death | 6 | 0 |  |
| assets/sprites/enemies/gas_sac/manifest.json | float | 6 | 0 |  |
| assets/sprites/enemies/gas_sac/manifest.json | bump | 3 | 0 |  |
| assets/sprites/enemies/gas_sac/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/gas_sac/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/gas_sac/manifest.json | death_swell | 6 | 0 |  |
| assets/sprites/enemies/gas_sac/manifest.json | burst | 5 | 0 |  |
| assets/sprites/enemies/wraith_ray/manifest.json | glide | 8 | 0 | frame 2: multiple substantial disconnected components; frame 3: multiple substantial disconnected components; frame 7: multiple substantial disconnected components |
| assets/sprites/enemies/wraith_ray/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/wraith_ray/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/wraith_ray/manifest.json | death | 6 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | guard_block | 3 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | claw_windup | 4 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | claw_attack | 3 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | claw_recovery | 4 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | tail_windup | 3 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | tail_strike | 3 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | tail_recovery | 4 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | turn | 6 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/shell_scorpion/manifest.json | death | 6 | 0 |  |
| assets/sprites/enemies/corpse_bomber/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/corpse_bomber/manifest.json | scream | 4 | 0 |  |
| assets/sprites/enemies/corpse_bomber/manifest.json | run | 8 | 0 |  |
| assets/sprites/enemies/corpse_bomber/manifest.json | fuse | 6 | 0 |  |
| assets/sprites/enemies/corpse_bomber/manifest.json | explode | 6 | 0 |  |
| assets/sprites/enemies/corpse_bomber/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/corpse_bomber/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | tail_windup | 5 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | tail_sweep | 4 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | tail_recovery | 5 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | chain_windup | 4 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | chain_throw | 4 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | pull_hold | 3 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | smash_windup | 4 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | smash | 3 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | smash_recovery | 5 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | turn | 6 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/chain_beastman/manifest.json | death | 8 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | windup | 4 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | thrust | 3 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | slash | 3 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | attack_recovery | 4 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | shield_up | 3 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | shield_hold | 2 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | shield_break_stun | 4 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/cedar_sentinel/manifest.json | death | 6 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | slam_windup | 6 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | slam | 3 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | slam_recovery | 5 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | sweep_windup | 5 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | sweep | 3 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | sweep_recovery | 5 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | rear_poke | 4 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | turn | 6 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/cedar_colossus/manifest.json | death | 8 | 0 |  |
| assets/sprites/enemies/cedar_archer/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/cedar_archer/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/cedar_archer/manifest.json | windup | 4 | 0 |  |
| assets/sprites/enemies/cedar_archer/manifest.json | shoot | 3 | 0 |  |
| assets/sprites/enemies/cedar_archer/manifest.json | recovery | 4 | 0 |  |
| assets/sprites/enemies/cedar_archer/manifest.json | hop_back | 5 | 0 |  |
| assets/sprites/enemies/cedar_archer/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/cedar_archer/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/cedar_archer/manifest.json | death | 6 | 0 |  |
| assets/sprites/enemies/cedar_wisp/manifest.json | float | 6 | 0 |  |
| assets/sprites/enemies/cedar_wisp/manifest.json | contact | 3 | 0 |  |
| assets/sprites/enemies/cedar_wisp/manifest.json | fuse | 5 | 0 |  |
| assets/sprites/enemies/cedar_wisp/manifest.json | explode | 6 | 0 |  |
| assets/sprites/enemies/cedar_wisp/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/cedar_wisp/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | perch | 4 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | tell | 3 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | fall | 3 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | land_stab | 4 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | claw_windup | 4 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | claws | 6 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | recovery | 4 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | idle | 6 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | turn | 4 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | hurt | 2 | 0 |  |
| assets/sprites/enemies/cedar_demon/manifest.json | death | 6 | 0 |  |
| assets/sprites/npcs/enkidua/manifest.json | idle_front | 6 | 0 |  |
| assets/sprites/npcs/enkidua/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/enkidua/manifest.json | bed_awake | 6 | 0 |  |
| assets/sprites/npcs/enkidua/manifest.json | bed_asleep | 6 | 0 |  |
| assets/props/doors/stage6_manifest.json | nimrod_home_inner_door | 6 | 0 |  |
| assets/props/doors/stage6_manifest.json | villa_back_door_exterior | 6 | 0 |  |
| assets/props/doors/stage6_manifest.json | cedar_forest_portal | 6 | 0 |  |
| assets/props/doors/stage6_manifest.json | cedar_portal | 6 | 0 |  |
| assets/sprites/fx/stage6_manifest.json | bone_spike | 4 | 0 |  |
| assets/sprites/fx/stage6_manifest.json | soul_flame_cone | 6 | 0 |  |
| assets/sprites/fx/stage6_manifest.json | bone_arrow | 1 | 0 |  |
| assets/sprites/fx/stage6_manifest.json | bone_spike_ground | 3 | 0 |  |
| assets/sprites/fx/stage6_manifest.json | blue_flame_explosion | 6 | 0 |  |
| assets/sprites/fx/stage6_manifest.json | armor_hit_spark | 5 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | idle | 8 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | whip_windup | 5 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | whip_swing | 4 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | whip_swing_back | 4 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | whip_recovery | 5 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | slam_windup | 5 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | slam | 3 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | slam_recovery | 5 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | summon | 6 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | turn | 6 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | phase_transition | 8 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | roar_windup | 5 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | roar_loop | 4 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | roar_recovery | 5 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | spines_back | 4 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | collapse | 6 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | final_swing_windup | 5 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | final_swing | 4 | 0 |  |
| assets/sprites/enemies/kala_ushumgal/manifest.json | death | 8 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | idle | 10 | 0 | loop seam difference 3.039 >1.3 average 2.245 |
| assets/sprites/player/unarmed/manifest.json | walk | 10 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | crouch_enter | 4 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | crouch_idle | 6 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | crouch_exit | 4 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | jump_start | 4 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | jump_rise | 6 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | fall | 6 | 0 | loop seam difference 14.961 >1.3 average 9.708 |
| assets/sprites/player/unarmed/manifest.json | land | 5 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | drop_through | 5 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | hurt | 5 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | death | 8 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | run | 10 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | roll | 12 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | sit_down | 4 | 0 |  |
| assets/sprites/player/unarmed/manifest.json | sit_idle | 6 | 0 | loop seam difference 2.300 >1.3 average 1.687 |
| assets/sprites/player/unarmed/manifest.json | stand_up | 4 | 0 |  |
| assets/sprites/player/staff/manifest.json | idle | 10 | 0 |  |
| assets/sprites/player/staff/manifest.json | walk | 10 | 0 | loop seam difference 6.872 >1.3 average 5.001 |
| assets/sprites/player/staff/manifest.json | crouch_enter | 4 | 0 |  |
| assets/sprites/player/staff/manifest.json | crouch_idle | 6 | 0 |  |
| assets/sprites/player/staff/manifest.json | crouch_exit | 4 | 0 |  |
| assets/sprites/player/staff/manifest.json | jump_start | 4 | 0 |  |
| assets/sprites/player/staff/manifest.json | jump_rise | 6 | 0 |  |
| assets/sprites/player/staff/manifest.json | fall | 6 | 0 | loop seam difference 12.078 >1.3 average 9.193 |
| assets/sprites/player/staff/manifest.json | land | 5 | 0 |  |
| assets/sprites/player/staff/manifest.json | drop_through | 5 | 0 |  |
| assets/sprites/player/staff/manifest.json | hurt | 5 | 0 |  |
| assets/sprites/player/staff/manifest.json | death | 8 | 0 |  |
| assets/sprites/player/staff/manifest.json | run | 10 | 0 |  |
| assets/sprites/player/staff/manifest.json | roll | 12 | 0 |  |
| assets/sprites/player/staff/manifest.json | attack_1 | 8 | 0 |  |
| assets/sprites/player/staff/manifest.json | attack_2 | 8 | 0 |  |
| assets/sprites/player/staff/manifest.json | attack_3 | 10 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | idle | 8 | 0 | loop seam difference 6.667 >1.3 average 4.196 |
| assets/sprites/enemies/humbaba/manifest.json | bite_windup | 5 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | bite | 3 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | bite_recovery | 4 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | claw_windup | 4 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | claw_swipe | 6 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | claw_recovery | 4 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | breath_windup | 5 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | breath_loop | 4 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | breath_recovery | 4 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | tail_windup | 3 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | tail_strike | 3 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | tail_recovery | 4 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | turn | 6 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | phase_roar | 8 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | death | 8 | 0 |  |
| assets/sprites/enemies/humbaba/manifest.json | walk | 8 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | idle | 10 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | walk | 10 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | crouch_enter | 4 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | crouch_idle | 6 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | crouch_exit | 4 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | jump_start | 4 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | jump_rise | 6 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | fall | 6 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | land | 5 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | drop_through | 5 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | hurt | 5 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | death | 8 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | attack_1 | 8 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | attack_2 | 8 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | attack_3 | 10 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | attack_4 | 10 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | run | 10 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | roll | 12 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | arm_loss_hit | 5 | 0 |  |
| assets/sprites/player/axe_onearm/manifest.json | melammu_absorb | 6 | 0 |  |
| assets/sprites/player/cutscene/manifest.json | cry_collapse | 5 | 0 | frame 1: multiple substantial disconnected components; frame 2: multiple substantial disconnected components; frame 3: multiple substantial disconnected components; frame 4: multiple substantial disconnected components |
| assets/sprites/player/cutscene/manifest.json | cry_loop | 6 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | idle | 8 | 0 | loop seam difference 4.368 >1.3 average 3.274 |
| assets/sprites/enemies/gugalanna/manifest.json | walk | 8 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | stomp_windup | 6 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | stomp | 3 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | stomp_recovery | 5 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | charge_windup | 5 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | charge_loop | 4 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | charge_crash | 5 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | charge_recovery | 4 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | uppercut_windup | 5 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | uppercut | 3 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | uppercut_recovery | 5 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | rake_windup | 6 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | rake | 5 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | rake_recovery | 5 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | turn | 6 | 0 |  |
| assets/sprites/enemies/gugalanna/manifest.json | death | 10 | 0 |  |
| assets/sprites/fx/stage11_manifest.json | devour_bite | 5 | 0 |  |
| assets/sprites/fx/stage11_manifest.json | mote | 4 | 0 |  |
| assets/sprites/npcs/shimati/manifest.json | idle | 6 | 0 |  |
| assets/sprites/npcs/shimati/manifest.json | idle_front | 6 | 0 |  |
| assets/sprites/npcs/shimati/manifest.json | give_paper | 4 | 0 |  |
| assets/sprites/npcs/urshanabi/manifest.json | dice_loop | 8 | 0 | loop seam difference 5.499 >1.3 average 4.050 |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | idle | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | walk | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | run | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | crouch_idle | 6 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | crouch_enter | 4 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | crouch_exit | 4 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | jump_start | 4 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | land | 5 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | jump_rise | 6 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | fall | 6 | 0 | loop seam difference 22.945 >1.3 average 15.067 |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | drop_through | 5 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | hurt | 5 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | attack_1 | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | attack_2 | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | attack_3 | 10 | 0 | frame 1: multiple substantial disconnected components; frame 2: multiple substantial disconnected components; frame 3: multiple substantial disconnected components; frame 4: multiple substantial disconnected components |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | attack_4 | 10 | 0 | frame 3: multiple substantial disconnected components |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | roll | 12 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | death | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r50/manifest.json | devour | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | idle | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | walk | 10 | 0 | frame 1: multiple substantial disconnected components; frame 2: multiple substantial disconnected components; frame 3: multiple substantial disconnected components; frame 4: multiple substantial disconnected components; frame 5: multiple substantial disconnected components; frame 6: multiple substantial disconnected components; frame 7: multiple substantial disconnected components; frame 8: multiple substantial disconnected components; frame 9: multiple substantial disconnected components; frame 10: multiple substantial disconnected components |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | run | 10 | 0 | frame 1: multiple substantial disconnected components; frame 2: multiple substantial disconnected components; frame 3: multiple substantial disconnected components; frame 4: multiple substantial disconnected components; frame 5: multiple substantial disconnected components; frame 6: multiple substantial disconnected components; frame 7: multiple substantial disconnected components; frame 8: multiple substantial disconnected components; frame 9: multiple substantial disconnected components; frame 10: multiple substantial disconnected components; loop seam difference 11.751 >1.3 average 8.812 |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | crouch_idle | 6 | 0 | frame 1: multiple substantial disconnected components; frame 2: multiple substantial disconnected components; frame 4: multiple substantial disconnected components; frame 5: multiple substantial disconnected components; frame 6: multiple substantial disconnected components; loop seam difference 6.109 >1.3 average 3.601 |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | crouch_enter | 4 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | crouch_exit | 4 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | jump_start | 4 | 0 | frame 1: multiple substantial disconnected components; frame 4: multiple substantial disconnected components |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | land | 5 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | jump_rise | 6 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | fall | 6 | 0 | loop seam difference 21.619 >1.3 average 13.930 |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | drop_through | 5 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | hurt | 5 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | attack_1 | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | attack_2 | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | attack_3 | 10 | 0 | frame 3: multiple substantial disconnected components |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | attack_4 | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | roll | 12 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | death | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r90/manifest.json | devour | 8 | 0 |  |
| assets/sprites/player/axe_onearm_helm/manifest.json | idle | 10 | 0 | loop seam difference 4.092 >1.3 average 2.889 |
| assets/sprites/player/axe_onearm_helm/manifest.json | helm_equip | 5 | 0 |  |
| assets/sprites/player/axe/manifest.json | idle | 10 | 0 |  |
| assets/sprites/player/axe/manifest.json | walk | 10 | 0 | loop seam difference 8.196 >1.3 average 6.214 |
| assets/sprites/player/axe/manifest.json | crouch_enter | 4 | 0 |  |
| assets/sprites/player/axe/manifest.json | crouch_idle | 6 | 0 |  |
| assets/sprites/player/axe/manifest.json | crouch_exit | 4 | 0 |  |
| assets/sprites/player/axe/manifest.json | jump_start | 4 | 0 |  |
| assets/sprites/player/axe/manifest.json | jump_rise | 6 | 0 |  |
| assets/sprites/player/axe/manifest.json | fall | 6 | 0 | loop seam difference 15.223 >1.3 average 10.509 |
| assets/sprites/player/axe/manifest.json | land | 5 | 0 |  |
| assets/sprites/player/axe/manifest.json | drop_through | 5 | 0 |  |
| assets/sprites/player/axe/manifest.json | hurt | 5 | 0 |  |
| assets/sprites/player/axe/manifest.json | death | 8 | 0 |  |
| assets/sprites/player/axe/manifest.json | attack_1 | 8 | 0 |  |
| assets/sprites/player/axe/manifest.json | attack_2 | 8 | 0 |  |
| assets/sprites/player/axe/manifest.json | attack_3 | 10 | 0 |  |
| assets/sprites/player/axe/manifest.json | attack_4 | 10 | 0 |  |
| assets/sprites/player/axe/manifest.json | run | 10 | 0 |  |
| assets/sprites/player/axe/manifest.json | roll | 12 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | idle | 10 | 0 | loop seam difference 10.028 >1.3 average 3.715 |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | walk | 10 | 0 | frame 1: multiple substantial disconnected components; frame 2: multiple substantial disconnected components; frame 3: multiple substantial disconnected components; frame 4: multiple substantial disconnected components; frame 5: multiple substantial disconnected components; frame 6: multiple substantial disconnected components; frame 7: multiple substantial disconnected components; frame 8: multiple substantial disconnected components; frame 9: multiple substantial disconnected components; frame 10: multiple substantial disconnected components; loop seam difference 7.871 >1.3 average 4.699 |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | run | 10 | 0 | frame 1: multiple substantial disconnected components; frame 2: multiple substantial disconnected components; frame 3: multiple substantial disconnected components; frame 4: multiple substantial disconnected components; frame 5: multiple substantial disconnected components; frame 6: multiple substantial disconnected components; frame 7: multiple substantial disconnected components; frame 8: multiple substantial disconnected components; frame 9: multiple substantial disconnected components |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | crouch_idle | 6 | 0 | frame 2: multiple substantial disconnected components; frame 3: multiple substantial disconnected components; frame 4: multiple substantial disconnected components; frame 5: multiple substantial disconnected components; frame 6: multiple substantial disconnected components; loop seam difference 10.158 >1.3 average 3.845 |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | crouch_enter | 4 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | crouch_exit | 4 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | jump_start | 4 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | land | 5 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | jump_rise | 6 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | fall | 6 | 0 | frame 1: multiple substantial disconnected components; frame 5: multiple substantial disconnected components; loop seam difference 9.942 >1.3 average 7.481 |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | drop_through | 5 | 0 | frame 1: multiple substantial disconnected components; frame 2: multiple substantial disconnected components; frame 3: multiple substantial disconnected components; frame 5: multiple substantial disconnected components |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | hurt | 5 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | attack_1 | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | attack_2 | 8 | 0 | frame 1: multiple substantial disconnected components |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | attack_3 | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | attack_4 | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | roll | 12 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | death | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm/manifest.json | devour | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | idle | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | walk | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | run | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | crouch_idle | 6 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | jump_start | 4 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | jump_rise | 6 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | fall | 6 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | hurt | 5 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | attack_1 | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | attack_2 | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | attack_3 | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | attack_4 | 10 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | roll | 12 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | death | 8 | 0 |  |
| assets/sprites/player/axe_prosthetic_helm_r40/manifest.json | devour | 8 | 0 |  |
