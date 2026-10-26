#!/usr/bin/env bash
# Resolves the Godot binary: $GODOT, then .tools/godot (see install-godot.sh), then godot on PATH.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_VERSION="${GODOT_VERSION:-4.7.2-stable}"
LOCAL_BIN="${ROOT_DIR}/.tools/godot/Godot_v${GODOT_VERSION}_linux.x86_64"

if [[ -n "${GODOT:-}" ]]; then
  exec "${GODOT}" "$@"
elif [[ -x "${LOCAL_BIN}" ]]; then
  exec "${LOCAL_BIN}" "$@"
elif command -v godot >/dev/null 2>&1; then
  exec godot "$@"
else
  echo "Godot not found. Run scripts/install-godot.sh or set GODOT=/path/to/godot" >&2
  exit 127
fi
