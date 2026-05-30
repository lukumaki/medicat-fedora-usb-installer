#!/bin/bash
# Fedora‑patched wrapper for Ventoy2Disk.sh
# Author: Frixos + Copilot
# Purpose: Make Ventoy fully compatible with Fedora 38–44

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
export PATH="$SCRIPT_DIR/tool/x86_64:$PATH"
export PATH="$SCRIPT_DIR/tool/aarch64:$PATH"
export PATH="$SCRIPT_DIR/tool/mips64el:$PATH"
export PATH="$SCRIPT_DIR/tool/i386:$PATH"

# --------------------------------------------------------------------
# 3. Run official Ventoy2Disk.sh with all arguments
# --------------------------------------------------------------------
echo "[Fedora Patch] Running official Ventoy2Disk.sh..."
exec bash "$SCRIPT_DIR/Ventoy2Disk.sh" "$@"
