#!/usr/bin/env bash
# ============================================================================
# install-selected-tools.sh
#
# Interactive, selective tool installer for OpenCode Portable (Linux).
#
# The full bundle is roughly 5-7 GB. This script lets the user pick only the
# toolchains they actually want, shows sizes, checks free space before
# downloading anything, and verifies each tool after install.
#
# Everything lands under <ROOT>/apps. The script never touches <ROOT>/data
# (chat sessions, caches) or <ROOT>/projects.
#
# Usage:
#   ./install-selected-tools.sh              interactive selection
#   ./install-selected-tools.sh --all        install everything
#   ./install-selected-tools.sh --minimal    OpenCode only
#   ./install-selected-tools.sh --only jdk,node,go
#   ./install-selected-tools.sh --list       show the catalogue and exit
#   ./install-selected-tools.sh --force      reinstall what is present
#   ./install-selected-tools.sh --no-android skip Android SDK packages
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
APPS="${ROOT}/apps"
DL="${ROOT}/downloads"
UNPACK="${DL}/_unpack"

FORCE=0
NO_ANDROID=0

mkdir -p "$APPS" "$DL" "$UNPACK"

# ---------------------------------------------------------------------------
# output helpers
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_STEP=$'\033[36m'; C_OK=$'\033[32m'; C_WARN=$'\033[33m'
  C_ERR=$'\033[31m';  C_OFF=$'\033[0m'
else
  C_STEP=''; C_OK=''; C_WARN=''; C_ERR=''; C_OFF=''
fi
step() { printf '\n==> %s%s\n' "$C_STEP" "$1"; }
ok()   { printf '    [ok]   %s%s\n' "$C_OK" "$1"; }
warn() { printf '    [warn] %s%s\n' "$C_WARN" "$1"; }
err()  { printf '    [FAIL] %s%s\n' "$C_ERR" "$1"; }
die()  { err "$1"; exit 1; }

# ---------------------------------------------------------------------------
# tool catalogue:  name|label|installed_size_mb|description
# ---------------------------------------------------------------------------
TOOLS=(
  "opencode|OpenCode GUI + CLI|740|The AI coding assistant (required)"
  "vscode|VS Code (portable)|400|Portable tarball, data on the stick"
  "jdk|Temurin JDK 21 LTS|330|Java, needed for Android and Gradle"
  "android|Android SDK|655|cmdline-tools, platform-tools, build-tools 34/35"
  "node|Node.js (latest LTS)|200|JavaScript and TypeScript"
  "go|Go (latest)|240|Go toolchain"
  "python|Python|250|BUILT FROM SOURCE - slow, expect 10-30 min"
  "dotnet|.NET SDK|770|C# and F#"
  "rust|Rust (rustup)|760|cargo / rustc, stable toolchain"
  "git|Git|70|BUILT FROM SOURCE - slow, expect 5-15 min"
  "maven|Maven|12|Java build tool"
  "gradle|Gradle|150|Java/Kotlin build automation"
)

field() { # field <toolname> <index 1..4>
  local name="$1" idx="$2" line
  line="$(printf '%s\n' "${TOOLS[@]}" | grep "^${name}|" || true)"
  [[ -z "$line" ]] && return 1
  printf '%s\n' "$line" | cut -d'|' -f"$idx"
}

known_tool() {
  local n
  for n in "${TOOLS[@]}"; do [[ "${n%%|*}" == "$1" ]] && return 0; done
  return 1
}

size_of() { field "$1" 3 || echo 0; }
label_of() { field "$1" 2 || echo "$1"; }

# ---------------------------------------------------------------------------
# prerequisites
# ---------------------------------------------------------------------------
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but not installed. $2"
}

json() { # tiny wrapper so we can insist on jq only when truly needed
  need_cmd jq "Install it:  sudo apt install jq   (or:  sudo dnf install jq)"
  jq "$@"
}

