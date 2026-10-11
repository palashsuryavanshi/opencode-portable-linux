#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - verification
# Run this on any new machine first to confirm all paths point to the stick.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

echo
echo "================================================================"
echo "  OpenCode Portable Linux - verification"
echo "  root: ${PORTABLE_ROOT}"
echo "================================================================"
echo

FAIL=0
ROOTDEV="${PORTABLE_ROOT%%/*}"  # rough check: same filesystem root

echo "[1] Path isolation"
check_isolate() {
  local name="$1"
  local path="$2"
  if [[ "${path}" == "${PORTABLE_ROOT}"* ]]; then
    echo "  ok   ${name} on the stick"
  else
    echo "  FAIL ${name} points off the stick: ${path}"
    FAIL=1
  fi
}

check_isolate XDG_DATA_HOME   "${XDG_DATA_HOME}"
check_isolate XDG_CONFIG_HOME "${XDG_CONFIG_HOME}"
check_isolate XDG_CACHE_HOME  "${XDG_CACHE_HOME}"
check_isolate XDG_STATE_HOME  "${XDG_STATE_HOME}"
check_isolate HOME            "${HOME}"
check_isolate TEMP            "${TEMP}"
echo

echo "[2] Chat sessions"
if [[ -f "${XDG_DATA_HOME}/opencode/opencode.db" ]]; then
  dbsize=$(du -h "${XDG_DATA_HOME}/opencode/opencode.db" | cut -f1)
  echo "  ok   opencode.db (${dbsize})"
else
  echo "  info opencode.db not found - fresh install (sign in to create)"
fi
[[ -f "${XDG_CONFIG_HOME}/opencode/opencode.jsonc" ]] && echo "  ok   opencode.jsonc" || echo "  warn no opencode.jsonc"
if [[ -f "${XDG_CONFIG_HOME}/opencode/auth.json" ]]; then
  authsize=$(stat -c%s "${XDG_CONFIG_HOME}/opencode/auth.json" 2>/dev/null || stat -f%z "${XDG_CONFIG_HOME}/opencode/auth.json")
  if [[ ${authsize} -gt 2 ]]; then
    echo "  ok   auth.json - already signed in"
  else
    echo "  ok   auth.json - empty (sign in on first run)"
  fi
else
  echo "  warn no auth.json"
fi
echo

echo "[3] Toolchains"
check_tool() {
  local name="$1"
  local cmd="$2"
  local required="${3:-optional}"
  if command -v "${cmd}" >/dev/null 2>&1; then
    echo "  ok   ${name}"
  else
    if [[ "${required}" == "required" ]]; then
      echo "  miss ${name} (required)"
      FAIL=1
    else
      echo "  miss ${name} (optional)"
    fi
  fi
}

check_tool java      java       required
check_tool node      node       required
check_tool go        go         required
check_tool git       git        required
check_tool maven     mvn        optional
check_tool adb       adb        optional
check_tool python3   python3    optional
check_tool dotnet    dotnet     optional
check_tool cargo     cargo      optional
check_tool rustc     rustc      optional
check_tool rustup    rustup     optional

[[ -f "${PORTABLE_ROOT}/apps/opencode/opencode" ]] && echo "  ok   OpenCode GUI" || { echo "  FAIL OpenCode GUI missing"; FAIL=1; }
echo

echo "================================================================"
if [[ ${FAIL} -eq 0 ]]; then
  echo "  RESULT: ready to use"
else
  echo "  RESULT: problems found - see FAIL above"
fi
echo "================================================================"
echo

exit ${FAIL}