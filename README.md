### MediCat USB Builder for Fedora
A fully automated, Fedora‑compatible Ventoy + MediCat USB installer with a clean patch‑layer architecture, improved logging, robust error handling, and automatic patch updates.

This project provides a reliable, repeatable, and fully automated workflow for creating a MediCat USB on Fedora systems, solving the long‑standing compatibility issues caused by Fedora’s removal of the mkexfatfs binary required by Ventoy.

## ✨ Key Features

### ✔ Fedora Ventoy Patch Layer:

Fedora removed mkexfatfs, breaking Ventoy’s installation scripts.
This project includes a patch‑layer that:

Creates a safe fallback (mkexfatfs → mkfs.exfat)

Fixes Ventoy tool PATH resolution

Adds udev wait‑time improvements for Fedora

Wraps Ventoy’s official scripts without modifying them

The patch scripts auto‑update from the GitHub repo when missing or outdated.

### ✔ Automatic Ventoy Download & Extraction
The builder:

Fetches the latest Ventoy release from GitHub

Downloads the correct Linux tarball

Extracts it cleanly

Renames the extracted folder to ventoy/ (stable path)

Ensures compatibility with the patch‑layer wrappers

This guarantees that Ventoy is always up‑to‑date and always in the correct structure.

### ✔ Improved Logging
The script provides clear, color‑coded, human‑readable output:

[INFO] for normal operations

[OK] for successful checks

[ERROR] for fatal issues

[WARNING] for destructive operations

This makes debugging and user experience significantly better.

### ✔ Improved Error Handling
The builder uses:

set -e for immediate failure on errors

explicit checks for missing binaries

safe fallback logic

validation of USB device paths

validation of MediCat archive presence

safe mount/umount operations

If something goes wrong, the script stops cleanly and tells the user exactly why.

### ✔ Automatic Patch Script Updates
The builder checks the GitHub repo for:

Ventoy2Disk_fedora.sh

VentoyWorker_fedora.sh

If they are missing or outdated, they are automatically downloaded and replaced.

This ensures the Fedora patch‑layer is always current.

### ✔ Clean Code Formatting
The script is structured into clear sections:

Dependency installation

Patch‑layer update

Ventoy download + extraction

USB device selection

Ventoy installation

MediCat extraction

Cleanup

Indentation, spacing, and function layout follow a consistent style for readability and maintainability.

## 📜 License
MIT License
This project includes wrapper scripts for Ventoy, which is GPLv3.

---
### ✔ Version Header
The script includes a clean header:
MediCat USB Builder for Fedora (with Ventoy Fedora Patch Layer)
No version inflation — just a clear identifier for the initial stable release.

