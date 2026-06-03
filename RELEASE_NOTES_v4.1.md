# MediCat USB Builder for Fedora — Release Notes (v4.1)

## Version 4.1 — Professional Clean Build  
**Release date:** 2026‑06‑04  

This release introduces a fully rewritten, Fedora‑compatible MediCat USB Builder with improved reliability, faster updates, and a professional‑grade logging and workflow system.  
It is the first version designed specifically for **Fedora 44+**, solving long‑standing compatibility issues with the official MediCat installer.

---

## 🚀 Highlights

### ✔ Fully working Fedora 44+ compatibility
Ventoy installation now works reliably on Fedora thanks to integrated Fedora‑specific patches:

- `Ventoy2Disk_fedora.sh`  
- `VentoyWorker_fedora.sh`

These patches resolve glibc/tooling issues that prevented Ventoy from running on Fedora.

---

## 🆕 New Features

### 🔹 Unified Logging Engine
A complete rewrite of the logging system with color‑coded output:

- **[INFO]** → yellow  
- **[OK]** → green  
- **[WARN]/[ERROR]** → red  
- Default output → blue  

All logs include timestamps and are written both to the terminal and to `medicat_usb_builder.log`.

---

### 🔹 New CLI Flags
- `--skip-ventoy` — keep existing Ventoy installation  
- `--skip-medicat` — skip MediCat formatting/copying  
- `--update-only` — incremental update mode (copy only changed files)  
- `--force-mbr` — force MBR partitioning  
- `--force-gpt` — force GPT partitioning  

---

### 🔹 Smart rsync Update Mode
Using `rsync --update`, the script now copies **only new or modified files**, reducing update time from:

**30 minutes → 30 seconds**

---

### 🔹 Progress Bars Everywhere
- 7z extraction now uses `-bsp1` for real‑time progress  
- rsync uses `--info=progress2` for a global progress bar  

---

### 🔹 Automatic Cleanup
A cleanup trap ensures the USB is always unmounted safely, even if the script exits unexpectedly.

---

## 🔧 Improvements

- Rewritten Ventoy installation logic with proper success detection  
- Safer USB selection and confirmation prompts  
- Cleaner directory structure and variable naming  
- More robust error handling  
- Removal of legacy code (`colEcho`, old logging, duplicate functions)  
- Faster MediCat extraction with SSD caching  
- Better compatibility with BIOS and UEFI systems  

---

## 🐛 Bug Fixes

- Fixed Ventoy installer failing on Fedora due to missing patches  
- Fixed missing dependencies (`ntfs-3g`, `exfatprogs`, `p7zip-plugins`)  
- Fixed extraction failures caused by incomplete 7z support  
- Fixed full‑overwrite rsync behavior  
- Removed duplicated `install_ventoy_and_format()` definitions  
- Removed leftover debug blocks from v4.0  

---

## 📦 Notes for Users

- This version is **recommended for all Fedora users**  
- Existing MediCat USB drives can be updated using:  
  ```
  ./medicat_usb_builder.sh --update-only
  ```
- First‑time installation still requires a full Ventoy setup  

---

## 🙌 Credits

- **Ventoy Project:** https://www.ventoy.net/  
- **MediCat USB:** https://medicatusb.com/  
- **mon5termatt (MediCat Installer):** https://github.com/mon5termatt/medicat_installer  
- **Frixos (Project Author):** Fedora 44 debugging, Ventoy patch integration, full script rewrite  

---

## 📜 License

This release is distributed under the MIT License.

