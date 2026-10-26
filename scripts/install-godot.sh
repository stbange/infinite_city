#!/usr/bin/env bash
# Downloads the pinned Godot editor binary (Linux x86_64) into .tools/godot/.
# Usage: scripts/install-godot.sh
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2-stable}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="${ROOT_DIR}/.tools/godot"
BIN="${DEST_DIR}/Godot_v${GODOT_VERSION}_linux.x86_64"

if [[ -x "${BIN}" ]]; then
  echo "Godot ${GODOT_VERSION} already installed at ${BIN}"
  exit 0
fi

mkdir -p "${DEST_DIR}"
URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
echo "Downloading ${URL}"
TMP_ZIP="$(mktemp --suffix=.zip)"
curl -fsSL -o "${TMP_ZIP}" "${URL}"
python3 -m zipfile -e "${TMP_ZIP}" "${DEST_DIR}"
rm -f "${TMP_ZIP}"
chmod +x "${BIN}"
"${BIN}" --version
