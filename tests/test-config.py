#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANAGER = ROOT / "lib/manage-config.py"


def run(command: str, env: dict[str, str]) -> None:
    subprocess.run([sys.executable, str(MANAGER), command], env=env, check=True)


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    config = root / "config"
    state = root / "state"
    config.mkdir()
    plasmarc = config / "plasmarc"
    kdeglobals = config / "kdeglobals"
    original_plasmarc = "[Theme]\nname=darkly\n\n[Theme-plasma-themeexplorer]\nname=darkly\n\n[Keep]\nValue=yes\n"
    original_kdeglobals = "[General]\nColorScheme=DarklyModded\nOther=preserved\n\n[Colors:Window]\nBackgroundNormal=25,25,25\n"
    plasmarc.write_text(original_plasmarc, encoding="utf-8")
    kdeglobals.write_text(original_kdeglobals, encoding="utf-8")
    env = os.environ.copy()
    env.update({"LDM_HOME": str(root), "LDM_CONFIG_HOME": str(config), "LDM_STATE_HOME": str(state)})

    run("install", env)
    assert "name=darkly-glass" in plasmarc.read_text(encoding="utf-8")
    assert "ColorScheme=DarklyGlass" in kdeglobals.read_text(encoding="utf-8")
    assert "Other=preserved" in kdeglobals.read_text(encoding="utf-8")

    run("install", env)
    assert plasmarc.read_text(encoding="utf-8").count("name=darkly-glass") == 2

    run("uninstall", env)
    assert plasmarc.read_text(encoding="utf-8") == original_plasmarc
    assert kdeglobals.read_text(encoding="utf-8") == original_kdeglobals

print("Configuration tests passed")
