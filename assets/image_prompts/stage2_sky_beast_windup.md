# sky_beast / windup

Purpose: stage 2 character animation.

Output: `assets/sprites/enemies/sky_beast/windup.png`

Frames: 4 × 768x640, one horizontal row; duration 0.4s; anchor [384,320].

Background: request flat #FF00FF, chromakey with tools/pack_sprites.py to RGBA.

Every pose is painted by the image-generation tool; no cloned action frames.

Complete generation prompt:

2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark. Animation sprite atlas, PURE #FF00FF magenta background. A single identical heron-swan hybrid giant bird, long neck, large white and blue-gray wings, ominous, side view facing right. Detailed pale feather edges with darkcharcoal thin outline, muted bluegray shadows, small amber eye, longblackdaggerbeak, unsettling noble grace. Match reference hand-painted lighting from upperleft. FOUR horizontal rows of equalheight and SIX equallyspaced cells perrow. Maximum canvas resolution. All wings, beak, feet completely insidecells, generous magenta gaps, no parts touching adjacentbirds. Every row uses only specified cells; leave remainingcells absolutely magenta. Row1 ALL6CELLS: six distinct sequential FLY_IDLE wingbeats, wings highspread to midspread to deepdownstroke then recover, longneckcurved facingright. Row2 FIRST4CELLS: four WINDUP threat poses, bird spreads wings wide, graduallyrearsback and brightens whitish highlights onfeathers as a warning (painted flash). Row3 FIRST3CELLS: three DIVE poses, wings folded tightly back, neckextended and sharpbeak to right/downright, streamlined attackbody. Row4 FIRST4CELLS: four RECOVERY poses, braking wingflaps and startingascent, neckcurled facingright. DO NOT draw ground, shadows, smoke, projectiles or scene. Exactly6+4+3+4=17 isolated fullypainted birdposes. Bird identity/size/featherpatterns consistent, no duplicates, no words no grid lines.
