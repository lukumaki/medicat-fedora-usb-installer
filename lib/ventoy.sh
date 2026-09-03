#!/bin/bash
# ventoy.sh — Ventoy download, preparation and installation (v7.1 PRO)

# ---------------------------------------------------------
# Download latest Ventoy release from SourceForge
# ---------------------------------------------------------
download_ventoy() {

  log_info "Detecting latest Ventoy version from SourceForge..."

  local latest
  latest=$(curl -sL "$VENTOY_SF_URL" 2>/dev/null \
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

  # Work inside a scratch directory under the cache. The previous version
  # downloaded and extracted into the caller's current directory, which
  # littered whatever directory the user happened to launch from.
  local workdir="$CACHE_DIR/.ventoy_download"
  rm -rf "$workdir"
  mkdir -p "$workdir"

  local archive="$workdir/ventoy.tar.gz"

  if ! wget --progress=dot:giga -O "$archive" "$url"; then
    log_error "Failed to download Ventoy"
    rm -rf "$workdir"
    log_diagnostics
    return 1
  fi

  log_info "Extracting Ventoy..."
  if ! tar -xf "$archive" -C "$workdir"; then
    log_error "Failed to extract Ventoy archive"
    rm -rf "$workdir"
    log_diagnostics
    return 1
  fi

  # Find extracted folder
  local extracted
  extracted=$(find "$workdir" -maxdepth 1 -type d -name "ventoy-*" -print -quit)

  if [ -z "$extracted" ]; then
    log_error "Extraction succeeded but no Ventoy directory found."
    rm -rf "$workdir"
    log_diagnostics
    return 1
  fi

  rm -rf "$VENTOY_DIR"
  mkdir -p "$(dirname "$VENTOY_DIR")"

  if ! mv "$extracted" "$VENTOY_DIR"; then
    log_error "Failed to move Ventoy files into $VENTOY_DIR"
    rm -rf "$workdir"
    log_diagnostics
    return 1
  fi

  rm -rf "$workdir"

  # Validate Ventoy folder
  if [ ! -f "$VENTOY_DIR/Ventoy2Disk.sh" ]; then
    log_error "Ventoy directory is missing Ventoy2Disk.sh."
    log_diagnostics
    return 1
  fi

  log_ok "Ventoy $latest ready in $VENTOY_DIR."
}

# ---------------------------------------------------------
# Prepare Ventoy folder (download if missing)
# ---------------------------------------------------------
prepare_ventoy() {

  if [ "$INSTALL_VENTOY" -ne 1 ]; then
    log_debug "Skipping Ventoy preparation (INSTALL_VENTOY=0)."
    return 0
  fi

  # A directory alone is not proof of a usable install: a previous run may
  # have been interrupted midway through extraction.
  if [ -f "$VENTOY_DIR/Ventoy2Disk.sh" ]; then
    log_ok "Ventoy folder already exists (cached)."
    return 0
  fi

  if [ -d "$VENTOY_DIR" ] && [ "$DRY_RUN" -ne 1 ]; then
    log_warn "Ventoy cache at $VENTOY_DIR is incomplete — re-downloading."
  fi

  download_ventoy
}

# ---------------------------------------------------------
# Install Ventoy to the USB device
# ---------------------------------------------------------
install_ventoy() {

  if [ "$INSTALL_VENTOY" -ne 1 ]; then
    log_debug "Ventoy installation skipped (MODE=$MODE)."
    return 0
  fi

  #
  # Partitioning mode
  #
  local use_gpt=1
  if [ "$FORCE_MBR" -eq 1 ]; then
    use_gpt=0
    log_info "Using MBR partitioning."
  else
    use_gpt=1
    log_info "Using GPT partitioning."
  fi

  #
  # DRY RUN
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would install Ventoy ($([ "$use_gpt" -eq 1 ] && echo GPT || echo MBR)) on $TARGET"
    return 0
  fi

  local wrapper="$PATCH_DIR/Ventoy2Disk_fedora.sh"
  if [ ! -x "$wrapper" ]; then
    log_error "Fedora Ventoy wrapper not found or not executable: $wrapper"
    log_diagnostics
    return 1
  fi

  #
  # Actual installation
  #
  local ventoy_output
  local rc=0

  # The wrapper needs VENTOY_DIR and VTOY_NO_PROMPT as root. `sudo -E` is
  # refused outright by common sudoers configurations (env_reset without
  # SETENV), so pass them through `env` instead, which always works.
  local sudo_env=(sudo env "VTOY_NO_PROMPT=1" "VENTOY_DIR=$VENTOY_DIR")

  if [ "$use_gpt" -eq 1 ]; then
    ventoy_output=$("${sudo_env[@]}" "$wrapper" -I -g "$TARGET" 2>&1) || rc=$?
  else
    ventoy_output=$("${sudo_env[@]}" "$wrapper" -I "$TARGET" 2>&1) || rc=$?
  fi

  printf '%s\n' "$ventoy_output" >> "$LOG_FILE"

  if [ "$rc" -ne 0 ]; then
    log_error "Ventoy installation exited with status $rc. Check log: $LOG_FILE"
    log_diagnostics
    return 1
  fi

  if ! printf '%s' "$ventoy_output" | grep -qi "success"; then
    log_error "Ventoy installation did not report success. Check log: $LOG_FILE"
    log_diagnostics
    return 1
  fi

  log_ok "Ventoy installed on $TARGET."
}