# ---------------------------------------------------------------------------
# layout helpers
#
# Many tool archives unpack into ONE wrapper directory whose CONTENTS belong
# in apps/<tool>. Flat archives must not be stripped. Getting this wrong
# leaves a tool one folder too deep and silently breaks PATH.
# ---------------------------------------------------------------------------
expand_strip() { # expand_strip <archive> <dest>
  local archive="$1" dest="$2" stage child
  stage="$(mktemp -d "${UNPACK}/strip.XXXXXX")"
  tar -xf "$archive" -C "$stage"
  child="$(find "$stage" -mindepth 1 -maxdepth 1 -type d | head -1)"
  rm -rf "$dest"
  mkdir -p "$dest"
  if [[ -n "$child" ]]; then
    mv "$child"/* "$dest"/ 2>/dev/null || true
    # copy dotfiles too, then drop the wrapper
    (cd "$child" && shopt -s dotglob nullglob && mv -- * "$dest"/ 2>/dev/null) || true
  else
    mv "$stage"/* "$dest"/ 2>/dev/null || true
  fi
  rm -rf "$stage"
}

expand_flat() { # expand_flat <archive> <dest>
  local archive="$1" dest="$2"
  rm -rf "$dest"
  mkdir -p "$dest"
  tar -xf "$archive" -C "$dest"
}

expand_flat_zip() { # expand_flat_zip <archive> <dest>
  local archive="$1" dest="$2"
  rm -rf "$dest"
  mkdir -p "$dest"
  unzip -q "$archive" -d "$dest"
}

# Locate the folder under apps/jdk that actually contains bin/java.
# A plain wildcard would match .../jdk/lib, which is NOT a usable JAVA_HOME.
jdk_home() {
  local d
  for d in "${APPS}"/jdk/*/; do
    [[ -f "$d/bin/java" ]] && { printf '%s' "${d%/}"; return 0; }
  done
  [[ -f "${APPS}/jdk/bin/java" ]] && { printf '%s' "${APPS}/jdk"; return 0; }
  printf '%s' "${APPS}/jdk"
}

# ---------------------------------------------------------------------------
# installed checks
# ---------------------------------------------------------------------------
is_installed() {
  case "$1" in
    opencode) [[ -f "${APPS}/opencode/opencode" ]] ;;
    vscode)   [[ -f "${APPS}/vscode/bin/code" ]] ;;
    jdk)      [[ -f "$(jdk_home)/bin/java" ]] ;;
    android)  [[ -f "${APPS}/android-sdk/cmdline-tools/latest/bin/sdkmanager" ]] ;;
    node)     [[ -f "${APPS}/node/bin/node" ]] ;;
    go)       [[ -f "${APPS}/go/bin/go" ]] ;;
    python)   [[ -f "${APPS}/python/bin/python3" ]] ;;
    dotnet)   [[ -f "${APPS}/dotnet/dotnet" ]] ;;
    rust)     [[ -f "${ROOT}/data/cargo/bin/cargo" ]] ;;
    git)      [[ -f "${APPS}/git/bin/git" ]] ;;
    maven)    [[ -f "${APPS}/maven/bin/mvn" ]] ;;
    gradle)   [[ -f "${APPS}/gradle/bin/gradle" ]] ;;
    *)        return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# URL resolution - each tool finds its own current stable release
