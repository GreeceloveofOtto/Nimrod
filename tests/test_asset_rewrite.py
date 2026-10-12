import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import downscale_assets


class AssetRewriteTest(unittest.TestCase):
    def test_runtime_paths_change_but_authoring_references_and_mapping_keys_do_not(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'data').mkdir()
            source = 'assets/sprites/hero/idle.png'
            target = 'assets/sprites/hero/idle.webp'
            mapping = root / 'data/image_mapping.json'
            mapping.write_text(json.dumps({source: target}))
            quality = root / 'data/quality.json'
            quality.write_text(json.dumps({'path': source, 'source': source,
                                          'source_archive': 'pack_source/sprites/hero/idle.png'}))
            previous = downscale_assets.ROOT
            try:
                downscale_assets.ROOT = root
                downscale_assets.rewrite_paths({source: target})
            finally:
                downscale_assets.ROOT = previous
            actual = json.loads(quality.read_text())
            self.assertEqual(actual['path'], target)
            self.assertEqual(actual['source'], source)
            self.assertEqual(actual['source_archive'], 'pack_source/sprites/hero/idle.png')
            self.assertEqual(json.loads(mapping.read_text()), {source: target})


if __name__ == '__main__':
    unittest.main()
