#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - OpenCode CLI (TUI)
# Same sessions as GUI because both use XDG_DATA_HOME on the stick.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

CLI="${PORTABLE_ROOT}/apps/opencode/opencode"
if [[ ! -f "${CLI}" ]]; then
  echo "ERROR: opencode CLI not found at ${CLI}"
  exit 1
fi

cd "${PORTABLE_ROOT}/projects"
exec "${CLI}" "$@"