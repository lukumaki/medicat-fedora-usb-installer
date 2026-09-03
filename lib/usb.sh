#!/bin/bash
# lib/usb.sh - USB selection and detection helpers for MediCat installer (v7.1 PRO)

TARGET=""
PART_DATA=""
EFI_PART=""
# MNT_DIR is loaded from config.json by load_config; this is only a safety net
# for callers that source this module without loading the configuration.
MNT_DIR="${MNT_DIR:-/mnt/medicat}"

# ---------------------------------------------------------
# Friendly message when no removable USB found
# ---------------------------------------------------------
no_usb_message() {
  log_error "No removable USB devices detected. Plug in the Medicat-Installation-USB and run the installer again."
}

# ---------------------------------------------------------
# Interactive USB device selection
# ---------------------------------------------------------
select_usb_device() {
  log_info "Detecting removable USB devices..."

  # -d limits the listing to whole disks: without it the device's own
  # partitions are also RM=1 and would be offered as install targets.
  mapfile -t usb_list < <(
    lsblk -d -o NAME,SIZE,RM,TYPE,MODEL -nr \
    | awk '$3 == 1 && $4 == "disk" {
        model = "";
        for (i = 5; i <= NF; i++) model = model (i > 5 ? " " : "") $i;
        gsub(/\\x20/, " ", model);
        if (model == "") model = "unknown model";
        print "/dev/" $1 "\t" $2 "\t" model;
      }'
  )

  if [ ${#usb_list[@]} -eq 0 ]; then
    no_usb_message
    return 1
  fi

  log_plain ""
  log_plain "Available USB devices:"
  log_plain ""

  local i=1
  for dev in "${usb_list[@]}"; do
    log_plain "  $i) $(echo -e "$dev")"
    ((i++))
  done

  require_interactive "Selecting a USB device" || return 1

  local choice=""
  local attempts=0

  # Re-prompt on a typo rather than aborting the whole run.
  while :; do
    log_plain ""
    read -rp "Select a USB device (1-${#usb_list[@]}), or press Enter to cancel: " choice

    if [ -z "$choice" ]; then
      log_info "No device selected."
      USER_DECLINED_USB=1
      return 1
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#usb_list[@]} ]; then
      break
    fi

    attempts=$((attempts + 1))
    if [ "$attempts" -ge 3 ]; then
      log_error "Too many invalid selections."
      return 1
    fi
    log_warn "Invalid selection: enter a number between 1 and ${#usb_list[@]}."
  done

  TARGET=$(echo "${usb_list[$((choice-1))]}" | awk '{print $1}')

  if [ ! -b "$TARGET" ]; then
    log_error "Selected device is not a block device: $TARGET"
    TARGET=""
    return 1
  fi

  log_plain ""
  log_plain "You selected: $TARGET"
  read -rp "Proceed with this device? (y/N): " confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    USER_DECLINED_USB=0
    log_info "Target device: $TARGET"
    return 0
  else
    USER_DECLINED_USB=1
    TARGET=""
    return 1
  fi
}

# ---------------------------------------------------------
# Ask the kernel to re-read the partition table
# (needed after Ventoy rewrites it, before partitions can be detected)
# ---------------------------------------------------------
refresh_partition_table() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_info "[DRY RUN] Would re-read the partition table on $TARGET"
    return 0
  fi

  [ -z "$TARGET" ] && return 0

  log_debug "Re-reading partition table on $TARGET"

  if command -v partprobe >/dev/null 2>&1; then
    sudo partprobe "$TARGET" >/dev/null 2>&1 || true
  fi

  if command -v udevadm >/dev/null 2>&1; then
    sudo udevadm settle >/dev/null 2>&1 || true
  fi

  # Give slow devices a moment to expose the new partition nodes.
  local tries=0
  while [ "$tries" -lt 10 ]; do
    if [ -n "$(lsblk -nr -o NAME "$TARGET" | tail -n +2)" ]; then
      return 0
    fi
    tries=$((tries + 1))
    sleep 1
  done

  log_warn "Partitions did not appear on $TARGET after re-reading the partition table."
  return 0
}

# ---------------------------------------------------------
# Partition detection wrapper
# ---------------------------------------------------------
detect_partitions() {
  if declare -F detect_partitions_impl >/dev/null 2>&1; then
    detect_partitions_impl
    return $?
  fi
  fallback_detect_partitions
}

