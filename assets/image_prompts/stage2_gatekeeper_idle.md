# gatekeeper / idle

Purpose: stage 2 character animation.

Output: `assets/sprites/npcs/gatekeeper/idle.png`

Frames: 6 × 640x640, one horizontal row; duration 2.4s; anchor [320,600].

Background: request flat #FF00FF, chromakey with tools/pack_sprites.py to RGBA.

The generated still is packed then six subtle breathing frames are derived by tools/make_breathing_sheet.py; feet stay fixed.

Complete generation prompt:

2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark. Repaint this worker atlas exactly THREE ROWS, firsttwo rows8frames, lastrow5frames andemptyrest, pure #FF00FF. CRITICAL SPRITE REQUIREMENT: every character stays UPRIGHT and crownofHEAD at exactly SAME HEIGHT, feet fixed SAME baseline in EVERY pose. No deepwaistbends. Sweep by moving shoulders/ARMS and thebroom angle alongfloor. All broom handles stay LOWER thanHEAD, broombristles atFOOTbaseline. Exactly8genuinelydifferent arm+broom sweep poses foreachservant; preserve originalsamefaces/clothesidentities. Thirdrowkeeper5poses, keep head/feetandstaffsameheight, rightarmgestures no handabovehead, firstrest,secondstart raising,thirdfullyextendpalm towardgate, fourthbeckon/fifthrelax. 21 fullypainted poses, naturaladultshortfantasyfolk, equalbodyheight perrow, sideviewright. Allisolated withmagenta gaps; noobjectsclip/touchcells, no text/numbers/frames.
