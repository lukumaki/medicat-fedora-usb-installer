#!/bin/bash

extract_medicat_to_cache() {
  if [ "$FORCE_UPDATE" -eq 1 ]; then
    if [ -d "$MEDICAT_DIR/extracted" ]; then
      log_ok "Force-update mode: Using existing extracted/ directory."
      return 0
    else
      log_error "Force-update mode: extracted/ directory not found at $MEDICAT_DIR/extracted"
      log_error "Please run without --force-update first to download and extract MediCat."
      return 1
    fi
  fi

  cd "$MEDICAT_DIR" || return 1

  FILE_NAME=$(find . -maxdepth 1 -name '*.7z' -print -quit)

  if [ -z "$FILE_NAME" ]; then
    log_error "No MediCat archive found"
    cd - >/dev/null
    return 1
  fi

  if [ -f ".extracted.ok" ]; then
    log_ok "MediCat already extracted."
    cd - >/dev/null
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would extract: $FILE_NAME"
    log_info "[DRY RUN] Would create: ./extracted/ directory"
    log_info "[DRY RUN] Would create: .extracted.ok marker"
    cd - >/dev/null
    return 0
  fi

  log_info "Extracting MediCat (progress enabled)..."
  rm -rf extracted
  mkdir -p extracted

  if ! 7z x -bsp1 -y -o"./extracted" "$FILE_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    log_error "Extraction failed"
    rm -rf extracted
    cd - >/dev/null
    return 1
  fi

  touch .extracted.ok
  log_ok "Extraction complete."

  cd - >/dev/null
}
