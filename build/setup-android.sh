#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - Android SDK setup
# Installs the Android SDK entirely inside the portable folder.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTABLE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

JAVA_HOME="${PORTABLE_ROOT}/apps/jdk"
SDK_DIR="${PORTABLE_ROOT}/apps/android-sdk"
SDKM="${SDK_DIR}/cmdline-tools/latest/bin/sdkmanager"

# Find actual JAVA_HOME
if [[ -d "${JAVA_HOME}" ]]; then
  for d in "${JAVA_HOME}"/*/; do
    if [[ -f "${d}bin/java" ]]; then
      JAVA_HOME="${d%/}"
      break
    fi
  done
fi

export JAVA_HOME
export ANDROID_HOME="${SDK_DIR}"
export ANDROID_SDK_ROOT="${SDK_DIR}"
export PATH="${JAVA_HOME}/bin:${SDK_DIR}/cmdline-tools/latest/bin:${SDK_DIR}/platform-tools:${PATH}"

if [[ ! -f "${SDKM}" ]]; then
  echo "ERROR: sdkmanager not found at ${SDKM}"
  echo "Run ./build/install-tools.sh first"
  exit 1
fi

echo "== Accepting SDK licenses =="
# The modern sdkmanager doesn't need --licenses, but older ones do
yes | "${SDKM}" --sdk_root="${SDK_DIR}" --licenses 2>/dev/null || true

# Packages to install (using sdk-style paths with colons for older sdkmanager,
# but modern sdkmanager uses forward slashes)
PACKAGES=(
  'platform-tools'
  'build-tools;35.0.0'
  'platforms;android-35'
  'build-tools;34.0.0'
  'platforms;android-34'
)

echo "== Installing packages =="
for pkg in "${PACKAGES[@]}"; do
  echo "-> ${pkg}"
  "${SDKM}" --sdk_root="${SDK_DIR}" "${pkg}" 2>&1 | tail -2
done

echo "== Done =="
ls -la "${SDK_DIR}"