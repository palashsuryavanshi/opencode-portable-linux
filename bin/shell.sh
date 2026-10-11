#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - Developer shell
# Starts an interactive bash with all toolchains on PATH.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

echo
echo "============================================================"
echo "  Portable Dev Shell"
echo "  root: ${PORTABLE_ROOT}"
echo "============================================================"
echo

command -v java >/dev/null 2>&1 && echo "  [ok] Java   : ${JAVA_HOME:-not found}"
command -v node >/dev/null 2>&1 && echo "  [ok] Node   : $(node --version)"
command -v go >/dev/null 2>&1 && echo "  [ok] Go     : ${GOROOT:-not found}"
command -v git >/dev/null 2>&1 && echo "  [ok] Git    : $(git --version | cut -d' ' -f3)"
command -v mvn >/dev/null 2>&1 && echo "  [ok] Maven  : ${MAVEN_HOME:-not found}"
command -v python3 >/dev/null 2>&1 && echo "  [ok] Python : $(python3 --version)"
command -v dotnet >/dev/null 2>&1 && echo "  [ok] .NET   : $(dotnet --version)"
command -v cargo >/dev/null 2>&1 && echo "  [ok] Rust   : $(cargo --version | cut -d' ' -f2)"
command -v adb >/dev/null 2>&1 && echo "  [ok] adb    : ${ANDROID_HOME:-not found}"
echo
echo "  opencode CLI : opencode"
echo
echo "  projects live in: ${PORTABLE_ROOT}/projects"
echo "  opencode data : ${XDG_DATA_HOME}"
echo
echo "============================================================"
echo

cd "${PORTABLE_ROOT}/projects"

if [[ $# -eq 0 ]]; then
  exec bash --rcfile <(cat ~/.bashrc 2>/dev/null; echo "PS1='(portable) \w\$ '")
else
  exec "$@"
fi