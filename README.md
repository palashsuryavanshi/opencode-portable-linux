# OpenCode Portable — Linux

A complete development environment that runs from a USB stick. Nothing is
installed, no root is needed, and all of your data — chat sessions, settings,
caches — stays on the drive.

> **Windows user?** See [opencode_portable](https://github.com/palashsuryavanshi/opencode_portable) — same tools, same layout, same launcher design.

![Release](https://img.shields.io/badge/release-v1.1-blue)
![Platform](https://img.shields.io/badge/platform-Linux%20x64-lightgrey)
![Tools](https://img.shields.io/badge/tools-optional-installer-orange)

---

## Quick start

**1. Get the portable folder** onto your USB drive:

```bash
git clone https://github.com/palashsuryavanshi/opencode-portable-linux.git /media/usb/opencode-portable
cd /media/usb/opencode-portable
```

> The repository is the **scaffold** — launchers, scripts and an empty directory
> structure. The toolchains themselves are ~5 GB and are downloaded by the
> installer in step 2, so that nobody has to take 5 GB they do not need.

**2. Install the tools you want:**

```bash
chmod +x build/install-selected-tools.sh
./build/install-selected-tools.sh
```

Pick what you need from the list. OpenCode on its own is about 740 MB.

**3. Launch:**

```bash
./launch.sh
```

---

## The tool catalogue

| Tool | Size | Purpose |
|---|---:|---|
| **OpenCode GUI + CLI** | 740 MB | AI coding assistant, with chat history that follows the stick |
| **VS Code (portable)** | 400 MB | Full editor; settings and extensions live on the drive |
| **Temurin JDK 21 LTS** | 330 MB | Java, and required by Android and Gradle |
| **Android SDK** | 655 MB | `adb`, `aapt2`, `d8`, `apksigner`, build-tools 34/35, platforms 34/35 |
| **Node.js** | 200 MB | JavaScript / TypeScript |
| **Go** | 240 MB | Go toolchain |
| **Python** | 250 MB | ⚠️ compiled from source, 10–30 min |
| **.NET SDK** | 770 MB | C# and F# |
| **Rust** | 760 MB | `cargo` / `rustc` via `rustup` |
| **Git** | 70 MB | ⚠️ compiled from source, 5–15 min |
| **Maven** | 12 MB | Java build tool |
| **Gradle** | 150 MB | Java / Kotlin build automation |
| | **4577 MB** | full bundle |

Versions are resolved to the **current stable release** at install time, so you
are never pinned to an old build. Re-running the installer refreshes a tool.

### About Git and Python

There is no official portable Linux build for either, so both are compiled from
source and are marked with ⚠️ in the list. That is the main reason they are
optional. If you only need version control, the Git that ships with your distro is
usually good enough — skip it and use the system one.

### Installing

```bash
./build/install-selected-tools.sh                      # interactive toggle list
./build/install-selected-tools.sh --minimal             # OpenCode only  (~740 MB)
./build/install-selected-tools.sh --only jdk,node,go   # exactly these
./build/install-selected-tools.sh --all                 # everything
./build/install-selected-tools.sh --list                # show the catalogue, install nothing
./build/install-selected-tools.sh --only jdk --force    # reinstall even if present
./build/install-selected-tools.sh --only android --no-android   # cmdline-tools only
```

The installer lists every tool with its size, shows a running total, checks free
space with `df` before downloading, fetches your selection in parallel, and
**verifies each tool after installing**. Anything already installed is skipped.

Some useful combinations:

| Goal | Selection | Size |
|---|---|---:|
| Just OpenCode | `--minimal` | 740 MB |
| OpenCode + web dev | `--only vscode,node` | 1340 MB |
| Android development | `--only android,jdk,node,vscode` | 2325 MB |
| Full stack | `--all` | 4577 MB |

OpenCode itself is always included. Choosing Android automatically adds the JDK,
because the Android SDK manager will not run without it.

### Build dependencies

Only needed for the **first run**, and only for the tools you actually choose:

```bash
# Debian / Ubuntu
sudo apt install -y build-essential libssl-dev zlib1g-dev libncurses5-dev \
                    libsqlite3-dev libreadline-dev libffi-dev \
                    curl wget unzip jq dpkg-dev

# Fedora / RHEL
sudo dnf install -y gcc gcc-c++ make openssl-devel zlib-devel ncurses-devel \
                    sqlite-devel readline-devel libffi-devel \
                    curl wget unzip jq rpmdevtools

# Arch
sudo pacman -S --needed base-devel openssl zlib ncurses sqlite readline \
                     libffi curl wget unzip jq
```

`dpkg-dev` (or `rpmdevtools`) is needed to unpack the OpenCode `.deb` / `.rpm`.
The build tools are only needed if you choose to compile Git or Python.

---

## The launcher menu

Run **`./launch.sh`**.

| Key | Action |
|---|---|
| **1** | OpenCode GUI — main app, your sessions included |
| **2** | VS Code |
| **3** | Developer Shell — bash with every toolchain on `PATH` |
| **4** | OpenCode CLI (TUI) — same sessions as the GUI |
| **5** | Android SDK Manager |
| **6** | Sessions — backup / restore / list / import |
| **7** | Verify portable setup |
| **8** | Update OpenCode |
| **0** | Exit |

---

## How the portability works

Every launcher sources `bin/env.sh` first, which exports each variable pointing
at the drive. Nothing is written to your home directory:

| Variable | Redirected to |
|---|---|
| `XDG_DATA_HOME` | `data/opencode-data/` — sessions (SQLite database) |
| `XDG_CONFIG_HOME` | `data/opencode-config/` — settings, providers, auth |
| `XDG_CACHE_HOME` | `data/opencode-cache/` |
| `XDG_STATE_HOME` | `data/opencode-state/` |
| `HOME` | `data/home/` |
| `TEMP`, `TMP` | `data/tmp/` |
| `NPM_CONFIG_CACHE`, `PIP_CACHE_DIR`, `GRADLE_USER_HOME`, `GOPATH`, `GOCACHE`, `CARGO_HOME`, `RUSTUP_HOME` | `data/…` |

Because `PATH` is rebuilt at every launch, tools you install later are picked up
automatically — there is nothing to edit.

> **Use the launchers, not the binaries.** Running `apps/opencode/opencode`
> directly skips `env.sh`, so OpenCode falls back to your real `$HOME` and
> creates an empty second set of sessions. Always go through `launch.sh`.

---

## Sessions

Your chat history is a SQLite database in `data/opencode-data/opencode/`. It
travels with the drive.

`launch.sh` → **6** gives you:

- **backup** — snapshot the current sessions into `data/backups/`
- **restore** — load the newest snapshot back
- **list** — show available snapshots
- **import** — pull sessions from a host PC's own OpenCode installation
  (`~/.local/share/opencode`)

Close OpenCode before backing up or restoring. The database runs in WAL mode, and
copying it while OpenCode is writing can produce a torn copy.

---

## Updating

```bash
./bin/update-opencode.sh        # or launch.sh -> 8
```

Downloads the latest stable OpenCode from
[opencode.ai](https://opencode.ai/download/stable/linux-x64-deb) — or the `.rpm`
on RPM-based distros — backs up the current copy into `data/backups/`, and leaves
all user data untouched.

Other tools update by re-running the installer with `--force`.

---

## Directory layout

```
opencode-portable-linux/
├── launch.sh                   main menu
├── bin/                        launchers
│   ├── opencode.sh             OpenCode GUI
│   ├── vscode.sh               VS Code
│   ├── shell.sh                developer shell
│   ├── opencode-cli.sh         OpenCode TUI
│   ├── android.sh              Android SDK manager
│   ├── sync.sh                 session backup / restore
│   ├── update-opencode.sh      OpenCode updater
│   ├── verify.sh               path isolation check
│   └── env.sh                  points every path at the stick
├── build/                      installers
│   ├── install-selected-tools.sh   pick toolchains   <- start here
│   ├── fetch-tools.sh             download everything
│   ├── install-tools.sh           build everything
│   └── setup-android.sh           Android SDK packages
├── apps/                       installed toolchains
├── data/                       everything persistent
│   ├── opencode-data/          chat sessions
│   ├── opencode-config/        settings, providers, auth
│   ├── home/                   redirected home directory
│   └── backups/                session snapshots
├── projects/                   put your code here
└── downloads/                  installer cache (safe to delete)
```

---

## Troubleshooting

**`Permission denied` running a script**
```bash
chmod +x launch.sh build/*.sh bin/*.sh
```

**A tool is missing from the Developer Shell**
Run `./bin/verify.sh` to see which `PATH` entries resolved, then re-run the
installer for that tool.

**`need dpkg-deb (Debian/Ubuntu) or rpm2cpio+cpio (Fedora/RHEL)`**
Install `dpkg-dev` or `rpmdevtools`. This is only needed to unpack the OpenCode
package.

**Android SDK manager appears to hang**
It blocks waiting on stdin when it inherits a console. The launcher already
handles this; if you call `sdkmanager` yourself, redirect stdin from `/dev/null`.

**Git or Python takes forever**
They are being compiled from source. Git takes a few minutes, CPython up to half
an hour. Skip them and use your distro's packages if you do not need them pinned
to the stick.

**`Not enough free space`**
The installer refuses to start rather than filling your drive. Drop a tool from
the selection, or use a larger stick.

**Verify anything at any time:** `./launch.sh` → **7**

---

## Requirements

- Linux x86_64, glibc 2.28 or newer, bash 4+
- A USB drive — budget 1 GB for OpenCode alone, 5 GB for everything
- Internet access on first run, for downloads

Unlike the Windows edition, there is no bundled 7-Zip here: the Linux scripts use
	ar and unzip, which every distribution already provides.

---

## Platforms

| Edition | Repository | Launcher |
|---|---|---|
| **Linux (x64)** | [`opencode-portable-linux`](https://github.com/palashsuryavanshi/opencode-portable-linux) — *this repo* | `./launch.sh` |
| **Windows 10/11 (x64)** | [`opencode_portable`](https://github.com/palashsuryavanshi/opencode_portable) | `Launch.cmd` |

Same toolchains, same session layout, same `data/` isolation model. Session
databases are platform-specific, but the launchers and directory structure are
identical, so moving a workflow between the two is straightforward.

---

## License

This packaging is MIT. Each bundled tool remains under its own licence — see
`apps/<tool>/` after installing.