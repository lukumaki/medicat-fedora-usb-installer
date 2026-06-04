<p align="center">

  <!-- Version -->
  <img src="https://img.shields.io/badge/version-4.1-blue.svg" alt="Version">

  <!-- License -->
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">

  <!-- Fedora -->
  <img src="https://img.shields.io/badge/Fedora-40--44-blue?logo=fedora&logoColor=white" alt="Fedora Compatibility">

  <!-- Ventoy -->
  <img src="https://img.shields.io/badge/Ventoy-Compatible-success?logo=linux&logoColor=white" alt="Ventoy Compatible">

  <!-- Shell -->
  <img src="https://img.shields.io/badge/shell-bash-121011.svg?logo=gnu-bash&logoColor=white" alt="Shell Script">

  <!-- GitHub Stars -->
  <img src="https://img.shields.io/github/stars/lukumaki/medicat-fedora-usb-installer?style=social" alt="GitHub Stars">

  <!-- GitHub Issues -->
  <img src="https://img.shields.io/github/issues/lukumaki/medicat-fedora-usb-installer" alt="GitHub Issues">

  <!-- Last Commit -->
  <img src="https://img.shields.io/github/last-commit/lukumaki/medicat-fedora-usb-installer" alt="Last Commit">

</p>

# MediCat USB Builder for Fedora  
### Ventoy‑based USB creation with smart caching, update‑only mode & Fedora‑compatible patches  
**Version 4.1 — Professional Clean Build**

---

## 📌 Overview

**MediCat USB Builder for Fedora** is a fully automated tool that creates a **Ventoy‑based MediCat USB** on Fedora Linux (and derivatives).  
It supports:

- Full installation (Ventoy + format + full copy)  
- Skip‑Ventoy mode  
- Update‑only mode (copy only new/modified files)  
- Smart SSD cache for MediCat  
- Progress bars (7z extraction + rsync)  
- Automatic cleanup (unmount on exit)  
- Fedora‑patched Ventoy installer  

This project was created because the official *Medicat_Installer.sh* does not work reliably on **Fedora 44+**, despite notes on GitHub suggesting Fedora compatibility.

---

## 🧩 Why this project exists

As a Fedora 44 user, I discovered that the official MediCat installer:

👉 https://github.com/mon5termatt/medicat_installer  

…although updated with Fedora notes, **did not work on Fedora 40–44**.

## 🧠 Summary of the Fedora issue

- Ventoy requires `mkexfatfs`
- Fedora removed it
- Ventoy fails its internal checks
- The official MediCat installer cannot proceed
- The Fedora Patch Layer restores compatibility
- Ventoy installs correctly again
- MediCat USB creation works flawlessly on Fedora 40–44
- 
### ❌ Fedora removed the `mkexfatfs` binary required by Ventoy  
Ventoy depends on `mkexfatfs` for formatting and validation.  
Fedora 40–44 removed this binary and replaced it with:

```
mkfs.exfat
```

This caused Ventoy to fail with:

```
mkexfatfs: command not found
Some tools can not run on current system.
```

Because of this, Ventoy’s internal checks failed, and the installer aborted.

This project solves that.

---

## 🧠 How I solved it (reasoning & process)

To fix this, the project includes a **🛠 Fedora Patch Layer for Ventoy**:

- `Ventoy2Disk_fedora.sh`
- `VentoyWorker_fedora.sh`

These wrappers:

### ✔ Create a safe symlink  
```
mkexfatfs → mkfs.exfat
```

### ✔ Fix Ventoy tool detection  
Ventoy now believes the required tools exist and proceeds normally.

### ✔ Fix partition wait timing  
Fedora’s udev timing differs from Debian/Ubuntu, causing Ventoy to wait incorrectly.

### ✔ Run the official Ventoy scripts in a Fedora‑compatible environment  
The wrappers do **not** modify Ventoy itself — they simply adapt the environment.

### ✔ Work with all future Ventoy versions  
Because the symlink and wrapper logic are version‑agnostic.

---

### 4. Creating a unified logging system  
With consistent color‑coded output:

- **[INFO]** → yellow  
- **[OK]** → green  
- **[WARN]/[ERROR]** → red  
- Default output → blue  

### 5. Implementing a smart cache system  
The MediCat archive (28GB) is stored in:

```
~/Medicat_USB_Cache
```

Extraction happens **only once**, dramatically speeding up future updates.

### 6. Adding update‑only mode  
Using:

```
rsync --update
```

Only new or modified files are copied.  
This reduces update time from **30 minutes → 30 seconds**.

### 7. Adding cleanup trap  
Automatic unmount on exit ensures no corrupted USB states.

---

## 🧑‍💻 Credits (updated)

### 🔹 Fedora Patch Layer  
Created to restore Ventoy compatibility on Fedora 40–44 by:

- Replacing missing `mkexfatfs` with a symlink to `mkfs.exfat`
- Fixing Ventoy worker timing
- Ensuring the official Ventoy scripts run without modification

### 🔹 Ventoy Project  
https://www.ventoy.net/  
https://github.com/ventoy/Ventoy  

### 🔹 MediCat USB  
https://medicatusb.com/

### 🔹 mon5termatt (MediCat Installer)  
https://github.com/mon5termatt/medicat_installer  
Provided the mirror selection logic and cdn.bat parsing.

### 🔹 lukumaki (Project Author)  
Identified the Fedora 44 incompatibility, implemented the patch layer,  
and built the first fully working **Fedora‑compatible MediCat USB Builder**.

---

## ⚙️ Installation & Usage

### Full installation (Ventoy + format + full copy)
```
./medicat_usb_builder.sh
```

### Skip Ventoy (keep existing Ventoy, rewrite MediCat)
```
./medicat_usb_builder.sh --skip-ventoy
```

### Update‑only (copy only new/modified files)
```
./medicat_usb_builder.sh --update-only
```

### Force MBR
```
./medicat_usb_builder.sh --force-mbr
```

### Force GPT
```
./medicat_usb_builder.sh --force-gpt
```

---

## 📂 Directory Structure

```
medicat_usb_builder.sh
patch/
  Ventoy2Disk_fedora.sh
  VentoyWorker_fedora.sh
ventoy/
Medicat_USB_Cache/
  *.7z
  extracted/
```

---

## 🛠 Dependencies (Fedora)

The script automatically installs:

- wget  
- curl  
- unzip  
- rsync  
- exfatprogs  
- ntfs‑3g  
- p7zip  
- p7zip‑plugins  
- bc  

---

## 🧪 Tested On

- Fedora 44 KDE  
- BIOS boot  
- UEFI boot  
- USB 3.0 sticks  
- SSD‑based USB enclosures  

---

## 🟢 Status

**Stable**  
Ready for daily use and incremental updates.

---

## 📜 License

MIT License.
