<p align="center">
  <img src="https://img.shields.io/badge/version-7.2-blue.svg">
  <img src="https://img.shields.io/badge/build-Modular--Architecture-brightgreen.svg">
  <img src="https://img.shields.io/badge/license-MIT-green.svg">
  <img src="https://img.shields.io/badge/platform-Fedora%2040%2B-orange.svg">
</p>

# MediCat USB Builder for Fedora  
A fully modular, JSON‑driven, production‑grade Ventoy + MediCat USB builder for Fedora.

Version **7.x** introduces a complete architectural redesign:  
- Modular Bash codebase  
- JSON configuration  
- Clean MODE engine  
- Fully isolated Ventoy/MediCat subsystems  
- Predictable, testable, maintainable structure  

---

## 📋 Why This Project Exists

The official MediCat installer doesn't work on Fedora 40–44 because **Fedora removed the `mkexfatfs` binary** that Ventoy requires.

### The Problem

| Issue | Result |
|-------|--------|
| Ventoy needs `mkexfatfs` | ❌ Removed in Fedora 40+ |
| Fedora uses `mkfs.exfat` | ❌ Ventoy doesn't recognize it |
| Tool check fails | ❌ Installer aborts |

### The Solution

This project includes a **Fedora Patch Layer** that creates a safe symlink and fixes environment timing:

```bash
mkexfatfs → mkfs.exfat  # Safe symlink
# Ventoy now works perfectly on Fedora!
```

---

# Features

### ✔ Modular Architecture
The project is now split into logical modules:

```
main.sh
config.json
lib/
  logging.sh
  config.sh
  mode.sh
  deps.sh
  usb.sh
  patches.sh
  ventoy.sh
  medicat_download.sh
  medicat_extract.sh
  medicat_install.sh
  format.sh
  cleanup.sh
patch/
  Ventoy2Disk_fedora.sh
  VentoyWorker_fedora.sh
```

Each module is responsible for a single subsystem.

### ✔ JSON‑Driven Configuration
All paths, URLs, defaults, and metadata are stored in `config.json`.  
The Bash modules load configuration dynamically using `jq`.

### ✔ Clean MODE Engine
The installer supports four modes:

- **install** → Ventoy + Format + MediCat  
- **update** → MediCat update only  
- **ventoy** → Ventoy only  
- **skip** → No USB operations  

### ✔ Ventoy Integration
- Auto‑detect latest version from SourceForge  
- Download + extract + cache  
- Fedora‑patched Ventoy installer  
- GPT/MBR selection  
- DRY RUN support  

### ✔ MediCat Integration
- Automatic CDN discovery via `cdn.bat`  
- Mirror speed benchmarking  
- Fastest‑mirror selection  
- 7z extraction with progress  
- Idempotent extraction (`.extracted.ok`)  
- rsync‑based install/update  

### ✔ Safe USB Handling
- Device selection with confirmation  
- Ventoy partition awareness  
- Safe formatting with explicit confirmation  
- DRY RUN support for all destructive operations  

---

# Requirements

- Fedora 40+ (earlier releases that still ship `mkexfatfs` work too)  
- A removable USB drive of at least 32 GB — **all data on it will be erased**  
- `sudo` privileges  
- Internet connection for the Ventoy + MediCat downloads  

Install everything the builder needs:

```bash
sudo dnf install jq rsync curl wget p7zip p7zip-plugins bc \
                 ntfs-3g ntfsprogs exfatprogs util-linux
```

The installer verifies these on startup and only requires the packages the
selected mode actually uses.

---

# Installation

Clone the repository:

```bash
git clone https://github.com/lukumaki/medicat-fedora-usb-installer
cd medicat-fedora-usb-installer
```

Make scripts executable:

```bash
chmod +x main.sh
chmod +x lib/*.sh patch/*.sh
```

---

# Usage

### Full installation (Ventoy + Format + MediCat)
```bash
./main.sh
```

### Update MediCat only
```bash
./main.sh --update-only
```

### Ventoy only (skip MediCat)
```bash
./main.sh --skip-medicat
```

### Force GPT or MBR
```bash
./main.sh --force-gpt
./main.sh --force-mbr
```

### Force a full re-copy of every MediCat file
```bash
./main.sh --force-update
```

### DRY RUN (no changes made)
```bash
./main.sh --dry-run
```

### Verbose output (show DEBUG lines on screen)
```bash
./main.sh --verbose
```

### All options
```bash
./main.sh --help
```

Everything is also written to `~/Medicat_USB_Cache/medicat_usb_builder.log`,
including a diagnostics dump whenever a step fails.

----

## 📦 Notes for Users

- This version is **recommended for all Fedora users**  
- Existing MediCat USB drives can be updated using:  
  ```bash
  ./main.sh --update-only
  ```
  Update-only expects you to mount the MediCat partition yourself first; the
  installer prints the exact `mount` command if it is not mounted.
- First‑time installation still requires a full Ventoy setup  
- Downloads are cached in `~/Medicat_USB_Cache`, so a repeated run does not
  re-download the ~20 GB archive  

---

## 🙌 Credits

- **Ventoy Project:** https://www.ventoy.net/  
- **MediCat USB:** https://medicatusb.com/  
- **mon5termatt (MediCat Installer):** https://github.com/mon5termatt/medicat_installer  
- **Frixos (Project Author):** Fedora 44 debugging, Ventoy patch integration, full script rewrite

---

# License
MIT License — see LICENSE file
