#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - session backup / restore
# The chat history lives in a SQLite database that uses WAL mode, so the
# .db, .db-wal and .db-shm files MUST be copied together or the copy is
# corrupt. Always run this with OpenCode closed.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

DATA_DIR="${XDG_DATA_HOME}/opencode"
BACKUP_DIR="${PORTABLE_ROOT}/data/backups"

usage() {
  cat <<EOF
Usage: $(basename "$0") <action>

Actions:
  backup      Snapshot current sessions to data/backups/
  restore     Load the newest snapshot back
  list        Show available snapshots
  import      Pull sessions from host PC's OpenCode install (~/.local/share/opencode)
EOF
}

# Check if OpenCode is running
check_running() {
  if pgrep -f "opencode" >/dev/null 2>&1; then
    echo "ERROR: OpenCode is still running." >&2
    echo "Close it first, otherwise the database copy can be torn." >&2
    return 1
  fi
  return 0
}

# Copy the three WAL-mode SQLite files + auth.json
copy_session_dir() {
  local src="$1"
  local dst="$2"
  mkdir -p "${dst}"
  for f in opencode.db opencode.db-wal opencode.db-shm auth.json; do
    [[ -f "${src}/${f}" ]] && cp -a "${src}/${f}" "${dst}/"
  done
}

action="${1:-list}"

case "${action}" in
  backup)
    check_running || exit 1
    stamp=$(date +%Y%m%d-%H%M%S)
    dest="${BACKUP_DIR}/sessions-${stamp}"
    copy_session_dir "${DATA_DIR}" "${dest}"
    size=$(du -sh "${dest}" | cut -f1)
    echo "Backed up sessions to ${dest} (${size})"
    ;;

  restore)
    check_running || exit 1
    [[ -d "${BACKUP_DIR}" ]] || { echo "No backups yet"; exit 1; }
    latest=$(ls -1dt "${BACKUP_DIR}"/sessions-* 2>/dev/null | head -1)
    [[ -n "${latest}" ]] || { echo "No backups yet"; exit 1; }
    echo "Restoring from ${latest}"
    copy_session_dir "${latest}" "${DATA_DIR}"
    echo "Done"
    ;;

  list)
    [[ -d "${BACKUP_DIR}" ]] || { echo "No backups yet"; exit 0; }
    for d in "${BACKUP_DIR}"/sessions-*; do
      [[ -d "${d}" ]] || continue
      size=$(du -sh "${d}" | cut -f1)
      echo "  $(basename "${d}")  (${size})"
    done
    ;;

  import)
    check_running || exit 1
    SRC="${HOME}/.local/share/opencode"
    [[ -d "${SRC}" ]] || { echo "No host sessions at ${SRC}"; exit 1; }
    stamp=$(date +%Y%m%d-%H%M%S)
    dest="${BACKUP_DIR}/host-${stamp}"
    copy_session_dir "${SRC}" "${dest}"
    echo "Imported host sessions to ${dest}"
    echo "Now run: $(basename "$0") restore"
    ;;

  *)
    usage
    exit 1
    ;;
esac