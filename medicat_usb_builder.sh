#!/bin/bash
# MediCat USB Builder for Fedora (Ventoy + Smart Cache)
# Version: 4.3 (Professional Clean Build - B6)
# Author: Frixos + Copilot

set -euo pipefail

# ---------------------------------------------------------
# Global paths
# ---------------------------------------------------------
REPO_URL="https://github.com/lukumaki/medicat-fedora-usb-installer"
PATCH_URL="$REPO_URL/raw/main/patch"
CDN_URL="https://raw.githubusercontent.com/mon5termatt/medicat_installer/main/download/cdn.bat"

# Patches + Ventoy + MediCat cache stored in HOME
MEDICAT_DIR="$HOME/Medicat_USB_Cache"
VENTOY_DIR="$MEDICAT_DIR/ventoy"
PATCH_DIR="$MEDICAT_DIR/patch"

MNT_DIR="/mnt/medicat"
LOG_FILE=""  # Will be set after MEDICAT_DIR is created

# ---------------------------------------------------------
# CLI flags
# ---------------------------------------------------------
SKIP_VENTOY=0
SKIP_MEDICAT=0
UPDATE_ONLY=0
FORCE_MBR=0
FORCE_GPT=0
DRY_RUN=0
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-ventoy)   SKIP_VENTOY=1; SKIP_MEDICAT=0 ;;
    --skip-medicat)  SKIP_MEDICAT=1; SKIP_VENTOY=0 ;;
    --update-only)   UPDATE_ONLY=1; SKIP_VENTOY=1; SKIP_MEDICAT=0 ;;
    --force-mbr)     FORCE_MBR=1 ;;
    --force-gpt)     FORCE_GPT=1 ;;
    --dry-run)       DRY_RUN=1 ;;
    --quiet)         QUIET=1 ;;
  esac
  shift
done

# ---------------------------------------------------------
# Colours
# ---------------------------------------------------------
NumColours=$(tput colors 2>/dev/null || echo 0)

if [ "$NumColours" -ge 8 ]; then
  redB="\033[1;31m"
  yellowB="\033[1;33m"
  blueB="\033[1;34m"
  greenB="\033[1;32m"
  resetC="\033[0m"
else
  redB=""; yellowB=""; blueB=""; greenB=""; resetC=""
fi

cecho() { printf "%b%s%b\n" "$1" "$2" "$resetC"; }

# ---------------------------------------------------------
# Logging
# ---------------------------------------------------------
log_raw() {
  [ "$QUIET" -eq 1 ] && return 0
  local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $*" | tee -a "$LOG_FILE"
}

log_info()  { [ "$QUIET" -eq 0 ] && cecho "$yellowB" "[INFO] $*";  log_raw "[INFO] $*"; }
log_ok()    { [ "$QUIET" -eq 0 ] && cecho "$greenB"  "[OK] $*";    log_raw "[OK] $*"; }
log_warn()  { [ "$QUIET" -eq 0 ] && cecho "$redB"    "[WARN] $*";  log_raw "[WARN] $*"; }
log_error() { cecho "$redB"    "[ERROR] $*"; log_raw "[ERROR] $*"; }
log_debug() { [ "$QUIET" -eq 0 ] && cecho "$blueB" "[DEBUG] $*"; log_raw "[DEBUG] $*"; }

out()    { [ "$QUIET" -eq 0 ] && cecho "$blueB" "$*"; }
prompt() { [ "$QUIET" -eq 0 ] && cecho "$yellowB" "$1"; }

