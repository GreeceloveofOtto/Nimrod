# player_run

목적: 니므롯 run 모션

최종 파일·시트 크기:

- assets/sprites/run.png: 6400x640

프레임: 10. 배경: 스프라이트·투명 소품은 단색 #FF00FF로 생성 후 크로마키; 불투명 배경은 알파 255.
앵커: [320,600], 하단 중앙 정렬.

생성·후처리 기록: {"source": "source_art/stage4/run_atlas.png", "scale": 0.8864265927977839, "source_pose_sizes": [[295, 361], [314, 361], [254, 361], [304, 361], [332, 361], [304, 361], [318, 361], [257, 361], [296, 361], [344, 361]], "normalization": "Uniformly resize each complete generated pose to the first source pose height; packed height 320px"}; tools/build_stage4_player.py → pack_sprites chromakey → 640 프레임. 전체 18종 검증 후 적용; 기존 PNG는 _legacy_player에 보존.

완성 생성 프롬프트:

2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark. Exact Nimrod in reference with black curly hair, diamond bronze straps black tattered tunic boots wraps and large crescent axe opposite spike. RUN animation exactly TEN different full-body poses in TWO rows FIVE columns equal cells. Solid #FF00FF background. VERY GENEROUS magenta margins inside every cell; absolutely no touching silhouettes, whole axe hair cloth and boots inside each cell. Same anatomical size/limb lengths all frames. All face RIGHT and run to RIGHT: contact stride, compress down, passing support, pushing up, airborne long stride, opposite-foot contact, compression, passing, push off, airborne. Axe trails behind close to body, hair/torn cloth follow momentum. Natural animated gait, no text, no gridlines, no glowing effects.
Negative: ancient costume, toga, loincloth, tiered fringe skirt, royal crown, mythological robe, veil, altar, temple priestess outfit, excessive jewelry, gaudy, halo, divine aura, glowing mystical effects, black outline
