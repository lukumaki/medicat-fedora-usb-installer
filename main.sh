#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load libs
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/mode.sh"
source "$SCRIPT_DIR/lib/usb.sh"
source "$SCRIPT_DIR/lib/patches.sh"
source "$SCRIPT_DIR/lib/ventoy.sh"
source "$SCRIPT_DIR/lib/medicat_download.sh"
source "$SCRIPT_DIR/lib/medicat_extract.sh"
source "$SCRIPT_DIR/lib/medicat_install.sh"
source "$SCRIPT_DIR/lib/format.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"

trap cleanup EXIT

main() {
  load_config

  mkdir -p "$CACHE_DIR"
  : > "$LOG_FILE"
  log_debug "Logging initialized: $LOG_FILE"

  log_raw ""
  log_raw "=============================================="
  log_raw "  MediCat USB Builder for Fedora v7.0"
  log_raw "=============================================="
  log_raw ""

  parse_args "$@"
  check_dependencies() {
    command -v rsync >/dev/null || { log_error "rsync not found"; exit 1; }
    command -v lsblk >/dev/null || { log_error "lsblk not found"; exit 1; }
    command -v mkntfs >/dev/null || { log_error "mkntfs not found (ntfs-3g)"; exit 1; }
    command -v curl >/dev/null || { log_error "curl not found"; exit 1; }
    command -v wget >/dev/null || { log_error "wget not found"; exit 1; }
    command -v 7z >/dev/null || { log_error "7z not found"; exit 1; }
    command -v jq >/dev/null || { log_error "jq not found"; exit 1; }
    log_ok "Core dependencies found."
  }
  check_dependencies

  ensure_patches
  prepare_ventoy
  download_medicat
  extract_medicat_to_cache

  select_usb_device
  decide_mode
  if [ "$MODE" = "skip" ]; then
    log_info "User declined USB operation. Exiting."
    exit 0
  fi
  mode_to_flags

  install_ventoy
  format_usb
  install_medicat

  log_ok "All operations completed."
}

main "$@"
