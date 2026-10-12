#!/usr/bin/env python3
"""Audit every active sheet manifest, including aliases and NPC/FX/player sets."""
import json,sys
from pathlib import Path
from check_sprite_frames import ROOT,main
(ROOT/'archive/stage11').mkdir(parents=True,exist_ok=True)
m=json.loads((ROOT/'assets/art_manifest.json').read_text());sys.argv=[sys.argv[0]]+[str(ROOT/'assets'/p) for p in m['sprite_manifests']]+['--json',str(ROOT/'archive/stage11/all_sprite_qa.json')]
raise SystemExit(main())
