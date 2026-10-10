# player_attack_4

목적: 니므롯 attack_4 모션

최종 파일·시트 크기:

- assets/sprites/attack_4.png: 6400x640

프레임: 10. 배경: 스프라이트·투명 소품은 단색 #FF00FF로 생성 후 크로마키; 불투명 배경은 알파 255.
앵커: [320,600], 하단 중앙 정렬.

생성·후처리 기록: {"source": "source_art/stage4/attack_4_clean_atlas.png", "scale": 1.2181208053691275, "source_pose_sizes": [[165, 278], [289, 263], [256, 301], [346, 305], [432, 231], [380, 223], [425, 192], [291, 191], [285, 280], [178, 298]], "frame_4_source": "source_art/stage4/attack_1_clean_atlas.png; second row first generated descending strike pose"}; tools/build_stage4_player.py → pack_sprites chromakey → 640 프레임. 전체 18종 검증 후 적용; 기존 PNG는 _legacy_player에 보존.

완성 생성 프롬프트:

2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark. PORTRAIT animation sheet with FIVE ROWS TWO COLUMNS, exactly ten figures. Characters are SMALL inside very spacious equal cells with at least 20% EMPTY magenta margins on ALL sides. Pure #FF00FF background. NO SILHOUETTES TOUCH, no overlap, full axe blade/handle and feet completely visible each cell. Exact reference Nimrod identity black curly hair, diamond bronze straps/belt over practical black tattered tunic, crescent steel axe opposite spike, wrapped boots. All movement attacks RIGHT. Read row1left,row1right,row2left,row2right,etc. Frame1ready,2liftshoulder,3axeoverhead,4startswingRIGHT,5extendbladeRIGHTchest,6bladeapproachesgroundRIGHT,7bladeflatonthegroundRIGHT,8recoilbladegroundlow,9recoverliftingblade,10standready. Same anatomy and relative scale throughout, clear anticipation-strike-followthrough, cloth overlap. No text, grids or motion effects.

활성 첫 포즈에 재사용한 하강 베기 원본 요청:
2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark. PORTRAIT animation sheet with FOUR ROWS TWO COLUMNS, exactly eight figures. Characters are SMALL inside very spacious equal cells with at least 20% EMPTY magenta margins on ALL sides. Pure #FF00FF background. NO SILHOUETTES TOUCH, no overlap, full axe blade/handle and feet completely visible each cell. Exact reference Nimrod identity black curly hair, diamond bronze straps/belt over practical black tattered tunic, crescent steel axe opposite spike, wrapped boots. All movement attacks RIGHT. Read row1left,row1right,row2left,row2right,etc. Frame1anticipatelow,2raise overhead,3descendingforwardbladeatRIGHTchest,4bladefullyextendedRIGHTwaist,5bladeforwardlowRIGHT,6lowfollowthrough,7recoverlow,8standready. Same anatomy and relative scale throughout, clear anticipation-strike-followthrough, cloth overlap. No text, grids or motion effects.
Negative: ancient costume, toga, loincloth, tiered fringe skirt, royal crown, mythological robe, veil, altar, temple priestess outfit, excessive jewelry, gaudy, halo, divine aura, glowing mystical effects, black outline
