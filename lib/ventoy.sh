#!/bin/bash
# ventoy.sh — Ventoy download, preparation and installation (v7.1 PRO)

# ---------------------------------------------------------
# Download latest Ventoy release from SourceForge
# ---------------------------------------------------------
download_ventoy() {

  if [ "$MODE" = "update" ]; then
    log_debug "Skipping Ventoy download (MODE=update)."
    return 0
  fi

  log_info "Detecting latest Ventoy version from SourceForge..."

  local latest
  latest=$(curl -s "$VENTOY_SF_URL" 2>/dev/null \
    | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -V \
    | tail -n 1 || true)

  if [ -z "$latest" ]; then
    log_error "Could not detect Ventoy version (network issue?)"
    log_diagnostics
    return 1
  fi

  log_info "Latest Ventoy version detected: $latest"

  local version="${latest#v}"
  local tarball="ventoy-${version}-linux.tar.gz"
  local url="https://sourceforge.net/projects/ventoy/files/${latest}/${tarball}/download"

  log_info "Downloading Ventoy..."
  log_debug "URL: $url"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would download: $url"
    return 0
  fi

  if ! wget --progress=dot:giga -O ventoy.tar.gz "$url"; then
    log_error "Failed to download Ventoy"
    log_diagnostics
    return 1
  fi

  log_info "Extracting Ventoy..."
  if ! tar -xf ventoy.tar.gz; then
    log_error "Failed to extract Ventoy archive"
    rm -f ventoy.tar.gz
    log_diagnostics
    return 1
  fi

  # Find extracted folder
  local extracted
  extracted=$(find . -maxdepth 1 -type d -name "ventoy-*" | head -n 1)

  if [ -z "$extracted" ]; then
    log_error "Extraction succeeded but no Ventoy directory found."
    log_diagnostics
    return 1
  fi

  rm -rf "$VENTOY_DIR"
  mkdir -p "$VENTOY_DIR"

  if ! mv "$extracted"/* "$VENTOY_DIR"/ 2>/dev/null; then
    log_error "Failed to move Ventoy files"
    rm -f ventoy.tar.gz
    log_diagnostics
    return 1
  fi

  rm -f ventoy.tar.gz
  rm -rf "$extracted"

  # Validate Ventoy folder
  if [ ! -f "$VENTOY_DIR/Ventoy2Disk.sh" ] && [ ! -f "$VENTOY_DIR/Ventoy2Disk_fedora.sh" ]; then
    log_error "Ventoy directory is missing required scripts."
    log_diagnostics
    return 1
  fi

  log_ok "Ventoy ready in $VENTOY_DIR."
}

# ---------------------------------------------------------
# Prepare Ventoy folder (download if missing)
# ---------------------------------------------------------
prepare_ventoy() {

  if [ "$MODE" = "update" ]; then
    log_debug "Skipping Ventoy preparation (MODE=update)."
    return 0
  fi

  if [ ! -d "$VENTOY_DIR" ]; then
    download_ventoy || exit 1
  else
    log_ok "Ventoy folder already exists (cached)."
  fi
}

# ---------------------------------------------------------
# Install Ventoy to the USB device
# ---------------------------------------------------------
install_ventoy() {
  export VTOY_NO_PROMPT=1

  if [ "$INSTALL_VENTOY" -ne 1 ]; then
    log_debug "Ventoy installation skipped (MODE=$MODE)."
    return 0
  fi

  #
  # Partitioning mode
  #
  local use_gpt=1
  if [ "$FORCE_GPT" -eq 1 ]; then
    use_gpt=1
    log_info "Forcing GPT partitioning."
  elif [ "$FORCE_MBR" -eq 1 ]; then
    use_gpt=0
    log_info "Forcing MBR partitioning."
  else
    use_gpt=1
    log_info "Using default GPT partitioning."
  fi

  #
  # DRY RUN
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would install Ventoy ($([ "$use_gpt" -eq 1 ] && echo GPT || echo MBR)) on $TARGET"
    return 0
  fi

  #
  # Actual installation
  #
  local ventoy_output
  if [ "$use_gpt" -eq 1 ]; then
    ventoy_output=$(sudo "$PATCH_DIR/Ventoy2Disk_fedora.sh" -I -g "$TARGET" 2>&1)
  else
    ventoy_output=$(sudo "$PATCH_DIR/Ventoy2Disk_fedora.sh" -I "$TARGET" 2>&1)
  fi

  echo "$ventoy_output" >> "$LOG_FILE"

  if ! echo "$ventoy_output" | grep -qi "success"; then
    log_error "Ventoy installation failed. Check log: $LOG_FILE"
    log_diagnostics
    return 1
  fi

  log_ok "Ventoy installed on $TARGET."
}
