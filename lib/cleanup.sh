#!/bin/bash
# cleanup.sh — Safe cleanup trap for MediCat Installer (v7.1 PRO)

# ---------------------------------------------------------
# Unmount every mountpoint of every partition on a device
# (shared by format.sh and the cleanup trap)
# ---------------------------------------------------------
unmount_device_partitions() {
  local device="$1"
  local parts mnts p m dev

  [ -z "$device" ] && return 0
  [ -b "$device" ] || return 0

  log_debug "Unmounting all partitions of $device..."

  mapfile -t parts < <(lsblk -ln -o NAME "$device" 2>/dev/null | tail -n +2)

  for p in "${parts[@]}"; do
    dev="/dev/$p"
    mapfile -t mnts < <(findmnt -nr -o TARGET -S "$dev" 2>/dev/null || true)

    for m in "${mnts[@]}"; do
      [ -z "$m" ] && continue
      log_debug "Unmounting $dev from $m"
      sudo umount "$m" 2>/dev/null || true
    done
  done
}

cleanup() {
  local code=$?

  # The trap is installed before the configuration is loaded, so every
  # variable used here must tolerate being unset under `set -u`.
  log_debug "Running cleanup trap (exit code: $code, MODE=${MODE:-<unset>})"

  #
  # DRY RUN: do nothing
  #
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY RUN → skipping cleanup actions."
    return 0
  fi

  #
  # Remove temporary write test file (if it survived a failure)
  #
  if [ -n "${MNT_DIR:-}" ] && [ -f "$MNT_DIR/.medicat_write_test" ]; then
    rm -f "$MNT_DIR/.medicat_write_test" 2>/dev/null || true
  fi

  #
  # Remove partial downloads.
  # These globs must stay unquoted: "$DIR/*.partial" is passed to rm
  # literally and silently matches nothing.
  #
  if [ -n "${MEDICAT_DIR:-}" ]; then
    rm -f "$MEDICAT_DIR"/*.partial 2>/dev/null || true
  fi
  if [ -n "${CACHE_DIR:-}" ]; then
    rm -rf "$CACHE_DIR/.ventoy_download" 2>/dev/null || true
  fi

  #
  # Unmount ALL partitions of the USB device
  #
  if [ -n "${TARGET:-}" ]; then
    unmount_device_partitions "$TARGET"
  else
    log_debug "No TARGET set → nothing to unmount."
  fi

  log_debug "Cleanup complete."
}
