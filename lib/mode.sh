#!/bin/bash
# mode.sh — MODE architecture for MediCat Installer (v7.1 PRO)

# ---------------------------------------------------------
# Global MODE state
# ---------------------------------------------------------
MODE="install"

UPDATE_ONLY=0
FORCE_UPDATE=0
SKIP_MEDICAT=0
FORCE_GPT=0
FORCE_MBR=0
DRY_RUN=0
USER_DECLINED_USB=0

INSTALL_VENTOY=0
INSTALL_MEDICAT=0
DO_FORMAT=0

# ---------------------------------------------------------
# Usage
# ---------------------------------------------------------
usage() {
  cat <<'USAGE'
Usage: ./main.sh [options]

Modes:
  (no options)      Full install: Ventoy + format + MediCat
  --update-only     Update MediCat on an already-mounted MediCat partition
  --force-update    Re-copy every MediCat file, ignoring timestamps
  --skip-medicat    Install Ventoy only

Partitioning:
  --force-gpt       Force GPT partitioning (default)
  --force-mbr       Force MBR partitioning

Other:
  --dry-run         Show what would happen; change nothing
  --verbose         Print [DEBUG] lines on screen as well as to the log
  -h, --help        Show this help and exit
USAGE
}

# ---------------------------------------------------------
# Parse CLI arguments
# ---------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --update-only)   UPDATE_ONLY=1 ;;
      --force-update)  FORCE_UPDATE=1 ;;
      --skip-medicat)  SKIP_MEDICAT=1 ;;
      --force-gpt)     FORCE_GPT=1 ;;
      --force-mbr)     FORCE_MBR=1 ;;
      --dry-run)       DRY_RUN=1 ;;
      --verbose)       VERBOSE=1 ;;
      -h|--help)       usage; exit 0 ;;
      *)
        log_error "Unknown argument: $1"
        usage >&2
        exit 1
        ;;
    esac
    shift
  done

  #
  # Conflict detection (checked here so we fail before touching anything)
  #
  if [ "$FORCE_GPT" -eq 1 ] && [ "$FORCE_MBR" -eq 1 ]; then
    log_error "Cannot use --force-gpt and --force-mbr together."
    exit 1
  fi

  if [ "$SKIP_MEDICAT" -eq 1 ] && { [ "$UPDATE_ONLY" -eq 1 ] || [ "$FORCE_UPDATE" -eq 1 ]; }; then
    log_error "--skip-medicat cannot be combined with --update-only/--force-update."
    exit 1
  fi
}

# ---------------------------------------------------------
# Decide MODE based on flags
# ---------------------------------------------------------
decide_mode() {

  #
  # Highest priority: user declined USB
  #
  if [ "$USER_DECLINED_USB" -eq 1 ]; then
    MODE="skip"
    log_debug "Selected MODE: skip (user declined USB)"
    return
  fi

  #
  # Update-only or force-update
  #
  if [ "$UPDATE_ONLY" -eq 1 ] || [ "$FORCE_UPDATE" -eq 1 ]; then
    MODE="update"
    log_debug "Selected MODE: update"
    return
  fi

  #
  # Ventoy-only mode (skip MediCat)
  #
  if [ "$SKIP_MEDICAT" -eq 1 ]; then
    MODE="ventoy"
    log_debug "Selected MODE: ventoy"
    return
  fi

  #
  # Default full install
  #
  MODE="install"
  log_debug "Selected MODE: install"
}

# ---------------------------------------------------------
# Convert MODE into actionable flags
# ---------------------------------------------------------
mode_to_flags() {

  INSTALL_VENTOY=0
  INSTALL_MEDICAT=0
  DO_FORMAT=0

  case "$MODE" in

    install)
      INSTALL_VENTOY=1
      INSTALL_MEDICAT=1
      DO_FORMAT=1
      ;;

    update)
      INSTALL_VENTOY=0
      INSTALL_MEDICAT=1
      DO_FORMAT=0
      ;;

    ventoy)
      INSTALL_VENTOY=1
      INSTALL_MEDICAT=0
      DO_FORMAT=1
      ;;

    skip)
      INSTALL_VENTOY=0
      INSTALL_MEDICAT=0
      DO_FORMAT=0
      ;;

    *)
      log_error "Unknown MODE: $MODE"
      exit 1
      ;;
  esac

  #
  # DRY RUN logging
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] No changes will be made."
  fi

  log_info "Mode: $MODE"
  log_debug "Flags resolved:"
  log_debug "  INSTALL_VENTOY=$INSTALL_VENTOY"
  log_debug "  INSTALL_MEDICAT=$INSTALL_MEDICAT"
  log_debug "  DO_FORMAT=$DO_FORMAT"
  log_debug "  FORCE_GPT=$FORCE_GPT"
  log_debug "  FORCE_MBR=$FORCE_MBR"
  log_debug "  DRY_RUN=$DRY_RUN"
}
