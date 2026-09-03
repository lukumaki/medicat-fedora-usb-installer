#!/bin/bash
# Fedora compatibility wrapper for Ventoy's tool/VentoyWorker.sh
set -euo pipefail

SELF="$(readlink -f "$0")"
PATCH_DIR="$(dirname "$SELF")"

VENTOY_ROOT="${VENTOY_DIR:-$(dirname "$PATCH_DIR")/ventoy}"

echo "[Fedora Patch] VENTOY_ROOT = $VENTOY_ROOT"

if [ ! -f "$VENTOY_ROOT/tool/VentoyWorker.sh" ]; then
    echo "[ERROR] tool/VentoyWorker.sh not found under $VENTOY_ROOT" >&2
    echo "[ERROR] Set VENTOY_DIR to your Ventoy installation directory." >&2
    exit 1
fi

if ! command -v mkexfatfs >/dev/null 2>&1; then
    if command -v mkfs.exfat >/dev/null 2>&1; then
        sudo ln -sf "$(command -v mkfs.exfat)" /usr/sbin/mkexfatfs
    else
        echo "[ERROR] mkfs.exfat missing (install: sudo dnf install exfatprogs)" >&2
        exit 1
    fi
fi

# Fedora's udev timing differs from Debian/Ubuntu; give Ventoy longer to
# see the partition nodes it just created.
export VENTOY_WAIT_EXTRA=1

exec bash "$VENTOY_ROOT/tool/VentoyWorker.sh" "$@"
