# Changelog  
All notable changes to this project will be documented in this file.  
This project adheres to semantic versioning where possible.

---

## [4.1] — 2026-06-04  
### Professional Clean Build (B3)

#### Added
- Fedora Patch Layer for Ventoy:
  - Fedora 40–44 removed the `mkexfatfs` binary required by Ventoy.
  - Added compatibility wrappers (`Ventoy2Disk_fedora.sh`, `VentoyWorker_fedora.sh`).
  - Added safe symlink (`mkexfatfs → mkfs.exfat`).
  - Fixed Ventoy tool detection and partition wait timing.
  - Ensures Ventoy installs correctly on all Fedora versions.
- Unified logging engine with color‑coded output.
- Unified output functions (`out`, `prompt`, `YesNo`).
- New CLI flags:
  - `--skip-ventoy`, `--skip-medicat`, `--update-only`, `--force-mbr`, `--force-gpt`.
- Smart rsync update mode (`rsync --update`).
- Progress bars for 7z extraction and rsync.
- Automatic cleanup trap (auto‑unmount on exit).
- Improved USB selection flow.

#### Changed
- Reworked Ventoy installation logic to use Fedora patch layer.
- Replaced legacy logging and color functions.
- Improved MediCat extraction and caching.
- Cleaned up directory structure and variable naming.

#### Fixed
- Ventoy failing on Fedora due to missing `mkexfatfs`.
- Missing dependencies (`ntfs-3g`, `exfatprogs`, `p7zip-plugins`) causing extraction/formatting issues.
- Old rsync logic overwriting entire USB unnecessarily.
- Duplicate function definitions and leftover debug code.

---

## [4.0] — 2026-06-03  
### First fully working Fedora build

#### Added
- Working Ventoy installation on Fedora using patched scripts.
- Full MediCat download via cdn.bat mirror selection.
- Smart SSD cache for MediCat archive and extraction.
- Full USB creation workflow (Ventoy + NTFS + rsync).
- BIOS and UEFI boot compatibility confirmed.

#### Fixed
- Fedora 44 incompatibility with official MediCat installer.
- Missing filesystem tools causing script failure.
- Ventoy worker script execution errors.

---

## [3.x] — Pre‑Fedora builds  
Legacy versions prior to Fedora compatibility.  
Not maintained.

---

## [2.x] — Early MediCat USB automation  
Initial automation attempts before Ventoy integration.

---

## [1.x] — Initial experiments  
Manual scripts, not publicly released.

