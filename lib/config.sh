#!/bin/bash
# config.sh — Configuration loader for MediCat Installer (v7.1 PRO)

# Determine absolute path of project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

load_config() {

  #
  # Validate config.json
  #
  if [ ! -f "$CONFIG_FILE" ]; then
    log_error "config.json not found at: $CONFIG_FILE"
    log_diagnostics
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is required to parse config.json"
    log_diagnostics
    exit 1
  fi

  #
  # Helper: load a JSON key safely
  #
  json_get() {
    local key="$1"
    local value
    value=$(jq -r "$key // empty" "$CONFIG_FILE" 2>/dev/null)

    if [ -z "$value" ] || [ "$value" = "null" ]; then
      log_error "Missing or empty config key: $key"
      log_diagnostics
      exit 1
    fi

    echo "$value"
  }

  #
  # Load paths (expand $HOME)
  #
  CACHE_DIR=$(eval echo "$(json_get '.paths.cache_dir')")
  LOG_FILE=$(eval echo "$(json_get '.paths.log_file')")
  MEDICAT_DIR=$(eval echo "$(json_get '.paths.medicat_dir')")
  MNT_DIR=$(json_get '.paths.mnt_dir')
  PATCH_DIR=$(eval echo "$(json_get '.paths.patch_dir')")
  VENTOY_DIR=$(eval echo "$(json_get '.paths.ventoy_dir')")

  #
  # Load URLs
  #
  REPO_URL=$(json_get '.urls.repo_url')
  PATCH_URL=$(json_get '.urls.patch_url')
  VENTOY_SF_URL=$(json_get '.urls.ventoy_sourceforge')
  CDN_URL=$(json_get '.urls.medicat_cdn_bat')

  #
  # Validate paths are absolute
  #
  for p in "$CACHE_DIR" "$LOG_FILE" "$MEDICAT_DIR" "$PATCH_DIR" "$VENTOY_DIR"; do
    case "$p" in
      /*) ;;  # OK
      *)
        log_error "Path must be absolute: $p"
        log_diagnostics
        exit 1
        ;;
    esac
  done

  #
  # Create directories (skip in DRY RUN)
  #
  if [ "$DRY_RUN" -ne 1 ]; then
    mkdir -p "$CACHE_DIR" "$MEDICAT_DIR" "$PATCH_DIR" "$VENTOY_DIR"
  fi

  #
  # Log loaded configuration
  #
  log_debug "Configuration loaded:"
  log_debug "  CACHE_DIR=$CACHE_DIR"
  log_debug "  LOG_FILE=$LOG_FILE"
  log_debug "  MEDICAT_DIR=$MEDICAT_DIR"
  log_debug "  MNT_DIR=$MNT_DIR"
  log_debug "  PATCH_DIR=$PATCH_DIR"
  log_debug "  VENTOY_DIR=$VENTOY_DIR"
  log_debug "  REPO_URL=$REPO_URL"
  log_debug "  PATCH_URL=$PATCH_URL"
  log_debug "  VENTOY_SF_URL=$VENTOY_SF_URL"
  log_debug "  CDN_URL=$CDN_URL"
}
