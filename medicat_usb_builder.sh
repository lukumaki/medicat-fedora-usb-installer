#!/bin/bash
# MediCat USB Builder for Fedora (with Ventoy Fedora Patch Layer)
# Author: Frixos + Copilot
# Version: 1.1-fedorapatch

set -e

REPO_URL="https://github.com/lukumaki/medicat-fedora-usb-installer"
PATCH_URL="$REPO_URL/raw/main/patch"
VENTOY_URL="https://github.com/ventoy/Ventoy/releases/latest/download/ventoy-linux.tar.gz"

echo ""
echo "=============================================="
echo "  MediCat USB Builder for Fedora (Patched)"
echo "=============================================="
echo ""

# ---------------------------------------------------------
# 1. Ensure dependencies
# ---------------------------------------------------------
echo "[INFO] Installing required packages..."
sudo dnf install -y wget curl unzip rsync 7zip exfatprogs ntfs-3g

# ---------------------------------------------------------
# 2. Ensure patch folder exists
# ---------------------------------------------------------
mkdir -p patch

download_patch_if_missing() {
    local file="$1"
    local url="$PATCH_URL/$file"

    if [ ! -f "patch/$file" ]; then
        echo "[INFO] Downloading $file..."
        curl -s -L -o "patch/$file" "$url"
        chmod +x "patch/$file"
    else
        echo "[OK] $file already present."
    fi
}

echo "[INFO] Checking Fedora Ventoy patches..."
download_patch_if_missing "Ventoy2Disk_fedora.sh"
download_patch_if_missing "VentoyWorker_fedora.sh"

# ---------------------------------------------------------
# 3. Download Ventoy if missing
# ---------------------------------------------------------
if [ ! -d "ventoy" ]; then
    echo "[INFO] Fetching latest Ventoy version..."
    LATEST=$(curl -s https://api.github.com/repos/ventoy/Ventoy/releases/latest \
        | grep browser_download_url \
        | grep linux.tar.gz \
        | cut -d '"' -f 4)

    if [ -z "$LATEST" ]; then
        echo "[ERROR] Could not fetch Ventoy download URL."
        exit 1
    fi

    echo "[INFO] Downloading Ventoy from:"
    echo "       $LATEST"

    wget -O ventoy.tar.gz "$LATEST"

    echo "[INFO] Extracting Ventoy..."
rm -rf ventoy
mkdir -p ventoy
tar --strip-components=1 -xf ventoy.tar.gz -C ventoy
else
    echo "[OK] Ventoy folder already exists."
fi

# ---------------------------------------------------------
# 4. Ask user for USB device
# ---------------------------------------------------------
echo ""
echo "[INFO] Available USB devices:"
lsblk -o NAME,SIZE,VENDOR,MODEL,SERIAL,TYPE | grep -E "disk|part"

echo ""
read -p "Enter USB device (example: sdd): " DEV

if [ ! -b "/dev/$DEV" ]; then
    echo "[ERROR] /dev/$DEV does not exist."
    exit 1
fi

TARGET="/dev/$DEV"

echo ""
echo "[WARNING] ALL DATA ON $TARGET WILL BE ERASED!"
read -p "Continue? (y/N): " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && exit 0

# ---------------------------------------------------------
# 5. Run Ventoy installation via Fedora wrapper
# ---------------------------------------------------------
echo ""
echo "[INFO] Installing Ventoy on $TARGET..."
bash patch/Ventoy2Disk_fedora.sh -I "$TARGET"

echo ""
echo "[OK] Ventoy installation completed."

# ---------------------------------------------------------
# 6. Locate MediCat package
# ---------------------------------------------------------
echo ""
echo "[INFO] Searching for MediCat package in ~/Downloads..."
MEDICAT=$(ls ~/Downloads/MediCat*.7z 2>/dev/null | head -n 1)

if [ -z "$MEDICAT" ]; then
    echo "[ERROR] No MediCat package found in ~/Downloads."
    exit 1
fi

echo "[OK] Found: $MEDICAT"

# ---------------------------------------------------------
# 7. Mount Ventoy partition and extract MediCat
# ---------------------------------------------------------
PART1="${TARGET}1"

echo ""
echo "[INFO] Mounting $PART1..."
sudo umount "$PART1" 2>/dev/null || true
sudo mkdir -p /mnt/medicat
sudo mount "$PART1" /mnt/medicat

echo "[INFO] Extracting MediCat..."
7z x -y -O/mnt/medicat "$MEDICAT"

echo ""
echo "[INFO] Syncing..."
sync

sudo umount /mnt/medicat
sudo rmdir /mnt/medicat

echo ""
echo "=============================================="
echo "  MediCat USB installation completed!"
echo "=============================================="
