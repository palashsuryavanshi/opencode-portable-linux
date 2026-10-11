#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - Main menu
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTABLE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

while true; do
  clear
  echo
  echo "================================================================"
  echo "    OpenCode Portable Linux   -   ${PORTABLE_ROOT##*/}"
  echo "================================================================"
  echo
  echo "  1.  OpenCode GUI          <- the main app, sessions included"
  echo "  2.  VS Code               <- portable, settings on the stick"
  echo "  3.  Developer Shell       <- bash with all toolchains on PATH"
  echo "  4.  OpenCode CLI (TUI)    <- terminal client, same sessions"
  echo "  5.  Android SDK Manager"
  echo "  6.  Sessions: backup / restore / list / import"
  echo "  7.  Verify portable setup"
  echo "  8.  Update OpenCode       <- download & install latest stable"
  echo "  0.  Exit"
  echo
  read -rp "  Choose: " CHOICE

  case "${CHOICE}" in
    1) "${SCRIPT_DIR}/opencode.sh" ;;
    2) "${SCRIPT_DIR}/vscode.sh" ;;
    3) "${SCRIPT_DIR}/shell.sh" ;;
    4) "${SCRIPT_DIR}/opencode-cli.sh" ;;
    5) "${SCRIPT_DIR}/android.sh" ;;
    6) "${SCRIPT_DIR}/sync.sh" ;;
    7) "${SCRIPT_DIR}/verify.sh" ;;
    8) "${SCRIPT_DIR}/update-opencode.sh" "${@}" ;;
    0) exit 0 ;;
    *) echo "  Invalid choice."; sleep 1 ;;
  esac

  # Pause after each action except exit
  [[ "${CHOICE}" != "0" ]] && read -rp "  Press Enter to continue..."
done