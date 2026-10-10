# sky_beast / turn

Purpose: stage 2 character animation.

Output: `assets/sprites/enemies/sky_beast/turn.png`

Frames: 4 × 768x640, one horizontal row; duration 0.25s; anchor [384,320].

Background: request flat #FF00FF, chromakey with tools/pack_sprites.py to RGBA.

Every pose is painted by the image-generation tool; no cloned action frames.

Complete generation prompt:

2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark. Animation sprite atlas, PURE flat #FF00FF magenta background. Consistent same heron-swan hybrid giant bird, long neck, large white and blue-gray wings, ominous, side view facing right. Whitefeathers with mutedbluegray shadow, darkthin readable contours, amber eyes, longblackdaggerbeak, handpainted referenceNimrodstyle/lightupperleft. THREE horizontal rows, SIX evenlyspaced cells perrow. Maximum canvasresolution; eachbird fullyinsideitscell, generous magenta gaps, wings/beak neverclip. ROW1 firstFOURcells TURN animation: pose1 sideview right wingsraised, pose2 bodytwisting tothreequarterfront, pose3 exactlyFRONTAL nearbilateralsymmetrical withhead/neckcentred andmatchingwings (thisframeengineflips), pose4 rightsideview landingthenrecovering flight (engineflipsfinaltwoframes toturnleft). Remaining2cellsmagenta. ROW2 firstTWOcells HURT: rightfacingbird recoilrunt, wingscontracting and neck recoiling thenstaggered spread. Remaining4cellsmagenta. ROW3 allSIXcells DEATH: sixdifferent actualpainted spiralplummetposes ofsamebird, beginsflinching wingscollapse, foldsneck, rollsrightward by quarterturn, spiralsupsidedown, tumblesheadfirst, finalcrumpledwingsfoldedpose. No corpseground, no effecttrail. Fullpaintedbird visibleallposes. Exactly4+2+6=12 poses. No words labels frames or gridlines.
