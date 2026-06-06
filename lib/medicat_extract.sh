#!/bin/bash

extract_medicat() {
    if [ "$MODE" = "update" ]; then
        log_debug "Skipping extraction (MODE=update)."
        return 0
    fi

    if [ -f "$MEDICAT_DIR/.extracted.ok" ]; then
        log_ok "MediCat already extracted."
        return 0
    fi

    log_info "Extracting MediCat archive..."
    mkdir -p "$MEDICAT_DIR/extracted"

    if ! 7z x "$MEDICAT_ARCHIVE" -o"$MEDICAT_DIR/extracted"; then
        log_error "Extraction failed."
        return 1
    fi

    touch "$MEDICAT_DIR/.extracted.ok"
    log_ok "Extraction complete."
}

install_medicat() {
  if [ "$INSTALL_MEDICAT" -ne 1 ]; then
    log_debug "MediCat operation skipped (MODE=$MODE)."
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would mount $PART_DATA to $MNT_DIR"
    log_info "[DRY RUN] Would copy/update MediCat files from $MEDICAT_DIR/extracted/"
    return 0
  fi

  sudo mkdir -p "$MNT_DIR"

  if ! sudo mount "$PART_DATA" "$MNT_DIR"; then
    log_error "Failed to mount $PART_DATA to $MNT_DIR"
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

