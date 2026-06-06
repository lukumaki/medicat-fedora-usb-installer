<p align="center">
  <img src="https://img.shields.io/badge/version-7.1-blue.svg">
  <img src="https://img.shields.io/badge/build-Modular--Architecture-brightgreen.svg">
  <img src="https://img.shields.io/badge/license-MIT-green.svg">
  <img src="https://img.shields.io/badge/platform-Fedora%2038%2B-orange.svg">
</p>

# MediCat USB Builder for Fedora  
A fully modular, JSON‑driven, production‑grade Ventoy + MediCat USB builder for Fedora.

Version **7.0** introduces a complete architectural redesign:  
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

### ✔ Modular Architecture (v7.0)
The project is now split into logical modules:

```
main.sh
config.json
lib/
  logging.sh
  config.sh
  mode.sh
  usb.sh
  patches.sh
  ventoy.sh
  medicat_download.sh
  medicat_extract.sh
  medicat_install.sh
  format.sh
  cleanup.sh
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

- Fedora 38+  
- `bash`, `jq`, `curl`, `wget`, `rsync`, `7z`, `ntfs-3g`, `lsblk`  
- Internet connection for Ventoy + MediCat downloads  

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
chmod -R +x lib/
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

### DRY RUN (no changes made)
```bash
./main.sh --dry-run
```

---

# Configuration (config.json)

All paths, URLs, and defaults are stored in `config.json`.  
Example:

```json
{
  "paths": {
    "cache_dir": "$HOME/Medicat_USB_Cache",
    "ventoy_dir": "$HOME/Medicat_USB_Cache/ventoy"
  }
}
```

You can safely modify paths, URLs, or defaults without touching the Bash code.

---

# Architecture Overview

### main.sh  
The orchestrator. Loads modules, parses arguments, runs the workflow.

### lib/config.sh  
Loads JSON configuration using `jq`.

### lib/mode.sh  
Implements the MODE engine and translates modes into action flags.

### lib/usb.sh  
Handles USB device detection and selection.

### lib/patches.sh  
Downloads Fedora‑specific Ventoy patches.

### lib/ventoy.sh  
Downloads, extracts, and installs Ventoy.

### lib/medicat_download.sh  
Downloads MediCat using CDN mirror benchmarking.

### lib/medicat_extract.sh  
Extracts MediCat into cache with idempotent markers.

### lib/medicat_install.sh  
Installs or updates MediCat on the USB drive.

### lib/format.sh  
Formats the Ventoy data partition safely.

### lib/logging.sh  
Unified logging API.

### lib/cleanup.sh  
Unmounts devices on exit.

---

# License
MIT License — see LICENSE file.

---

# Credits
- **Frixos** — architecture, design, testing  
