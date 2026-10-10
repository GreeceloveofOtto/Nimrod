# player_land

목적: 니므롯 land 모션

최종 파일·시트 크기:

- assets/sprites/land.png: 3200x640

프레임: 5. 배경: 스프라이트·투명 소품은 단색 #FF00FF로 생성 후 크로마키; 불투명 배경은 알파 255.
앵커: [320,600], 하단 중앙 정렬.

생성·후처리 기록: {"source": "source_art/stage4/responses_atlas.png", "scale": 1.5381355932203389, "source_pose_sizes": [[225, 245], [248, 164], [202, 133], [174, 192], [143, 236]]}; tools/build_stage4_player.py → pack_sprites chromakey → 640 프레임. 전체 18종 검증 후 적용; 기존 PNG는 _legacy_player에 보존.

완성 생성 프롬프트:

2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark. Exact reference Nimrod character, crescent axe, black curly hair, bronze diamond straps, tattered black tunic boots wraps. Animation atlas FOUR rows EIGHT columns equal cell widths, pure #FF00FF, all RIGHT direction. Row1 first FIVE sequential landing poses feet impact, knees bend deep, rebound rise to stand; last3cells EMPTY. Row2 first FIVE sequential drop through platform poses knees tuck then feet descend and spread to land; last3 EMPTY. Row3 first FIVE hurt recoil poses body bends backward, head delayed, axe lowers, recovery; last3 EMPTY. Row4 EIGHT sequential death poses stand wounded, knees buckle, kneel, collapse sideways, prone finalbody. Entire figures and axe, generous gaps, preserve anatomical scale and character design across poses. No text, no lines.
Negative: ancient costume, toga, loincloth, tiered fringe skirt, royal crown, mythological robe, veil, altar, temple priestess outfit, excessive jewelry, gaudy, halo, divine aura, glowing mystical effects, black outline
