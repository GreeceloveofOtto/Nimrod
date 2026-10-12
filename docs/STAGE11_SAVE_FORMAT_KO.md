# 저장 파일 형식 (버전 1)

샴하트의 첫 대화 후 선택 메뉴에서 **저장하기**를 선택한다. 저장은 루갈성 2층에서만 가능하며 대화·컷신·전투·이동 중에는 불가능하다. 별도 시작 화면 없이 다음 실행에서 마지막 저장을 읽는다.

```json
{"version":1,"level":"CastleF2","position":[850,620],"facing":-1,"hp":100,"run_flags":{"weapon":"axe","rampage_unlocked":true,"rampage":50},"rampage":50,"cooldowns":{"anur_light":0,"devour":0},"timestamp":1791800000}
```

run_flags에는 이 예시보다 많은 이야기·대화·장비 플래그가 들어간다. weapon은 해당 사전 안에 저장한다. 스킬 쿨다운은 저장 성공 및 불러오기 때 0으로 만든다. Y 개발용 HP 하한과 API의 임시 사망 유예는 저장하지 않는다.

save.json.tmp에 기록·flush·close한 뒤 유효한 기존 파일을 save.json.bak으로 복사하고 rename으로 본 파일을 교체한다. 본 파일이 손상되면 백업을 읽고 본 파일도 복구한다. 둘 다 손상되면 진단 로그를 남기고 집에서 새 게임으로 시작한다. JSON 문법 오류는 엔진 오류를 내지 않는 파서로 처리하며 좌표·HP·방향 등의 형식도 확인한다. 이전 형식은 누락 필드와 투구 플래그를 보정한다.

사망: 마지막 저장 위치·플래그로 복귀하고 현재 최대 HP까지 회복한다. 저장이 없으면 집에서 새 런을 시작한다. **F5: 새 런으로 시작하되 저장 파일은 삭제하지 않는다.** 다음 실행은 남아 있는 마지막 저장을 재개한다.

저장 경로는 프로젝트별 임시 다운로드 폴더와 무관한 사용자 데이터 폴더다.

- Windows: `%APPDATA%\Nimrod\save.json`
- Linux: `$XDG_DATA_HOME/Nimrod/save.json` (기본 `~/.local/share/Nimrod/save.json`)
- macOS: `~/Library/Application Support/Nimrod/save.json`

회귀 테스트는 테스트별 별도 사용자 폴더와 전용 파일명을 사용한다.
