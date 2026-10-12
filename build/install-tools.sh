#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - Tool installer
# Unpacks the downloaded archives into apps/ using the layout each tool
# expects when run in place rather than installed.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTABLE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DL_DIR="${PORTABLE_ROOT}/downloads"
APPS_DIR="${PORTABLE_ROOT}/apps"
TMP_DIR="${DL_DIR}/_unpack"

mkdir -p "${TMP_DIR}"

extract_tar() {
  local archive="$1"
  local dest="$2"
  local strip="${3:-false}"

  echo "Installing $(basename "${archive}")..."
  rm -rf "${dest}"
  mkdir -p "${dest}"

  if [[ "${strip}" == "true" ]]; then
    local stage="${TMP_DIR}/$(basename "${archive}" .tar.*)"
    rm -rf "${stage}"
    tar -xf "${archive}" -C "${TMP_DIR}"
    # Find the first directory
    local first_dir=$(find "${TMP_DIR}" -mindepth 1 -maxdepth 1 -type d | head -1)
    if [[ -n "${first_dir}" ]]; then
      mv "${first_dir}"/* "${dest}/"
    else
      mv "${TMP_DIR}"/* "${dest}/" 2>/dev/null || true
    fi
    rm -rf "${stage}"
  else
    tar -xf "${archive}" -C "${dest}"
  fi
}

extract_zip() {
  local archive="$1"
  local dest="$2"
  local strip="${3:-false}"

  echo "Installing $(basename "${archive}")..."
  rm -rf "${dest}"
  mkdir -p "${dest}"

  if [[ "${strip}" == "true" ]]; then
    local stage="${TMP_DIR}/$(basename "${archive}" .zip)"
    rm -rf "${stage}"
    unzip -q "${archive}" -d "${stage}"
    local first_dir=$(find "${stage}" -mindepth 1 -maxdepth 1 -type d | head -1)
    if [[ -n "${first_dir}" ]]; then
      mv "${first_dir}"/* "${dest}/"
    else
      mv "${stage}"/* "${dest}/" 2>/dev/null || true
    fi
    rm -rf "${stage}"
  else
    unzip -q "${archive}" -d "${dest}"
  fi
}

# --- VS Code ---
# VS Code Linux tarball extracts to VSCode-linux-x64/
extract_tar "${DL_DIR}/vscode.tar.gz" "${APPS_DIR}/vscode" true

# --- Temurin JDK 21 ---
# Extracts to jdk-21.x.x+X/
extract_tar "${DL_DIR}/jdk.tar.gz" "${APPS_DIR}/jdk" true

# --- Go ---
# Extracts to go/
extract_tar "${DL_DIR}/go.tar.gz" "${APPS_DIR}/go" true

# --- Node.js ---
# Extracts to node-vXX-linux-x64/
extract_tar "${DL_DIR}/node.tar.xz" "${APPS_DIR}/node" true

# --- Maven ---
# Extracts to apache-maven-X.Y.Z/
extract_tar "${DL_DIR}/maven.tar.gz" "${APPS_DIR}/maven" true

# --- Gradle ---
# Extracts to gradle-X.Y/
extract_zip "${DL_DIR}/gradle.zip" "${APPS_DIR}/gradle" true

# --- Git ---
# Build from source (tarball)
echo "Building Git from source..."
GIT_SRC="${TMP_DIR}/git-src"
rm -rf "${GIT_SRC}"
tar -xf "${DL_DIR}/git.tar.xz" -C "${TMP_DIR}"
GIT_SRC_DIR=$(find "${TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -name 'git-*' | head -1)
if [[ -n "${GIT_SRC_DIR}" ]]; then
  (
    cd "${GIT_SRC_DIR}"
    make configure >/dev/null 2>&1
    ./configure --prefix="${APPS_DIR}/git" >/dev/null 2>&1
    make -j$(nproc) >/dev/null 2>&1
    make install >/dev/null 2>&1
  )
  echo "  Git installed to ${APPS_DIR}/git"
else
  echo "  WARNING: Git source not found, skipping"
fi

# --- Python ---
# Build from source
echo "Building Python from source..."
PYTHON_SRC="${TMP_DIR}/python-src"
rm -rf "${PYTHON_SRC}"
tar -xf "${DL_DIR}/python.tar.xz" -C "${TMP_DIR}"
PYTHON_SRC_DIR=$(find "${TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -name 'Python-*' | head -1)
if [[ -n "${PYTHON_SRC_DIR}" ]]; then
  (
    cd "${PYTHON_SRC_DIR}"
    ./configure --prefix="${APPS_DIR}/python" --enable-optimizations >/dev/null 2>&1
    make -j$(nproc) >/dev/null 2>&1
    make install >/dev/null 2>&1
  )
  echo "  Python installed to ${APPS_DIR}/python"
else
  echo "  WARNING: Python source not found, skipping"
fi

# --- .NET SDK ---
# Already a portable tarball
extract_tar "${DL_DIR}/dotnet.tar.gz" "${APPS_DIR}/dotnet" false

# --- Android command-line tools ---
# Must end up at cmdline-tools/latest/bin
echo "Installing Android cmdline-tools..."
STAGE="${TMP_DIR}/androidcmd"
rm -rf "${STAGE}"
unzip -q "${DL_DIR}/androidcmd.zip" -d "${STAGE}"
SDK_DIR="${APPS_DIR}/android-sdk"
rm -rf "${SDK_DIR}/cmdline-tools"
mkdir -p "${SDK_DIR}/cmdline-tools"
mv "${STAGE}/cmdline-tools" "${SDK_DIR}/cmdline-tools/latest"
echo "  Android SDK installed to ${SDK_DIR}/cmdline-tools/latest"

# --- Rust (rustup) ---
# Run rustup-init with custom CARGO_HOME/RUSTUP_HOME
echo "Installing Rust (rustup)..."
CARGO_HOME="${PORTABLE_ROOT}/data/cargo"
RUSTUP_HOME="${PORTABLE_ROOT}/data/rustup"
mkdir -p "${CARGO_HOME}" "${RUSTUP_HOME}"

export CARGO_HOME
export RUSTUP_HOME

"${DL_DIR}/rustup-init" -y --no-modify-path --default-toolchain stable --profile minimal

# Create wrapper scripts for cargo, rustc, rustup
cat > "${APPS_DIR}/rust/cargo" <<'EOF'
#!/usr/bin/env bash
export CARGO_HOME="$(dirname "$(dirname "$(realpath "$0")")")/../data/cargo"
export RUSTUP_HOME="$(dirname "$(dirname "$(realpath "$0")")")/../data/rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"
exec "${CARGO_HOME}/bin/cargo" "$@"
EOF

cat > "${APPS_DIR}/rust/rustc" <<'EOF'
#!/usr/bin/env bash
export CARGO_HOME="$(dirname "$(dirname "$(realpath "$0")")")/../data/cargo"
export RUSTUP_HOME="$(dirname "$(dirname "$(realpath "$0")")")/../data/rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"
exec "${CARGO_HOME}/bin/rustc" "$@"
EOF

cat > "${APPS_DIR}/rust/rustup" <<'EOF'
#!/usr/bin/env bash
export CARGO_HOME="$(dirname "$(dirname "$(realpath "$0")")")/../data/cargo"
export RUSTUP_HOME="$(dirname "$(dirname "$(realpath "$0")")")/../data/rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"
exec "${CARGO_HOME}/bin/rustup" "$@"
EOF

chmod +x "${APPS_DIR}/rust/cargo" "${APPS_DIR}/rust/rustc" "${APPS_DIR}/rust/rustup"

echo "  Rust installed to ${APPS_DIR}/rust (toolchains in ${RUSTUP_HOME})"

# --- Cleanup ---
rm -rf "${TMP_DIR}"

echo "INSTALL DONE"