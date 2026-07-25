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
manager=$repo_dir/lib/manage-config.py
cleanup_ok=1
restore_theme=0
restore_color=0
previous_theme=
previous_color=

remove_path() {
    path=$1
    if [ -L "$path" ] || [ -f "$path" ]; then
        rm -f -- "$path"
    elif [ -d "$path" ]; then
        find "$path" -depth -delete
    fi
}

manager_env() {
    LDM_HOME=$home_dir LDM_CONFIG_HOME=$config_home LDM_STATE_HOME=$state_home \
        python3 "$manager" "$@"
}

if manager_env should-restore plasma-theme; then
    if previous_theme=$(manager_env previous plasma-theme); then
        restore_theme=1
    fi
fi
if manager_env should-restore color-scheme; then
    if previous_color=$(manager_env previous color-scheme); then
        restore_color=1
    fi
fi

if [ -d "$target_style" ] && [ -e "$target_style/$managed_marker" ]; then
    if diff -qr --exclude="$managed_marker" "$source_style" "$target_style" >/dev/null; then
        remove_path "$target_style"
    else
        printf 'Keeping modified Plasma style: %s\n' "$target_style" >&2
        cleanup_ok=0
    fi
fi
if [ -f "$target_color" ]; then
    if cmp -s -- "$source_color" "$target_color"; then
        remove_path "$target_color"
    else
        printf 'Keeping modified color scheme: %s\n' "$target_color" >&2
        cleanup_ok=0
    fi
fi

if [ -e "$state_dir/target-style-preexisting" ] && [ -e "$state_dir/target-style.before" ]; then
    if [ ! -e "$target_style" ]; then
        mv -- "$state_dir/target-style.before" "$target_style"
    else
        cleanup_ok=0
    fi
fi
if [ -e "$state_dir/target-color-preexisting" ] && [ -e "$state_dir/target-color.before" ]; then
    if [ ! -e "$target_color" ]; then
        mv -- "$state_dir/target-color.before" "$target_color"
    else
        cleanup_ok=0
    fi
fi
if [ -e "$state_dir/legacy-style-migrated" ] && [ -e "$state_dir/legacy-style.before" ]; then
    if [ ! -e "$legacy_style" ]; then
        mv -- "$state_dir/legacy-style.before" "$legacy_style"
    else
        printf 'Could not restore legacy style because its path is occupied: %s\n' "$legacy_style" >&2
        cleanup_ok=0
    fi
fi
if [ -e "$state_dir/legacy-color-migrated" ] && [ -e "$state_dir/legacy-color.before" ]; then
    if [ ! -e "$legacy_color" ]; then
        mv -- "$state_dir/legacy-color.before" "$legacy_color"
    else
        printf 'Could not restore legacy color scheme because its path is occupied: %s\n' "$legacy_color" >&2
        cleanup_ok=0
    fi
fi

if [ "${LDM_SKIP_APPLY:-0}" != 1 ]; then
    if [ "$restore_theme" = 1 ] && command -v plasma-apply-desktoptheme >/dev/null 2>&1; then
        plasma-apply-desktoptheme "$previous_theme" || true
    fi
    if [ "$restore_color" = 1 ] && command -v plasma-apply-colorscheme >/dev/null 2>&1; then
        plasma-apply-colorscheme "$previous_color" || true
    fi
fi
manager_env uninstall

if [ "$cleanup_ok" = 1 ]; then
    find "$state_dir" -depth -delete 2>/dev/null || true
else
    printf 'Installer state was retained for unresolved backups: %s\n' "$state_dir" >&2
fi

printf '%s\n' 'Darkly Glass was uninstalled and the previous Plasma appearance was restored.'
