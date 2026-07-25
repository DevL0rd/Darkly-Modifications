#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
python3 "$repo_dir/tests/test-assets.py"
python3 "$repo_dir/tests/test-config.py"
"$repo_dir/tests/test-install-cycle.sh"
printf '%s\n' 'All tests passed'
