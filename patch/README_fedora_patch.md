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

Place these files in:

medicat-fedora-usb-installer/patch/

Code

Then run:

```bash
sudo bash patch/Ventoy2Disk_fedora.sh -i /dev/sdX
```

All Ventoy CLI options work normally:

Code
-i  install
-I  force install
-u  update
-l  list
-g  GPT mode
-s  secure boot
Notes
These wrappers do NOT modify Ventoy itself.

They simply fix Fedora incompatibilities.

They work with all future Ventoy versions.

---

# 🟦 **patch folder structure**

patch/
│
├── Ventoy2Disk_fedora.sh
├── VentoyWorker_fedora.sh
└── README_fedora_patch.md

---
