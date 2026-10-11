#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - main launcher
# Run this from the USB root to start the GUI.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

echo "Starting OpenCode Portable..."
echo "Root: ${PORTABLE_ROOT}"

# Check if OpenCode exists
OPENCODE_EXE="${PORTABLE_ROOT}/apps/opencode/opencode"
if [[ ! -f "${OPENCODE_EXE}" ]]; then
  echo "ERROR: OpenCode not found at ${OPENCODE_EXE}"
  echo "Run the build scripts first: ./build/fetch-tools.sh && ./build/install-tools.sh"
  exit 1
fi

# Make sure it's executable
chmod +x "${OPENCODE_EXE}"

# Run OpenCode
exec "${OPENCODE_EXE}" "$@"