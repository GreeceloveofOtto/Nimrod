# ranged_beast_flame

목적: 원거리 괴수 입에서 뻗는 화염 루프

저장 경로: `assets/sprites/enemies/ranged_beast/flame.png`

최종 크기: 3072x256px. 프레임 구성: 6프레임, 프레임당 512x256px, 한 줄, 0.36초 루프.

배경 처리: 단색 마젠타 #FF00FF 생성 → 크로마키 투명 RGBA

후처리: --frame-width 512 --frame-height 256 --anchor 16,128 --alignment left-center --fit 480,200. 게임에서 판정 길이 약 220px로 표시.

## 완성 생성 프롬프트

2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark. 니므롯 스프라이트와 동일한 2D 다크 판타지, 고대 메소포타미아(우루크) 분위기. Match assets/sprites/idle.png and attack_4.png: muted hand-painted charcoal shadows, warm bronze highlights, readable realistic forms, restrained saturation and consistent soft-edged dark outlines. Exactly six separate flame plume animation poses in one horizontal row, fire begins on the LEFT and extends RIGHT, orange and red flame with small pale hot cores, body and scenery excluded. Consistent left emission anchor, turbulent tips change between frames. Each cell 512x256px. Pure solid magenta #FF00FF background; no smoke beyond cell. Final emission anchor [16,128]; render plume to cover approximately 220x60px gameplay hit area.
