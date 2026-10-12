# OpenCode Portable Linux

Complete portable development environment for Linux. Run from USB without installation.

![Version](https://img.shields.io/badge/version-1.0-blue)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![Size](https://img.shields.io/badge/portable%20size-~6.8%20GB-orange)

> ### Also available for Windows
> This is the **Linux** edition. For the Windows version, with the same
> toolchain and the same portable design, see:
> **[opencode_portable](https://github.com/palashsuryavanshi/opencode_portable)**

## What's Included

| Tool | Version | Purpose |
|------|---------|---------|
| **OpenCode GUI + CLI** | v2.x | AI coding assistant with session persistence |
| **VS Code Portable** | Latest stable | Full editor, settings/extensions on stick |
| **Temurin JDK** | 21 LTS | Java development |
| **Android SDK** | cmdline-tools latest | Android builds (adb, aapt2, apksigner, Gradle) |
| **Git** | Latest | Version control |
| **Node.js** | Latest LTS | JavaScript/TypeScript |
| **Go** | Latest | Go development |
| **Maven** | Latest | Java builds |
| **Gradle** | Latest | Build automation |
| **Python** | Latest | Python development |
| **.NET SDK** | 9.x LTS | C#/F# development |
| **Rust** | Latest stable (via rustup) | Rust development |

## Quick Start

1. **Clone** this repository to your USB drive:
   ```bash
   git clone https://github.com/palashsuryavanshi/opencode-portable-linux.git /media/usb/opencode-portable
   cd /media/usb/opencode-portable
   ```

2. **Run the launcher**:
   ```bash
   ./launch.sh
   ```

3. **Choose an option:**
   - **1** — OpenCode GUI (sign in on first run)
   - **2** — VS Code
   - **3** — Developer Shell (all tools on PATH)
   - **4** — OpenCode CLI (TUI)
   - **5** — Android SDK Manager
   - **6** — Session backup/restore/import
   - **7** — Verify portable setup
   - **8** — Update OpenCode

## First Run — Install Tools

The repository contains launchers and build scripts. Tools are downloaded and built on first use:

```bash
# From the portable root directory:
./build/fetch-tools.sh      # Download tool sources (~2 GB)
./build/install-tools.sh    # Build and install to apps/ (takes 10-30 min)
./build/setup-android.sh    # Install Android SDK packages
```

This downloads ~2 GB and builds/installs to `apps/`. Only needed once per USB.

## Features

- **100% portable** — all data stays on USB (sessions, config, caches, tool caches)
- **No root required** — runs on any Linux distribution (glibc 2.28+)
- **Session persistence** — chat history follows the stick
- **Auto-updater** — option 8 downloads latest OpenCode from opencode.ai
- **Session backup/restore** — option 6 manages session snapshots
- **Path verification** — option 7 confirms isolation from host

## Updating OpenCode

From `launch.sh` choose **8**, or run directly:
```bash
./bin/update-opencode.sh
```
Flags: `--force` (reinstall same version)

## Session Management

From `launch.sh` choose **6**:
- **backup** — snapshot sessions to `data/backups/`
- **restore** — load latest snapshot
- **import** — pull sessions from host PC's OpenCode install (`~/.local/share/opencode`)
- **list** — show available backups

## Verification

From `launch.sh` choose **7** — confirms:
- All XDG paths point to USB
- Session database present
- All toolchains on PATH

## Directory Structure

```
opencode-portable-linux/
├── launch.sh               # Main menu
├── bin/                    # All launchers
│   ├── opencode.sh         # OpenCode GUI
│   ├── vscode.sh           # VS Code
│   ├── shell.sh            # Dev shell (bash)
│   ├── opencode-cli.sh     # OpenCode TUI
│   ├── android.sh          # Android SDK manager
│   ├── sync.sh             # Session backup/restore
│   ├── update-opencode.sh  # Updater
│   ├── verify.sh           # Path verification
│   └── env.sh              # Environment setup (sourced by all)
├── apps/                   # Tools (populated by build scripts)
├── data/                   # All persistent data
│   ├── opencode-data/      # Sessions (SQLite DB)
│   ├── opencode-config/    # Config, auth, service.json
│   ├── opencode-cache/     # Logs, caches
│   ├── opencode-state/     # State files
│   ├── home/               # Redirected HOME
│   ├── cargo/ rustup/      # Rust toolchains
│   ├── gopath/ gocache/    # Go caches
│   ├── gradle/             # Gradle cache
│   ├── npm-cache/ pip-cache/ # Package caches
│   ├── vscode-user/        # VS Code settings/extensions
│   └── backups/            # Session snapshots
├── projects/               # Your code goes here
├── build/                  # Build scripts
│   ├── fetch-tools.sh      # Download tool sources
│   ├── install-tools.sh    # Build and install to apps/
│   └── setup-android.sh    # Install Android SDK packages
├── downloads/              # Downloaded installers (gitignored)
└── README.md               # This file
```

## How It Works

All launchers source `bin/env.sh` which sets:
- `XDG_DATA_HOME` → `data/opencode-data`
- `XDG_CONFIG_HOME` → `data/opencode-config`
- `XDG_CACHE_HOME` → `data/opencode-cache`
- `XDG_STATE_HOME` → `data/opencode-state`
- `HOME` → `data/home/`
- `TEMP` / `TMP` → `data/tmp/`
- Tool caches → `data/<tool>-cache/`

This ensures **nothing writes to the host machine**.

## Requirements

- Linux (glibc 2.28+, x86_64)
- ~8 GB free space on USB for full toolchain
- Internet connection for initial tool downloads
- Build dependencies for first run: `build-essential`, `libssl-dev`, `zlib1g-dev`, `libncurses5-dev`, `libsqlite3-dev`, `libreadline-dev`, `libffi-dev`, `wget`, `curl`, `unzip`, `jq`, `dpkg-dev` (for .deb extraction)

## Installing Build Dependencies

**Debian/Ubuntu:**
```bash
sudo apt update && sudo apt install -y build-essential libssl-dev zlib1g-dev libncurses5-dev libsqlite3-dev libreadline-dev libffi-dev wget curl unzip jq dpkg-dev
```

**Fedora/RHEL:**
```bash
sudo dnf install -y gcc gcc-c++ make openssl-devel zlib-devel ncurses-devel sqlite-devel readline-devel libffi-devel wget curl unzip jq rpmdevtools
```

**Arch:**
```bash
sudo pacman -S --needed base-devel openssl zlib ncurses sqlite readline libffi wget curl unzip jq
```

## Platforms

| Edition | Repository | Launcher |
|---|---|---|
| **Linux (x64)** | [`opencode-portable-linux`](https://github.com/palashsuryavanshi/opencode-portable-linux) — *this repo* | `./launch.sh` |
| **Windows 10/11 (x64)** | [`opencode_portable`](https://github.com/palashsuryavanshi/opencode_portable) | `Launch.cmd` |

Both editions ship the same toolchains, the same session layout, and the same
`data/`-on-the-stick isolation model. Session databases are not shared between
platforms, but the launchers and directory structure are identical, so moving
a workflow between the two is straightforward.

## License

Tools subject to their respective licenses. This packaging is MIT.