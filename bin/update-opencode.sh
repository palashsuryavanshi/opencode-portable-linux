#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - Updater
# Downloads the latest stable .deb from opencode.ai, extracts it,
# and replaces apps/opencode/ while preserving all user data in data/.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

DEB_URL="https://opencode.ai/download/stable/linux-x64-deb"
RPM_URL="https://opencode.ai/download/stable/linux-x64-rpm"

# Detect package format preference (default to .deb)
USE_DEB=true
if [[ -f /etc/redhat-release ]] || [[ -f /etc/fedora-release ]] || command -v rpm >/dev/null 2>&1; then
  USE_DEB=false
fi

DOWNLOAD_URL="${USE_DEB:+${DEB_URL}}"
DOWNLOAD_URL="${USE_DEB:-${RPM_URL}}"
PKG_EXT="${USE_DEB:+deb}"
PKG_EXT="${USE_DEB:-rpm}"

INSTALLER_PATH="${PORTABLE_ROOT}/downloads/opencode-update.${PKG_EXT}"
STAGE_DIR="${PORTABLE_ROOT}/downloads/_update_stage"
OPENCODE_DIR="${PORTABLE_ROOT}/apps/opencode"

echo "========================================================"
echo "  OpenCode Portable Linux Updater"
echo "  Root: ${PORTABLE_ROOT}"
echo "========================================================"
echo

# --- 1. Check current version ---
CURRENT_VER="unknown"
if [[ -f "${OPENCODE_DIR}/opencode" ]]; then
  # Try to get version from the binary
  CURRENT_VER=$("${OPENCODE_DIR}/opencode" --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
fi
echo "  Current version: ${CURRENT_VER}"

# --- 2. Download latest package ---
echo
echo "  Downloading latest ${PKG_EXT} package..."
echo "  URL: ${DOWNLOAD_URL}"

mkdir -p "$(dirname "${INSTALLER_PATH}")"
mkdir -p "${STAGE_DIR}"

if ! curl -L -o "${INSTALLER_PATH}" "${DOWNLOAD_URL}" --connect-timeout 30 --max-time 300; then
  echo "ERROR: Download failed" >&2
  exit 1
fi

SIZE_MB=$(du -m "${INSTALLER_PATH}" | cut -f1)
echo "  Downloaded: ${SIZE_MB} MB"

# --- 3. Extract package ---
echo
echo "  Extracting..."

rm -rf "${STAGE_DIR:?}/*"

if [[ "${USE_DEB}" == "true" ]]; then
  # Extract .deb with dpkg-deb
  if ! command -v dpkg-deb >/dev/null 2>&1; then
    echo "ERROR: dpkg-deb not found. Install dpkg-dev or use RPM on RPM-based distros." >&2
    exit 1
  fi
  dpkg-deb -x "${INSTALLER_PATH}" "${STAGE_DIR}"
  NEW_APP_DIR="${STAGE_DIR}/opt/opencode"
else
  # Extract .rpm with rpm2cpio
  if ! command -v rpm2cpio >/dev/null 2>&1 || ! command -v cpio >/dev/null 2>&1; then
    echo "ERROR: rpm2cpio/cpio not found. Install rpm2cpio." >&2
    exit 1
  fi
  rpm2cpio "${INSTALLER_PATH}" | (cd "${STAGE_DIR}" && cpio -idmv)
  NEW_APP_DIR="${STAGE_DIR}/opt/opencode"
fi

if [[ ! -f "${NEW_APP_DIR}/opencode" ]]; then
  echo "ERROR: opencode binary not found in extracted package." >&2
  echo "Package structure may have changed." >&2
  exit 1
fi

# --- 4. Verify extracted app ---
NEW_VER=$("${NEW_APP_DIR}/opencode" --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
echo "  New version: ${NEW_VER}"

if [[ "${CURRENT_VER}" == "${NEW_VER}" && "${1:-}" != "--force" ]]; then
  echo
  echo "Already on latest version (${CURRENT_VER}). Use --force to reinstall."
  exit 0
fi

# --- 5. Backup current opencode ---
BACKUP_DIR="${PORTABLE_ROOT}/data/backups/opencode-${CURRENT_VER}-$(date +%Y%m%d-%H%M%S)"
echo
echo "  Backing up current opencode to: ${BACKUP_DIR}"
mkdir -p "$(dirname "${BACKUP_DIR}")"
cp -a "${OPENCODE_DIR}" "${BACKUP_DIR}"

# --- 6. Replace apps/opencode ---
echo
echo "  Installing new version..."
rm -rf "${OPENCODE_DIR}"
mv "${NEW_APP_DIR}" "${OPENCODE_DIR}"
chmod +x "${OPENCODE_DIR}/opencode"

# --- 7. Verify ---
CHECK_VER=$("${OPENCODE_DIR}/opencode" --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")

echo
echo "========================================================"
echo "  Update complete!"
echo "  Old version: ${CURRENT_VER}"
echo "  New version: ${CHECK_VER}"
echo "  User data preserved in: ${PORTABLE_ROOT}/data/"
echo "========================================================"
echo
echo "  Run ./bin/verify.sh to confirm."

# --- 8. Cleanup ---
rm -rf "${STAGE_DIR}"
rm -f "${INSTALLER_PATH}"