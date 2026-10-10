# player_jump_start

목적: 니므롯 jump_start 모션

최종 파일·시트 크기:

- assets/sprites/jump_start.png: 2560x640

프레임: 4. 배경: 스프라이트·투명 소품은 단색 #FF00FF로 생성 후 크로마키; 불투명 배경은 알파 255.
앵커: [320,600], 하단 중앙 정렬.

생성·후처리 기록: {"source": "source_art/stage4/airborne_atlas.png", "scale": 1.1089613034623218, "source_pose_sizes": [[241, 232], [258, 201], [258, 253], [213, 296]]}; tools/build_stage4_player.py → pack_sprites chromakey → 640 프레임. 전체 18종 검증 후 적용; 기존 PNG는 _legacy_player에 보존.

완성 생성 프롬프트:

2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark. Reference character Nimrod with exactly same black curly hair, diamond straps and steel crescent axe. Animation atlas 3 rows SIX columns equal cells, pure solid #FF00FF, full separate bodies axe and feet within cells, all face RIGHT. First row FOUR sequential jump startup poses: compress squat, deeper squat, push off, toes leaving ground; final two cells EMPTY magenta. Second row SIX sequential jump rise poses: upward extension then knees drawn up, axe behind body, coat and hair follow movement. Third row SIX sequential fall loop poses: spread arms holding axe to balance, fabric floats up, legs prepare to land. Natural animation varied poses, same anatomical body scale. No labels, no separators.
Negative: ancient costume, toga, loincloth, tiered fringe skirt, royal crown, mythological robe, veil, altar, temple priestess outfit, excessive jewelry, gaudy, halo, divine aura, glowing mystical effects, black outline