YesNo() {
  prompt "$1"
  read -rp "> " ans
  case "$ans" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------
# Cleanup trap
# ---------------------------------------------------------
cleanup() {
  local exit_code=$?
  log_debug "Running cleanup trap (exit code: $exit_code)"
  if mountpoint -q "$MNT_DIR" 2>/dev/null; then
    log_info "Unmounting $MNT_DIR..."
    sudo umount "$MNT_DIR" 2>/dev/null || log_warn "Failed to unmount $MNT_DIR"
  fi
  exit $exit_code
}
trap cleanup EXIT INT TERM

# ---------------------------------------------------------
# Initialize logging
# ---------------------------------------------------------
init_logging() {
  if [ "$DRY_RUN" -eq 1 ]; then
    mkdir -p /tmp/medicat_dry_run
    LOG_FILE="/tmp/medicat_dry_run/medicat_usb_builder.log"
    log_debug "[DRY RUN] Logging to: $LOG_FILE"
  else
    mkdir -p "$MEDICAT_DIR"
    LOG_FILE="$MEDICAT_DIR/medicat_usb_builder.log"
    log_debug "Logging initialized: $LOG_FILE"
  fi
}

# ---------------------------------------------------------
# Banner
# ---------------------------------------------------------
show_banner() {
  echo ""
  echo "=============================================="
  echo "  MediCat USB Builder for Fedora (v4.3)"
  echo "=============================================="
  echo ""
  [ "$DRY_RUN" -eq 1 ] && echo "⚠️  DRY RUN MODE - No changes will be made"
  if [ "$UPDATE_ONLY" -eq 1 ]; then
    echo "🔄 UPDATE-ONLY mode - Will update existing MediCat"
  elif [ "$SKIP_VENTOY" -eq 1 ]; then
    echo "📦 SKIP-VENTOY mode - Will install only MediCat"
  elif [ "$SKIP_MEDICAT" -eq 1 ]; then
    echo "🚀 SKIP-MEDICAT mode - Will install only Ventoy"
  fi
}

# ---------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------
check_system_dependencies() {
  log_info "Checking system dependencies..."
  
  local missing_deps=()
  for cmd in wget curl rsync bc; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -gt 0 ]; then
    log_warn "Missing commands: ${missing_deps[*]}"
    log_info "Proceeding with full dependency installation..."
    install_dependencies || return 1
  else
    log_ok "Core dependencies found."
  fi

  for cmd in 7z mkntfs lsblk; do
    if ! command -v "$cmd" &>/dev/null; then
      log_warn "Missing: $cmd (will attempt install)"
      install_dependencies || return 1
      break
    fi
  done
}

# ---------------------------------------------------------
# Dependencies
# ---------------------------------------------------------
install_dependencies() {
  log_info "Installing required packages..."
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would run: sudo dnf install -y wget curl unzip rsync exfatprogs ntfs-3g p7zip p7zip-plugins bc"
  else
    if ! sudo dnf install -y wget curl unzip rsync exfatprogs ntfs-3g p7zip p7zip-plugins bc; then
      log_error "Failed to install dependencies"
      return 1
    fi
  fi
  log_ok "Dependencies installed."
}

# ---------------------------------------------------------
# Ventoy patches
# ---------------------------------------------------------
ensure_patches() {
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$PATCH_DIR"
  fi

  download_patch() {
    local file="$1"
    if [ ! -f "$PATCH_DIR/$file" ]; then
      log_info "Downloading $file..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[DRY RUN] Would download: $PATCH_URL/$file"
      else
        if ! curl -s -L -o "$PATCH_DIR/$file" "$PATCH_URL/$file"; then
          log_error "Failed to download $file"
          return 1
        fi
        chmod +x "$PATCH_DIR/$file"
      fi
    else
      log_ok "$file already present."
    fi
  }

  log_info "Checking Fedora Ventoy patches..."
  download_patch "Ventoy2Disk_fedora.sh" || return 1
  download_patch "VentoyWorker_fedora.sh" || return 1
}

# ---------------------------------------------------------
# Ventoy download
# ---------------------------------------------------------
download_ventoy() {
  log_info "Detecting latest Ventoy version..."
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
  else
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
  fi

  log_ok "Ventoy ready."
}

