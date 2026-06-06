#!/bin/bash
# medicat_extract.sh
# Safe, MODE-aware MediCat extraction logic (v7.1 PRO)

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
    log_info "[DRY RUN] Would extract MediCat archive:"
    log_info "  Archive: $MEDICAT_ARCHIVE"
    log_info "  Target:  $MEDICAT_DIR/extracted/"
    return 0
  fi

  #
  # VALIDATE ARCHIVE
  #
  if [ ! -f "$MEDICAT_ARCHIVE" ]; then
    log_error "MediCat archive not found: $MEDICAT_ARCHIVE"
    log_diagnostics
    return 1
  fi

  #
  # SKIP IF ALREADY EXTRACTED
  #
  if [ -f "$MEDICAT_DIR/.extracted.ok" ]; then
    log_ok "MediCat already extracted."
    return 0
  fi

  #
  # PREPARE EXTRACTION DIRECTORY
  #
  mkdir -p "$MEDICAT_DIR/extracted"

  log_info "Extracting MediCat archive..."
  log_debug "7z x \"$MEDICAT_ARCHIVE\" -o\"$MEDICAT_DIR/extracted\""

  #
  # EXTRACTION
  #
  if ! 7z x "$MEDICAT_ARCHIVE" -o"$MEDICAT_DIR/extracted" >>"$LOG_FILE" 2>&1; then
    log_error "Extraction failed."
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
