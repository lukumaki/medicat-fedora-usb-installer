#!/bin/bash

MODE="install"
UPDATE_ONLY=0
FORCE_UPDATE=0
SKIP_MEDICAT=0
FORCE_GPT=0
FORCE_MBR=0
DRY_RUN=0
USER_DECLINED_USB=0

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --update-only) UPDATE_ONLY=1 ;;
      --force-update) FORCE_UPDATE=1 ;;
      --skip-medicat) SKIP_MEDICAT=1 ;;
      --force-gpt) FORCE_GPT=1 ;;
      --force-mbr) FORCE_MBR=1 ;;
      --dry-run) DRY_RUN=1 ;;
      *) log_error "Unknown argument: $1"; exit 1 ;;
    esac
    shift
  done
}

decide_mode() {
  MODE="install"

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
}

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

  log_debug "Flags: INSTALL_VENTOY=$INSTALL_VENTOY INSTALL_MEDICAT=$INSTALL_MEDICAT DO_FORMAT=$DO_FORMAT"
}
