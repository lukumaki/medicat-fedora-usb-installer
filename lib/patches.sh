#!/bin/bash
# patches.sh — Fedora Ventoy patch management (v7.1 PRO)
#
# The wrappers ship with this repository, so the local copies under patch/
# are authoritative. Downloading is only a fallback for installations that
# were copied without the patch/ directory.

PATCH_FILES=("Ventoy2Disk_fedora.sh" "VentoyWorker_fedora.sh")

ensure_patches() {

  #
  # MODE CHECK
  #
  if [ "$INSTALL_VENTOY" -ne 1 ]; then
    log_debug "Skipping Ventoy patch setup (INSTALL_VENTOY=0)."
    return 0
  fi

  log_info "Preparing Fedora Ventoy patches..."
  log_debug "Patch directory: $PATCH_DIR"

  #
  # DRY RUN
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would install patch wrappers into $PATCH_DIR"
    return 0
  fi

  mkdir -p "$PATCH_DIR"

  local local_patch_dir="$PROJECT_ROOT/patch"
  local file

  for file in "${PATCH_FILES[@]}"; do
    if [ -f "$local_patch_dir/$file" ]; then
      # Always refresh from the repository copy so an updated checkout is
      # not shadowed by a stale wrapper left in the cache.
      cp -f "$local_patch_dir/$file" "$PATCH_DIR/$file"
      chmod +x "$PATCH_DIR/$file"
      log_debug "Installed local patch: $file"
    else
      download_patch "$file" || return 1
    fi
  done

  log_ok "Fedora Ventoy patches ready in $PATCH_DIR."
}

# ---------------------------------------------------------
# Fallback: download a single patch file from the repository
# ---------------------------------------------------------
download_patch() {
  local file="$1"

  if [ -z "${PATCH_URL:-}" ]; then
    log_error "PATCH_URL is not set and $file is missing locally."
    log_diagnostics
    return 1
  fi

  local url="$PATCH_URL/$file"
  local dest="$PATCH_DIR/$file"

  log_info "Downloading $file..."
  log_debug "URL: $url"

  # -f makes curl fail on HTTP errors. Without it a GitHub 404 page is saved
  # as the "patch": non-empty, chmod +x, and executed as an HTML file.
  if ! curl -fsSL -o "$dest" "$url"; then
    log_error "Failed to download $file from $url"
    rm -f "$dest"
    log_diagnostics
    return 1
  fi

  if [ ! -s "$dest" ]; then
    log_error "Downloaded $file but the file is empty."
    rm -f "$dest"
    log_diagnostics
    return 1
  fi

  # Sanity check: a shell wrapper must start with a shebang.
  if ! head -c 2 "$dest" | grep -q '#!'; then
    log_error "Downloaded $file does not look like a shell script (wrong patch_url?)."
    rm -f "$dest"
    log_diagnostics
    return 1
  fi

  chmod +x "$dest"
  log_ok "$file downloaded and validated."
}
