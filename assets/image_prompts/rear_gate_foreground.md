# rear_gate_foreground

목적: 화면 앞쪽 잔해, 기둥과 마른 풀

저장 경로: `assets/backgrounds/rear_gate/foreground.png`

최종 크기: 3328x720px. 프레임 구성: 정지 이미지 1프레임.

배경 처리: 단색 마젠타 #FF00FF 생성 → 크로마키 투명 RGBA PNG

카메라 이동량 2320px. 필요한 최소 너비 = 1280 + 2320 × 스크롤 비율.

## 완성 생성 프롬프트

2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark. 니므롯 스프라이트와 동일한 2D 다크 판타지, 고대 메소포타미아(우루크) 분위기. Match assets/sprites/idle.png and attack_4.png: muted hand-painted charcoal shadows, warm bronze highlights, readable realistic forms, restrained saturation and consistent soft-edged dark outlines. Wide foreground panorama of dark broken stone columns, low rubble and dry grass concentrated at lower edges. Leave the central band at character height widely clear so gameplay remains visible. Sparse tall columns at far margins only. All empty areas pure solid magenta #FF00FF, no sky, no characters. Output final image size 3328x720px. Keep painting style consistent with the supplied Nimrod sprite reference.

최종 시야 보정: 양 끝3%폭에 높이40%이하의 작은 기둥만 두고, 중앙5~95%폭의 상단95%높이는 비웁니다. 잔해와 풀은 하단4%에만 배치해 시작 위치x260의 플레이어를 가리지 않게 생성합니다.
