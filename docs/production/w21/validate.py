"""Check the pinned W21 asset and storyboard ledgers using the standard library."""

import argparse
import csv
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
WORK_ORDER = HERE.parent / 'W21_PRODUCTION_ASSET_AUDIT.md'
PLACEHOLDER = re.compile(r'\bplaceholder\b', re.IGNORECASE)
MEDIA = re.compile(r'''res://([^"'\n]+\.(?:png|jpg|jpeg|svg|webp|ttf|otf|ogg|wav|mp3|flac|opus))(?=["'])''', re.I)
COUNTS = {
    'ranger_kit': 12, 'facility_state': 65, 'enemy_kit': 15, 'boss_kit': 3,
    'boss_portrait': 3, 'dialogue_portrait': 3, 'dialogue_pose': 10,
    'outreach_pose': 4, 'hq_room': 11, 'board_geometry': 6, 'region_backdrop': 6,
    'atlas_piece': 56, 'modifier_icon': 30, 'tree_stage': 12, 'garden_art': 7,
    'scout_part': 19, 'archive_illustration': 10,
}


def need(condition, message):
    if not condition:
        raise ValueError(message)


def load_csv(filename, key):
    with (HERE / filename).open(encoding='utf-8', newline='') as source:
        rows = list(csv.DictReader(source))
    values = {row[key]: row for row in rows}
    need(len(values) == len(rows) and '' not in values, f'Duplicate or empty IDs in {filename}')
    return values


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def check_tickets(ids, defined, key):
    need(ids and set(ids.split('|')) <= defined, f'{key} has an undefined production ticket')


def check_paths(field, info):
    for path in filter(None, field.split('|')):
        need((ROOT / path).is_file(), f'{info} cites missing repository evidence {path}')


def check_catalog(assets):
    families = Counter(row['family'] for row in assets.values())
    for family, quantity in COUNTS.items():
        need(families[family] == quantity, f'{family} has {families[family]} records, expected {quantity}')
    catalog = (ROOT / 'docs/canon/SYSTEMS_INDEX.md').read_text(encoding='utf-8')
    facility_states = {'card', 'placement', 'construction', 'operational', 'siege_loss'}
    stage_paths = {'seed', 'sapling', 'mature'}
    for family, prefix in [('ranger_kit', 'ranger'), ('boss_kit', 'boss'), ('hq_room', 'room')]:
        ids = set(re.findall(rf'`({prefix}\.[a-z0-9_]+)`', catalog))
        need({key for key, row in assets.items() if row['family'] == family} == ids, f'Canon IDs differ for {family}')
    facilities = set(re.findall(r'`(facility\.[a-z0-9_]+)`', catalog))
    expected = {f'{facility}.state.{state}' for facility in facilities for state in facility_states}
    need({key for key, row in assets.items() if row['family'] == 'facility_state'} == expected, 'Facility states differ from canon')
    need({key for key, row in assets.items() if row['family'] == 'enemy_kit'} == {f'E{number:02}' for number in range(1, 16)},
         'Enemy kit IDs differ from canon')
    for number in range(1, 57):
        atlas = assets[f'KRT_{number:02}']
        need(atlas['runtime_status'] == 'CANDIDATE' and not atlas['repository_file'], 'Atlas availability needs review')
    maps = {f'T{number:02}' for number in range(1, 7)}
    need({key for key, row in assets.items() if row['family'] == 'board_geometry'} == maps, 'Map layouts differ')
    need({key for key, row in assets.items() if row['family'] == 'region_backdrop'} == {f'backdrop.{key}' for key in maps},
         'Region backdrops differ')
    modifiers = {f'icon.modifier.{kind}{entry:02}' for entry in range(1, 16) for kind in 'BD'}
    need({key for key, row in assets.items() if row['family'] == 'modifier_icon'} == modifiers, 'Modifier IDs differ')

    speakers = read_json(ROOT / 'docs/production/w13/campaign.json')['speakers'].values()
    portraits = {speaker['portrait_key'] for speaker in speakers}
    poses = {f'{speaker["portrait_key"]}.pose.{pose}' for speaker in speakers for pose in speaker['pose_keys']}
    need({key for key, row in assets.items() if row['family'] in {'boss_portrait', 'dialogue_portrait'}} == portraits,
         'Portrait keys differ from the campaign')
    need({key for key, row in assets.items() if row['family'] == 'dialogue_pose'} == poses, 'Pose keys differ from the campaign')

    garden = read_json(ROOT / 'assets/source-art/restoration/manifest.json')
    expected = [garden['board_art'], garden['plot_art'], garden['guide_art'], garden['nest_box']['prop'], garden['nest_box']['visitor']]
    expected.extend(garden['effects'].values())
    for tree in garden['species'].values():
        need(set(tree['stage_assets']) == stage_paths, 'Garden stage contract differs')
        expected.extend(tree['stage_assets'].values())
    for item in expected:
        row = assets[item['id']]
        expected_path = item['texture'].removeprefix('res://')
        need(row['runtime_status'] == 'LIVE_TEXTURE' and row['repository_file'] == expected_path,
             f'Garden binding differs for {item["id"]}')