prepare_ventoy() {
  if [ ! -d "$VENTOY_DIR" ]; then
    download_ventoy || return 1
  else
    log_ok "Ventoy folder already exists (cached)."
  fi
}

# ---------------------------------------------------------
# MediCat download
# ---------------------------------------------------------
download_medicat() {
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

  out "Extracting MediCat (progress enabled)..."
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
# USB selection
# ---------------------------------------------------------
select_usb() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Skipping USB device selection"
    TARGET="/dev/test_dry_run"
    PART_DATA="${TARGET}1"
    return 0
  fi

  prompt "Please plug your USB now and press Enter..."
  read -r _

  out "Available devices:"
  if ! lsblk --nodeps --output "NAME,SIZE,VENDOR,MODEL,SERIAL" 2>/dev/null | grep -v loop; then
    log_error "Failed to list block devices"
    return 1
  fi

  prompt "Enter device name (e.g. sdb):"
  read -r letter

  TARGET="/dev/$letter"
  PART_DATA="${TARGET}1"

  if [ ! -b "$TARGET" ]; then
    log_error "$TARGET does not exist."
    return 1
  fi

  # Verify it's removable media
  if [ ! -f "/sys/block/$letter/removable" ]; then
    log_warn "$letter does not appear to be a removable device"
  fi

  if [ "$(cat /sys/block/"$letter"/removable 2>/dev/null || echo 0)" -ne 1 ]; then
    log_warn "$letter may not be removable media (use with caution)"
  fi

  echo ""
  echo "Install MediCat to $TARGET ? (y/N)"
  echo "(type 'yes' only for fresh/full installation,"
  echo " for all other flags type No or press Enter)"
  echo ""

  read -rp "> " ans
  case "$ans" in
      yes|YES|Yes|y|Y) ;;  # proceed
      *) 
        log_info "Skipping installation to USB (operating in cache-only mode)."
        SKIP_VENTOY=1
        SKIP_MEDICAT=1
        ;;
  esac
}

# ---------------------------------------------------------
# Ventoy detection
# ---------------------------------------------------------
has_existing_ventoy() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log_debug "[DRY RUN] Skipping Ventoy detection check"
    return 1
  fi

  local part="${1}1"
  local tmp
  
  tmp=$(mktemp -d) || {
    log_error "Failed to create temporary directory"
    return 1
  }
  trap "rmdir '$tmp' 2>/dev/null || true" RETURN

  if sudo mount "$part" "$tmp" 2>/dev/null; then
    if [ -d "$tmp/ventoy" ] || [ -f "$tmp/ventoy.json" ]; then
      sudo umount "$tmp" 2>/dev/null || true
      return 0
    fi
    sudo umount "$tmp" 2>/dev/null || true
  fi

  return 1
}

# ---------------------------------------------------------
# Install Ventoy + format
# ---------------------------------------------------------
install_ventoy_and_format() {
  export VTOY_NO_PROMPT=1

  if [ "$SKIP_VENTOY" -eq 1 ]; then
    log_info "Skipping Ventoy installation."
  else
    if has_existing_ventoy "$TARGET"; then
      if YesNo "Existing Ventoy detected. Keep it?"; then
        log_ok "Keeping existing Ventoy."
      else
        log_info "Reinstalling Ventoy."
      fi
    fi
  fi

  if [ "$SKIP_VENTOY" -eq 0 ]; then
    local use_gpt=0

    if [ "$FORCE_GPT" -eq 1 ]; then
      use_gpt=1
    elif [ "$FORCE_MBR" -eq 1 ]; then
      use_gpt=0
    else
      if [ "$DRY_RUN" -eq 0 ]; then
        YesNo "Use GPT instead of MBR?" && use_gpt=1
      else
        log_info "[DRY RUN] Assuming MBR for testing purposes"
        use_gpt=0
      fi
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      log_info "[DRY RUN] Would install Ventoy with $([ "$use_gpt" -eq 1 ] && echo "GPT" || echo "MBR")"
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

      log_ok "Ventoy installed."
    fi
  fi

  # Skip format if UPDATE_ONLY mode is active
  if [ "$UPDATE_ONLY" -eq 1 ]; then
    log_info "Update-only mode: Skipping format."
  else
    if [ "$DRY_RUN" -eq 0 ]; then
      sudo umount "$TARGET" 2>/dev/null || true
      sudo umount "${TARGET}1" 2>/dev/null || true
    fi
    
    if [ "$DRY_RUN" -eq 1 ]; then
      log_info "[DRY RUN] Would format: $PART_DATA as NTFS"
    else
      echo ""
      echo "⚠ WARNING: You are about to FORMAT $PART_DATA"
      echo "This will ERASE ALL DATA on the USB drive."
      echo ""
      echo "To continue, type: FORMAT"
      echo "To cancel, press Enter."
      echo ""

      read -rp "> " confirm_format
      case "$confirm_format" in
          FORMAT) 
              log_info "Proceeding with format..."
              if ! sudo mkntfs --fast --label Medicat "$PART_DATA"; then
                log_error "Failed to format $PART_DATA"
                return 1
              fi
              ;;
          *)
              log_info "Format cancelled by user."
              exit 0
              ;;
      esac
    fi
  fi
}

