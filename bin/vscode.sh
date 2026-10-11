#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - VS Code launcher
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

VSCODE_EXE="${PORTABLE_ROOT}/apps/vscode/bin/code"
if [[ ! -f "${VSCODE_EXE}" ]]; then
  echo "ERROR: VS Code not found at ${VSCODE_EXE}"
  exit 1
fi

# VS Code portable mode: user-data-dir and extensions-dir on the stick
mkdir -p "${PORTABLE_ROOT}/data/vscode-user" "${PORTABLE_ROOT}/data/vscode-extensions"

exec "${VSCODE_EXE}" \
  --user-data-dir="${PORTABLE_ROOT}/data/vscode-user" \
  --extensions-dir="${PORTABLE_ROOT}/data/vscode-extensions" \
  "${PORTABLE_ROOT}/projects" \
  "$@"