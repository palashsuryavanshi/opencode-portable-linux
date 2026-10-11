#!/usr/bin/env bash
# ============================================================================
# OpenCode Portable Linux - environment
# Sourced by all launchers. Redirects EVERY path to the USB drive so that
# nothing is written to the host system and everything follows the stick.
# ============================================================================

# Resolve portable root (parent of bin/)
export PORTABLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- OpenCode session data: THE portable part ---
export XDG_DATA_HOME="${PORTABLE_ROOT}/data/opencode-data"
export XDG_CONFIG_HOME="${PORTABLE_ROOT}/data/opencode-config"
export XDG_CACHE_HOME="${PORTABLE_ROOT}/data/opencode-cache"
export XDG_STATE_HOME="${PORTABLE_ROOT}/data/opencode-state"
export OPENCODE_CONFIG_DIR="${XDG_CONFIG_HOME}/opencode"
# Never let the app self-update in place (it would rewrite the USB copy)
export OPENCODE_DISABLE_AUTOUPDATE=1

# --- Isolate user profile writes ---
export HOME="${PORTABLE_ROOT}/data/home"
export TEMP="${PORTABLE_ROOT}/data/tmp"
export TMP="${PORTABLE_ROOT}/data/tmp"

# --- Toolchains ---
if [[ -d "${PORTABLE_ROOT}/apps/jdk" ]]; then
  # Find the JDK root (folder containing bin/java)
  for d in "${PORTABLE_ROOT}/apps/jdk"/*/; do
    if [[ -f "${d}bin/java" ]]; then
      export JAVA_HOME="${d%/}"
      break
    fi
  done
  # Fallback
  if [[ -z "${JAVA_HOME}" && -f "${PORTABLE_ROOT}/apps/jdk/bin/java" ]]; then
    export JAVA_HOME="${PORTABLE_ROOT}/apps/jdk"
  fi
fi

if [[ -d "${PORTABLE_ROOT}/apps/android-sdk" ]]; then
  export ANDROID_HOME="${PORTABLE_ROOT}/apps/android-sdk"
  export ANDROID_SDK_ROOT="${PORTABLE_ROOT}/apps/android-sdk"
fi

if [[ -d "${PORTABLE_ROOT}/apps/go" ]]; then
  export GOROOT="${PORTABLE_ROOT}/apps/go"
fi
export GOPATH="${PORTABLE_ROOT}/data/gopath"
export GOCACHE="${PORTABLE_ROOT}/data/gocache"

if [[ -d "${PORTABLE_ROOT}/apps/maven" ]]; then
  export MAVEN_HOME="${PORTABLE_ROOT}/apps/maven"
fi
export GRADLE_USER_HOME="${PORTABLE_ROOT}/data/gradle"

export NPM_CONFIG_CACHE="${PORTABLE_ROOT}/data/npm-cache"
export PIP_CACHE_DIR="${PORTABLE_ROOT}/data/pip-cache"

if [[ -d "${PORTABLE_ROOT}/apps/dotnet" ]]; then
  export DOTNET_ROOT="${PORTABLE_ROOT}/apps/dotnet"
fi

if [[ -d "${PORTABLE_ROOT}/data/cargo/bin" ]]; then
  export CARGO_HOME="${PORTABLE_ROOT}/data/cargo"
fi
if [[ -d "${PORTABLE_ROOT}/data/rustup" ]]; then
  export RUSTUP_HOME="${PORTABLE_ROOT}/data/rustup"
fi

# --- Build PATH: portable tools first, then system ---
_PORTABLE_PATH="${PORTABLE_ROOT}/apps/opencode"
[[ -n "${JAVA_HOME}" ]] && _PORTABLE_PATH="${_PORTABLE_PATH}:${JAVA_HOME}/bin"
[[ -n "${ANDROID_HOME}" ]] && _PORTABLE_PATH="${_PORTABLE_PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"
[[ -n "${GOROOT}" ]] && _PORTABLE_PATH="${_PORTABLE_PATH}:${GOROOT}/bin:${GOPATH}/bin"
[[ -n "${MAVEN_HOME}" ]] && _PORTABLE_PATH="${_PORTABLE_PATH}:${MAVEN_HOME}/bin"
[[ -n "${DOTNET_ROOT}" ]] && _PORTABLE_PATH="${_PORTABLE_PATH}:${DOTNET_ROOT}"
[[ -n "${CARGO_HOME}" ]] && _PORTABLE_PATH="${_PORTABLE_PATH}:${CARGO_HOME}/bin"
[[ -d "${PORTABLE_ROOT}/apps/node" ]] && _PORTABLE_PATH="${_PORTABLE_PATH}:${PORTABLE_ROOT}/apps/node/bin"
[[ -d "${PORTABLE_ROOT}/apps/python/bin" ]] && _PORTABLE_PATH="${_PORTABLE_PATH}:${PORTABLE_ROOT}/apps/python/bin"
[[ -d "${PORTABLE_ROOT}/apps/gradle/bin" ]] && _PORTABLE_PATH="${_PORTABLE_PATH}:${PORTABLE_ROOT}/apps/gradle/bin"

export PATH="${_PORTABLE_PATH}:${PORTABLE_ROOT}/bin:${PATH}"

# --- Create directories that tools expect ---
mkdir -p \
  "${HOME}" \
  "${TEMP}" \
  "${GOPATH}" \
  "${GOCACHE}" \
  "${GRADLE_USER_HOME}" \
  "${NPM_CONFIG_CACHE}" \
  "${PIP_CACHE_DIR}" \
  "${XDG_CACHE_HOME}" \
  "${XDG_STATE_HOME}" \
  "${PORTABLE_ROOT}/projects" \
  "${XDG_DATA_HOME}/opencode" \
  "${XDG_CONFIG_HOME}/opencode" \
  2>/dev/null