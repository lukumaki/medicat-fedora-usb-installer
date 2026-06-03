# Changelog  
All notable changes to this project will be documented in this file.  
This project adheres to semantic versioning where possible.

---

## [4.1] — 2026-06-04  
### Professional Clean Build (B3)

#### Added
- Unified logging engine with color‑coded output (`INFO`, `OK`, `WARN`, `ERROR`).
- Unified output functions (`out`, `prompt`, `YesNo`) replacing legacy `colEcho`.
- Fedora‑compatible Ventoy installation logic with auto‑detection of existing Ventoy.
- New CLI flags:
  - `--skip-ventoy` — keeps existing Ventoy installation.
  - `--skip-medicat` — skips MediCat formatting/copying.
  - `--update-only` — incremental update mode using `rsync --update`.
  - `--force-mbr` — force MBR partitioning.
  - `--force-gpt` — force GPT partitioning.
- Smart rsync update mode (copies only new/modified files).
- Progress bars:
  - 7z extraction (`-bsp1`)
  - rsync (`--info=progress2`)
- Automatic cleanup trap (auto‑unmount on exit).
- Improved USB selection flow with safer prompts.
- Complete rewrite of `install_ventoy_and_format()` for clarity and reliability.
- Full README rewrite (international English version).
- Added credits to Ventoy, MediCat USB, and mon5termatt.
- Added Fedora 44 compatibility notes and debugging story.

#### Changed
- Replaced all legacy logging (`log`, `colEcho`) with unified logging system.
- Replaced old Ventoy validation logic with output‑based success detection.
- Reworked MediCat extraction logic with progress and caching.
- Cleaned up directory structure and variable naming.
- Improved error handling and exit conditions.
- Removed duplicated or conflicting code blocks from v4.0.

#### Fixed
- Ventoy installer failing on Fedora due to missing patches.
- Missing dependencies (`ntfs-3g`, `exfatprogs`, `p7zip-plugins`) causing extraction and formatting failures.
- Old rsync logic overwriting entire USB unnecessarily.
- Duplicate `install_ventoy_and_format()` definitions.
- Residual debug blocks from v4.0.
- Inconsistent color output and raw escape sequences.

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

