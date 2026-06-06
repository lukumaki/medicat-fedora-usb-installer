#!/bin/bash
# cleanup.sh — Safe cleanup trap for MediCat Installer (v7.1 PRO)

cleanup() {
  local code=$?
  log_debug "Running cleanup trap (exit code: $code, MODE=$MODE)"

  #
  # DRY RUN: do nothing
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_debug "DRY RUN → skipping cleanup actions."
    return 0
  fi

  #
  # If no TARGET was selected, nothing to clean
  #
  if [ -z "$TARGET" ]; then
    log_debug "No TARGET set → nothing to unmount."
    return 0
  fi

  #
  # Unmount ALL partitions of the USB device
  #
  log_debug "Unmounting all partitions of $TARGET..."

  # List partitions: /dev/sde1 /dev/sde2 ...
  mapfile -t parts < <(lsblk -ln -o NAME "$TARGET" | tail -n +2)

  for p in "${parts[@]}"; do
    local dev="/dev/$p"

    # Find all mountpoints for this partition
    mapfile -t mnts < <(findmnt -nr -o TARGET -S "$dev" 2>/dev/null || true)

    for m in "${mnts[@]}"; do
      log_debug "Unmounting $dev from $m"
      sudo umount "$m" 2>/dev/null || true
    done
  done

  #
  # Remove temporary write test file (if exists)
  #
  if [ -n "$MNT_DIR" ] && [ -f "$MNT_DIR/.medicat_write_test" ]; then
    rm -f "$MNT_DIR/.medicat_write_test" 2>/dev/null || true
  fi

  #
  # Remove partial downloads
  #
  rm -f "$MEDICAT_DIR/cdn.bat.partial" 2>/dev/null || true
  rm -f "$MEDICAT_DIR/*.partial" 2>/dev/null || true
  rm -f "$VENTOY_DIR/*.partial" 2>/dev/null || true

  #
  # Remove temporary archives if extraction failed
  #
  if [ ! -f "$MEDICAT_DIR/.extracted.ok" ]; then
    rm -rf "$MEDICAT_DIR/extracted.tmp" 2>/dev/null || true
  fi

  log_debug "Cleanup complete."
}