def check_live_sources(assets, surfaces):
    tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
    inspected = [path for path in tracked if path.endswith(('.tscn', '.tres', '.gd'))
                 and path.startswith(('scenes/', 'scripts/', 'resources/', 'data/'))]
    inspected.extend(['project.godot', 'export_presets.cfg'])
    text = {path: (ROOT / path).read_text(encoding='utf-8') for path in inspected}
    media_refs = {ref for contents in text.values() for ref in MEDIA.findall(contents)}
    listed_files = {row['repository_file'] for row in assets.values() if row['repository_file']}
    need(media_refs <= listed_files, f'Unmapped static media references {sorted(media_refs - listed_files)}')
    textures = {row['repository_file'] for row in assets.values() if row['runtime_status'] in {'LIVE_TEXTURE', 'QA_TEXTURE'}}
    scanned_textures = {path.relative_to(ROOT).as_posix() for path in (ROOT / 'assets/imported').rglob('*')
                        if path.is_file() and path.suffix in {'.png', '.jpg', '.svg', '.webp'}}
    need(textures == scanned_textures, 'Imported texture inventory differs')
    need(not any(path.endswith(('.wav', '.ogg', '.mp3', '.flac', '.opus')) for path in tracked), 'Audit newly added audio files')
    playback = {path for path, block in text.items() if re.search(r'\bAudioStreamPlayer(?:2D|3D)?\b', block)}
    audio_bindings = {path for row in assets.values() if row['family'] == 'audio'
                      for path in row['binding_paths'].split('|') if path}
    need(playback <= audio_bindings, f'Unmapped playback nodes {sorted(playback - audio_bindings)}')

    source_markers = {(path, index) for path, block in text.items() if path.endswith(('.tscn', '.gd'))
                      for index, line in enumerate(block.splitlines(), 1) if PLACEHOLDER.search(line)}
    registered = {(row['evidence_path'], int(row['locator'])) for row in surfaces.values() if row['kind'] == 'literal'}
    need(source_markers == registered, f'Unmatched literal placeholder locations {sorted(source_markers ^ registered)}')
    draw_sites = {path for path, block in text.items() if re.search(r'\bfunc _draw\(', block)}
    covered = {row['evidence_path'] for row in surfaces.values() if row['kind'] != 'literal'}
    need(draw_sites <= covered, f'Unmapped draw sites {sorted(draw_sites - covered)}')
    for row in surfaces.values():
        if row['kind'] != 'literal':
            need(row['locator'] in text[row['evidence_path']], f'Outdated locator for {row["surface_id"]}')
    duplicates = {hashlib.sha256((ROOT / row['repository_file']).read_bytes()).hexdigest()
                  for row in assets.values() if row['reuse_group'] == 'identical_tracking_jpeg'}
    need(len(duplicates) == 1, 'Scaffold copies differ')
    return len([path for path in inspected if path.endswith('.tscn')]), len(media_refs), len(source_markers), len(draw_sites)


def vector_pairs(line):
    return [[int(x), int(y)] for x, y in re.findall(r'Vector2i\((-?\d+),\s*(-?\d+)\)', line)]