# ---------------------------------------------------------
# Copy MediCat to USB
# ---------------------------------------------------------
copy_medicat_to_usb() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would mount ${TARGET}1 to $MNT_DIR"
    log_info "[DRY RUN] Would copy: $MEDICAT_DIR/extracted/ → $MNT_DIR/"
    return 0
  fi

  sudo mkdir -p "$MNT_DIR"
  
  if ! sudo mount "${TARGET}1" "$MNT_DIR"; then
    log_error "Failed to mount ${TARGET}1 to $MNT_DIR"
    return 1
  fi

  out "Copying MediCat to USB..."

  local rsync_opts="-avh --info=progress2"
  [ "$UPDATE_ONLY" -eq 1 ] && rsync_opts="$rsync_opts --update"

  log_debug "Running rsync with options: $rsync_opts"
  
  if ! rsync $rsync_opts "$MEDICAT_DIR/extracted/" "$MNT_DIR/"; then
    log_error "rsync copy failed"
    sudo umount "$MNT_DIR" 2>/dev/null || true
    return 1
  fi

  log_ok "Copy complete."
}

# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------
init_logging
show_banner

log_info "Starting MediCat USB Builder."
[ "$DRY_RUN" -eq 1 ] && log_warn "Dry run mode - no changes will be made"

check_system_dependencies || exit 1

# Conditionally prepare Ventoy
if [ "$SKIP_MEDICAT" -eq 1 ]; then
  log_info "Skipping MediCat preparation (--skip-medicat mode)."
  ensure_patches || exit 1
  prepare_ventoy || exit 1
else
  ensure_patches || exit 1
  prepare_ventoy || exit 1
  download_medicat || exit 1
  extract_medicat_to_cache || exit 1
fi

# Conditionally prepare MediCat
if [ "$SKIP_VENTOY" -eq 1 ]; then
  log_info "Skipping Ventoy preparation (--skip-ventoy mode)."
else
  log_debug "Ventoy preparation already handled."
fi

select_usb || exit 1

if [ "$SKIP_VENTOY" -eq 0 ] || [ "$SKIP_MEDICAT" -eq 0 ]; then
  install_ventoy_and_format || exit 1
  
  if [ "$SKIP_MEDICAT" -eq 0 ]; then
    copy_medicat_to_usb || exit 1
  fi
  
  echo ""
  echo "=============================================="
  echo "  MediCat USB installation completed!"
  echo "=============================================="
  if [ "$DRY_RUN" -eq 1 ]; then
    log_warn "Dry run completed (no changes made)"
  else
    log_ok "MediCat USB installation completed successfully."
  fi
else
  log_ok "Installation skipped. Cache prepared for future use."
fi

