#!/usr/bin/env python3
"""Write complete reproducible generation requests alongside final asset paths."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
A = ROOT / 'assets'
PROMPTS = json.loads((A / 'source_art/stage4/generation_prompts.json').read_text())
PERSON = '2D side-view game character sprite, advanced space-faring civilization, near-future sci-fi fantasy, practical yet elegant tailored clothing, only subtle Mesopotamian motif accents, NOT ancient costume, NOT mythological robes, NOT gaudy, soft warm rim light on the light-facing edge, no black outline, no text, no watermark'
NEGATIVE = 'ancient costume, toga, loincloth, tiered fringe skirt, royal crown, mythological robe, veil, altar, temple priestess outfit, excessive jewelry, gaudy, halo, divine aura, glowing mystical effects, black outline'


def write(name, paths, prompt, purpose, notes, frames=1, anchor=None):
    sizes = []
    for path in paths:
        im = Image.open(A / path)
        sizes.append(f'assets/{path}: {im.width}x{im.height}')
    text = f'# {name}\n\n목적: {purpose}\n\n최종 파일·시트 크기:\n\n'
    text += '\n'.join('- ' + s for s in sizes)
    text += f'\n\n프레임: {frames}. 배경: 스프라이트·투명 소품은 단색 #FF00FF로 생성 후 크로마키; 불투명 배경은 알파 255.\n'
    if anchor:
        text += f'앵커: {anchor}, 하단 중앙 정렬.\n'
    text += f'\n생성·후처리 기록: {notes}\n\n완성 생성 프롬프트:\n\n{prompt}\n'
    (A / 'image_prompts' / f'stage4_{name}.md').write_text(text)


def main():
    manifest = json.loads((A / 'animation_manifest.json').read_text())
    packing = json.loads((A / 'source_art/stage4/player_packing.json').read_text())
    for c in manifest['clips']:
        n = c['name']
        source = Path(packing[n]['source']).stem.replace('_atlas', '')
        key = {'locomotion': 'locomotion', 'crouch': 'crouch', 'airborne': 'airborne', 'responses': 'responses'}.get(source, source)
        prompt = PROMPTS[key]
        notes = json.dumps(packing[n], ensure_ascii=False) + '; tools/build_stage4_player.py → pack_sprites chromakey → 640 프레임. 전체 18종 검증 후 적용; 기존 PNG는 _legacy_player에 보존.'
        if n == 'roll':
            prompt += '\n\n구르기 중앙 5포즈 재생성 요청:\n' + PROMPTS['roll_compact']
        if n == 'attack_1':
            prompt += '\n\n마지막 대기 포즈 원본 요청:\n' + PROMPTS['attack_1']
        if n == 'attack_4':
            prompt += '\n\n활성 첫 포즈에 재사용한 하강 베기 원본 요청:\n' + PROMPTS['attack_1_clean']
        write('player_' + n, [c['sheet']], prompt + '\nNegative: ' + NEGATIVE, '니므롯 ' + n + ' 모션', notes, c['frames'], '[320,600]')
    stats = {n['id']: n for n in json.loads((ROOT / 'data/npcs.json').read_text())['npcs']}
    for n in ['lugalbanda', 'ninsun', 'shamhat', 'inanna', 'papsukkal', 'shamash', 'aya']:
        existing = n not in ['shamash', 'aya']
        prompt = (PERSON + f'. Use the exact existing {n} design sheet as reference. Comfortable complete FRONT standing pose looking at camera, same face hair and tailored costume, solid #FF00FF background, character height {round(363 * stats[n]["height_ratio"])}px in 640x640 frame, feet at [320,600], generous margins. Warm #FFE8C4 rim light 4-6px inside edge at 35-45% opacity. Negative: ' + NEGATIVE) if existing else PROMPTS['couple_design']
        notes = '이전 대화에서 생성한 assets/reference/' + n + '_design.png의 첫 열을 그대로 재사용. 신규 이미지 생성 없이 크로마키·키 정렬·림라이트·허용된 6프레임 숨쉬기 파생.' if existing else 'source_art/stage4/couple_design_atlas.png에서 해당 인물 디자인·정면·측면 추출. make_breathing_sheet.py와 add_rim_light.py 사용.'
        paths = ['sprites/npcs/' + n + '/idle_front.png']
        if not existing:
            paths += ['sprites/npcs/' + n + '/idle.png', 'reference/' + n + '_design.png']
        write('npc_' + n, paths, prompt, stats[n]['display_name'] + ' 정면 숨쉬기' + ('' if existing else '·측면·디자인'), notes, '6 / 2.4초 루프', '[320,600]')
    groups = {
        'bg': ['backgrounds/outskirts/' + n + '.png' for n in ['sky', 'far_city_tile', 'mid_ruins_tile', 'far_landmark']],
        'ruins': ['props/' + n + '.png' for n in ['ruin_wall_a', 'ruin_wall_b', 'broken_tower', 'chasm_edge_left', 'chasm_edge_right', 'collapsed_bridge', 'upper_walkway']],
        'props': ['props/' + n + '.png' for n in ['large_rubble_a', 'large_rubble_b', 'dead_tree', 'crashed_pod_wreck', 'outskirts_lamp']],
        'tiles': ['tiles/outskirts/' + n + '.png' for n in ['ground_tile', 'plaza_tile', 'ruin_platform', 'bridge_platform', 'ruin_ledge']] + ['tiles/underground_fill.png'],
        'villa': ['backgrounds/villa/villa_f2_dining.png', 'backgrounds/villa/villa_f3_chamber.png'],
        'villa_props': ['props/' + n + '.png' for n in ['villa_dining_table_wide', 'villa_chairs', 'villa_sofa', 'villa_side_table']] + ['props/doors/villa_back_door.png'],
        'nimrod_base': ['reference/nimrod_design.png', 'reference/nimrod_base_right.png', 'reference/nimrod_base_rear.png', 'reference/nimrod_base_three_quarter.png'],
    }
    for key, paths in groups.items():
        for path in paths:
            frames = 6 if path.endswith('villa_back_door.png') else 1
            write(Path(path).stem, [path], PROMPTS[key], '4단계 ' + Path(path).stem, f'source_art/stage4/{key}_atlas.png; tools/build_stage4_assets.py의 명시적 crop/resize. 타일은 기존 가장자리 픽셀 블렌드로 이음새 정렬. 원본 픽셀을 새로 그리지 않음.', frames)
    master = json.loads((A / 'art_manifest.json').read_text())
    for path in ['source_art/stage4/generation_prompts.json', 'source_art/stage4/player_packing.json']:
        if path not in master['source_metadata']:
            master['source_metadata'].append(path)
    (A / 'art_manifest.json').write_text(json.dumps(master, ensure_ascii=False, indent=2) + '\n')
    print('Stage 4 complete prompts written; all final assets have generation/packing records.')


if __name__ == '__main__':
    main()