def check_maps(archive, assets):
    for spec in read_json(archive / 'tile_layouts.json'):
        key = spec['id']
        resource = (ROOT / assets[key]['repository_file']).read_text(encoding='utf-8')
        fields = {name: vector_pairs(value) for name, value in re.findall(r'^(size|ground|elevated|spawns|tunnel) = (.+)$', resource, re.M)}
        need(fields['size'] == [[spec['columns'], spec['rows']]], f'{key} dimensions differ')
        need(fields['spawns'] == spec['entries'] and fields['tunnel'] == [spec['exit']], f'{key} gate mismatch')
        need(sorted(fields['elevated']) == sorted(spec['elevated']), f'{key} raised cells differ')
        ground = {tuple(cell) for route in spec['routes'] for cell in route[1:-1]}
        need({tuple(cell) for cell in fields['ground']} == ground, f'{key} ground cells differ')
        routes = (ROOT / 'data/stages/t01_route.tres').read_text() if key == 'T01' else resource
        runtime_routes = [vector_pairs(line) for line in re.findall(r'^cells = (.+)$', routes, re.M)]
        need(runtime_routes == spec['routes'], f'{key} ordered routes differ')


def check_archive(archive, screens, assets):
    manifest = read_json(archive / 'storyboard_manifest.json')
    received = [(entry['id'], page, entry['title']) for page, entry in enumerate(manifest, 12)]
    audited = [(row['frame_id'], int(row['pdf_page']), row['frame_title']) for row in screens.values()]
    need(received == audited, 'Storyboard IDs, titles or page order differ')
    expected_paths = {f'{folder}/{key}.{ext}' for key in screens for folder, ext in [('screens', 'svg'), ('renders', 'png')]}
    expected_paths.update(f'assets/{key.rsplit(".", 1)[-1]}.png' for key in assets if key.startswith('archive.illustration.'))
    expected_paths.update({'tile_layouts.json', 'tile_piece_catalog.json', 'tile_atlas_spec.svg', 'tile_grammar.svg'})
    expected_paths.add('Kenyalang_Rangers_Tileset_UI_Storyboard.pdf')
    receipts = {item['path']: item for item in read_json(archive / 'package_manifest.json')}
    for path in sorted(expected_paths):
        data = (archive / path).read_bytes()
        receipt = receipts[path]
        need(receipt['bytes'] == len(data) and receipt['sha256'] == hashlib.sha256(data).hexdigest(), f'Archive fingerprint changed for {path}')
        if path.endswith('.svg'):
            ElementTree.fromstring(data)
    for tile in read_json(archive / 'tile_piece_catalog.json'):
        row = assets[tile['id']]
        rect = ','.join(map(str, tile['source_rect_px']))
        need(row['deliverable'] == tile['name'] and rect in row['implementation_and_gap'], f'{tile["id"]} source differs')
    check_maps(archive, assets)
    print(f'PASS {len(expected_paths)} external source fingerprints, 116 frame IDs and titles, 56 atlas entries and all six runtime geometries')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--design-archive', type=Path, help='Extracted Kenyalang Rangers Design Pack v2 directory')
    options = parser.parse_args()
    assets = load_csv('asset_register.csv', 'asset_id')
    screens = load_csv('screen_coverage.csv', 'frame_id')
    surfaces = load_csv('placeholder_coverage.csv', 'surface_id')
    defined = set(re.findall(r'\| \*\*(W21-A\d+)\*\* \|', WORK_ORDER.read_text(encoding='utf-8')))
    need(defined, 'Missing production tickets')
    for row in assets.values():
        key = row['asset_id']
        check_tickets(row['ticket_id'], defined, key)
        check_paths(row['binding_paths'], key)
        check_paths(row['repository_file'], key)
        if row['runtime_status'] == 'CANDIDATE':
            need(not row['repository_file'], f'External source is incorrectly shown as an imported file for {key}')
        need(row['source_reference'] and row['provenance'], f'Missing source or provenance for {key}')
    need([int(row['pdf_page']) for row in screens.values()] == list(range(12, 128)), 'Storyboard page coverage differs')
    for row in screens.values():
        check_tickets(row['tickets'], defined, row['frame_id'])
        check_paths(row['runtime_evidence'], row['frame_id'])
    for row in surfaces.values():
        check_tickets(row['tickets'], defined, row['surface_id'])
        check_paths(row['evidence_path'], row['surface_id'])

    check_catalog(assets)
    scenes, media, labels, draws = check_live_sources(assets, surfaces)
    components = len({row['component'] for row in screens.values()})
    print(f'PASS {len(assets)} unique asset records, {len(screens)} frame mappings across {components} components, {len(surfaces)} surfaces and {len(defined)} tickets')
    print(f'PASS {scenes} packed scenes inventoried, {media} static media references, {labels} literal labels and {draws} draw sites')
    if options.design_archive:
        check_archive(options.design_archive, screens, assets)


if __name__ == '__main__':
    main()
