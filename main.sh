#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load libs
source "$SCRIPT_DIR/lib/deps.sh"
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

  parse_args "$@"
  check_dependencies
  if ! select_usb_device; then
    no_usb_message
    exit 1
  fi

  decide_mode
  if [[ "$MODE" = "update" ]]; then
    if ! detect_partitions; then
      log_error "Partition autodetection failed. Aborting."
      exit 1
    fi
    if ! ensure_mounted_manual_only; then
      log_error "Medicat partition not mounted or not writable. Aborting update-only."
      exit 1
    fi
  fi

  mode_to_flags
  ensure_patches
  prepare_ventoy
  download_medicat

  if [[ "$MODE" != "update" ]]; then
    extract_medicat
  fi

  install_ventoy
  format_usb
  install_medicat

  log_ok "All operations completed."
}

main "$@"
