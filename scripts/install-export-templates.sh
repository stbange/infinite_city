#!/usr/bin/env bash
# Downloads Godot's export templates for the pinned version (about 1.3 GB) and keeps the ones
# for the platforms we export to. Usage: scripts/install-export-templates.sh
set -euo pipefail
GODOT_VERSION="${GODOT_VERSION:-4.7.2-stable}"
DEST="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION/-/.}"
if [[ -f "${DEST}/linux_release.x86_64" && -f "${DEST}/windows_release_x86_64.exe" && -f "${DEST}/macos.zip" ]]; then
  echo "Export templates already in ${DEST}"
  exit 0
fi
TMP="$(mktemp --suffix=.tpz)"
curl -fsSL -o "${TMP}" "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz"
mkdir -p "${DEST}"
python3 -I - "${TMP}" "${DEST}" <<'PY'
import os, sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
keep = ("version.txt", "linux_release.x86_64", "linux_debug.x86_64", "windows_release_x86_64.exe",
        "windows_debug_x86_64.exe", "macos.zip")
for name in z.namelist():
    if os.path.basename(name) in keep:
        open(os.path.join(sys.argv[2], os.path.basename(name)), "wb").write(z.read(name))
PY
rm -f "${TMP}"
ls "${DEST}"