# ---------------------------------------------------------
# Fallback partition detector (robust, label-aware)
# ---------------------------------------------------------
fallback_detect_partitions() {
  if [[ -z "$TARGET" ]]; then
    log_error "No TARGET set for partition detection."
    return 1
  fi

  log_debug "Running fallback partition detection on $TARGET"
  PART_DATA=""
  EFI_PART=""

  # -b gives sizes in bytes. Human-readable sizes cannot be compared
  # numerically: "28.9G" and "512M" both reduce to bare digits (289 vs 512).
  mapfile -t parts < <(lsblk -nrb -o NAME,FSTYPE,SIZE,LABEL,PARTTYPE "$TARGET")

  local largest_ntfs_size=0
  local smallest_vfat_size=0
  local labelled_data=0
  local labelled_efi=0

  local line name fstype size label parttype full
  for line in "${parts[@]}"; do
    read -r name fstype size label parttype <<< "$line"
    full="/dev/$name"

    # Skip the whole-disk line and any unformatted partition
    [[ -z "$fstype" ]] && continue
    [[ "$full" == "$TARGET" ]] && continue

    local num="${size:-0}"
    [[ "$num" =~ ^[0-9]+$ ]] || num=0

    # -----------------------------
    # NTFS (MediCat data partition)
    # -----------------------------
    if [[ "$fstype" == "ntfs" ]]; then
      if [[ "$label" == "Medicat" ]]; then
        PART_DATA="$full"
        labelled_data=1
      elif [ "$labelled_data" -eq 0 ] && { [[ -z "$PART_DATA" ]] || [ "$num" -gt "$largest_ntfs_size" ]; }; then
        PART_DATA="$full"
        largest_ntfs_size="$num"
      fi
    fi

    # -----------------------------
    # VFAT (Ventoy EFI partition)
    # -----------------------------
    if [[ "$fstype" == "vfat" ]]; then
      if [[ "$label" == "VTOYEFI" ]]; then
        EFI_PART="$full"
        labelled_efi=1
      elif [ "$labelled_efi" -eq 0 ] && { [[ -z "$EFI_PART" ]] || [ "$num" -lt "$smallest_vfat_size" ]; }; then
        EFI_PART="$full"
        smallest_vfat_size="$num"
      fi
    fi
  done

  if [[ -z "$PART_DATA" ]]; then
    log_error "Could not find an NTFS data partition on $TARGET."
    log_diagnostics
    return 1
  fi

  log_info "Detected partitions: PART_DATA=$PART_DATA, EFI_PART=${EFI_PART:-NOT FOUND}"
  return 0
}

# ---------------------------------------------------------
# Print manual mount instructions (update-only)
# ---------------------------------------------------------
print_mount_instructions() {
  local part="${1:-$PART_DATA}"
  local mnt="${2:-$MNT_DIR}"
  cat <<INSTR
Update-only requires the Medicat data partition to be mounted and writable.

Recommended commands (replace $part if different):
  sudo umount $mnt 2>/dev/null || true
  sudo ntfsfix $part
  sudo mkdir -p $mnt
  sudo mount -t ntfs-3g -o uid=$(id -u),gid=$(id -g),umask=0022 $part $mnt

Alternatively, use your file manager to mount the USB; ensure files under the mount are owned by your user.

After mounting, re-run:
  ./main.sh --update-only
INSTR
}

# ---------------------------------------------------------
# Ensure PART_DATA is mounted and writable (update-only)
# ---------------------------------------------------------
ensure_mounted_manual_only() {
  local part="${PART_DATA:-}"
  local expected_mnt="${MNT_DIR:-/mnt/medicat}"
  local user_mount

  if [[ -z "$part" ]]; then
    log_error "No PART_DATA detected. Cannot verify mount."
    return 1
  fi

  log_info "Verifying Medicat data partition for update-only..."

  # Detect actual mountpoint
  user_mount=$(findmnt -nr -o TARGET -S "$part" 2>/dev/null | head -n1 || true)

  if [[ -n "$user_mount" ]]; then
    log_debug "Partition $part is mounted at $user_mount (expected $expected_mnt)."

    # Test writability
    if touch "$user_mount/.medicat_write_test" 2>/dev/null; then
      rm -f "$user_mount/.medicat_write_test" 2>/dev/null || true
      log_info "Partition $part is mounted and writable at $user_mount."
      MNT_DIR="$user_mount"
      return 0
    fi

    log_error "Partition $part is mounted at $user_mount but not writable by the current user."
    print_mount_instructions "$part" "$user_mount"
    return 1
  fi

  # Not mounted anywhere
  log_error "Detected Medicat partition: $part (not mounted)"
  print_mount_instructions "$part" "$expected_mnt"
  return 1
}
