#!/usr/bin/env python3
from __future__ import annotations

import configparser
import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STYLE = ROOT / "plasma-style/darkly-glass"
COLOR = ROOT / "color-scheme/DarklyGlass.colors"

metadata = json.loads((STYLE / "metadata.json").read_text(encoding="utf-8"))
assert metadata["KPlugin"]["Id"] == "darkly-glass"
assert metadata["KPlugin"]["Name"] == "Darkly Glass"

svg_files = sorted(STYLE.rglob("*.svg"))
assert len(svg_files) == 17, len(svg_files)
for svg in svg_files:
    ET.parse(svg)

parser = configparser.ConfigParser(interpolation=None, strict=False)
parser.optionxform = str
parser.read(COLOR, encoding="utf-8")
assert parser["General"]["ColorScheme"] == "DarklyGlass"
assert parser["General"]["Name"] == "Darkly Glass"
assert parser["Colors:Window"]["BackgroundNormal"] == "25,25,25"
assert parser["WM"]["activeBackground"] == "25,25,25,204"

print("Asset validation tests passed")
