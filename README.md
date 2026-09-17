# Linux Darkly Modifications

Darkly Glass packages DevL0rd's KDE Plasma modifications to the official
[Darkly](https://github.com/Bali10050/Darkly) desktop style as two consistently
named components:

- **Darkly Glass** Plasma style (`darkly-glass`)
- **Darkly Glass** color scheme (`DarklyGlass`)

The Plasma backgrounds use the Darkly color scheme with 80% opacity. The color
scheme uses the matching `25,25,25` window/view background and 80%-opaque window
manager backgrounds.

## Install

```bash
git clone https://github.com/DevL0rd/Darkly-Modifications.git
cd Darkly-Modifications
./install.sh
```

The installer requires no root access. It installs and activates both components
under the current user's XDG data directory:

- `~/.local/share/plasma/desktoptheme/darkly-glass`
- `~/.local/share/color-schemes/DarklyGlass.colors`

If the legacy modified names exist, the installer moves
`desktoptheme/darkly` and `DarklyModded.colors` into reversible state rather
than deleting them. This stops the user-level `darkly` directory from shadowing
the official system Darkly style.

## Uninstall

```bash
./uninstall.sh
```

The uninstaller restores the previously active Plasma style and color scheme,
restores migrated legacy files, and restores any pre-existing files that used
the `darkly-glass` or `DarklyGlass` names. Files changed after installation are
preserved instead of being overwritten.

## Test

```bash
./tests/run.sh
```

Tests validate every SVG and metadata file, verify focused configuration edits,
and exercise a complete isolated install/reinstall/uninstall cycle.

## Credits and license

The base Plasma artwork is by Bali10050 and the Darkly contributors. Darkly
Glass retains that attribution and documents its modifications in `NOTICE`.
The modified work is distributed under the GNU General Public License version 2.
