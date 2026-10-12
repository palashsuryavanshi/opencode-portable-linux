#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - main launcher
# Run this from the USB root to start the GUI.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

if [[ -z "${PORTABLE_ROOT}" ]]; then
  echo "ERROR: env.sh failed to load - cannot resolve the portable root." >&2
  exit 1
fi

echo "Starting OpenCode Portable..."
echo "Root: ${PORTABLE_ROOT}"

OPENCODE_EXE="${PORTABLE_ROOT}/apps/opencode/opencode"
if [[ ! -f "${OPENCODE_EXE}" ]]; then
  echo "ERROR: OpenCode not found at ${OPENCODE_EXE}" >&2
  echo "Install the app first:  ./bin/update-opencode.sh" >&2
  exit 1
fi

# Make sure it's executable
chmod +x "${OPENCODE_EXE}"

# Run OpenCode
exec "${OPENCODE_EXE}" "$@"