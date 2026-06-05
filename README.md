<p align="center">

  <!-- Badges -->
  <img src="https://img.shields.io/badge/version-4.1--B4-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/build-Professional--Clean-brightgreen.svg" alt="Build Status">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/Fedora-40--44-blue?logo=fedora&logoColor=white" alt="Fedora Compatibility">
  <img src="https://img.shields.io/badge/Ventoy-Compatible-success?logo=linux&logoColor=white" alt="Ventoy Compatible">
  <img src="https://img.shields.io/badge/shell-bash-121011.svg?logo=gnu-bash&logoColor=white" alt="Shell Script">
  <img src="https://img.shields.io/github/stars/lukumaki/medicat-fedora-usb-installer?style=social" alt="GitHub Stars">
  <img src="https://img.shields.io/github/issues/lukumaki/medicat-fedora-usb-installer" alt="GitHub Issues">
  <img src="https://img.shields.io/github/last-commit/lukumaki/medicat-fedora-usb-installer" alt="Last Commit">

</p>

# 🔥 MediCat USB Builder for Fedora

### Fully automated, production-ready tool for creating Ventoy-based MediCat USB drives on Fedora Linux.

**Version 5**

---

## ✨ Key Features

- ✅ **Full automation** — Ventoy + format + MediCat copy in one command
- ✅ **Smart caching** — Download once, install infinitely (28 GB cached)
- ✅ **Update-only mode** — 30 min → 30 sec for incremental updates
- ✅ **Dry-run mode** — Preview operations without making changes
- ✅ **Verbose debugging** — Detailed output for troubleshooting
- ✅ **Quiet mode** — Suppress all non-critical output
- ✅ **Error handling** — Proper error recovery and validation
- ✅ **Progress tracking** — Real-time progress bars (7z + rsync)
- ✅ **BIOS/UEFI support** — MBR and GPT partitioning
- ✅ **USB safety checks** — Removable media verification
- ✅ **Fedora-patched Ventoy** — Works on Fedora 40–44 without issues

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

## 🚀 Quick Start

### Method 1: One-Line Installation (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lukumaki/medicat-fedora-usb-installer/main/medicat_usb_builder.sh)
```

### Method 2: Clone & Modify (For Developers)

```bash
git clone https://github.com/lukumaki/medicat-fedora-usb-installer.git
cd medicat-fedora-usb-installer
chmod +x medicat_usb_builder.sh
./medicat_usb_builder.sh
```

---

## 🔧 All Available Flags

| Flag | Purpose | Example |
|------|---------|---------|
| `--skip-ventoy` | Keep existing Ventoy | `./medicat_usb_builder.sh --skip-ventoy` |
| `--skip-medicat` | Skip MediCat copy | `./medicat_usb_builder.sh --skip-medicat` |
| `--update-only` | Copy only new Medicat files | `./medicat_usb_builder.sh --update-only` |
| `--force-mbr` | Use MBR partitioning | `./medicat_usb_builder.sh --force-mbr` |
| `--force-gpt` | Use GPT partitioning | `./medicat_usb_builder.sh --force-gpt` |
| `--dry-run` | Preview without changes | `./medicat_usb_builder.sh --dry-run` |
| `--force-update` | Copy Medicat files from existing local cache | `./medicat_usb_builder.sh --force-update` |
| `--quiet` | Suppress output | `./medicat_usb_builder.sh --quiet` |

---

### Force Partitioning Scheme
```bash
./medicat_usb_builder.sh --force-mbr   # Old BIOS systems
./medicat_usb_builder.sh --force-gpt   # Modern UEFI systems
```

### Combine Flags
```bash
./medicat_usb_builder.sh --dry-run --verbose
./medicat_usb_builder.sh --update-only --quiet
```

---

## 📊 Performance & Time Requirements

The MediCat archive is **~28 GB**, but smart caching reduces repeat installations:

| Operation | Time | Details |
|-----------|------|---------|
| **First Download** | 5–40 min | Depends on connection speed |
| **Extraction** | 3–20 min | SSD vs HDD |
| **USB Copy** | 10–60 min | USB 3.0, 2.0, or SSD enclosure |
| **Update Only** | 30 sec | Uses cached files + rsync --update |

### Download Speed Optimization

The script **automatically tests all mirrors** and selects the fastest one:

```
Testing mirror speeds...
Mirror 1: 2.5 MB/s
Mirror 2: 15.3 MB/s ← Selected (best)
Mirror 3: 1.8 MB/s
```

---

## 📦 Dependencies

The script automatically installs missing packages via `dnf`:

- **Network:** `wget`, `curl`
- **Archive:** `p7zip`, `p7zip-plugins`, `unzip`
- **Filesystem:** `rsync`, `exfatprogs`, `ntfs-3g`
- **Tools:** `bc`, `lsblk`, `mkntfs`

---

## ✅ System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **OS** | Fedora 40+ | Fedora 44 |
| **Storage** | 60 GB free | 100 GB free |
| **RAM** | 2 GB | 4 GB+ |
| **USB** | 32 GB | 64 GB USB 3.0 |
| **Internet** | 50 Mbps | 100+ Mbps fiber |

---

## 🧪 Tested On

- ✅ Fedora 44 (KDE Plasma)
- ✅ Fedora 43 (Workstation)
- ✅ BIOS boot mode
- ✅ UEFI boot mode
- ✅ USB 3.0 sticks
- ✅ SSD-based USB enclosures
- ✅ Network mirroring (automatic selection)

---

## 🐛 Troubleshooting

### "Ventoy installation failed"
```bash
# Check the detailed log
cat ~/Medicat_USB_Cache/medicat_usb_builder.log

