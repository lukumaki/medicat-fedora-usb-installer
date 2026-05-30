#!/bin/bash
set -e

SELF="$(readlink -f "$0")"
PATCH_DIR="$(dirname "$SELF")"
ROOT_DIR="$(dirname "$PATCH_DIR")"

echo "[Fedora Patch] ROOT_DIR = $ROOT_DIR"

if ! command -v mkexfatfs >/dev/null 2>&1; then
    if command -v mkfs.exfat >/dev/null 2>&1; then
        sudo ln -sf "$(command -v mkfs.exfat)" /usr/sbin/mkexfatfs
    else
        echo "[ERROR] exfatprogs missing"
        exit 1
    fi
fi

export VENTOY_WAIT_EXTRA=1

exec bash "$ROOT_DIR/ventoy/tool/VentoyWorker.sh" "$@"
