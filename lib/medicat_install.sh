#!/bin/bash

# medicat_install.sh
# Safe, MODE-aware MediCat installation logic (v7.1 PRO)

install_medicat() {

  #
  # MODE / FLAG CHECKS
  #
  if [ "$INSTALL_MEDICAT" -ne 1 ]; then
    log_debug "Skipping MediCat installation (INSTALL_MEDICAT=0, MODE=$MODE)."
    return 0
  fi

  #
  # Base rsync options shared by both paths.
  # -rltvh instead of -avh: -a implies -D (device/special files), which NTFS
  # cannot represent. -t is kept so --update can compare timestamps.
  # --no-perms/--no-owner/--no-group: NTFS cannot store POSIX ownership,
  # so preserving it would make rsync fail on every file.
  #
  local rsync_opts=(
    -rltvh
    --info=progress2
    --no-perms
    --no-owner
    --no-group
    --modify-window=2
  )

  # Default is an incremental update; --force-update re-copies everything.
  if [ "$MODE" = "update" ] && [ "$FORCE_UPDATE" -ne 1 ]; then
    rsync_opts+=(--update)
  fi

  #
  # DRY RUN
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would rsync MediCat files:"
    log_info "  Source: $MEDICAT_DIR/extracted/"
    log_info "  Target: $MNT_DIR"
    log_info "  Options: ${rsync_opts[*]}"
    return 0
  fi

  #
  # Ensure extracted directory exists and has content
  #
  if [ ! -d "$MEDICAT_DIR/extracted" ] || [ -z "$(ls -A "$MEDICAT_DIR/extracted" 2>/dev/null)" ]; then
    log_error "Extracted MediCat directory is missing or empty: $MEDICAT_DIR/extracted"
    log_diagnostics
    return 1
  fi

  log_debug "Running rsync with options: ${rsync_opts[*]}"

  #
  # UPDATE-ONLY MODE — the partition is already mounted by the user
  #
  if [ "$MODE" = "update" ]; then
    log_info "Updating existing MediCat installation at $MNT_DIR"

    if ! rsync "${rsync_opts[@]}" "$MEDICAT_DIR/extracted/" "$MNT_DIR/"; then
      log_error "rsync update failed"
      log_diagnostics
      return 1
    fi

    sync
    log_ok "MediCat update complete."
    return 0
  fi

  #
  # FULL INSTALL MODE — we mount the freshly formatted partition ourselves
  #
  log_info "Performing full MediCat installation..."

  if [ -z "${PART_DATA:-}" ] || [ ! -b "$PART_DATA" ]; then
    log_error "No valid MediCat data partition to install to: ${PART_DATA:-<unset>}"
    log_diagnostics
    return 1
  fi

  sudo mkdir -p "$MNT_DIR"

  # Mount as the invoking user so rsync can write without sudo.
  if ! sudo mount -t ntfs-3g -o "uid=$(id -u),gid=$(id -g),umask=0022" "$PART_DATA" "$MNT_DIR"; then
    log_warn "ntfs-3g mount failed, retrying with the default driver..."
    if ! sudo mount "$PART_DATA" "$MNT_DIR"; then
      log_error "Failed to mount $PART_DATA at $MNT_DIR"
      log_diagnostics
      return 1
    fi
  fi

  if ! rsync "${rsync_opts[@]}" "$MEDICAT_DIR/extracted/" "$MNT_DIR/"; then
    log_error "rsync copy failed"
    log_diagnostics
    sync
    sudo umount "$MNT_DIR" 2>/dev/null || true
    return 1
  fi

  log_info "Flushing writes to disk (this can take a while)..."
  sync

  sudo umount "$MNT_DIR" 2>/dev/null || true

  log_ok "MediCat installation complete. It is now safe to remove the USB drive."
}
