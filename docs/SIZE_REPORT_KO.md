# 용량 보고: 영웅·단검 추가

품질 게이트 실패 후보는 적용하지 않았다. 변환 전 파일은 archive/plaza_dagger_2026-10-14의 compression_before/density_before에 보존한다.

| 단계 | assets(MiB) | 실행 ZIP(MiB) |
|---|---:|---:|
|11단계|이전 보고서 참조|69.4|
|12단계|60.54|60.93|
|13단계 훔바바|65.13|65.60|
|13단계 시야우와르샨|65.08|65.55|
| 이번 영웅·단검 |65.638|66.142|

| 신규 에셋 | B | MiB | 상한 MiB |
|---|---:|---:|---:|
|laodastahma|322178|0.3073|0.35|
|tusa|64812|0.0618|0.15|
|gudarz|48246|0.0460|0.15|
|gaevani|43240|0.0412|0.15|
|baraja|88640|0.0845|0.15|
|pariburz|58784|0.0561|0.15|
|siyavash_dagger|213358|0.2035|0.6|
|dagger_icon|2980|0.0028|0.02|

신규 합계 842,238B / 0.8032MiB, 모든 개별·합계 상한 통과.

| 분류 | 이전 B | 이번 B | 차이 B |
|---|---:|---:|---:|
|sprites|49,547,079|50,340,346|+793,267|
|backgrounds|7,027,420|7,042,950|+15,530|
|props|7,351,004|7,206,487|-144,517|
|tiles|1,996,124|1,996,124|+0|
|audio|1,879,737|1,879,737|+0|
|fonts|131,152|132,564|+1,412|
|ui|9,422|12,402|+2,980|
|image_prompts|43,511|71,660|+28,149|

기존 재인코딩242,764B + 밀도62,020B = **304,784B 절감**. 신규842,238B보다 작아 전체 용량은 증가했고 ZIP62/60MiB 목표는 미달이다. 별장 대문/통로 외관 재인코딩과 사슬 수인 turn·삼나무 거인 death 축소만 품질 게이트를 통과했다. assets의 JSON 메타데이터도 화소·값 변경 없이 공백을 줄여392,340B를 절감했다.

상위30 시트를 원본 대조로 밀도 재검토했고 재인코딩·팔레트는 42개 파일×5정책을 비교했다. 현재 대부분은 이미 밀도 하한이거나 낮추면 SSIM .93/RGB3 기준을 넘었다. 이음새 타일은 RGBA 양쪽 끝 일치 및 가장자리 색차2도 확인했다. 중복/미사용0. 대기 프레임 병합은 논리 시간/눈·장식 변화 보존 조건에서 신규 절감0. 오디오167개는 이미 모노 OGG, 약1.79MiB로 이전 결과를 유지한다(이번에 재인코딩하지 않았다).

| 줄이지 못한 상위20 파일 | MiB | 이유·후보 | 예상 절감(미검증) |
|---|---:|---|---:|
|assets/props/doors/castle_great_gate.webp|0.849|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.085MiB|
|assets/backgrounds/hwanira/plaza.webp|0.686|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.069MiB|
|assets/backgrounds/deathsea/stars_tile.webp|0.517|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.052MiB|
|assets/sprites/enemies/gugalanna/walk.webp|0.506|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.051MiB|
|assets/sprites/enemies/gugalanna/idle.webp|0.478|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.048MiB|
|assets/sprites/enemies/gugalanna/death.webp|0.459|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.046MiB|
|assets/backgrounds/cedar/mid_trunks_tile_2d.webp|0.458|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.046MiB|
|assets/sprites/enemies/kala_ushumgal/phase_transition.webp|0.442|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.044MiB|
|assets/sprites/enemies/kala_ushumgal/death.webp|0.431|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.043MiB|
|assets/sprites/enemies/kala_ushumgal/collapse.webp|0.408|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.041MiB|
|assets/sprites/enemies/kala_ushumgal/walk.webp|0.379|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.038MiB|
|assets/sprites/enemies/kala_ushumgal/whip_recovery.webp|0.365|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.036MiB|
|assets/sprites/enemies/kala_ushumgal/turn.webp|0.357|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.036MiB|
|assets/sprites/enemies/gugalanna/turn.webp|0.353|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.035MiB|
|assets/backgrounds/homeroad/mid_district_tile.webp|0.351|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.035MiB|
|assets/sprites/enemies/gugalanna/rake_windup.webp|0.348|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.035MiB|
|assets/sprites/enemies/kala_ushumgal/idle.webp|0.347|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.035MiB|
|assets/sprites/enemies/kala_ushumgal/summon.webp|0.344|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.034MiB|
|assets/sprites/enemies/gugalanna/rake.webp|0.338|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.034MiB|
|assets/sprites/enemies/kala_ushumgal/roar_loop.webp|0.327|원본 SSIM·색차/밀도 하한 때문에 유지. 후속으로 실제 참조·프레임 분리 재검토|0.033MiB|

실패 후보와 수치는 QA archive의 compression_trials.json / density_trials.json에 기록했다. 위 예상치는 검증되지 않은 후보일 뿐 확보된 절감량이 아니다. 생성 원본/참고/테스트캡처/캐시/이전ZIP/archive는 실행 ZIP에 포함하지 않는다. 기능 검증과 용량 목표 반환값은 분리한다.

## 요청한 콘텐츠 분류별 비교

| 분류 | 이전 B | 이번 B | 차이 B |
|---|---:|---:|---:|
|NPC|1,851,590|2,486,737|+635,147|
|괴수·보스|32,028,887|31,967,203|-61,684|
|플레이어|15,666,602|15,886,406|+219,804|
|배경|7,141,024|7,042,950|-98,074|
|오디오|1,879,737|1,879,737|+0|
