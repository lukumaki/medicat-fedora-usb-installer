#!/bin/bash

# Determine absolute path of project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

load_config() {
  if ! command -v jq >/dev/null; then
    echo "jq is required to parse config.json" >&2
    exit 1
  fi

  # Load paths from JSON and expand $HOME
  CACHE_DIR=$(eval echo "$(jq -r '.paths.cache_dir' "$CONFIG_FILE")")
  LOG_FILE=$(eval echo "$(jq -r '.paths.log_file' "$CONFIG_FILE")")
  MEDICAT_DIR=$(eval echo "$(jq -r '.paths.medicat_dir' "$CONFIG_FILE")")
  MNT_DIR=$(jq -r '.paths.mnt_dir' "$CONFIG_FILE")
  PATCH_DIR=$(eval echo "$(jq -r '.paths.patch_dir' "$CONFIG_FILE")")
  VENTOY_DIR=$(eval echo "$(jq -r '.paths.ventoy_dir' "$CONFIG_FILE")")

  REPO_URL=$(jq -r '.urls.repo_url' "$CONFIG_FILE")
  PATCH_URL=$(jq -r '.urls.patch_url' "$CONFIG_FILE")
  VENTOY_SF_URL=$(jq -r '.urls.ventoy_sourceforge' "$CONFIG_FILE")
  CDN_URL=$(jq -r '.urls.medicat_cdn_bat' "$CONFIG_FILE")
}
