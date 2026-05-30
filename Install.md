# 📘 **INSTALL.md — MediCat USB Builder for Fedora**

## MediCat USB Builder for Fedora  
A fully automated Ventoy + MediCat USB installer for Fedora, featuring a Fedora‑compatible Ventoy patch‑layer, automatic updates, improved logging, and robust error handling.

This guide explains:

- How to install and run the builder  
- How the system works internally  
- What the patch‑layer does  
- What to expect during installation  

---

# 🟩 **1. Requirements**

Before starting, ensure you have:

- Fedora 38–44 (Workstation or Server)
- A USB drive (32GB minimum, 64GB+ recommended)
- The MediCat USB archive placed in:

```
~/Downloads/MediCat*.7z
```

The builder will automatically install all required packages.

---

# 🟩 **2. Installation Steps**

## **Step 1 — Clone the repository**

```bash
git clone https://github.com/lukumaki/medicat-fedora-usb-installer
cd medicat-fedora-usb-installer
```

---

## **Step 2 — Make the builder executable**

```bash
chmod +x medicat_usb_builder.sh
```

---

## **Step 3 — Run the builder**

```bash
bash medicat_usb_builder.sh
```

The script will:

1. Install required dependencies  
2. Auto‑update the Fedora Ventoy patch‑layer  
3. Download the latest Ventoy release  
4. Extract and prepare Ventoy  
5. Ask you to select your USB device  
6. Install Ventoy using the Fedora‑patched wrapper  
7. Extract MediCat onto the Ventoy partition  

---

## **Step 4 — Select your USB device**

You will see a list like:

```
sda  223G  SSD
sdb  465G  HDD
sdd   57G  USB Flash Drive
```

Enter only the device name (e.g., `sdd`).

⚠️ **All data on the selected device will be erased.**

---

## **Step 5 — Wait for MediCat extraction**

The MediCat archive is large (20–25GB).  
Extraction may take several minutes depending on USB speed.

When finished, you will see:

```
MediCat USB installation completed!
```

Your USB is now ready to boot.

---

# 🟩 **3. How It Works (Technical Overview)**

This section explains the internal architecture of the builder.

---

## **3.1 Ventoy Download & Extraction**

The builder automatically:

1. Fetches the latest Ventoy version from GitHub  
2. Downloads the correct Linux tarball  
3. Extracts it  
4. Renames the extracted folder to:

```
ventoy/
```

This ensures a **stable path** for the Fedora patch‑layer.

---

## **3.2 Fedora Ventoy Patch‑Layer**

Fedora removed the `mkexfatfs` binary required by Ventoy.  
This breaks Ventoy’s installation scripts.

The patch‑layer fixes this by:

- Creating a fallback symlink:  
  `mkexfatfs → mkfs.exfat`
- Fixing PATH resolution for Ventoy tools  
- Adding udev wait‑time improvements  
- Wrapping Ventoy’s official scripts without modifying them  

Patch scripts are auto‑updated from the GitHub repo when missing or outdated.

---

## **3.3 Ventoy Installation Flow**

When installing Ventoy:

1. The builder calls:  
   `patch/Ventoy2Disk_fedora.sh`
2. The wrapper prepares the environment  
3. The wrapper calls the official Ventoy script  
4. Ventoy formats the USB and installs its bootloader  
5. The builder mounts the Ventoy partition  
6. MediCat is extracted onto the USB  

This ensures **full compatibility with Fedora**, even though Ventoy does not officially support Fedora’s filesystem changes.

---

## **3.4 MediCat Extraction**

The builder:

- Mounts the Ventoy data partition  
- Extracts the MediCat archive using 7zip  
- Syncs and unmounts the USB safely  

All files are placed exactly where Ventoy expects them.

---

# 🟩 **4. Troubleshooting**

### **Ventoy shows “Failed to access /dev/sdX”**
This is normal.  
Ventoy performs a dry‑run before the real installation.  
If the script continues and shows:

```
[OK] Ventoy installation completed.
```

then everything worked.

---

### **MediCat archive not found**
Ensure the file is in:

```
~/Downloads/
```

and named like:

```
MediCat*.7z
```

---

### **USB not detected**
Run:

```bash
lsblk -o NAME,SIZE,MODEL
```

Ensure the device appears as a `disk`, not a `loop`.

---

# 🟩 **5. License**

This project is MIT‑licensed.  
Ventoy is GPLv3.  
MediCat is distributed separately by its author.

---

# 🟩 **6. Credits**

- Ventoy Project  
- MediCat Project  
- Fedora Community  

---
