#!/bin/bash
# deps.sh — Dependency validation for MediCat Installer (v7.1 PRO)

check_dependencies() {

  #
  # DRY RUN: skip dependency checks
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Skipping dependency checks."
    return 0
  fi

  log_info "Checking system dependencies..."
  local missing=0

  #
  # Helper: check a command
  #
  require() {
    local cmd="$1"
    local pkg="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_error "Missing dependency: $cmd (package: $pkg)"
      missing=1
    else
      log_debug "Found: $cmd"
    fi
  }

  #
  # Core dependencies (always required)
  #
  require rsync      "rsync"
  require lsblk      "util-linux"
  require curl       "curl"
  require wget       "wget"
  require findmnt    "util-linux"
  require sudo       "sudo"

  #
  # Ventoy dependencies (only if INSTALL_VENTOY=1)
  #
  if [ "$INSTALL_VENTOY" -eq 1 ]; then
    require tar        "tar"
    require wipefs     "util-linux"
  fi

  #
  # MediCat extraction dependencies (only if INSTALL_MEDICAT=1)
  #
  if [ "$INSTALL_MEDICAT" -eq 1 ]; then
    require 7z         "p7zip"
    require jq         "jq"
    require bc         "bc"
  fi

  #
  # NTFS tools (recommended)
  #
  if ! command -v ntfsfix >/dev/null 2>&1; then
    log_warn "ntfsfix not found (package: ntfs-3g). NTFS repair may not be available."
  fi

  if ! command -v mount.ntfs >/dev/null 2>&1 && ! command -v ntfs-3g >/dev/null 2>&1; then
    log_warn "NTFS-3G not found. NTFS mounting may fail."
  fi

  #
  # Final result
  #
  if [ "$missing" -ne 0 ]; then
    log_error "One or more required commands are missing. Install the missing packages and retry."
    log_diagnostics
    return 1
  fi

  log_ok "All required dependencies are present."
  return 0
}
