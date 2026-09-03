#!/bin/bash
# format.sh — Safe USB formatting logic (v7.1 PRO)

format_usb() {

  #
  # MODE-aware skip
  #
  if [ "$DO_FORMAT" -ne 1 ]; then
    log_debug "Format skipped (MODE=$MODE)."
    return 0
  fi

  #
  # DRY RUN
  #
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "[DRY RUN] Would format the MediCat data partition on $TARGET as NTFS"
    return 0
  fi

  #
  # Validate TARGET and PART_DATA
  #
  if [ -z "$TARGET" ] || [ ! -b "$TARGET" ]; then
    log_error "Invalid TARGET device: $TARGET"
    log_diagnostics
    return 1
  fi

  if [ -z "$PART_DATA" ] || [ ! -b "$PART_DATA" ]; then
    log_error "Invalid PART_DATA partition: $PART_DATA"
    log_diagnostics
    return 1
  fi

  # Refuse to format anything that is not a partition of the selected device.
  case "$PART_DATA" in
    "$TARGET"?*) ;;
    *)
      log_error "Refusing to format $PART_DATA: it is not a partition of $TARGET."
      log_diagnostics
      return 1
      ;;
  esac

  #
  # Unmount all partitions of the target device
  #
  unmount_device_partitions "$TARGET"

  #
  # User confirmation — never format unattended
  #
  if ! require_interactive "Formatting $PART_DATA"; then
    log_diagnostics
    return 1
  fi

  echo ""
  echo "⚠ WARNING: You are about to FORMAT $PART_DATA on $TARGET"
  echo "This will ERASE ALL DATA on that partition."
  echo ""
  lsblk -o NAME,SIZE,FSTYPE,LABEL "$TARGET" || true
  echo ""
  echo "To continue, type: FORMAT"
  echo "To cancel, press Enter."
  echo ""

  read -rp "> " confirm_format
  case "$confirm_format" in
    FORMAT)
      log_info "Proceeding with format..."
      ;;
    *)
      log_info "Format cancelled by user."
      exit 0
      ;;
  esac

  #
  # Wipe filesystem signatures
  #
  log_debug "Wiping filesystem signatures on $PART_DATA..."
  if ! sudo wipefs -a "$PART_DATA" >>"$LOG_FILE" 2>&1; then
    log_error "wipefs failed on $PART_DATA"
    log_diagnostics
    return 1
  fi

  #
  # Create NTFS filesystem
  #
  log_info "Creating NTFS filesystem on $PART_DATA..."
  if ! sudo mkntfs --fast --label Medicat "$PART_DATA" >>"$LOG_FILE" 2>&1; then
    log_error "Failed to format $PART_DATA"
    log_diagnostics
    return 1
  fi

  # The label changed, so re-detect to keep PART_DATA/EFI_PART accurate.
  refresh_partition_table

  log_ok "Format complete."
}
