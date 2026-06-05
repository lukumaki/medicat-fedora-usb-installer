#!/bin/bash

download_medicat() {

  # Skip download entirely in update mode
  if [ "$MODE" = "update" ]; then
    log_info "MODE=update → Skipping MediCat download step."
    return 0
  fi

  if [ "$FORCE_UPDATE" -eq 1 ]; then
    log_info "Force-update mode: Skipping MediCat archive download."
    return 0
  fi

  mkdir -p "$MEDICAT_DIR"
  cd "$MEDICAT_DIR" || return 1

  if find . -maxdepth 1 -name '*.7z' -quit | grep -q .; then
    log_ok "MediCat archive already present."
    cd - >/dev/null
    return 0
  fi

  log_info "Downloading cdn.bat..."
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would download: $CDN_URL"
    cd - >/dev/null
    return 0
  fi

  if ! wget -q -O cdn.bat "$CDN_URL"; then
    log_error "Failed to download cdn.bat"
    cd - >/dev/null
    return 1
  fi

  FILE_NAME=$(grep -i 'FILE_NAME=' cdn.bat 2>/dev/null | sed -E 's/.*FILE_NAME=([^"]+)".*/\1/' || true)
  [ -z "$FILE_NAME" ] && FILE_NAME="Medicat.USB.v21.12.7z"

  log_info "Detected archive: $FILE_NAME"

  local best_url=""
  local best_speed=0

  log_info "Testing mirror speeds..."
  while read -r line; do
    local url
    url=$(echo "$line" | grep -oP 'https?://[^"]+' || true)
    [ -z "$url" ] && continue
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

  if [ -z "$best_url" ]; then
    log_error "No valid server found"
    cd - >/dev/null
    return 1
  fi

  log_info "Downloading MediCat from fastest server..."
  log_debug "URL: $best_url"
  if ! wget --progress=dot:giga -O "$FILE_NAME" "$best_url"; then
    log_error "Failed to download MediCat archive"
    rm -f "$FILE_NAME"
    cd - >/dev/null
    return 1
  fi

  log_ok "MediCat archive downloaded."
  cd - >/dev/null
}