# Run in verbose mode for more info
./medicat_usb_builder.sh --verbose
```

### "No valid server found"
The CDN mirrors are temporarily down. Try again later or:
```bash
# Use dry-run to see which mirrors are being tested
./medicat_usb_builder.sh --dry-run --verbose
```

### "Failed to mount ${TARGET}1"
```bash
# Check device is recognized
lsblk

# Manually unmount if stuck
sudo umount /mnt/medicat 2>/dev/null

# Try again
./medicat_usb_builder.sh
```

### Log file not created
The cache directory is created automatically on first run. If permissions are denied:
```bash
sudo chown $USER:$USER ~/Medicat_USB_Cache
```

---

## 📜 Logging

All operations are logged to:
```
~/Medicat_USB_Cache/medicat_usb_builder.log
```

Logs include:
- Timestamps for all operations
- Mirror speeds and selection
- Download/extraction progress
- Error messages with context
- USB device information

View logs in real-time:
```bash
tail -f ~/Medicat_USB_Cache/medicat_usb_builder.log
```

---

## 🏆 Performance Tips

1. **Use USB 3.0 or SSD enclosure** — Copy time 10–25 min vs 30–60 min
2. **Update-only mode** — 30 seconds instead of 30 minutes for incremental updates
3. **Fast internet** — Download time is major bottleneck (mirror auto-selection helps)
4. **SSD for cache** — Extraction 2–3× faster than HDD
5. **Pre-cache before travel** — Run once, use update-only mode later

---

## 🔐 Safety Features

- ✅ **Removable media check** — Prevents accidental formatting of system drive
- ✅ **Confirmation prompts** — Requires explicit "FORMAT" confirmation
- ✅ **Auto-unmount cleanup** — Prevents corrupted USB states on exit
- ✅ **Error validation** — All critical operations verified
- ✅ **Dry-run mode** — Preview without making changes
- ✅ **Log file tracking** — Full audit trail of all operations

---

## 🧑‍💻 Credits

### Project Author
- **lukumaki** — Identified Fedora 44 incompatibility, implemented Fedora Patch Layer, built first fully working MediCat USB Builder for Fedora

### Fedora Patch Layer
Restores Ventoy compatibility on Fedora 40–44 by:
- Safe symlink: `mkexfatfs → mkfs.exfat`
- Ventoy timing fixes for Fedora's udev
- Official Ventoy scripts run unmodified

### External Projects
- **Ventoy Project** — https://www.ventoy.net / https://github.com/ventoy/Ventoy
- **MediCat USB** — https://medicatusb.com
- **mon5termatt** — https://github.com/mon5termatt/medicat_installer (mirror selection logic)

---

## 📝 Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history, improvements, and migration guides.

---

## 📄 License

MIT License — Free to use, modify, and distribute.

See [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

Found a bug? Have a suggestion?

1. Check existing issues: https://github.com/lukumaki/medicat-fedora-usb-installer/issues
2. Create a new issue with details
3. Consider submitting a pull request

---

## ⚠️ Disclaimer

This tool is provided as-is. Use at your own risk. Always:
- Verify you've selected the correct USB device
- Backup important data before formatting
- Read confirmation prompts carefully
- Check logs if something goes wrong

---

## 🔗 Quick Links

- **GitHub Repository** — https://github.com/lukumaki/medicat-fedora-usb-installer
- **Issue Tracker** — https://github.com/lukumaki/medicat-fedora-usb-installer/issues
- **Latest Release** — https://github.com/lukumaki/medicat-fedora-usb-installer/releases
- **Fedora Patch Documentation** — [patch/README_fedora_patch.md](patch/README_fedora_patch.md)

---

<p align="center">
  <b>Made with ❤️ for Fedora Users</b><br>
  <a href="https://github.com/lukumaki/medicat-fedora-usb-installer">⭐ Star this repo</a> if it helped you!
</p>
