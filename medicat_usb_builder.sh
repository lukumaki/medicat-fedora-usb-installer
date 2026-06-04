#!/bin/bash
# MediCat USB Builder for Fedora (Ventoy + Smart Cache)
# Version: 4.1 (Professional Clean Build - B3)
# Author: Frixos + Copilot

set -euo pipefail

# ---------------------------------------------------------
# Global paths
# ---------------------------------------------------------
REPO_URL="https://github.com/lukumaki/medicat-fedora-usb-installer"
PATCH_URL="$REPO_URL/raw/main/patch"
VENTOY_DIR="./ventoy"
PATCH_DIR="./patch"
MEDICAT_DIR="$HOME/Medicat_USB_Cache"
MNT_DIR="/mnt/medicat"
LOG_FILE="$PWD/medicat_usb_builder.log"

# ---------------------------------------------------------
# CLI flags
# ---------------------------------------------------------
SKIP_VENTOY=0
SKIP_MEDICAT=0
UPDATE_ONLY=0
FORCE_MBR=0
FORCE_GPT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-ventoy)   SKIP_VENTOY=1 ;;
    --skip-medicat)  SKIP_MEDICAT=1 ;;
    --update-only)   UPDATE_ONLY=1; SKIP_VENTOY=1; SKIP_MEDICAT=0 ;;
    --force-mbr)     FORCE_MBR=1 ;;
    --force-gpt)     FORCE_GPT=1 ;;
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
  local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $*" | tee -a "$LOG_FILE"
}

log_info()  { cecho "$yellowB" "[INFO] $*";  log_raw "[INFO] $*"; }
log_ok()    { cecho "$greenB"  "[OK] $*";    log_raw "[OK] $*"; }
log_warn()  { cecho "$redB"    "[WARN] $*";  log_raw "[WARN] $*"; }
log_error() { cecho "$redB"    "[ERROR] $*"; log_raw "[ERROR] $*"; }

out()    { cecho "$blueB" "$*"; }
prompt() { cecho "$yellowB" "$1"; }

