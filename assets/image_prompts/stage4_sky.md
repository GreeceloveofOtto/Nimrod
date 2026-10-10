# sky

목적: 4단계 sky

최종 파일·시트 크기:

- assets/backgrounds/outskirts/sky.png: 1792x720

프레임: 1. 배경: 스프라이트·투명 소품은 단색 #FF00FF로 생성 후 크로마키; 불투명 배경은 알파 255.

생성·후처리 기록: source_art/stage4/bg_atlas.png; tools/build_stage4_assets.py의 명시적 crop/resize. 타일은 기존 가장자리 픽셀 블렌드로 이음새 정렬. 원본 픽셀을 새로 그리지 않음.

완성 생성 프롬프트:

2D side-view game asset, dark fantasy, ancient Mesopotamian Uruk atmosphere, hand-painted look, clean readable silhouette, consistent with the Nimrod character sprite sheets, no text, no watermark
Environmental layer atlas FOUR evenly separated horizontal ROWS. Top row opaque deep indigo dusk sky with red horizon and giant pale planet. Second row distant blue-gray Uruk city and ziggurat silhouettes and light mist on pure magenta #FF00FF; left/right seamlessly repeatable skyline tile. Third row dark broken walls and ruins skyline with sparse amber lights, pure magenta, seamless left/right edges. Fourth row ONLY isolated ominous black-violet castle tower spire silhouette rising tall on left with crimson lit windows, pure magenta. Flat 2D horizontal scrolling game perspective. No terrain in front of character height, no grass/rock foreground layer. Clean generous magenta gutters between rows. Preferred 2048x2048 atlas. Consistent palette existing rear gate backgrounds. Output PNG.
