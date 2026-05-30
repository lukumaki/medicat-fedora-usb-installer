#!/bin/bash
set -e

# Resolve absolute path of THIS script
SELF="$(readlink -f "$0")"
PATCH_DIR="$(dirname "$SELF")"
ROOT_DIR="$(dirname "$PATCH_DIR")"

echo "[Fedora Patch] ROOT_DIR = $ROOT_DIR"

# Fix mkexfatfs
if ! command -v mkexfatfs >/dev/null 2>&1; then
    if command -v mkfs.exfat >/dev/null 2>&1; then
        sudo ln -sf "$(command -v mkfs.exfat)" /usr/sbin/mkexfatfs
    else
        echo "[ERROR] exfatprogs missing"
        exit 1
    fi
fi

# Fix PATH
export PATH="$ROOT_DIR/ventoy/tool/x86_64:$PATH"
export PATH="$ROOT_DIR/ventoy/tool/aarch64:$PATH"
export PATH="$ROOT_DIR/ventoy/tool/mips64el:$PATH"
export PATH="$ROOT_DIR/ventoy/tool/i386:$PATH"

echo "[Fedora Patch] Running official Ventoy2Disk.sh..."
exec bash "$ROOT_DIR/ventoy/Ventoy2Disk.sh" "$@"
