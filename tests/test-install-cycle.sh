#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT HUP INT TERM
home_dir=$test_root/home
config_home=$test_root/config
data_home=$test_root/data
state_home=$test_root/state
legacy_style=$data_home/plasma/desktoptheme/darkly
legacy_color=$data_home/color-schemes/DarklyModded.colors
target_style=$data_home/plasma/desktoptheme/darkly-glass
target_color=$data_home/color-schemes/DarklyGlass.colors
mkdir -p "$home_dir" "$config_home" "$legacy_style/widgets" "$target_style/widgets" "$(dirname -- "$legacy_color")"
printf '%s\n' '[Theme]' 'name=darkly' '' '[Theme-plasma-themeexplorer]' 'name=darkly' > "$config_home/plasmarc"
printf '%s\n' '[General]' 'ColorScheme=DarklyModded' 'Keep=yes' > "$config_home/kdeglobals"
printf '%s\n' legacy-style > "$legacy_style/widgets/original.txt"
printf '%s\n' legacy-color > "$legacy_color"
printf '%s\n' preexisting-target-style > "$target_style/widgets/original.txt"
printf '%s\n' preexisting-target-color > "$target_color"
cp -a -- "$legacy_style" "$test_root/legacy-style.before"
cp -a -- "$legacy_color" "$test_root/legacy-color.before"
cp -a -- "$target_style" "$test_root/target-style.before"
cp -a -- "$target_color" "$test_root/target-color.before"
cp -a -- "$config_home/plasmarc" "$test_root/plasmarc.before"
cp -a -- "$config_home/kdeglobals" "$test_root/kdeglobals.before"

LDM_HOME=$home_dir LDM_CONFIG_HOME=$config_home LDM_DATA_HOME=$data_home \
LDM_STATE_HOME=$state_home LDM_SKIP_APPLY=1 "$repo_dir/install.sh" >/dev/null

test -f "$data_home/plasma/desktoptheme/darkly-glass/metadata.json"
test -f "$data_home/color-schemes/DarklyGlass.colors"
test ! -e "$legacy_style"
test ! -e "$legacy_color"
grep -q '^name=darkly-glass$' "$config_home/plasmarc"
grep -q '^ColorScheme=DarklyGlass$' "$config_home/kdeglobals"

LDM_HOME=$home_dir LDM_CONFIG_HOME=$config_home LDM_DATA_HOME=$data_home \
LDM_STATE_HOME=$state_home LDM_SKIP_APPLY=1 "$repo_dir/install.sh" >/dev/null

LDM_HOME=$home_dir LDM_CONFIG_HOME=$config_home LDM_DATA_HOME=$data_home \
LDM_STATE_HOME=$state_home LDM_SKIP_APPLY=1 "$repo_dir/uninstall.sh" >/dev/null

diff -qr "$test_root/target-style.before" "$target_style"
cmp -s -- "$test_root/target-color.before" "$target_color"
diff -qr "$test_root/legacy-style.before" "$legacy_style"
cmp -s -- "$test_root/legacy-color.before" "$legacy_color"
cmp -s -- "$test_root/plasmarc.before" "$config_home/plasmarc"
cmp -s -- "$test_root/kdeglobals.before" "$config_home/kdeglobals"
test ! -e "$state_home/linux-darkly-modifications"

printf '%s\n' 'Installer cycle test passed'
