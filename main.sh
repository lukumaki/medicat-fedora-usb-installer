#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load libs (logging first: every other module reports through it)
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/mode.sh"
source "$SCRIPT_DIR/lib/deps.sh"
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
  # Arguments first: DRY_RUN must be known before load_config creates anything.
  parse_args "$@"

  load_config

  # MODE and its flags must be resolved before dependency checking, because
  # which dependencies are required depends on what we are actually going to do.
  decide_mode
  mode_to_flags
  check_dependencies

  if ! select_usb_device; then
    if [ "$USER_DECLINED_USB" -eq 1 ]; then
      log_info "USB selection cancelled by user. Nothing was changed."
    fi
    exit 1
  fi

  if [[ "$MODE" == "update" ]]; then
    if ! detect_partitions; then
      log_error "Partition autodetection failed. Aborting."
      exit 1
    fi
    if ! ensure_mounted_manual_only; then
      log_error "Medicat partition not mounted or not writable. Aborting update-only."
      exit 1
    fi
  fi

  ensure_patches
  prepare_ventoy
  download_medicat

  if [[ "$MODE" != "update" ]]; then
    extract_medicat
  fi

  install_ventoy

  # In install/ventoy mode the partitions only exist once Ventoy has written
  # the partition table, so detection has to happen here rather than up front.
  if [[ "$MODE" != "update" ]] && [ "$DO_FORMAT" -eq 1 ]; then
    refresh_partition_table
    if ! detect_partitions; then
      log_error "Could not locate the MediCat data partition after Ventoy installation."
      exit 1
    fi
  fi

  format_usb
  install_medicat

  log_ok "All operations completed."
}

main "$@"