# ---------------------------------------------------------------------------
resolve_url() {
  case "$1" in

    opencode)
      # Debian/Ubuntu get the .deb, RPM distros the .rpm
      if [[ -f /etc/redhat-release || -f /etc/fedora-release ]] && command -v rpm >/dev/null 2>&1; then
        echo "https://opencode.ai/download/stable/linux-x64-rpm"
      else
        echo "https://opencode.ai/download/stable/linux-x64-deb"
      fi
      ;;

    vscode)   echo "https://update.code.visualstudio.com/latest/linux-x64/stable" ;;

    jdk)
      json '.[0].binary.package.link' <<<"$(curl -fsSL \
        'https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=linux&vendor=eclipse')"
      ;;

    go)
      json -r '.[0].files[] | select(.os=="linux" and .arch=="amd64" and .kind=="archive") | .filename' \
        <<<"$(curl -fsSL 'https://go.dev/dl/?mode=json')" | head -1 \
      | { read -r f; echo "https://go.dev/dl/${f}"; }
      ;;

    node)
      local v
      v="$(json -r '[.[] | select(.lts and (.files|index("linux-x64")))] | first | .version' \
            <<<"$(curl -fsSL 'https://nodejs.org/dist/index.json')")"
      echo "https://nodejs.org/dist/${v}/node-${v}-linux-x64.tar.xz"
      ;;

    maven)
      local v
      v="$(curl -fsSL 'https://dlcdn.apache.org/maven/maven-3/' \
           | grep -oE '3\.[0-9]+\.[0-9]+' | sort -V | tail -1)"
      echo "https://dlcdn.apache.org/maven/maven-3/${v}/binaries/apache-maven-${v}-bin.tar.gz"
      ;;

    gradle)
      local v
      v="$(json -r '.version' <<<"$(curl -fsSL 'https://services.gradle.org/versions/current')")"
      echo "https://services.gradle.org/distributions/gradle-${v}-bin.zip"
      ;;

    git)
      # Built from source: only the version number is needed
      json -r '.tag_name | ltrimstr("v")' \
        <<<"$(curl -fsSL -H 'User-Agent: opencode-portable' \
              'https://api.github.com/repos/git/git/releases/latest')" \
      | { read -r v; echo "https://mirrors.edge.kernel.org/pub/software/scm/git/git-${v}.tar.xz"; }
      ;;

    dotnet)
      # Channel 9.0 LTS. The SDK tarball is already flat (no wrapper folder).
      local ch ver url
      ch="$(json -r '.["releases-index"][] | select(.["channel-version"]=="9.0" and .["support-phase"]=="active") | .["releases-json"]' \
            <<<"$(curl -fsSL 'https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json')")"
      ver="$(json -r '.["releases-index"][] | select(.["channel-version"]=="9.0" and .["support-phase"]=="active") | .["latest-sdk"]' \
            <<<"$(curl -fsSL 'https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json')")"
      url="$(json -r ".releases[] | select(.sdk.version==\"${ver}\") | .sdk.files[] | select(.name|test(\"linux-x64\\\\.tar\\\\.gz\$\")) | select(.name|test(\"aspnetcore|runtime\")|not) | .url" \
            <<<"$(curl -fsSL "$ch")")"
      echo "$url"
      ;;

    python)
      # No official portable Linux Python build exists, so this is a source
      # build. It is slow and is labelled as such in the catalogue.
      local v
      v="$(curl -fsSL 'https://www.python.org/ftp/python/' | grep -oE '3\.1[0-9]+\.[0-9]+' | sort -V | tail -1)"
      echo "https://www.python.org/ftp/python/${v}/Python-${v}.tar.xz"
      ;;

    rust)
      echo "https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"
      ;;

    android)
      curl -fsSL 'https://dl.google.com/android/repository/repository2-3.xml' \
        | grep -oE 'commandlinetools-linux-[0-9]+_latest\.zip' | head -1 \
      | { read -r f; echo "https://dl.google.com/android/repository/${f}"; }
      ;;
  esac
}

archive_name() {
  case "$1" in
    opencode) echo "opencode.pkg"   ;;
    vscode)   echo "vscode.tar.gz"  ;;
    jdk)      echo "jdk.tar.gz"     ;;
    android)  echo "android-cmd.zip" ;;
    node)     echo "node.tar.xz"    ;;
    go)       echo "go.tar.gz"      ;;
    python)   echo "python.tar.xz"  ;;
    dotnet)   echo "dotnet.tar.gz"  ;;
    rust)     echo "rustup-init"    ;;
    git)      echo "git.tar.xz"     ;;
    maven)    echo "maven.tar.gz"   ;;
    gradle)   echo "gradle.zip"     ;;
  esac
}

