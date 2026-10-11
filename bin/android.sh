#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - Android SDK manager / ADB
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

SDK="${ANDROID_HOME}"
SDKM="${SDK}/cmdline-tools/latest/bin/sdkmanager"

if [[ ! -f "${SDKM}" ]]; then
  echo "ERROR: Android command-line tools not found at ${SDKM}"
  echo "Run: ./build/setup-android.sh"
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo
  echo "Android SDK root : ${SDK}"
  echo "Java            : ${JAVA_HOME}"
  echo
  echo "Examples:"
  echo "  $(basename "$0") --list"
  echo "  $(basename "$0") --list_installed"
  echo "  $(basename "$0") 'build-tools;35.0.0'"
  echo "  $(basename "$0") 'platforms;android-35'"
  echo
  echo "ADB (connect phone with USB debugging):"
  echo "  adb devices"
  echo "  adb install path/to/app.apk"
  echo
  "${SDKM}" --sdk_root="${SDK}" --list_installed
else
  exec "${SDKM}" --sdk_root="${SDK}" "$@"
fi