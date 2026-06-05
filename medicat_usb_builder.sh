#!/bin/bash
# MediCat USB Builder for Fedora (Ventoy + Smart Cache)
# Version: 6.1
# Author: Frixos + Copilot

set -euo pipefail

# ---------------------------------------------------------
# Global paths and config
# ---------------------------------------------------------
REPO_URL="https://github.com/lukumaki/medicat-fedora-usb-installer"
CACHE_DIR="$HOME/Medicat_USB_Cache"
LOG_FILE="$CACHE_DIR/medicat_usb_builder.log"
MEDICAT_DIR="$CACHE_DIR/medicat"
MNT_DIR="/mnt/medicat"

PATCH_DIR="$CACHE_DIR/ventoy_patches"
PATCH_URL="$REPO_URL/raw/main/patches"

VENTOY_DIR="$CACHE_DIR/ventoy"
CDN_URL="https://cdn.medicatusb.com/cdn.bat"

# Flags (default values)
UPDATE_ONLY=0
FORCE_UPDATE=0
SKIP_MEDICAT=0
FORCE_GPT=0
FORCE_MBR=0
DRY_RUN=0
USER_DECLINED_USB=0

TARGET=""
PART_DATA=""

# ---------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------
timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

log_raw() {
  echo "$@" | tee -a "$LOG_FILE"
}

log_debug() {
  echo "[$(timestamp)] [DEBUG] $@" | tee -a "$LOG_FILE"
}

log_info() {
  echo "[$(timestamp)] [INFO] $@" | tee -a "$LOG_FILE"
}

log_ok() {
  echo "[$(timestamp)] [OK] $@" | tee -a "$LOG_FILE"
}

log_error() {
  echo "[$(timestamp)] [ERROR] $@" | tee -a "$LOG_FILE" >&2
}

# ---------------------------------------------------------
# Trap cleanup
# ---------------------------------------------------------
cleanup() {
  local code=$?
  log_debug "Running cleanup trap (exit code: $code)"
  sudo umount "$MNT_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# ---------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --update-only)
        UPDATE_ONLY=1
        ;;
      --force-update)
        FORCE_UPDATE=1
        ;;
      --skip-medicat)
        SKIP_MEDICAT=1
        ;;
      --force-gpt)
        FORCE_GPT=1
        ;;
      --force-mbr)
        FORCE_MBR=1
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      *)
        log_error "Unknown argument: $1"
        exit 1
        ;;
    esac
    shift
  done
}

