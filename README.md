# Medicat Fedora USB Installer
A fully automated **Ventoy + MediCat USB** installer for **Fedora Linux**, using a clean **TUI interface**, with **automatic Ventoy updates**, **automatic MediCat detection**, and **MIT license**.

This tool is designed for Fedora users who want a reliable, repeatable, and fully automated way to create a Medicat USB using Ventoy — without GUI dependencies, without Zenity, and without manual partitioning.

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

## 🚀 Installation

Clone the repository:

```bash
git clone https://github.com/lukumaki/medicat-fedora-usb-installer.git
cd medicat-fedora-usb-installer
