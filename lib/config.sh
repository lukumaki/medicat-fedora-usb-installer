#!/bin/bash
# config.sh — Configuration loader for MediCat Installer (v7.1 PRO)

# Determine absolute path of project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$PROJECT_ROOT/config.json}"

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
    log_error "jq is required to parse config.json (package: jq)"
    log_diagnostics
    exit 1
  fi

  if ! jq -e . "$CONFIG_FILE" >/dev/null 2>&1; then
    log_error "config.json is not valid JSON: $CONFIG_FILE"
    log_diagnostics
    exit 1
  fi

  #
  # Helper: load a required JSON key
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
  # Helper: load an optional JSON key with a default
  #
  json_get_default() {
    local key="$1"
    local fallback="$2"
    local value
    value=$(jq -r "$key // empty" "$CONFIG_FILE" 2>/dev/null)

    if [ -z "$value" ] || [ "$value" = "null" ]; then
      echo "$fallback"
    else
      echo "$value"
    fi
  }

  #
  # Helper: expand a leading $HOME / ~ without running arbitrary shell code
  #
  expand_path() {
    local raw="$1"
    raw="${raw/#\~/$HOME}"
    raw="${raw//\$HOME/$HOME}"
    raw="${raw//\$\{HOME\}/$HOME}"
    echo "$raw"
  }

  #
  # Project metadata
  #
  PROJECT_NAME=$(json_get_default '.project.name' 'MediCat USB Builder for Fedora')
  PROJECT_VERSION=$(json_get_default '.project.version' 'unknown')

  #
  # Load paths
  #
  CACHE_DIR=$(expand_path "$(json_get '.paths.cache_dir')")
  LOG_FILE_PATH=$(expand_path "$(json_get '.paths.log_file')")
  MEDICAT_DIR=$(expand_path "$(json_get '.paths.medicat_dir')")
  MNT_DIR=$(expand_path "$(json_get '.paths.mnt_dir')")
  PATCH_DIR=$(expand_path "$(json_get '.paths.patch_dir')")
  VENTOY_DIR=$(expand_path "$(json_get '.paths.ventoy_dir')")

  #
  # Load URLs
  #
  REPO_URL=$(json_get '.urls.repo_url')
  PATCH_URL=$(json_get '.urls.patch_url')
  VENTOY_SF_URL=$(json_get '.urls.ventoy_sourceforge')
  CDN_URL=$(json_get '.urls.medicat_cdn_bat')

  #
  # Apply partitioning defaults from config, unless overridden on the CLI.
  # CLI flags always win: they are only applied here when still unset.
  #
  if [ "$FORCE_GPT" -eq 0 ] && [ "$FORCE_MBR" -eq 0 ]; then
    case "$(json_get_default '.defaults.force_mbr' 'false')" in
      true|1) FORCE_MBR=1 ;;
    esac
    if [ "$FORCE_MBR" -eq 0 ]; then
      case "$(json_get_default '.defaults.force_gpt' 'true')" in
        true|1) FORCE_GPT=1 ;;
      esac
    fi
  fi

  #
  # Validate paths are absolute
  #
  for p in "$CACHE_DIR" "$LOG_FILE_PATH" "$MEDICAT_DIR" "$MNT_DIR" "$PATCH_DIR" "$VENTOY_DIR"; do
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
  # Create directories and start the real log (skip creation in DRY RUN)
  #
  if [ "$DRY_RUN" -ne 1 ]; then
    mkdir -p "$CACHE_DIR" "$MEDICAT_DIR" "$PATCH_DIR" "$VENTOY_DIR"
    init_log "$LOG_FILE_PATH"
  else
    log_info "[DRY RUN] Would create: $CACHE_DIR $MEDICAT_DIR $PATCH_DIR $VENTOY_DIR"
  fi

  #
  # Log loaded configuration
  #
  log_debug "$PROJECT_NAME v$PROJECT_VERSION"
  log_debug "Configuration loaded from $CONFIG_FILE:"
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
  log_debug "  FORCE_GPT=$FORCE_GPT FORCE_MBR=$FORCE_MBR"
}
