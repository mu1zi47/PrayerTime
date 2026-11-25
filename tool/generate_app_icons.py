#!/usr/bin/env python3
"""Regenerate icon rasters/platform assets from the design-system SVG sources.

Install tool/requirements-icons.txt first. CairoSVG also needs system Cairo
(on macOS: brew install cairo). Run from any directory with python3.
"""
from pathlib import Path
import ctypes.util
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
# Apple's system Python may not discover Homebrew libraries automatically.
if sys.platform == 'darwin' and ctypes.util.find_library('cairo') is None:
    for prefix in ['/opt/homebrew', '/usr/local']:
        library = Path(prefix) / 'lib/libcairo.2.dylib'
        if library.is_file():
            original_find = ctypes.util.find_library
            ctypes.util.find_library = lambda name: (
                str(library) if name in ['cairo', 'cairo-2', 'libcairo-2']
                else original_find(name)
            )
            break

import cairosvg

runpy.run_path(str(ROOT / 'tool/sync_design_tokens.py'))
for source, target, size in [
    ('icon.svg', 'assets/icon/icon.png', 1024),
    ('mark.svg', 'assets/icon/icon_foreground.png', 1024),
    ('background.svg', 'assets/icon/icon_background.png', 1024),
    ('icon.svg', 'store/icon-512.png', 512),
]:
    cairosvg.svg2png(url=str(ROOT / 'assets/icon' / source),
                    write_to=str(ROOT / target),
                    output_width=size, output_height=size)
subprocess.run(['dart', 'run', 'flutter_launcher_icons'], cwd=ROOT, check=True)
