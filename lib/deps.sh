
#!/bin/bash
# lib/deps.sh - dependency checks for MediCat installer

check_dependencies() {
  local missing=0

  command -v rsync >/dev/null 2>&1 || { log_error "rsync not found"; missing=1; }
  command -v lsblk >/dev/null 2>&1 || { log_error "lsblk not found"; missing=1; }
  command -v mount >/dev/null 2>&1 || { log_error "mount not found"; missing=1; }
  command -v curl >/dev/null 2>&1 || { log_error "curl not found"; missing=1; }
  command -v wget >/dev/null 2>&1 || { log_error "wget not found"; missing=1; }
  command -v 7z >/dev/null 2>&1 || { log_error "7z not found"; missing=1; }
  command -v jq >/dev/null 2>&1 || { log_error "jq not found"; missing=1; }

  if ! command -v ntfsfix >/dev/null 2>&1; then
    log_warn "ntfsfix not found; NTFS repairs may not be available. Install ntfs-3g if needed."
  fi

  if [[ $missing -ne 0 ]]; then
    log_error "One or more required commands are missing. Install the missing packages and retry."
    return 1
  fi

  log_ok "Core dependencies checked."
  return 0
}
