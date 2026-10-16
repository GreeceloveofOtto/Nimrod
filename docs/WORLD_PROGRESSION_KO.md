# 축제 공명과 왕복 경로

능력의 획득 체인은 없습니다. 전부 독립적인 0단 축제 터에서 얻습니다. 벽 차오르기의 사용만 벽의 발톱을 요구합니다. 터18곳, 마을 제외 지역당2곳이며 각 능력은 서로 다른 최소2지역에서 공급됩니다. 터의 명시 좌표는 stage15_map_review_revision/assumed_coordinates.tsv에 수록했습니다.

| ID | 이름 | 키 | 유지 수치 | 공급 지역 |
|---|---|---|---|---|
| dash | 쥐의 질주 | Q | speed=900, seconds=0.22, cooldown=0.65 | deep, landing, mine |
| double_jump | 두 번째 도약 | Space | impulse=640 | deep, fortress, landing |
| wall_cling | 벽의 발톱 | A/D | slide_speed=65 | forest, ridge |
| wall_jump | 벽 차오르기 | Space | x_impulse=460, y_impulse=695 | mine, skywalk |
| crawl | 틈새 기기 | S+A/D | speed=115, height=48 | marsh, ridge |
| vision | 광질 시야 | F | hold=True | crystal, forest, fortress |
| light_throw | 천륜 빛 투척 | R | damage=30, speed=900, range=720, cooldown=2 | crystal, marsh, skywalk |

모든 지역의 대표 입구·보스·각 지역 축제 터·귀환 잔교·문 스위치는 지름길이 모두 닫혀 있어도 기본 이동으로 도달합니다. 각 지역의 영구 지름길은2개입니다. 아래 이동 시간은 능력0, 지름길 전부 열림 상태에서 걷기360px/s와 실제 탄도 점프/낙하 시간을 반영한 최단 경로 추정값입니다.

| 지역 | 대표 입구 타일 | 추정 초 |
|---|---|---|
| landing | [12, 20] | 0.0 |
| forest | [128, 32] | 10.876 |
| marsh | [256, 39] | 22.411 |
| mine | [384, 55] | 34.004 |
| fortress | [512, 71] | 46.183 |
| village | [44, 180] | 18.28 |
| ridge | [131, 182] | 22.582 |
| skywalk | [256, 186] | 27.615 |
| deep | [385, 180] | 37.811 |
| crystal | [517, 183] | 48.832 |

귀환 경로는 36×124 걷기/점프와 36×48 접지 기어가기의 고정 스텝 그래프입니다. 추가 이동 능력의 진입은 서 있는 몸의 무제한 비행으로 넓게 가정해 더 높은 공간을 놓치지 않습니다. 짧은 몸의 비행은 허용하지 않습니다. 좁은 통로는 실제 기어가기 이동으로만 전파합니다.
능력128×문1,048,576=134,217,728상태의 진입→반환 함의를 전수 비교했습니다. 독립 저장 시야 벽10개는 최소조건 함의 증명으로 추가 이력을 포괄합니다. 증명 모델·범위와 물리 그래프 해시는 STAGE15_MAP_REWORK_REPORT_KO.md에 적었습니다.
