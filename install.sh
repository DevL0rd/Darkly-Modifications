#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
home_dir=${LDM_HOME:-${HOME:?HOME is not set}}
config_home=${LDM_CONFIG_HOME:-${XDG_CONFIG_HOME:-$home_dir/.config}}
data_home=${LDM_DATA_HOME:-${XDG_DATA_HOME:-$home_dir/.local/share}}
state_home=${LDM_STATE_HOME:-${XDG_STATE_HOME:-$home_dir/.local/state}}
state_dir=$state_home/linux-darkly-modifications
source_style=$repo_dir/plasma-style/darkly-glass
source_color=$repo_dir/color-scheme/DarklyGlass.colors
target_style=$data_home/plasma/desktoptheme/darkly-glass
target_color=$data_home/color-schemes/DarklyGlass.colors
legacy_style=$data_home/plasma/desktoptheme/darkly
legacy_color=$data_home/color-schemes/DarklyModded.colors
managed_marker=.linux-darkly-modifications-managed

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

remove_path() {
    path=$1
    if [ -L "$path" ] || [ -f "$path" ]; then
        rm -f -- "$path"
    elif [ -d "$path" ]; then
        find "$path" -depth -delete
    fi
}

command -v python3 >/dev/null 2>&1 || die 'python3 is required.'
[ -f "$source_style/metadata.json" ] || die 'The bundled Plasma style is incomplete.'
[ -f "$source_color" ] || die 'The bundled color scheme is missing.'
mkdir -p "$state_dir" "$(dirname -- "$target_style")" "$(dirname -- "$target_color")"

LDM_HOME=$home_dir LDM_CONFIG_HOME=$config_home LDM_STATE_HOME=$state_home \
    python3 "$repo_dir/lib/manage-config.py" capture

if [ ! -e "$state_dir/install-state-version" ]; then
    if [ -e "$target_style" ]; then
        mv -- "$target_style" "$state_dir/target-style.before"
        : > "$state_dir/target-style-preexisting"
    fi
    if [ -e "$target_color" ]; then
        mv -- "$target_color" "$state_dir/target-color.before"
        : > "$state_dir/target-color-preexisting"
    fi
    if [ -e "$legacy_style" ]; then
        mv -- "$legacy_style" "$state_dir/legacy-style.before"
        : > "$state_dir/legacy-style-migrated"
    fi
    if [ -e "$legacy_color" ]; then
        mv -- "$legacy_color" "$state_dir/legacy-color.before"
        : > "$state_dir/legacy-color-migrated"
    fi
    printf '1\n' > "$state_dir/install-state-version"
elif [ -e "$target_style" ] && [ ! -e "$target_style/$managed_marker" ]; then
    die "Refusing to overwrite an unmanaged Plasma style: $target_style"
fi

remove_path "$target_style"
mkdir -p "$target_style"
cp -a -- "$source_style/." "$target_style/"
: > "$target_style/$managed_marker"
install -m 0644 -- "$source_color" "$target_color"

if [ "${LDM_SKIP_APPLY:-0}" != 1 ]; then
    if command -v plasma-apply-desktoptheme >/dev/null 2>&1; then
        plasma-apply-desktoptheme darkly-glass
    fi
    if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
        plasma-apply-colorscheme DarklyGlass
    fi
fi
LDM_HOME=$home_dir LDM_CONFIG_HOME=$config_home LDM_STATE_HOME=$state_home \
    python3 "$repo_dir/lib/manage-config.py" install

printf '%s\n' \
    'Darkly Glass Plasma style and color scheme are installed and active.' \
    'Any legacy Darkly user override or Darkly Modded scheme is kept in reversible installer state.'
