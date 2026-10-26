#!/usr/bin/env bash
# Runs the GUT test suite headless.
# Usage: scripts/test.sh                 # all tests
#        scripts/test.sh -gselect=hash   # extra GUT options are passed through
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Import once so class_name scripts are registered in the global class cache.
scripts/godot.sh --headless --path . --import >/dev/null 2>&1 || true

scripts/godot.sh --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json "$@"