# ---------------------------------------------------------
# USB selection (device only, no mode decisions)
# ---------------------------------------------------------
select_usb_device() {
  log_info "Detecting removable USB devices..."

  mapfile -t usb_list < <(lsblk -o NAME,SIZE,MODEL,RM -nr | awk '$4 == 1 {print "/dev/"$1" "$2" "$3}')

  if [ ${#usb_list[@]} -eq 0 ]; then
    log_error "No removable USB devices detected."
    exit 1
  fi

  log_raw ""
  log_raw "Available USB devices:"
  log_raw ""

  local i=1
  for dev in "${usb_list[@]}"; do
    log_raw "  $i) $dev"
    ((i++))
  done

  log_raw ""
  read -rp "Select a USB device (1-${#usb_list[@]}): " choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#usb_list[@]} ]; then
    log_error "Invalid selection."
    exit 1
  fi

  TARGET=$(echo "${usb_list[$((choice-1))]}" | awk '{print $1}')
  PART_DATA="${TARGET}1"

  log_raw ""
  log_raw "You selected: $TARGET"
  read -rp "Proceed with this device? (y/N): " confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    USER_DECLINED_USB=0
  else
    USER_DECLINED_USB=1
  fi
}

# ---------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------
check_dependencies() {
  log_info "Checking system dependencies..."
  command -v rsync >/dev/null || { log_error "rsync not found"; exit 1; }
  command -v lsblk >/dev/null || { log_error "lsblk not found"; exit 1; }
  command -v mkntfs >/dev/null || { log_error "mkntfs not found (ntfs-3g)"; exit 1; }
  command -v curl >/dev/null || { log_error "curl not found"; exit 1; }
  command -v wget >/dev/null || { log_error "wget not found"; exit 1; }
  command -v 7z >/dev/null || { log_error "7z not found"; exit 1; }
  log_ok "Core dependencies found."
}

# ---------------------------------------------------------
# Ventoy patch preparation (Fedora-specific)
# ---------------------------------------------------------
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

  download_patch "Ventoy2Disk_fedora.sh" || return 1
  download_patch "VentoyWorker_fedora.sh" || return 1

  log_ok "Fedora Ventoy patches ready."
}

# ---------------------------------------------------------
# Ventoy download and preparation
# ---------------------------------------------------------
download_ventoy() {
  local LATEST
  LATEST=$(curl -s "https://sourceforge.net/projects/ventoy/files/" 2>/dev/null \
    | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)

  if [ -z "$LATEST" ]; then
    log_error "Could not detect Ventoy version (network issue?)"
    return 1
  fi

  log_info "Latest Ventoy version: $LATEST"

  local VERSION="${LATEST#v}"
  local TARBALL="ventoy-${VERSION}-linux.tar.gz"
  local URL="https://sourceforge.net/projects/ventoy/files/${LATEST}/${TARBALL}/download"

  log_info "Downloading Ventoy..."
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would download: $URL"
    return 0
  fi

  if ! wget --progress=dot:giga -O ventoy.tar.gz "$URL"; then
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
  log_ok "Ventoy ready."
}

prepare_ventoy() {
  if [ ! -d "$VENTOY_DIR" ]; then
    download_ventoy || return 1
  else
    log_ok "Ventoy folder already exists (cached)."
  fi

  log_info "Detecting latest Ventoy version..."
}

# ---------------------------------------------------------
# MediCat download
# ---------------------------------------------------------
download_medicat() {
  if [ "$FORCE_UPDATE" -eq 1 ]; then
    log_info "Force-update mode: Skipping MediCat archive download."
    return 0
  fi

  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$MEDICAT_DIR"
  fi
  cd "$MEDICAT_DIR" || return 1

  if find . -maxdepth 1 -name '*.7z' -quit | grep -q .; then
    log_ok "MediCat archive already present."
    cd - >/dev/null
    return 0
  fi

  log_info "Downloading cdn.bat..."
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would download: $CDN_URL"
  else
    if ! wget -q -O cdn.bat "$CDN_URL"; then
      log_error "Failed to download cdn.bat"
      cd - >/dev/null
      return 1
    fi
  fi

  FILE_NAME=$(grep -i 'FILE_NAME=' cdn.bat 2>/dev/null | sed -E 's/.*FILE_NAME=([^"]+)".*/\1/' || true)
  [ -z "$FILE_NAME" ] && FILE_NAME="Medicat.USB.v21.12.7z"

  log_info "Detected archive: $FILE_NAME"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would find best mirror and download: $FILE_NAME"
    cd - >/dev/null
    return 0
  fi

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

# ---------------------------------------------------------
# Extraction
# ---------------------------------------------------------
extract_medicat_to_cache() {
  if [ "$FORCE_UPDATE" -eq 1 ]; then
    if [ -d "$MEDICAT_DIR/extracted" ]; then
      log_ok "Force-update mode: Using existing extracted/ directory."
      return 0
    else
      log_error "Force-update mode: extracted/ directory not found at $MEDICAT_DIR/extracted"
      log_error "Please run without --force-update first to download and extract MediCat."
      return 1
    fi
  fi

  cd "$MEDICAT_DIR" || return 1

  FILE_NAME=$(find . -maxdepth 1 -name '*.7z' -print -quit)

  if [ -z "$FILE_NAME" ]; then
    log_error "No MediCat archive found"
    cd - >/dev/null
    return 1
  fi

  if [ -f ".extracted.ok" ]; then
    log_ok "MediCat already extracted."
    cd - >/dev/null
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would extract: $FILE_NAME"
    log_info "[DRY RUN] Would create: ./extracted/ directory"
    log_info "[DRY RUN] Would create: .extracted.ok marker"
    cd - >/dev/null
    return 0
  fi

  log_info "Extracting MediCat (progress enabled)..."
  mkdir -p extracted

  if ! 7z x -bsp1 -y -o"./extracted" "$FILE_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    log_error "Extraction failed"
    cd - >/dev/null
    return 1
  fi

  touch .extracted.ok
  log_ok "Extraction complete."

  cd - >/dev/null
}

# ---------------------------------------------------------
# Main install function (MODE-based)
# ---------------------------------------------------------
install_ventoy_and_format() {
  export VTOY_NO_PROMPT=1

  select_usb_device

  local MODE="install"

  if [ "$UPDATE_ONLY" -eq 1 ] || [ "$FORCE_UPDATE" -eq 1 ]; then
    MODE="update"
  fi

  if [ "$SKIP_MEDICAT" -eq 1 ] && [ "$MODE" != "update" ]; then
    MODE="ventoy"
  fi

  if [ "$USER_DECLINED_USB" -eq 1 ]; then
    MODE="skip"
  fi

  log_debug "Selected MODE: $MODE"

  if [ "$MODE" = "skip" ]; then
    log_info "User declined USB operation. Exiting."
    return 0
  fi

  local install_ventoy=0
  local install_medicat=0
  local do_format=0

  case "$MODE" in
    install)
      install_ventoy=1
      install_medicat=1
      do_format=1
      ;;
    update)
      install_ventoy=0
      install_medicat=1
      do_format=0
      ;;
    ventoy)
      install_ventoy=1
      install_medicat=0
      do_format=1
      ;;
    *)
      log_error "Unknown MODE: $MODE"
      return 1
      ;;
  esac

  log_debug "Actions: install_ventoy=$install_ventoy install_medicat=$install_medicat do_format=$do_format"

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

  if [ "$install_ventoy" -eq 1 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log_info "[DRY RUN] Would install Ventoy ($([ "$use_gpt" -eq 1 ] && echo GPT || echo MBR)) on $TARGET"
    else
      local ventoy_output
      if [ "$use_gpt" -eq 1 ]; then
        ventoy_output=$(sudo "$PATCH_DIR/Ventoy2Disk_fedora.sh" -I -g "$TARGET" 2>&1)
      else
        ventoy_output=$(sudo "$PATCH_DIR/Ventoy2Disk_fedora.sh" -I "$TARGET" 2>&1)
      fi

      echo "$ventoy_output" >> "$LOG_FILE"

      if ! echo "$ventoy_output" | grep -qi "successfully finished"; then
        log_error "Ventoy installation failed. Check log: $LOG_FILE"
        return 1
      fi

      log_ok "Ventoy installed on $TARGET."
    fi
  else
    log_debug "Ventoy installation skipped (MODE=$MODE)."
  fi

  if [ "$do_format" -eq 1 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log_info "[DRY RUN] Would format $PART_DATA as NTFS"
    else
      sudo umount "$TARGET" 2>/dev/null || true
      sudo umount "$PART_DATA" 2>/dev/null || true

      log_raw ""
      log_raw "⚠ WARNING: You are about to FORMAT $PART_DATA"
      log_raw "This will ERASE ALL DATA on the USB drive."
      log_raw ""
      log_raw "To continue, type: FORMAT"
      log_raw "To cancel, press Enter."
      log_raw ""

      read -rp "> " confirm_format
      case "$confirm_format" in
        FORMAT)
          log_info "Proceeding with format..."
          if ! sudo mkntfs --fast --label Medicat "$PART_DATA"; then
            log_error "Failed to format $PART_DATA"
            return 1
          fi
          log_ok "Format complete."
          ;;
        *)
          log_info "Format cancelled by user."
          exit 0
          ;;
      esac
    fi
  else
    log_debug "Format skipped (MODE=$MODE)."
  fi

  if [ "$install_medicat" -eq 1 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log_info "[DRY RUN] Would mount ${TARGET}1 to $MNT_DIR"
      log_info "[DRY RUN] Would copy/update MediCat files from $MEDICAT_DIR/extracted/"
      return 0
    fi

    sudo mkdir -p "$MNT_DIR"

    if ! sudo mount "${TARGET}1" "$MNT_DIR"; then
      log_error "Failed to mount ${TARGET}1 to $MNT_DIR"
      return 1
    fi

    local rsync_opts="-avh --info=progress2"
    if [ "$MODE" = "update" ]; then
      rsync_opts="$rsync_opts --update"
      log_info "Updating existing MediCat installation..."
    else
      log_info "Performing full MediCat installation..."
    fi

    log_debug "Running rsync with options: $rsync_opts"

    if ! rsync $rsync_opts "$MEDICAT_DIR/extracted/" "$MNT_DIR/"; then
      log_error "rsync copy failed"
      sudo umount "$MNT_DIR" 2>/dev/null || true
      return 1
    fi

    log_ok "MediCat copy/update complete."
    sudo umount "$MNT_DIR" 2>/dev/null || true
  else
    log_debug "MediCat operation skipped (MODE=$MODE)."
  fi
}

# ---------------------------------------------------------
# Main
# ---------------------------------------------------------
main() {
  mkdir -p "$CACHE_DIR"
  : > "$LOG_FILE"
  log_debug "Logging initialized: $LOG_FILE"

  log_raw ""
  log_raw "=============================================="
  log_raw "  MediCat USB Builder for Fedora v6.1"
  log_raw "=============================================="
  log_raw ""

  parse_args "$@"
  check_dependencies
  ensure_patches
  prepare_ventoy
  download_medicat
  extract_medicat_to_cache

  install_ventoy_and_format

  log_ok "All operations completed."
}

main "$@"
