# player_idle

목적: 니므롯 idle 모션

최종 파일·시트 크기:

- assets/sprites/idle.png: 6400x640

프레임: 10. 배경: 스프라이트·투명 소품은 단색 #FF00FF로 생성 후 크로마키; 불투명 배경은 알파 255.
앵커: [320,600], 하단 중앙 정렬.

생성·후처리 기록: {"source": "source_art/stage4/locomotion_atlas.png", "scale": 1.4015444015444016, "source_pose_sizes": [[170, 259], [158, 258], [139, 258], [146, 258], [155, 258], [140, 259], [143, 260], [148, 259], [153, 259], [158, 259]]}; tools/build_stage4_player.py → pack_sprites chromakey → 640 프레임. 전체 18종 검증 후 적용; 기존 PNG는 _legacy_player에 보존.

완성 생성 프롬프트:

2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark. Exact character in reference: curly black hair, black high neck tattered practical tunic with bronze diamond straps, boots and wrist wraps, steel crescent axe opposite spike. Animation atlas exactly 3 rows and 10 columns, equal grid cells, pure solid #FF00FF background, separate complete figures with generous margins and consistent standing anatomical height. All face RIGHT. Row 1 ten subtly different breathing guarded idle poses axe held low, row 2 ten sequential natural walking poses contact down passing up with alternating feet and weight transfer, row 3 ten sequential running poses body leans forward, axe trails behind, both feet in alternating airborne/contact phases. No separators or labels. Smooth cyclic last to first, detailed readable game sprites. Draw every figure entire axe and feet. Character pose must vary, identity and costume identical.
Negative: ancient costume, toga, loincloth, tiered fringe skirt, royal crown, mythological robe, veil, altar, temple priestess outfit, excessive jewelry, gaudy, halo, divine aura, glowing mystical effects, black outline
