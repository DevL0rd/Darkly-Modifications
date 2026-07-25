#!/usr/bin/env python3
"""Surgically apply and restore the KDE settings owned by Darkly Glass."""

from __future__ import annotations

import argparse
import json
import os
import re
import tempfile
from pathlib import Path
from typing import Any

THEME_ID = "darkly-glass"
COLOR_ID = "DarklyGlass"


def locations() -> tuple[Path, Path, Path]:
    home = Path(os.environ.get("LDM_HOME", os.environ.get("HOME", str(Path.home()))))
    config_home = Path(os.environ.get("LDM_CONFIG_HOME", os.environ.get("XDG_CONFIG_HOME", home / ".config")))
    state_home = Path(os.environ.get("LDM_STATE_HOME", os.environ.get("XDG_STATE_HOME", home / ".local/state")))
    return config_home / "plasmarc", config_home / "kdeglobals", state_home / "linux-darkly-modifications/config-state.json"


SETTINGS = {
    "plasma-theme": (0, "Theme", "name", THEME_ID),
    "plasma-theme-explorer": (0, "Theme-plasma-themeexplorer", "name", THEME_ID),
    "color-scheme": (1, "General", "ColorScheme", COLOR_ID),
}


def read_lines(path: Path) -> list[str]:
    if not path.exists():
        return []
    return path.read_text(encoding="utf-8").splitlines(keepends=True)


def group_bounds(lines: list[str], group: str) -> tuple[int, int] | None:
    header = f"[{group}]"
    start = None
    for index, line in enumerate(lines):
        stripped = line.strip()
        if stripped == header:
            start = index + 1
            continue
        if start is not None and re.fullmatch(r"\[[^]]+\]", stripped):
            return start, index
    return (start, len(lines)) if start is not None else None


def find_key(lines: list[str], group: str, key: str) -> int | None:
    bounds = group_bounds(lines, group)
    if bounds is None:
        return None
    for index in range(*bounds):
        line = lines[index]
        if line.lstrip().startswith(("#", ";")) or "=" not in line:
            continue
        if line.split("=", 1)[0].strip() == key:
            return index
    return None


def get_value(path: Path, group: str, key: str) -> tuple[bool, str | None]:
    lines = read_lines(path)
    index = find_key(lines, group, key)
    if index is None:
        return False, None
    return True, lines[index].split("=", 1)[1].rstrip("\r\n")


def set_value(lines: list[str], group: str, key: str, value: str) -> list[str]:
    index = find_key(lines, group, key)
    if index is not None:
        newline = "\r\n" if lines[index].endswith("\r\n") else "\n"
        lines[index] = f"{key}={value}{newline}"
        return lines
    bounds = group_bounds(lines, group)
    if bounds is not None:
        lines.insert(bounds[1], f"{key}={value}\n")
        return lines
    if lines and lines[-1].strip():
        lines.append("\n")
    lines.extend([f"[{group}]\n", f"{key}={value}\n"])
    return lines


def remove_value(lines: list[str], group: str, key: str) -> list[str]:
    index = find_key(lines, group, key)
    if index is not None:
        lines.pop(index)
    return lines


def atomic_write(path: Path, lines: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    previous_mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            handle.writelines(lines)
        os.chmod(temporary, previous_mode)
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def load_state(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def capture() -> None:
    plasmarc, kdeglobals, state_path = locations()
    if state_path.exists():
        return
    files = [plasmarc, kdeglobals]
    state: dict[str, Any] = {"version": 1, "settings": {}}
    for name, (file_index, group, key, _desired) in SETTINGS.items():
        present, value = get_value(files[file_index], group, key)
        state["settings"][name] = {"present": present, "value": value}
    state_path.parent.mkdir(parents=True, exist_ok=True)
    atomic_write(state_path, [json.dumps(state, indent=2), "\n"])


def install() -> None:
    plasmarc, kdeglobals, state_path = locations()
    capture()
    files = [plasmarc, kdeglobals]
    contents = [read_lines(path) for path in files]
    for _name, (file_index, group, key, desired) in SETTINGS.items():
        contents[file_index] = set_value(contents[file_index], group, key, desired)
    for path, lines in zip(files, contents):
        atomic_write(path, lines)


def uninstall() -> None:
    plasmarc, kdeglobals, state_path = locations()
    if not state_path.exists():
        return
    state = load_state(state_path)
    files = [plasmarc, kdeglobals]
    contents = [read_lines(path) for path in files]
    for name, (file_index, group, key, desired) in SETTINGS.items():
        current_present, current_value = get_value(files[file_index], group, key)
        if not current_present or current_value != desired:
            continue
        previous = state["settings"][name]
        if previous["present"]:
            contents[file_index] = set_value(contents[file_index], group, key, previous["value"])
        else:
            contents[file_index] = remove_value(contents[file_index], group, key)
    for path, lines in zip(files, contents):
        atomic_write(path, lines)
    state_path.unlink()


def previous(name: str) -> None:
    _plasmarc, _kdeglobals, state_path = locations()
    if not state_path.exists():
        raise SystemExit(1)
    value = load_state(state_path)["settings"][name]
    if not value["present"]:
        raise SystemExit(1)
    print(value["value"])


def should_restore(name: str) -> None:
    plasmarc, kdeglobals, _state_path = locations()
    files = [plasmarc, kdeglobals]
    file_index, group, key, desired = SETTINGS[name]
    present, value = get_value(files[file_index], group, key)
    raise SystemExit(0 if present and value == desired else 1)


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("capture")
    subparsers.add_parser("install")
    subparsers.add_parser("uninstall")
    for command in ("previous", "should-restore"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument("setting", choices=SETTINGS)
    args = parser.parse_args()
    if args.command == "capture":
        capture()
    elif args.command == "install":
        install()
    elif args.command == "uninstall":
        uninstall()
    elif args.command == "previous":
        previous(args.setting)
    else:
        should_restore(args.setting)


if __name__ == "__main__":
    main()
