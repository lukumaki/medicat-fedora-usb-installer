#!/bin/bash

ensure_patches() {
  log_info "Checking Fedora Ventoy patches..."
  mkdir -p "$PATCH_DIR"

  download_patch() {
    local file="$1"
    local url="$PATCH_URL/$file"

    if [ -f "$PATCH_DIR/$file" ]; then
      log_ok "$file already present."
      return 0
    fi

    log_info "Downloading $file..."

    if [ "$DRY_RUN" -eq 1 ]; then
      log_info "[DRY RUN] Would download: $url"
      return 0
    fi

    if ! curl -s -L -o "$PATCH_DIR/$file" "$url"; then
      log_error "Failed to download $file"
      return 1
    fi

    chmod +x "$PATCH_DIR/$file"
    log_ok "$file downloaded."
  }

  download_patch "Ventoy2Disk_fedora.sh" || exit 1
  download_patch "VentoyWorker_fedora.sh" || exit 1

  log_ok "Fedora Ventoy patches ready."
}
