#!/usr/bin/env python3
"""Exercise Godot's ZIP import directory semantics, without auto-creating parents."""
import argparse
import json
import tempfile
import zipfile
from pathlib import Path


def check_import(package):
    with tempfile.TemporaryDirectory(prefix='nimrod-godot-zip-') as directory:
        target = Path(directory)
        failures = []
        count = 0
        with zipfile.ZipFile(package) as archive:
            projects = [entry for entry in archive.infolist()
                        if Path(entry.filename).name == 'project.godot']
            if len(projects) != 1:
                raise ValueError('Package must contain exactly one project.godot')
            root = Path(projects[0].filename).parent.as_posix()
            for entry in archive.infolist():
                relative = entry.filename.removeprefix(root).lstrip('/')
                if not relative:
                    continue
                if '..' in Path(relative).parts or '\\' in relative:
                    raise ValueError('Unsafe ZIP entry: ' + relative)
                destination = target / relative
                try:
                    if entry.is_dir():
                        destination.mkdir(exist_ok=True)  # Godot uses make_dir, not recursive.
                    else:
                        destination.write_bytes(archive.read(entry))
                        count += 1
                except OSError:
                    failures.append('/' + relative)
            if archive.testzip() is not None:
                raise ValueError('ZIP CRC failed')
        return {'files_written': count, 'failed_files': failures}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path)
    result = check_import(parser.parse_args().package)
    print(json.dumps(result))
    raise SystemExit(bool(result['failed_files']))
