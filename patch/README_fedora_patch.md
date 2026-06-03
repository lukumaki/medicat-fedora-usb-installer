# Fedora Patch Layer for Ventoy  
### Compatibility wrappers for Fedora 40–44

Fedora 40–44 removed the `mkexfatfs` binary required by Ventoy.  
This patch layer provides Fedora‑compatible wrapper scripts that restore full Ventoy functionality without modifying Ventoy itself.

---

## ❗ Why this patch is required

Ventoy depends on the `mkexfatfs` binary for formatting and validation.  
However, Fedora removed this binary and replaced it with:

```
mkfs.exfat
```

As a result, Ventoy fails with:

```
mkexfatfs: command not found
Some tools can not run on current system.
```

This causes:

- Ventoy tool detection to fail  
- VentoyWorker to abort  
- Ventoy2Disk to stop before installation  
- The official MediCat installer to fail on Fedora  

---

## ✔ What the Fedora Patch Layer does

These wrapper scripts provide a compatibility layer that allows Ventoy to run normally on Fedora:

### 1. Create a safe symlink  
```
mkexfatfs → mkfs.exfat
```

### 2. Fix Ventoy tool detection  
Ventoy now believes the required tools exist and continues installation.

### 3. Fix partition wait timing  
Fedora’s udev timing differs from Debian/Ubuntu, causing Ventoy to wait incorrectly.  
The wrapper adjusts timing to match Fedora’s behavior.

### 4. Run the official Ventoy scripts unchanged  
The wrappers:

- Do **not** modify Ventoy  
- Do **not** patch Ventoy binaries  
- Do **not** alter Ventoy’s logic  

They simply provide a Fedora‑compatible environment.

### 5. Work with all future Ventoy versions  
Because the symlink and wrapper logic are version‑agnostic.

---

## 📁 Patch folder structure

```
patch/
│
├── Ventoy2Disk_fedora.sh
├── VentoyWorker_fedora.sh
└── README_fedora_patch.md
```

---

## 🛠 Usage

Place the patch files inside:

```
medicat-fedora-usb-installer/patch/
```

Then run Ventoy using the Fedora wrapper:

```bash
sudo bash patch/Ventoy2Disk_fedora.sh -i /dev/sdX
```

All Ventoy CLI options work normally:

```
-i   install
-I   force install
-u   update
-l   list
-g   GPT mode
-s   secure boot
```

---

## 📌 Notes

- These wrappers **do NOT modify Ventoy**.  
- They only fix Fedora‑specific incompatibilities.  
- They are safe to use with all future Ventoy releases.  
- They are required for Fedora 40–44 (and likely future versions).  

---

## 🙌 Credits

- Ventoy Project — https://www.ventoy.net/  
- Fedora community for documenting the removal of `mkexfatfs`  
- Patch integration and testing by **Frixos**  
