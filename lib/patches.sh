#!/bin/bash
# patches.sh — Fedora Ventoy patch management (v7.1 PRO)

ensure_patches() {

  #
  # MODE CHECK
  #
  if [ "$MODE" = "update" ]; then
    log_debug "Skipping Ventoy patch download (MODE=update)."
    return 0
  fi

  #
  # Validate PATCH_URL
  #
  if [ -z "$PATCH_URL" ]; then
    log_error "PATCH_URL is not set. Cannot download Fedora Ventoy patches."
    log_diagnostics
    return 1
  fi

  log_info "Checking Fedora Ventoy patches..."
  log_debug "Patch directory: $PATCH_DIR"
  log_debug "Patch source URL: $PATCH_URL"

  #
  # DRY RUN
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would ensure patches exist in $PATCH_DIR"
    return 0
  fi

  mkdir -p "$PATCH_DIR"

  #
  # Helper: download a single patch file
  #
  download_patch() {
    local file="$1"
    local url="$PATCH_URL/$file"

    log_debug "Processing patch: $file"
    log_debug "URL: $url"

    # Already present?
    if [ -f "$PATCH_DIR/$file" ]; then
      if [ -s "$PATCH_DIR/$file" ]; then
        log_ok "$file already present."
        return 0
      else
        log_warn "$file exists but is empty. Re-downloading."
        rm -f "$PATCH_DIR/$file"
      fi
    fi

    log_info "Downloading $file..."

    if ! curl -s -L -o "$PATCH_DIR/$file" "$url"; then
      log_error "Failed to download $file"
      rm -f "$PATCH_DIR/$file"
      log_diagnostics
      return 1
    fi

    # Validate file
    if [ ! -s "$PATCH_DIR/$file" ]; then
      log_error "Downloaded $file but file is empty."
      rm -f "$PATCH_DIR/$file"
      log_diagnostics
      return 1
    fi

    chmod +x "$PATCH_DIR/$file"
    log_ok "$file downloaded and validated."
  }

  #
  # Download required patches
  #
  download_patch "Ventoy2Disk_fedora.sh" || return 1
  download_patch "VentoyWorker_fedora.sh" || return 1

  log_ok "Fedora Ventoy patches ready."
}
