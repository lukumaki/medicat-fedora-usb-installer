#!/bin/bash

install_medicat() {
  if [ "$INSTALL_MEDICAT" -ne 1 ]; then
    log_debug "MediCat operation skipped (MODE=$MODE)."
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would mount ${TARGET}2 to $MNT_DIR"
    log_info "[DRY RUN] Would copy/update MediCat files from $MEDICAT_DIR/extracted/"
    return 0
  fi

  sudo mkdir -p "$MNT_DIR"

  if ! sudo mount "${TARGET}2" "$MNT_DIR"; then
    log_error "Failed to mount ${TARGET}2 to $MNT_DIR"
    return 1
  fi

  local rsync_opts="-avh --info=progress2"
  if [ "$MODE" = "update" ]; then
    rsync_opts="$rsync_opts --update"
    log_info "Updating existing MediCat installation..."
  else
    log_info "Performing full MediCat installation..."
  fi

  log_debug "Running rsync with options: $rsync_opts"

  if ! rsync $rsync_opts "$MEDICAT_DIR/extracted/" "$MNT_DIR/"; then
    log_error "rsync copy failed"
    sudo umount "$MNT_DIR" 2>/dev/null || true
    return 1
  fi

  log_ok "MediCat copy/update complete."
  sudo umount "$MNT_DIR" 2>/dev/null || true
}
