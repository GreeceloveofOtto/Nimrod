# cook_b / stir

Purpose: stage 2 character animation.

Output: `assets/sprites/npcs/cook_b/stir.png`

Frames: 6 × 640x640, one horizontal row; duration 1.6s; anchor [320,600].

Background: request flat #FF00FF, chromakey with tools/pack_sprites.py to RGBA.

Every pose is painted by the image-generation tool; no cloned action frames.

Complete generation prompt:

2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark. Repaint the attached cook atlas with exactly same three characters and 3 rows x6 animation frames, pure #FF00FF background. CRITICAL SPRITE REQUIREMENT: all characters keep their HEADS at exactly the SAME HEIGHT throughout their six poses. Their feet have exact same baseline. Only ARMS, HANDS, and subtle shoulder/torso rotations change. Cook A knife must ALWAYS be BELOW HEAD HEIGHT, use small careful chopping between chest and waist, NEVER raise knife over head. Cook B stir arms in a circle while upright. Cook C move food plates with arms while upright. Avoid any bending that changes crown-of-head or foot level. All body silhouettes must have almost identical bounding-box heights within each row. All eighteen full-body poses facing right; six genuinely different poses perrow, original characteridentity/costume maintained. No furniture, no table, no stove, onlyheldutensils. Generate exactly six aligned frames each row, ample magenta spacing, no text/numbers.