# ---------------------------------------------------------------------------
# installers
# ---------------------------------------------------------------------------
install_opencode() {
  local a="$1" stage
  stage="$(mktemp -d "${UNPACK}/oc.XXXXXX")"
  if command -v dpkg-deb >/dev/null 2>&1; then
    dpkg-deb -x "$a" "$stage" || return 1
  elif command -v rpm2cpio >/dev/null 2>&1 && command -v cpio >/dev/null 2>&1; then
    rpm2cpio "$a" | (cd "$stage" && cpio -idmu) || return 1
  else
    err "need dpkg-deb (Debian/Ubuntu) or rpm2cpio+cpio (Fedora/RHEL) to unpack this package"
    rm -rf "$stage"
    return 1
  fi
  # NOTE: do not rely on 'set -e' here. Bash disables errexit inside a
  # function invoked from an if-condition, so failures must be explicit.
  if [[ ! -f "$stage/opt/opencode/opencode" ]]; then
    err "opencode binary not found inside the package"
    rm -rf "$stage"; return 1
  fi
  rm -rf "${APPS}/opencode"
  mv "$stage/opt/opencode" "${APPS}/opencode" || { rm -rf "$stage"; return 1; }
  rm -rf "$stage"
  chmod +x "${APPS}/opencode/opencode" || return 1
  ok "OpenCode GUI + CLI ($("${APPS}/opencode/opencode" --version 2>&1 | head -1))"
}

install_vscode() {
  expand_strip "$1" "${APPS}/vscode"
  mkdir -p "${APPS}/vscode/data"
  ok "VS Code (bin/code present)"
}

install_jdk() {
  expand_strip "$1" "${APPS}/jdk"
  ok "JDK $("${APPS}/jdk/bin/java" -version 2>&1 | head -1)"
}

install_go() {
  expand_strip "$1" "${APPS}/go"
  ok "Go $("${APPS}/go/bin/go" version)"
}

install_node() {
  expand_strip "$1" "${APPS}/node"
  ok "Node $("${APPS}/node/bin/node" --version)"
}

install_maven() {
  expand_strip "$1" "${APPS}/maven"
  ok "Maven installed"
}

install_gradle() {
  expand_strip "$1" "${APPS}/gradle"
  ok "Gradle installed"
}

install_git() {
  local src
  src="$(mktemp -d "${UNPACK}/git.XXXXXX")"
  tar -xf "$1" -C "$src"
  (
    cd "$src"/git-* || exit 1
    make configure >/dev/null 2>&1
    ./configure --prefix="${APPS}/git" >/dev/null 2>&1
    make -j"$(nproc)" >/dev/null 2>&1
    make install >/dev/null 2>&1
  )
  rm -rf "$src"
  [[ -f "${APPS}/git/bin/git" ]] || return 1
  ok "Git $("${APPS}/git/bin/git" --version | awk '{print $3}')"
}

install_python() {
  local src
  warn "building CPython from source, this takes 10-30 minutes"
  src="$(mktemp -d "${UNPACK}/py.XXXXXX")"
  tar -xf "$1" -C "$src"
  (
    cd "$src"/Python-* || exit 1
    ./configure --prefix="${APPS}/python" --enable-optimizations >/dev/null 2>&1
    make -j"$(nproc)" >/dev/null 2>&1
    make install >/dev/null 2>&1
  )
  rm -rf "$src"
  ok "Python $("${APPS}/python/bin/python3" --version)"
}

install_dotnet() {
  expand_flat "$1" "${APPS}/dotnet"     # already flat
  ok ".NET $("${APPS}/dotnet/dotnet" --version)"
}

