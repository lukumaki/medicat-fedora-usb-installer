#!/bin/bash

format_usb() {
  if [ "$DO_FORMAT" -ne 1 ]; then
    log_debug "Format skipped (MODE=$MODE)."
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would format $PART_DATA as NTFS"
    return 0
  fi

  sudo umount "$TARGET" 2>/dev/null || true
  sudo umount "$PART_DATA" 2>/dev/null || true

  log_raw ""
  log_raw "⚠ WARNING: You are about to FORMAT $PART_DATA"
  log_raw "This will ERASE ALL DATA on the USB drive."
  log_raw ""
  log_raw "To continue, type: FORMAT"
  log_raw "To cancel, press Enter."
  log_raw ""

  read -rp "> " confirm_format
  case "$confirm_format" in
    FORMAT)
      log_info "Proceeding with format..."
      if ! sudo mkntfs --label Medicat "$PART_DATA"; then
        log_error "Failed to format $PART_DATA"
        return 1
      fi
      log_ok "Format complete."
      ;;
    *)
      log_info "Format cancelled by user."
      exit 0
      ;;
  esac
}
