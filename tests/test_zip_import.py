"""Packaging regression: Godot does not automatically create parent directories."""
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from check_zip_import import check_import
import make_slim_zip


class GodotZipImportTests(unittest.TestCase):
    def test_directories_are_written_before_nested_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'scenes' / 'props').mkdir(parents=True)
            project = root / 'project.godot'
            scene = root / 'scenes' / 'props' / 'Door.tscn'
            project.write_text('config_version=5\n')
            scene.write_text('[gd_scene format=3]\n')
            broken = root / 'broken.zip'
            with zipfile.ZipFile(broken, 'w') as archive:
                for item in [project, scene]:
                    archive.write(item, 'Nimrod/' + item.relative_to(root).as_posix())
            self.assertEqual(check_import(broken)['failed_files'], ['/scenes/props/Door.tscn'])
            original_root = make_slim_zip.ROOT
            try:
                make_slim_zip.ROOT = root
                fixed = root / 'fixed.zip'
                self.assertEqual(make_slim_zip.write_archive(fixed, [project, scene]), 3)
            finally:
                make_slim_zip.ROOT = original_root
            self.assertEqual(check_import(fixed), {'files_written': 2, 'failed_files': []})
            with zipfile.ZipFile(fixed) as archive:
                self.assertEqual(archive.read('Nimrod/scenes/props/Door.tscn'), scene.read_bytes())


if __name__ == '__main__':
    unittest.main()
