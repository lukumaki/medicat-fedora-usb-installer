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

…although updated 6 months ago with Fedora notes, **did not work on Fedora 44**.

The root causes were:

- Missing required packages (`ntfs-3g`, `exfatprogs`, `p7zip-plugins`)  
- Ventoy’s Linux installer failing on Fedora due to glibc/tooling differences  
- The Ventoy worker script not being compatible with Fedora  
- The official script not including Fedora‑specific patches  

This made it impossible to create a working MediCat USB on Fedora without manual intervention.

This project solves that.

---

## 🧠 How I solved it (reasoning & process)

### 1. Identifying the failure  
Running the official *Medicat_Installer.sh* on Fedora 44 resulted in:

- Ventoy installer errors  
- Missing filesystem tools  
- Extraction failures  
- Incomplete USB creation  

### 2. Investigating Ventoy  
I analyzed:

- https://www.ventoy.net/  
- https://github.com/ventoy/Ventoy  

I discovered that Ventoy requires **Fedora‑specific patches** to run correctly.

### 3. Integrating Fedora Ventoy patches  
I added:

- `Ventoy2Disk_fedora.sh`  
- `VentoyWorker_fedora.sh`

These scripts allow Ventoy to install correctly on Fedora.

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

## 🧑‍💻 Credits

### 🔹 Ventoy Project  
- Website: https://www.ventoy.net/  
- GitHub: https://github.com/ventoy/Ventoy  
Ventoy makes MediCat USB possible.

### 🔹 MediCat USB  
- Website: https://medicatusb.com/  
The best Windows PE toolkit available.

### 🔹 mon5termatt (MediCat Installer)  
- GitHub: https://github.com/mon5termatt/medicat_installer  
Their project inspired the mirror selection logic and cdn.bat parsing.  
This project is a **Fedora‑specific re‑implementation**, not a fork.

### 🔹 lukumaki (Project Author)  
Discovered the Fedora 44 incompatibility, debugged the Ventoy installer, tested BIOS/UEFI boot, and built the first fully working **Fedora‑compatible MediCat USB Builder**.

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
