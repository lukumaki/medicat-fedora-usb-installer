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
  # DRY RUN
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would rsync MediCat files:"
    log_info "  Source: $MEDICAT_DIR/extracted/"
    log_info "  Target: $MNT_DIR"
    log_info "  Options: -avh --info=progress2 --no-perms --no-owner --no-group"
    return 0
  fi

  #
  # Ensure extracted directory exists
  #
  if [ ! -d "$MEDICAT_DIR/extracted" ]; then
    log_error "Extracted MediCat directory not found: $MEDICAT_DIR/extracted"
    log_diagnostics
    return 1
  fi

  #
  # UPDATE-ONLY MODE
  #
  if [ "$MODE" = "update" ]; then
    log_info "Updating existing MediCat installation at $MNT_DIR"

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
      log_diagnostics
      return 1
    fi

    log_ok "MediCat update complete."
    return 0
  fi

  #
  # FULL INSTALL MODE
  #
  log_info "Performing full MediCat installation..."

  sudo mkdir -p "$MNT_DIR"

  if ! sudo mount "$PART_DATA" "$MNT_DIR"; then
    log_error "Failed to mount $PART_DATA to $MNT_DIR"
    log_diagnostics
    return 1
  fi

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
    log_diagnostics
    sudo umount "$MNT_DIR" 2>/dev/null || true
    return 1
  fi

  log_ok "MediCat installation complete."

  sudo umount "$MNT_DIR" 2>/dev/null || true
}
