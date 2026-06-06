#!/bin/bash

install_medicat() {
  if [ "$INSTALL_MEDICAT" -ne 1 ]; then
    log_debug "MediCat operation skipped (MODE=$MODE)."
    return 0
  fi

  #
  # DRY RUN
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would copy/update MediCat files from $MEDICAT_DIR/extracted/ to $MNT_DIR"
    return 0
  fi

  #
  # UPDATE-ONLY MODE
  # (User must have mounted the Medicat NTFS partition manually)
  #
  if [ "$MODE" = "update" ]; then
    log_info "Updating existing MediCat installation at $MNT_DIR"

    # NTFS‑safe rsync options
    local rsync_opts=(
      -avh
      --info=progress2
      --update
      --no-perms
      --no-owner
      --no-group
    )

    log_debug "Running rsync with options: ${rsync_opts[*]}"

    if ! rsync "${rsync_opts[@]}" "$MEDICAT_DIR/extracted/" "$MNT_DIR/"; then
      log_error "rsync update failed"
      return 1
    fi

    log_ok "MediCat update complete."
    return 0
  fi

  #
  # FULL INSTALL MODE
  # (Script mounts and unmounts the NTFS partition)
  #
  log_info "Performing full MediCat installation..."

  sudo mkdir -p "$MNT_DIR"

  if ! sudo mount "$PART_DATA" "$MNT_DIR"; then
    log_error "Failed to mount $PART_DATA to $MNT_DIR"
    return 1
  fi

  # NTFS‑safe rsync options
  local rsync_opts=(
    -avh
    --info=progress2
    --no-perms
    --no-owner
    --no-group
  )

  log_debug "Running rsync with options: ${rsync_opts[*]}"

  if ! rsync "${rsync_opts[@]}" "$MEDICAT_DIR/extracted/" "$MNT_DIR/"; then
    log_error "rsync copy failed"
    sudo umount "$MNT_DIR" 2>/dev/null || true
    return 1
  fi

  log_ok "MediCat installation complete."

  sudo umount "$MNT_DIR" 2>/dev/null || true
}

