# player_roll

목적: 니므롯 roll 모션

최종 파일·시트 크기:

- assets/sprites/roll.png: 6400x640

프레임: 10. 배경: 스프라이트·투명 소품은 단색 #FF00FF로 생성 후 크로마키; 불투명 배경은 알파 255.
앵커: [320,600], 하단 중앙 정렬.

생성·후처리 기록: {"source": "source_art/stage4/roll_atlas.png", "scale": 0.9945205479452055, "source_pose_sizes": [[350, 247], [318, 218], [245, 305], [290, 266], [357, 266], [355, 232], [344, 233], [315, 271], [283, 343], [321, 365]], "compact_frames": {"frames": [2, 3, 4, 5, 6], "source": "source_art/stage4/roll_compact_atlas.png", "scale": 0.37825059101654845, "maximum_packed_height_px": 160}}; tools/build_stage4_player.py → pack_sprites chromakey → 640 프레임. 전체 18종 검증 후 적용; 기존 PNG는 _legacy_player에 보존.

완성 생성 프롬프트:

2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark. Exact referenced Nimrod game character black curly hair, black tunic bronze diamond straps, crescent axe. Animation atlas TWO rows FIVE columns equal cells pure #FF00FF. Read left to right top row then bottom row TEN distinct sequential somersault roll poses toward RIGHT:1quick low crouch,2tucked forward,3upside down compact,4tucked back,5tucked low,6compact completing roll,7uncoil low,8kneeling,9rising,10standing ready. Fold axe close to body, body rotates with feet and head alternating, cloth follows. Anatomical size remains consistent, entire feet axe hair visible no cropped figures. No text or separators.

구르기 중앙 5포즈 재생성 요청:
2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark. Exactly FIVE compact rolling poses in ONE horizontal row. Full separate game sprite silhouettes on pure #FF00FF, generous gaps, all rolling toward RIGHT. Exact reference Nimrod black curly hair black tunic bronze diamond straps boots wraps crescent axe. EVERY POSE tightly curled into a SMALL ROUND BALL: knees tucked to chest, chin tucked, elbows folded, axe folded close with shaft across belly and blade protected. NO extended legs, feet or arms. Frame1front diagonal tuck,2upside-down tightly curled knees at forehead,3back-down compact tuck,4side-down round tuck,5forward-down completing rotation. Anatomical proportions identical but body folded naturally, head size remains realistic. Fabric folds around ball and moves slightly. Each circle silhouette roughly equally tall and wide, no larger than 45% of standing character height. No pose outside compact ball except small axe blade. No text or lines.
Negative: ancient costume, toga, loincloth, tiered fringe skirt, royal crown, mythological robe, veil, altar, temple priestess outfit, excessive jewelry, gaudy, halo, divine aura, glowing mystical effects, black outline
