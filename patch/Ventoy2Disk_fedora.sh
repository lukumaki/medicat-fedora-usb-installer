#!/bin/bash
# Fedora compatibility wrapper for Ventoy2Disk.sh
# Passes every argument through to the official script unchanged.
set -euo pipefail

SELF="$(readlink -f "$0")"
PATCH_DIR="$(dirname "$SELF")"

# The installer exports VENTOY_DIR. When the wrapper is run by hand it falls
# back to a ventoy/ directory next to the patch directory.
VENTOY_ROOT="${VENTOY_DIR:-$(dirname "$PATCH_DIR")/ventoy}"

echo "[Fedora Patch] VENTOY_ROOT = $VENTOY_ROOT"

if [ ! -f "$VENTOY_ROOT/Ventoy2Disk.sh" ]; then
    echo "[ERROR] Ventoy2Disk.sh not found under $VENTOY_ROOT" >&2
    echo "[ERROR] Set VENTOY_DIR to your Ventoy installation directory." >&2
    exit 1
fi

# Fedora ships mkfs.exfat instead of the mkexfatfs binary Ventoy looks for.
if ! command -v mkexfatfs >/dev/null 2>&1; then
    if command -v mkfs.exfat >/dev/null 2>&1; then
        sudo ln -sf "$(command -v mkfs.exfat)" /usr/sbin/mkexfatfs
    else
        echo "[ERROR] mkfs.exfat missing (install: sudo dnf install exfatprogs)" >&2
        exit 1
    fi
fi

# Make Ventoy's bundled helper binaries reachable.
for arch in x86_64 aarch64 mips64el i386; do
    if [ -d "$VENTOY_ROOT/tool/$arch" ]; then
        PATH="$VENTOY_ROOT/tool/$arch:$PATH"
    fi
done
export PATH

echo "[Fedora Patch] Running official Ventoy2Disk.sh..."
# The arguments must stay outside the quoted path: quoting them together
# makes bash look for a file literally named "Ventoy2Disk.sh -I".
exec bash "$VENTOY_ROOT/Ventoy2Disk.sh" "$@"