install_rust() {
  mkdir -p "${ROOT}/data/cargo" "${ROOT}/data/rustup"
  export CARGO_HOME="${ROOT}/data/cargo"
  export RUSTUP_HOME="${ROOT}/data/rustup"
  chmod +x "$1"
  "$1" -y --no-modify-path --default-toolchain stable --profile minimal >/dev/null 2>&1
  local wrap="${APPS}/rust"
  mkdir -p "$wrap"
  for t in cargo rustc rustup; do
    cat > "${wrap}/${t}" <<EOF
#!/usr/bin/env bash
export CARGO_HOME="${ROOT}/data/cargo"
export RUSTUP_HOME="${ROOT}/data/rustup"
export PATH="\${CARGO_HOME}/bin:\${PATH}"
exec "\${CARGO_HOME}/bin/${t}" "\$@"
EOF
    chmod +x "${wrap}/${t}"
  done
  ok "Rust $("${CARGO_HOME}/bin/cargo" --version | awk '{print $2}')"
}

install_android() {
  local sdk="${APPS}/android-sdk" stage
  stage="$(mktemp -d "${UNPACK}/andcmd.XXXXXX")"
  unzip -q "$1" -d "$stage"
  # The SDK manager only runs from a directory literally named 'latest'
  rm -rf "${sdk}/cmdline-tools"
  mkdir -p "${sdk}/cmdline-tools"
  mv "$stage/cmdline-tools" "${sdk}/cmdline-tools/latest"
  rm -rf "$stage"
  ok "Android command-line tools installed"

  if [[ "$NO_ANDROID" -eq 1 ]]; then
    warn "skipping SDK packages (--no-android)"
    return 0
  fi

  export JAVA_HOME="$(jdk_home)"
  export ANDROID_HOME="$sdk"
  export ANDROID_SDK_ROOT="$sdk"
  local sdkm="${sdk}/cmdline-tools/latest/bin/sdkmanager"

  yes | "$sdkm" --sdk_root="$sdk" --licenses >/dev/null 2>&1 || true

  # NOTE: the current cmdline-tools delegate to the new `android` CLI, which
  # takes sdk-style paths with FORWARD SLASHES. The semicolon form fails with
  # "Package not found".
  local p
  for p in platform-tools build-tools/35.0.0 platforms/android-35 \
           build-tools/34.0.0 platforms/android-34; do
    printf '    installing %s ...\n' "$p"
    "$sdkm" --sdk_root="$sdk" "$p" >/dev/null 2>&1 || warn "could not install $p"
  done

  [[ -f "${sdk}/platform-tools/adb" ]] || return 1
  ok "Android SDK ($("${sdk}/platform-tools/adb" version 2>/dev/null | head -1))"
}

# ---------------------------------------------------------------------------
# catalogue + selection
# ---------------------------------------------------------------------------
show_catalogue() {
  local n name label size desc mark i total=0
  printf '\n  OpenCode Portable - tool installer\n'
  printf '  root: %s\n\n' "$ROOT"
  printf '  %-3s %-26s %9s  %s\n' '#' 'Tool' 'Size' ''
  printf '  %s\n' "$(printf '%.0s-' {1..76})"
  i=0
  for n in "${TOOLS[@]}"; do
    IFS='|' read -r name label size desc <<<"$n"
    i=$((i+1))
    mark=""
    is_installed "$name" && mark="installed"
    printf '  %-3s %-26s %6s MB  %s %s\n' "$i" "$label" "$size" "$desc" "$mark"
    total=$((total + size))
  done
  printf '  %s\n' "$(printf '%.0s-' {1..76})"
  printf '  %-30s %6s MB  (full bundle)\n' 'TOTAL' "$total"
  printf '\n'
}

