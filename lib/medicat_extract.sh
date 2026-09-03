#!/bin/bash
# medicat_extract.sh
# Safe, MODE-aware MediCat extraction logic (v7.1 PRO)

# ---------------------------------------------------------
# Resolve the archive path set by download_medicat, falling back to
# whatever .7z is sitting in the cache (e.g. a manually placed archive).
# ---------------------------------------------------------
resolve_medicat_archive() {
  if [ -n "${MEDICAT_ARCHIVE:-}" ] && [ -f "$MEDICAT_ARCHIVE" ]; then
    return 0
  fi

  local found
  found="$(find "$MEDICAT_DIR" -maxdepth 1 -type f -name '*.7z' -print -quit 2>/dev/null)"

  if [ -n "$found" ]; then
    MEDICAT_ARCHIVE="$found"
    log_debug "Resolved MediCat archive from cache: $MEDICAT_ARCHIVE"
    return 0
  fi

  MEDICAT_ARCHIVE=""
  return 1
}

extract_medicat() {

  #
  # MODE CHECKS
  #
  if [ "$INSTALL_MEDICAT" -ne 1 ]; then
    log_debug "Skipping MediCat extraction (INSTALL_MEDICAT=0)."
    return 0
  fi

  if [ "$MODE" = "update" ]; then
    log_debug "Skipping extraction (MODE=update)."
    return 0
  fi

  #
  # DRY RUN
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would extract the MediCat archive:"
    log_info "  Archive: ${MEDICAT_ARCHIVE:-<downloaded into $MEDICAT_DIR>}"
    log_info "  Target:  $MEDICAT_DIR/extracted/"
    return 0
  fi

  #
  # SKIP IF ALREADY EXTRACTED
  #
  if [ -f "$MEDICAT_DIR/.extracted.ok" ]; then
    log_ok "MediCat already extracted."
    return 0
  fi

  #
  # VALIDATE ARCHIVE
  #
  if ! resolve_medicat_archive; then
    log_error "No MediCat archive (*.7z) found in $MEDICAT_DIR"
    log_diagnostics
    return 1
  fi

  #
  # PREPARE EXTRACTION DIRECTORY
  #
  mkdir -p "$MEDICAT_DIR/extracted"

  log_info "Extracting MediCat archive (this takes a while)..."
  log_debug "7z x \"$MEDICAT_ARCHIVE\" -o\"$MEDICAT_DIR/extracted\""

  #
  # EXTRACTION
  #
  if ! 7z x -y "$MEDICAT_ARCHIVE" -o"$MEDICAT_DIR/extracted" >>"$LOG_FILE" 2>&1; then
    log_error "Extraction failed. Check log: $LOG_FILE"
    log_diagnostics
    return 1
  fi

  #
  # VALIDATE EXTRACTION RESULT
  #
  if [ ! -d "$MEDICAT_DIR/extracted" ] || [ -z "$(ls -A "$MEDICAT_DIR/extracted")" ]; then
    log_error "Extraction completed but directory is empty."
    log_diagnostics
    return 1
  fi

  #
  # MARK SUCCESS
  #
  touch "$MEDICAT_DIR/.extracted.ok"
  log_ok "Extraction complete."
}