YesNo() {
  prompt "$1"
  read -rp "> " ans
  case "$ans" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------
# Cleanup trap
# ---------------------------------------------------------
cleanup() {
  sudo umount "$MNT_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# ---------------------------------------------------------
# Banner
# ---------------------------------------------------------
echo ""
echo "=============================================="
echo "  MediCat USB Builder for Fedora (v4.1)"
echo "=============================================="
echo ""

log_info "Starting MediCat USB Builder."

# ---------------------------------------------------------
# Dependencies
# ---------------------------------------------------------
install_dependencies() {
  log_info "Installing required packages..."
  sudo dnf install -y wget curl unzip rsync exfatprogs ntfs-3g p7zip p7zip-plugins bc
}

# ---------------------------------------------------------
# Ventoy patches
# ---------------------------------------------------------
ensure_patches() {
  mkdir -p "$PATCH_DIR"

  download_patch() {
    local file="$1"
    if [ ! -f "$PATCH_DIR/$file" ]; then
      log_info "Downloading $file..."
      curl -s -L -o "$PATCH_DIR/$file" "$PATCH_URL/$file"
      chmod +x "$PATCH_DIR/$file"
    else
      log_ok "$file already present."
    fi
  }

  log_info "Checking Fedora Ventoy patches..."
  download_patch "Ventoy2Disk_fedora.sh"
  download_patch "VentoyWorker_fedora.sh"
}

# ---------------------------------------------------------
# Ventoy download
# ---------------------------------------------------------
download_ventoy() {
  log_info "Detecting latest Ventoy version..."
  local LATEST
  LATEST=$(curl -s "https://sourceforge.net/projects/ventoy/files/" \
    | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)

  [ -z "$LATEST" ] && log_error "Could not detect Ventoy version." && exit 1

  log_info "Latest Ventoy version: $LATEST"

  local VERSION="${LATEST#v}"
  local TARBALL="ventoy-${VERSION}-linux.tar.gz"
  local URL="https://sourceforge.net/projects/ventoy/files/${LATEST}/${TARBALL}/download"

  log_info "Downloading Ventoy..."
  wget --progress=bar:force -O ventoy.tar.gz "$URL"

  log_info "Extracting Ventoy..."
  tar -xf ventoy.tar.gz
  rm -rf "$VENTOY_DIR"
  mv ventoy-* "$VENTOY_DIR"
  rm -f ventoy.tar.gz

  log_ok "Ventoy ready."
}

prepare_ventoy() {
  if [ ! -d "$VENTOY_DIR" ]; then
    download_ventoy
  else
    log_ok "Ventoy folder already exists (cached)."
  fi
}

# ---------------------------------------------------------
# MediCat download
# ---------------------------------------------------------
download_medicat() {
  mkdir -p "$MEDICAT_DIR"
  cd "$MEDICAT_DIR"

  if ls *.7z >/dev/null 2>&1; then
    log_ok "MediCat archive already present."
    cd - >/dev/null
    return
  fi

  log_info "Downloading cdn.bat..."
  wget -q -O cdn.bat "https://raw.githubusercontent.com/mon5termatt/medicat_installer/main/download/cdn.bat"

  FILE_NAME=$(grep -i 'FILE_NAME=' cdn.bat | sed -E 's/.*FILE_NAME=([^"]+)".*/\1/')
  [ -z "$FILE_NAME" ] && FILE_NAME="Medicat.USB.v21.12.7z"

  log_info "Detected archive: $FILE_NAME"

  local best_url=""
  local best_speed=0

  while read -r line; do
    local url=$(echo "$line" | grep -oP 'https?://[^"]+')
    [ -z "$url" ] && continue
    url=${url//%FILE_NAME%/$FILE_NAME}

    local speed
    speed=$(curl -L --max-time 3 -w "%{speed_download}" -o /dev/null -s "$url" || echo 0)

    if (( $(echo "$speed > $best_speed" | bc -l) )); then
      best_speed="$speed"
      best_url="$url"
    fi
  done < <(grep -i 'SERVER[0-9]=' cdn.bat)

  [ -z "$best_url" ] && log_error "No valid server found." && exit 1

  log_info "Downloading MediCat from fastest server..."
  wget --progress=bar:force -O "$FILE_NAME" "$best_url"

  log_ok "MediCat archive downloaded."
  cd - >/dev/null
}

# ---------------------------------------------------------
# Extraction
# ---------------------------------------------------------
extract_medicat_to_cache() {
  cd "$MEDICAT_DIR"

  FILE_NAME=$(ls *.7z | head -n 1)
  [ -z "$FILE_NAME" ] && log_error "No MediCat archive found." && exit 1

  if [ -f ".extracted.ok" ]; then
    log_ok "MediCat already extracted."
    cd - >/dev/null
    return
  fi

  out "Extracting MediCat (progress enabled)..."
  mkdir -p extracted
  7z x -bsp1 -y -o"./extracted" "$FILE_NAME" 2>&1 | tee -a "$LOG_FILE"

  touch .extracted.ok
  log_ok "Extraction complete."

  cd - >/dev/null
}

# ---------------------------------------------------------
# USB selection
# ---------------------------------------------------------
select_usb() {
  prompt "Please plug your USB now and press Enter..."
  read -r _

  out "Available devices:"
  lsblk --nodeps --output "NAME,SIZE,VENDOR,MODEL,SERIAL" | grep -v loop

  prompt "Enter device name (e.g. sdb):"
  read -r letter

  TARGET="/dev/$letter"
  PART_DATA="${TARGET}1"

  [ ! -b "$TARGET" ] && log_error "$TARGET does not exist." && exit 1

  YesNo "Install MediCat to $TARGET ?" || exit 0
}

# ---------------------------------------------------------
# Ventoy detection
# ---------------------------------------------------------
has_existing_ventoy() {
  local part="${1}1"
  local tmp=$(mktemp -d)

  if sudo mount "$part" "$tmp" 2>/dev/null; then
    if [ -d "$tmp/ventoy" ] || [ -f "$tmp/ventoy.json" ]; then
      sudo umount "$tmp"
      rmdir "$tmp"
      return 0
    fi
    sudo umount "$tmp"
  fi

  rmdir "$tmp"
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
      YesNo "Use GPT instead of MBR?" && use_gpt=1
    fi

    local ventoy_output
    if [ "$use_gpt" -eq 1 ]; then
      ventoy_output=$(sudo "$PATCH_DIR/Ventoy2Disk_fedora.sh" -I -g "$TARGET" 2>&1)
    else
      ventoy_output=$(sudo "$PATCH_DIR/Ventoy2Disk_fedora.sh" -I "$TARGET" 2>&1)
    fi

    echo "$ventoy_output" >> "$LOG_FILE"

    echo "$ventoy_output" | grep -qi "successfully finished" \
      || { log_error "Ventoy installation failed."; exit 1; }

    log_ok "Ventoy installed."
  fi

  if [ "$SKIP_MEDICAT" -eq 1 ] && [ "$UPDATE_ONLY" -eq 1 ]; then
    log_info "Skipping format due to update-only."
  else
    sudo umount "$TARGET" 2>/dev/null || true
    sudo umount "${TARGET}1" 2>/dev/null || true

    out "Formatting $PART_DATA as NTFS..."
    sudo mkntfs --fast --label Medicat "$PART_DATA"
  fi
}

# ---------------------------------------------------------
# Copy MediCat to USB
# ---------------------------------------------------------
copy_medicat_to_usb() {
  sudo mkdir -p "$MNT_DIR"
  sudo mount "${TARGET}1" "$MNT_DIR"

  out "Copying MediCat to USB..."

  local rsync_opts="-avh --info=progress2"
  [ "$UPDATE_ONLY" -eq 1 ] && rsync_opts="$rsync_opts --update"

  rsync $rsync_opts "$MEDICAT_DIR/extracted"/ "$MNT_DIR"/

  log_ok "Copy complete."
}

# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------
install_dependencies
ensure_patches
prepare_ventoy
download_medicat
extract_medicat_to_cache
select_usb
install_ventoy_and_format
copy_medicat_to_usb

echo ""
echo "=============================================="
echo "  MediCat USB installation completed!"
echo "=============================================="
log_ok "MediCat USB installation completed successfully."

