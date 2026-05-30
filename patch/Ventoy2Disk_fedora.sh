#!/bin/bash
# Fedora‑patched wrapper for Ventoy2Disk.sh

set -e

# SCRIPT_DIR = root folder of the project
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "[Fedora Patch] Preparing Ventoy environment..."

# --------------------------------------------------------------------
# 1. Fix missing mkexfatfs (Fedora uses mkfs.exfat instead)
# --------------------------------------------------------------------
if ! command -v mkexfatfs >/dev/null 2>&1; then
    if command -v mkfs.exfat >/dev/null 2>&1; then
        echo "[Fedora Patch] Creating mkexfatfs → mkfs.exfat symlink..."
        sudo ln -sf "$(command -v mkfs.exfat)" /usr/sbin/mkexfatfs
    else
        echo "[ERROR] Neither mkexfatfs nor mkfs.exfat found. Install exfatprogs."
        exit 1
    fi
fi

# --------------------------------------------------------------------
# 2. Fix PATH so Ventoy tools resolve correctly
# --------------------------------------------------------------------
export PATH="$SCRIPT_DIR/ventoy/tool/x86_64:$PATH"
export PATH="$SCRIPT_DIR/ventoy/tool/aarch64:$PATH"
export PATH="$SCRIPT_DIR/ventoy/tool/mips64el:$PATH"
export PATH="$SCRIPT_DIR/ventoy/tool/i386:$PATH"

# --------------------------------------------------------------------
# 3. Run official Ventoy2Disk.sh with all arguments
# --------------------------------------------------------------------
echo "[Fedora Patch] Running official Ventoy2Disk.sh..."
exec bash "$SCRIPT_DIR/ventoy/Ventoy2Disk.sh" "$@"
