#!/bin/bash

# medicat_download.sh
# Fully MODE-aware MediCat archive download logic (v7.1 PRO)

# Absolute path of the downloaded archive; consumed by medicat_extract.sh.
MEDICAT_ARCHIVE="${MEDICAT_ARCHIVE:-}"

# ---------------------------------------------------------
# Locate an already-downloaded MediCat archive in the cache
# ---------------------------------------------------------
find_cached_archive() {
  # `-print -quit` is required: `-quit` is an action, so it suppresses the
  # implicit -print and the plain `-quit` form never outputs anything.
  find "$MEDICAT_DIR" -maxdepth 1 -type f -name '*.7z' -print -quit 2>/dev/null
}

download_medicat() {

  #
  # Respect MODE and flags
  #
  if [ "$INSTALL_MEDICAT" -ne 1 ]; then
    log_debug "Skipping MediCat download (INSTALL_MEDICAT=0)."
    return 0
  fi

  if [ "$MODE" = "update" ]; then
    log_info "MODE=update → using the MediCat files already in the cache."
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would download the MediCat archive into $MEDICAT_DIR"
    return 0
  fi

  mkdir -p "$MEDICAT_DIR"

  #
  # If an archive already exists, reuse it
  #
  local cached
  cached="$(find_cached_archive)"
  if [ -n "$cached" ]; then
    MEDICAT_ARCHIVE="$cached"
    log_ok "MediCat archive already present: $MEDICAT_ARCHIVE"
    return 0
  fi

  local cdn_file="$MEDICAT_DIR/cdn.bat"

  #
  # Download cdn.bat (mirror list + FILE_NAME)
  #
  log_info "Downloading cdn.bat..."
  if ! wget -q -O "$cdn_file" "$CDN_URL"; then
    log_error "Failed to download cdn.bat from $CDN_URL"
    rm -f "$cdn_file"
    log_diagnostics
    return 1
  fi

  #
  # Extract FILE_NAME from cdn.bat
  # (handles both `set FILE_NAME=x.7z` and `set "FILE_NAME=x.7z"`, CRLF included)
  #
  local file_name
  file_name=$(grep -io 'FILE_NAME=[^"[:space:]]*' "$cdn_file" 2>/dev/null \
    | head -n1 | cut -d= -f2- | tr -d '\r' || true)

  if [ -z "$file_name" ]; then
    log_warn "FILE_NAME not found in cdn.bat. Falling back to default."
    file_name="Medicat.USB.v21.12.7z"
  fi

  log_info "Detected archive: $file_name"

  #
  # Select fastest mirror
  #
  local best_url=""
  local best_speed="0"
  local mirror_count=0
  local line url speed

  log_info "Testing mirror speeds..."

  while read -r line; do
    url=$(echo "$line" | grep -oP 'https?://[^"[:space:]]+' || true)
    [ -z "$url" ] && continue

    mirror_count=$((mirror_count + 1))
    url=${url//%FILE_NAME%/$file_name}

    log_debug "Testing: $url"
    speed=$(curl -L --max-time 3 -w "%{speed_download}" -o /dev/null -s "$url" 2>/dev/null || echo 0)
    [ -z "$speed" ] && speed=0
    log_debug "Speed: $speed bytes/sec"

    if (( $(echo "$speed > $best_speed" | bc -l) )); then
      best_speed="$speed"
      best_url="$url"
      log_debug "New best mirror: $best_url"
    fi
  done < <(grep -i 'SERVER[0-9]*=' "$cdn_file")

  if [ "$mirror_count" -eq 0 ]; then
    log_error "cdn.bat contains no SERVER entries."
    log_diagnostics
    return 1
  fi

  if [ -z "$best_url" ]; then
    log_error "No reachable mirror found in cdn.bat"
    log_diagnostics
    return 1
  fi

  #
  # Download MediCat archive from best mirror
  #
  local target="$MEDICAT_DIR/$file_name"
  local partial="$target.partial"

  log_info "Downloading MediCat from fastest server..."
  log_debug "URL: $best_url"

  # Download to *.partial first so an interrupted run never leaves a
  # truncated *.7z behind that the cache check would happily reuse.
  if ! wget --progress=dot:giga -c -O "$partial" "$best_url"; then
    log_error "Failed to download MediCat archive"
    rm -f "$partial"
    log_diagnostics
    return 1
  fi

  if [ ! -s "$partial" ]; then
    log_error "Downloaded archive is empty or invalid."
    rm -f "$partial"
    log_diagnostics
    return 1
  fi

  mv -f "$partial" "$target"
  MEDICAT_ARCHIVE="$target"

  log_ok "MediCat archive downloaded: $MEDICAT_ARCHIVE"
}
