#!/bin/bash

# medicat_download.sh
# Fully MODE-aware MediCat archive download logic (v7.1 PRO)

download_medicat() {

  #
  # Respect MODE and flags
  #
  if [ "$INSTALL_MEDICAT" -ne 1 ]; then
    log_debug "Skipping MediCat download (INSTALL_MEDICAT=0)."
    return 0
  fi

  if [ "$MODE" = "update" ]; then
    log_info "MODE=update → Skipping MediCat download step."
    return 0
  fi

  if [ "$FORCE_UPDATE" -eq 1 ]; then
    log_info "Force-update mode: Skipping MediCat archive download."
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would download MediCat archive."
    return 0
  fi

  #
  # Prepare directory
  #
  mkdir -p "$MEDICAT_DIR"
  cd "$MEDICAT_DIR" || return 1

  #
  # If archive already exists, reuse it
  #
  if find . -maxdepth 1 -name '*.7z' -quit | grep -q .; then
    log_ok "MediCat archive already present."
    cd - >/dev/null
    return 0
  fi

  #
  # Download cdn.bat (mirror list + FILE_NAME)
  #
  log_info "Downloading cdn.bat..."
  if ! wget -q -O cdn.bat "$CDN_URL"; then
    log_error "Failed to download cdn.bat"
    rm -f cdn.bat
    log_diagnostics
    cd - >/dev/null
    return 1
  fi

  #
  # Extract FILE_NAME from cdn.bat
  #
  FILE_NAME=$(grep -i 'FILE_NAME=' cdn.bat 2>/dev/null | sed -E 's/.*FILE_NAME=([^"]+)".*/\1/' || true)

  if [ -z "$FILE_NAME" ]; then
    log_warn "FILE_NAME not found in cdn.bat. Falling back to default."
    FILE_NAME="Medicat.USB.v21.12.7z"
  fi

  log_info "Detected archive: $FILE_NAME"

  #
  # Select fastest mirror
  #
  local best_url=""
  local best_speed="0"
  local mirror_count=0

  log_info "Testing mirror speeds..."

  while read -r line; do
    local url
    url=$(echo "$line" | grep -oP 'https?://[^"]+' || true)
    [ -z "$url" ] && continue

    mirror_count=$((mirror_count + 1))
    url=${url//%FILE_NAME%/$FILE_NAME}

    log_debug "Testing: $url"
    local speed
    speed=$(curl -L --max-time 3 -w "%{speed_download}" -o /dev/null -s "$url" 2>/dev/null || echo 0)
    log_debug "Speed: $speed bytes/sec"

    if (( $(echo "$speed > $best_speed" | bc -l) )); then
      best_speed="$speed"
      best_url="$url"
      log_debug "New best mirror: $best_url ($(echo "$speed / 1024 / 1024" | bc -l) MB/s)"
    fi
  done < <(grep -i 'SERVER[0-9]=' cdn.bat)

  if [ "$mirror_count" -eq 0 ]; then
    log_error "cdn.bat contains no SERVER entries."
    log_diagnostics
    cd - >/dev/null
    return 1
  fi

  if [ -z "$best_url" ]; then
    log_error "No valid server found in cdn.bat"
    log_diagnostics
    cd - >/dev/null
    return 1
  fi

  #
  # Download MediCat archive from best mirror
  #
  log_info "Downloading MediCat from fastest server..."
  log_debug "URL: $best_url"

  if ! wget --progress=dot:giga -O "$FILE_NAME" "$best_url"; then
    log_error "Failed to download MediCat archive"
    rm -f "$FILE_NAME"
    log_diagnostics
    cd - >/dev/null
    return 1
  fi

  #
  # Validate archive
  #
  if [ ! -s "$FILE_NAME" ]; then
    log_error "Downloaded archive is empty or invalid."
    rm -f "$FILE_NAME"
    log_diagnostics
    cd - >/dev/null
    return 1
  fi

  log_ok "MediCat archive downloaded: $FILE_NAME"
  cd - >/dev/null
}
