#!/usr/bin/env bash
# Renders one frame of the main scene to a PNG using a virtual display (Xvfb) and the
# Compatibility renderer, so it works on machines without a GPU.
# Usage: scripts/screenshot.sh out.png [--pos=x,y,z] [--yaw=deg] [--pitch=deg] [--wait=frames]
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:?usage: scripts/screenshot.sh out.png [--pos=x,y,z] [--yaw=deg] [--pitch=deg]}"
shift
mkdir -p "$(dirname "${OUT}")"
OUT_ABS="$(cd "$(dirname "${OUT}")" && pwd)/$(basename "${OUT}")"
# Keep Godot from importing screenshots that land inside the project.
case "${OUT_ABS}" in "${ROOT_DIR}"/*) touch "$(dirname "${OUT_ABS}")/.gdignore" ;; esac
cd "${ROOT_DIR}"
scripts/godot.sh --headless --path . --import >/dev/null 2>&1 || true
xvfb-run -a -s "-screen 0 1600x900x24" \
  scripts/godot.sh --path . --rendering-method gl_compatibility --rendering-driver opengl3 \
  --resolution 1600x900 -- --screenshot="${OUT_ABS}" "$@"
