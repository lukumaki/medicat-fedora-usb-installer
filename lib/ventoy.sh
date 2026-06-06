#!/bin/bash

download_ventoy() {
  log_info "Detecting latest Ventoy version from SourceForge..."

  local latest
  latest=$(curl -s "$VENTOY_SF_URL" 2>/dev/null \
    | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)

  if [ -z "$latest" ]; then
    log_error "Could not detect Ventoy version (network issue?)"
    return 1
  fi

  log_info "Latest Ventoy version: $latest"

  local version="${latest#v}"
  local tarball="ventoy-${version}-linux.tar.gz"
  local url="https://sourceforge.net/projects/ventoy/files/${latest}/${tarball}/download"

  log_info "Downloading Ventoy..."
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would download: $url"
    return 0
  fi

  if ! wget --progress=dot:giga -O ventoy.tar.gz "$url"; then
    log_error "Failed to download Ventoy"
    return 1
  fi

  log_info "Extracting Ventoy..."
  if ! tar -xf ventoy.tar.gz; then
    log_error "Failed to extract Ventoy archive"
    rm -f ventoy.tar.gz
    return 1
  fi

  rm -rf "$VENTOY_DIR"
  mkdir -p "$VENTOY_DIR"

  if ! mv ventoy-*/* "$VENTOY_DIR"/ 2>/dev/null; then
    log_error "Failed to move Ventoy files"
    rm -f ventoy.tar.gz
    return 1
  fi

  rm -f ventoy.tar.gz
  log_ok "Ventoy ready in $VENTOY_DIR."
}

prepare_ventoy() {
  if [ ! -d "$VENTOY_DIR" ]; then
    download_ventoy || exit 1
  else
    log_ok "Ventoy folder already exists (cached)."
  fi
}

install_ventoy() {
  export VTOY_NO_PROMPT=1

  if [ "$INSTALL_VENTOY" -ne 1 ]; then
    log_debug "Ventoy installation skipped (MODE=$MODE)."
    return 0
  fi

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

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would install Ventoy ($([ "$use_gpt" -eq 1 ] && echo GPT || echo MBR)) on $TARGET"
    return 0
  fi

  local ventoy_output
  if [ "$use_gpt" -eq 1 ]; then
    ventoy_output=$(sudo "$PATCH_DIR/Ventoy2Disk_fedora.sh" -I -g "$TARGET" 2>&1)
  else
    ventoy_output=$(sudo "$PATCH_DIR/Ventoy2Disk_fedora.sh" -I "$TARGET" 2>&1)
  fi

  echo "$ventoy_output" >> "$LOG_FILE"

  if ! echo "$ventoy_output" | grep -qi "success"; then
    log_error "Ventoy installation failed. Check log: $LOG_FILE"
    return 1
  fi

  log_ok "Ventoy installed on $TARGET."
}
