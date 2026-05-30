# Medicat Fedora USB Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Fedora](https://img.shields.io/badge/Fedora-38%2B-blue?logo=fedora)
![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![Ventoy](https://img.shields.io/badge/Ventoy-Automated-orange)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

A fully automated **Ventoy + MediCat USB** installer for **Fedora Linux**, using a clean **TUI interface**, with:

- automatic Ventoy updates  
- automatic MediCat detection  
- MBR/GPT selection  
- NTFS partition creation  
- extraction directly to USB  
- logging  
- MIT license  

This project is designed for Fedora users who want a **reliable, repeatable, GUI‑free** way to create a Medicat USB.

---

## 📥 Quick Installer (Recommended)

Run the installer **without downloading or cloning the repository**:

```bash
bash <(curl -s https://raw.githubusercontent.com/lukumaki/medicat-fedora-usb-installer/main/medicat_usb_builder.sh)
```

This will:

- download the latest version of the installer  
- run it directly in your shell  
- without needing `chmod +x`  
- without needing `git clone`  
- without leaving temporary files  

Perfect for quick usage or remote systems.

---

## ✨ Features

- ✔ **TUI interface** (no GUI, no Zenity, no portals)
- ✔ **Automatic Ventoy download** (latest version via GitHub API)
- ✔ **Automatic MediCat detection** in `~/Downloads`
- ✔ **Fallback prompt** to open the official MediCat download page
- ✔ **USB device detection** using `lsblk`
- ✔ **MBR/GPT selection** for Ventoy installation
- ✔ **Automatic NTFS creation** for Medicat partition
- ✔ **Automatic extraction** of MediCat `.7z` archive
- ✔ **Logging** to `./medicat_builder.log`
- ✔ **Safe prompts** to prevent accidental disk erasure
- ✔ **MIT licensed**

---

## 📦 Requirements

This tool is designed for **Fedora 38+**.

The script automatically installs:

- `wget`
- `unzip`
- `exfatprogs`
- `ntfs-3g`
- `rsync`
- `p7zip`
- `p7zip-plugins`

No GUI dependencies are required.

---

## 🚀 Manual Installation

Clone the repository:

```bash
git clone https://github.com/lukumaki/medicat-fedora-usb-installer.git
cd medicat-fedora-usb-installer
```

Make the script executable:

```bash
chmod +x medicat_usb_builder.sh
```

Run it:

```bash
./medicat_usb_builder.sh
```

---

## 🧠 How It Works

### 1. Dependency installation  
The script installs all required packages using `dnf`.

### 2. Ventoy auto‑download  
It fetches the **latest Ventoy release** from GitHub using the official API.

### 3. USB detection  
It lists all connected storage devices and asks you to choose the correct one.

### 4. Ventoy installation  
You choose **MBR** or **GPT**, and Ventoy is installed accordingly.

### 5. MediCat detection  
The script automatically searches for:

```
~/Downloads/MediCat*.7z
```

If not found, it offers to open the official download page.

### 6. NTFS creation  
The second partition (`/dev/sdX1`) is formatted as NTFS with label `Medicat`.

### 7. Extraction  
The MediCat archive is extracted directly onto the USB.

### 8. Optional unmount  
You can choose whether to unmount the USB at the end.

---

## 📁 Project Structure

```
medicat-fedora-usb-installer/
│
├── medicat_usb_builder.sh
│
├── ventoy/
│   ├── Ventoy2Disk.sh
│   ├── tool/
│   │   ├── VentoyWorker.sh
│   │   ├── ventoy_lib.sh
│   │   └── (Ventoy binaries)
│
├── patch/
│   ├── Ventoy2Disk_fedora.sh
│   ├── VentoyWorker_fedora.sh
│   └── README_fedora_patch.md
│
└── assets/
    └── (logos, screenshots, etc)

```

---

## 📝 Logging

All operations are logged to:

```
./medicat_builder.log
```

Useful for debugging or reporting issues.

---

## 🛠 Troubleshooting

### ❗ Ventoy download fails  
Check your internet connection or GitHub availability.

### ❗ MediCat not detected  
Ensure the `.7z` file is in:

```
~/Downloads
```

Or enter the full path manually.

### ❗ Permission errors  
Run the script normally — it elevates itself using `sudo`.

### ❗ USB not listed  
Ensure the USB is properly connected and recognized by `lsblk`.

---

# Fedora Patch Layer for Ventoy

Fedora 40–44 removed the `mkexfatfs` binary required by Ventoy.
This patch layer provides Fedora‑compatible wrappers for:

- `Ventoy2Disk.sh`
- `VentoyWorker.sh`

## Why this is needed

Ventoy fails on Fedora with:
mkexfatfs: command not found
Some tools can not run on current system.

Fedora uses `mkfs.exfat` instead of `mkexfatfs`.

These wrappers:

- create a safe symlink (`mkexfatfs → mkfs.exfat`)
- fix tool detection
- fix partition wait timing
- run the official Ventoy scripts with a Fedora‑compatible environment

## Usage

Place the files `Ventoy2Disk_fedora.sh` & `VentoyWorker_fedora.sh` next to the official Ventoy scripts `Ventoy2Disk.sh` & `tool/VentoyWorker.sh`

The script can now be used as standalone for installing Ventoy in **Fedora 38+**. Replace X with your correct drive as shown in: `lsblk --nodeps --output "NAME,SIZE,VENDOR,MODEL,SERIAL"` )

```bash
sudo bash Ventoy2Disk_fedora.sh -i /dev/sdX
```

All Ventoy CLI options work normally:
-i  install
-I  force install
-u  update
-l  list
-g  GPT mode
-s  secure boot

## Notes
These wrappers do NOT modify Ventoy itself.

They simply fix Fedora incompatibilities.

They work with all future Ventoy versions.

## 🗺 Roadmap

- [ ] Add AppImage version  
- [ ] Add RPM package  
- [ ] Add Flatpak version  
- [ ] Add checksum verification for MediCat  
- [ ] Add Ventoy plugin configuration  
- [ ] Add progress bars for extraction  
- [ ] Add multi‑USB batch mode  
- [ ] Add self‑update flag (`--update`)  

---

## 🤝 Contributing

Pull requests are welcome!  
Feel free to open issues for bugs, feature requests, or improvements.

---

## 📜 License

This project is licensed under the **MIT License**.  
See the `LICENSE` file for details.
