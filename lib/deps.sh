#!/bin/bash
# deps.sh — Dependency validation for MediCat Installer (v7.1 PRO)
#
# NOTE: this must run AFTER mode_to_flags(), because which dependencies are
# required depends on INSTALL_VENTOY / INSTALL_MEDICAT / DO_FORMAT.

check_dependencies() {

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
  require jq         "jq"
  require rsync      "rsync"
  require lsblk      "util-linux"
  require findmnt    "util-linux"
  require curl       "curl"
  require wget       "wget"
  require sudo       "sudo"

  #
  # Ventoy dependencies
  #
  if [ "$INSTALL_VENTOY" -eq 1 ]; then
    require tar        "tar"
    require wipefs     "util-linux"
    # Ventoy needs mkexfatfs; on Fedora that is provided by mkfs.exfat and
    # bridged by the patch layer in patch/.
    if ! command -v mkexfatfs >/dev/null 2>&1 && ! command -v mkfs.exfat >/dev/null 2>&1; then
      log_error "Missing dependency: mkfs.exfat (package: exfatprogs)"
      missing=1
    fi
  fi

  #
  # Formatting dependencies
  #
  if [ "$DO_FORMAT" -eq 1 ]; then
    require mkntfs     "ntfsprogs (or ntfs-3g)"
    require wipefs     "util-linux"
  fi

  #
  # MediCat download/extraction dependencies
  #
  if [ "$INSTALL_MEDICAT" -eq 1 ]; then
    require 7z         "p7zip / p7zip-plugins"
    require bc         "bc"
  fi

  #
  # NTFS tools (recommended, not fatal)
  #
  if ! command -v ntfsfix >/dev/null 2>&1; then
    log_warn "ntfsfix not found (package: ntfs-3g). NTFS repair may not be available."
  fi

  if ! command -v mount.ntfs >/dev/null 2>&1 && ! command -v ntfs-3g >/dev/null 2>&1; then
    log_warn "NTFS-3G not found. NTFS mounting may fail."
  fi

  if ! command -v partprobe >/dev/null 2>&1 && ! command -v udevadm >/dev/null 2>&1; then
    log_warn "Neither partprobe nor udevadm found. Partition rescan after Ventoy may be unreliable."
  fi

  #
  # Final result
  #
  if [ "$missing" -ne 0 ]; then
    log_error "One or more required commands are missing. Install the missing packages and retry."
    log_error "Fedora: sudo dnf install jq rsync curl wget p7zip p7zip-plugins bc ntfs-3g ntfsprogs exfatprogs util-linux"
    log_diagnostics
    return 1
  fi

  log_ok "All required dependencies are present."
  return 0
}