select_tools() {
  local sel=() i=1 n name label size desc cur total answer
  show_catalogue
  printf '  Enter numbers to toggle, separated by spaces or commas.\n'
  printf "  Useful: 'a' = all, 'n' = none, 'q' = quit\n\n"

  while true; do
    printf '  Your selection: '
    # Read a whole line; on EOF this returns non-zero so we stop cleanly
    if ! IFS= read -r answer; then break; fi
    answer="${answer,,}"
    answer="${answer// /}"

    case "$answer" in
      q) exit 0 ;;
      a) for n in "${TOOLS[@]}"; do sel+=("${n%%|*}"); done; break ;;
      n|"") break ;;
      *) ;;
    esac

    for tok in $(printf '%s' "$answer" | tr ',' ' '); do
      [[ "$tok" =~ ^[0-9]+$ ]] || continue
      local idx=$((tok - 1))
      [[ $idx -ge 0 && $idx -lt ${#TOOLS[@]} ]] || { warn "no tool numbered $tok"; continue; }
      local pick="${TOOLS[$idx]%%|*}"
      # toggle
      local found=0 new=()
      for s in "${sel[@]:-}"; do
        if [[ "$s" == "$pick" ]]; then found=1; else new+=("$s"); fi
      done
      [[ $found -eq 0 ]] && new+=("$pick")
      sel=("${new[@]}")
    done

    printf '\n'
    cur=0
    for s in "${sel[@]:-}"; do
      label="$(label_of "$s")"; size="$(size_of "$s")"
      local mark=" " inst=""
      is_installed "$s" && inst=" (already installed)"
      printf '   [%s] %-26s %6s MB%s\n' "$mark" "$label" "$size" "$inst"
      cur=$((cur + size))
    done
    printf '   selected total: %s MB\n\n' "$cur" "$C_STEP"
  done

  printf '%s\n' "${sel[@]:-}" | grep -v '^$' || true
}

space_check() {
  local names=("$@") need=0 free_mb total name
  for name in "${names[@]}"; do need=$((need + $(size_of "$name"))); done
  # downloads stage on the same filesystem, so allow roughly double plus 2 GB
  total=$(( need * 14 / 10 + 2048 ))
  free_mb="$(df -Pm "$ROOT" | awk 'NR==2 {print $4}')"

  printf '\n'
  printf '  Selected : %s tool(s), about %s MB installed\n' "${#names[@]}" "$need"
  printf '  Needs    : about %s MB free (includes download staging)\n' "$total"
  printf '  Free on %s : %s MB\n' "$(df -Pm "$ROOT" | awk 'NR==2 {print $6}')" "$free_mb"
  printf '\n'

  if [[ "$free_mb" -lt "$total" ]]; then
    err "Not enough free space."
    printf '       Need about %s MB, have %s MB.\n' "$total" "$free_mb"
    printf '       Remove some tools from the selection and try again.\n'
    return 1
  fi
  return 0
}

contains() { # contains <needle> <haystack...>
  local n="$1"; shift
  local x
  for x in "$@"; do [[ "$x" == "$n" ]] && return 0; done
  return 1
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
MODE="" ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)        MODE="all" ;;
    --minimal)    MODE="minimal" ;;
    --list|-l)    show_catalogue; exit 0 ;;
    --only)       MODE="only"; ONLY="${2:-}"; shift ;;
    --force|-f)   FORCE=1 ;;
    --no-android) NO_ANDROID=1 ;;
    -h|--help)    sed -n '2,30p' "$0"; exit 0 ;;
    *)            die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

need_cmd curl "Install it with your package manager."
need_cmd tar  "Install it with your package manager."
if [[ "$MODE" != "minimal" ]]; then
  need_cmd unzip "Install it:  sudo apt install unzip"
fi

selected=()
case "$MODE" in
  minimal) selected=(opencode) ;;
  all)     for n in "${TOOLS[@]}"; do selected+=("${n%%|*}"); done ;;
  only)
    IFS=',' read -ra parts <<<"$ONLY"
    for t in "${parts[@]}"; do
      t="${t// /}"
      [[ -z "$t" ]] && continue
      known_tool "$t" || die "unknown tool: $t"
      selected+=("$t")
    done
    ;;
  *) mapfile -t selected < <(select_tools) ;;
esac

# strip empties that mapfile may pick up
clean=(); for s in "${selected[@]:-}"; do [[ -n "$s" ]] && clean+=("$s"); done
selected=("${clean[@]:-}")

