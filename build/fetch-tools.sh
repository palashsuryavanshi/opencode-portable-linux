#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - Tool fetcher
# Downloads the portable-friendly (tar.gz / binary) builds of every tool.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTABLE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DL_DIR="${PORTABLE_ROOT}/downloads"

mkdir -p "${DL_DIR}"

echo "Resolving latest versions..."

# --- VS Code ---
VSCODE_URL="https://update.code.visualstudio.com/latest/linux-x64/stable"

# --- Node.js ---
NODE_VERSION=$(curl -s https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts and (.files | index("linux-x64")))] | first | .version')
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz"

# --- Go ---
GO_VERSION=$(curl -s https://go.dev/dl/?mode=json | jq -r '.[0].version')
GO_URL="https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"

# --- Temurin JDK 21 ---
JDK_URL=$(curl -s "https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=linux&vendor=eclipse" | jq -r '.[0].binary.package.link')

# --- Git ---
GIT_VERSION=$(curl -s "https://api.github.com/repos/git/git/releases/latest" -H 'User-Agent: opencode-portable' | jq -r '.tag_name | ltrimstr("v")')
GIT_URL="https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz"

# --- Maven ---
MAVEN_VERSION=$(curl -s "https://dlcdn.apache.org/maven/maven-3/" | grep -oP '3\.\d+\.\d+' | sort -V | tail -1)
MAVEN_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"

# --- Gradle ---
GRADLE_VERSION=$(curl -s "https://services.gradle.org/versions/current" | jq -r '.version')
GRADLE_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

# --- Python ---
PYTHON_VERSION=$(curl -s "https://www.python.org/ftp/python/" | grep -oP '3\.\d+\.\d+' | sort -V | tail -1)
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"

# --- .NET SDK ---
DOTNET_VERSION=$(curl -s "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json" | jq -r '.["releases-index"][] | select(.["channel-version"]=="9.0" and .["support-phase"]=="active") | .["latest-sdk"]' | head -1)
DOTNET_URL="https://builds.dotnet.microsoft.com/dotnet/Sdk/${DOTNET_VERSION}/dotnet-sdk-${DOTNET_VERSION}-linux-x64.tar.gz"

# --- Android cmdline-tools ---
ANDROID_CMD_TOOLS=$(curl -s "https://dl.google.com/android/repository/repository2-3.xml" | grep -oP 'commandlinetools-linux-\d+_latest\.zip' | head -1)
ANDROID_CMD_URL="https://dl.google.com/android/repository/${ANDROID_CMD_TOOLS}"

# --- Rust (rustup) ---
RUSTUP_URL="https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"

# --- Display resolved URLs ---
cat <<EOF
RESOLVED:
  VS Code     : ${VSCODE_URL}
  Node.js     : ${NODE_URL}
  Go          : ${GO_URL}
  JDK 21      : ${JDK_URL}
  Git         : ${GIT_URL}
  Maven       : ${MAVEN_URL}
  Gradle      : ${GRADLE_URL}
  Python      : ${PYTHON_URL}
  .NET SDK    : ${DOTNET_URL}
  Android SDK : ${ANDROID_CMD_URL}
  Rust        : ${RUSTUP_URL}
EOF

# --- Download in parallel ---
download() {
  local name="$1"
  local url="$2"
  local dest="${DL_DIR}/${name}"
  echo "Downloading ${name}..."
  if curl -L -o "${dest}" "${url}" --connect-timeout 30 --max-time 600 --silent --show-error; then
    echo "  OK: ${dest}"
  else
    echo "  FAIL: ${name}" >&2
    return 1
  fi
}

export -f download
export DL_DIR

# Run downloads in background jobs
download "vscode.tar.gz" "${VSCODE_URL}" &
download "node.tar.xz" "${NODE_URL}" &
download "go.tar.gz" "${GO_URL}" &
download "jdk.tar.gz" "${JDK_URL}" &
download "git.tar.xz" "${GIT_URL}" &
download "maven.tar.gz" "${MAVEN_URL}" &
download "gradle.zip" "${GRADLE_URL}" &
download "python.tar.xz" "${PYTHON_URL}" &
download "dotnet.tar.gz" "${DOTNET_URL}" &
download "androidcmd.zip" "${ANDROID_CMD_URL}" &
download "rustup-init" "${RUSTUP_URL}" &

wait

echo "DOWNLOADS DONE"