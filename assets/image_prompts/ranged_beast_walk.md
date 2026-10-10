# ranged_beast_walk

목적: 우루크 원거리 괴수 walk 애니메이션

저장 경로: `assets/sprites/enemies/ranged_beast/walk.png`

최종 크기: 5120x640px. 프레임 구성: 8프레임, 프레임당 640x640px, 한 줄, 오른쪽 기준; 1.0초; 루프 예.

배경 처리: 생성 원본은 완전 단색 마젠타 #FF00FF. tools/pack_sprites.py로 마젠타를 투명 처리하고 RGBA PNG로 패킹.

후처리: idle 첫 프레임 기준 공통 배율을 모든 클립에 유지. 각 프레임은 하단 중앙 [320,600] 정렬. turn 클립은 프레임 3 시작 시 flip_h 전환. 프레임/크기 검사는 tools/validate_assets.py.

## 완성 생성 프롬프트

2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark. 니므롯 스프라이트와 동일한 2D 다크 판타지, 고대 메소포타미아(우루크) 분위기. Match assets/sprites/idle.png and attack_4.png: muted hand-painted charcoal shadows, warm bronze highlights, readable realistic forms, restrained saturation and consistent soft-edged dark outlines. crocodile-headed giraffe-bodied beast, green-gray and charcoal hide, long neck, side view facing right. Long giraffe neck and torso, slender legs, crocodile snout with teeth, green-gray and charcoal textured hide, small threatening eyes. Animation: Eight long-striding thin-legged walking poses, neck balances gait. Generate exactly 8 separately spaced full-body poses in one horizontal row, equal empty margins, do not overlap or crop any limb or horn. Keep anatomy, lighting, hide colors and scale identical in every pose. Pure solid magenta #FF00FF background, no shadows outside the character. Subject baseline consistent. Final 640x640 cells with foot anchor [320,600], body occupies approximately 380x600px. Use the idle first frame as the fixed visual identity reference.