if [[ ${#selected[@]} -eq 0 ]]; then
  printf '\n  Nothing selected. Exiting.\n\n'
  exit 0
fi

# OpenCode itself is the point of the bundle
if ! contains opencode "${selected[@]}"; then
  warn "adding OpenCode itself to the selection"
  selected+=(opencode)
fi

# Android needs a JDK to run sdkmanager
if contains android "${selected[@]}" && ! contains jdk "${selected[@]}" && ! is_installed jdk; then
  warn "Android SDK requires the JDK - adding it"
  selected+=(jdk)
fi

space_check "${selected[@]}" || exit 1

# skip already installed
if [[ "$FORCE" -eq 0 ]]; then
  keep=()
  for s in "${selected[@]}"; do
    if is_installed "$s"; then
      warn "$s already installed - skipping (use --force to reinstall)"
    else
      keep+=("$s")
    fi
  done
  selected=("${keep[@]:-}")
fi

if [[ ${#selected[@]} -eq 0 ]]; then
  printf '\n  Nothing to do - everything selected is already installed.\n\n'
  exit 0
fi

step "Resolving download URLs"
urls=()
for s in "${selected[@]}"; do
  if u="$(resolve_url "$s" 2>/dev/null)" && [[ -n "$u" ]]; then
    printf '    %-9s %s\n' "$s" "$u"
    urls+=("$s|$u")
  else
    err "$s : could not resolve a download URL"
  fi
done
[[ ${#urls[@]} -eq 0 ]] && die "nothing could be resolved"

step "Downloading ${#urls[@]} item(s) in parallel"
pids=()
for entry in "${urls[@]}"; do
  s="${entry%%|*}"; u="${entry#*|}"
  (
    curl -fL --connect-timeout 30 --retry 3 -o "${DL}/$(archive_name "$s")" "$u" \
      >"${DL}/${s}.log" 2>&1
  ) &
  pids+=("$!:$s")
done
okmap=()
for pid_entry in "${pids[@]}"; do
  pid="${pid_entry%%:*}"; s="${pid_entry#*:}"
  if wait "$pid"; then ok " $s downloaded"; okmap+=("$s"); else err "$s download failed (see downloads/${s}.log)"; fi
done

step "Installing"
succeeded=(); failed=()
for entry in "${urls[@]}"; do
  s="${entry%%|*}"
  contains "$s" "${okmap[@]:-}" || { failed+=("$s"); continue; }
  a="${DL}/$(archive_name "$s")"
  # Verify after installing too: set -e is inert inside a function called
  # from an if-condition, so an installer can "succeed" while doing nothing.
  if "install_${s}" "$a" && is_installed "$s"; then
    succeeded+=("$s")
  else
    err "$s : install failed (tool did not verify as installed)"
    failed+=("$s")
  fi
done

rm -rf "$UNPACK"

step "Summary"
n_ok=0; n_bad=0; tot=0
# ${arr[@]:-} yields one empty string when the array is empty - skip those
for s in ${succeeded[@]+"${succeeded[@]}"}; do
  [[ -z "$s" ]] && continue
  printf '    installed  %-10s %-26s %6s MB\n' "$s" "$(label_of "$s")" "$(size_of "$s")"
  n_ok=$((n_ok+1)); tot=$((tot + $(size_of "$s")))
done
for s in ${failed[@]+"${failed[@]}"}; do
  [[ -z "$s" ]] && continue
  printf '    FAILED     %-10s %-26s\n' "$s" "$(label_of "$s")"
  n_bad=$((n_bad+1))
done

printf '\n    %s installed, %s failed, about %s MB on disk\n\n' "$n_ok" "$n_bad" "$tot"

if [[ $n_ok -gt 0 ]]; then
  printf '  Next steps:\n'
  printf '    1. Run ./bin/verify.sh to confirm every path is isolated.\n'
  printf '    2. Run ./launch.sh to start OpenCode.\n\n'
  printf '  Note: bin/env.sh builds PATH at launch time, so newly installed\n'
  printf '        tools are picked up automatically - no edit needed.\n\n'
fi

[[ $n_bad -eq 0 ]] || exit 1
exit 0