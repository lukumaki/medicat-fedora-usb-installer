# MediCat USB Builder for Fedora  
A fully automated Ventoy + MediCat USB installer for Fedora Linux.

This project provides:

- A **Fedora‑compatible Ventoy installer** (via patch‑layer wrappers)
- A **fully automated MediCat USB builder**
- A simple **TUI‑style workflow**
- 100% compatibility with Fedora 38–44

---

## 🚀 Features

### ✔ Fully automated Ventoy installation  
Fedora removed the `mkexfatfs` binary required by Ventoy.  
This project includes a **patch layer** that:

- Creates a safe fallback (`mkexfatfs → mkfs.exfat`)
- Fixes Ventoy tool detection
- Fixes partition wait timing (udev delay)
- Runs the official Ventoy scripts in a Fedora‑safe environment

### ✔ Fully automated MediCat extraction  

The builder:

- Detects your USB drive
- Installs Ventoy (patched)
- Extracts MediCat from your `~/Downloads` folder
- Copies everything to the Ventoy partition

---

## 🧩 Fedora Ventoy Patch Layer

Fedora 40–44 removed the `mkexfatfs` binary required by Ventoy.  
Ventoy fails with:
mkexfatfs: command not found
Some tools can not run on current system.

This project includes **patched wrapper scripts** that:

- Create a fallback symlink (`mkexfatfs → mkfs.exfat`)
- Fix PATH issues
- Fix partition wait timing
- Run the official Ventoy scripts safely

These wrappers are automatically downloaded by the builder if missing.

---

## 🛠 Installation

### 1. Clone the repo

```bash
git clone https://github.com/lukumaki/medicat-fedora-usb-installer
cd medicat-fedora-usb-installer
```

### 2. Place your MediCat package in:
```
~/Downloads/MediCat*.7z
```

### 3. Run the builder
```
bash medicat_usb_builder.sh
```

### 4. Follow the on-screen instructions
The script will:

Download Ventoy

Download Fedora patches (if missing)

Install Ventoy on your USB

Extract MediCat onto the Ventoy partition

## 🧪 Supported Fedora Versions
Fedora 38

Fedora 39

Fedora 40

Fedora 41

Fedora 42

Fedora 43

Fedora 44

## 📜 License
MIT License
This project includes wrapper scripts for Ventoy, which is GPLv3.

## ❤️ Credits
Ventoy project (GPLv3)

MediCat project

Fedora community
