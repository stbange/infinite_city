#!/usr/bin/env bash
# Runs the GUT test suite headless.
# Usage: scripts/test.sh                 # all tests (unit and integration in separate processes)
#        scripts/test.sh -gselect=hash   # extra GUT options are passed through
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Import once so class_name scripts are registered in the global class cache.
scripts/godot.sh --headless --path . --import >/dev/null 2>&1 || true

run_gut() {
	scripts/godot.sh --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json "$@"
}

# A selection runs in one process; the whole suite runs one test directory per process, which
# keeps peak memory low (generated districts are large and Godot does not return all of it).
for arg in "$@"; do
	case "${arg}" in
		-gselect=*|-gtest=*|-gdir=*|-gunit_test_name=*) run_gut "$@"; exit $? ;;
	esac
done
status=0
for dir in res://test/unit/ res://test/integration/; do
	run_gut -gdir="${dir}" "$@" || status=$?
done
exit "${status}"
