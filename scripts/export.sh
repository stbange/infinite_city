#!/usr/bin/env bash
# Exports release builds with the presets in export_presets.cfg.
# Needs Godot's export templates for the pinned version in
# ~/.local/share/godot/export_templates/<version>/ (scripts/install-export-templates.sh).
# Usage: scripts/export.sh [Linux|Windows|macOS ...]   (default: all three)
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"
presets=("$@")
if [[ ${#presets[@]} -eq 0 ]]; then
  presets=(Linux Windows macOS)
fi
scripts/godot.sh --headless --path . --import >/dev/null 2>&1 || true
for preset in "${presets[@]}"; do
  path="$(python3 -c "import configparser,sys
c=configparser.ConfigParser(); c.read('export_presets.cfg')
for s in c.sections():
    if c.get(s,'name',fallback='').strip('\"')==sys.argv[1]: print(c.get(s,'export_path').strip('\"'))" "${preset}")"
  mkdir -p "$(dirname "${path}")"
  echo "Exporting ${preset} -> ${path}"
  scripts/godot.sh --headless --path . --export-release "${preset}" "${path}"
done
