#!/bin/bash
# Fedora‑patched wrapper for VentoyWorker.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "[Fedora Patch] Preparing VentoyWorker environment..."

# --------------------------------------------------------------------
# 1. Ensure mkexfatfs exists (fallback to mkfs.exfat)
# --------------------------------------------------------------------
if ! command -v mkexfatfs >/dev/null 2>&1; then
    if command -v mkfs.exfat >/dev/null 2>&1; then
        echo "[Fedora Patch] Creating mkexfatfs → mkfs.exfat symlink..."
        sudo ln -sf "$(command -v mkfs.exfat)" /usr/sbin/mkexfatfs
    else
        echo "[ERROR] mkexfatfs/mkfs.exfat missing. Install exfatprogs."
        exit 1
    fi
fi

# --------------------------------------------------------------------
# 2. Improve partition wait logic (Fedora udev is slower)
# --------------------------------------------------------------------
export VENTOY_WAIT_EXTRA=1

# --------------------------------------------------------------------
# 3. Run official VentoyWorker.sh
# --------------------------------------------------------------------
echo "[Fedora Patch] Running official VentoyWorker.sh..."
exec bash "$SCRIPT_DIR/ventoy/tool/VentoyWorker.sh" "$@"
