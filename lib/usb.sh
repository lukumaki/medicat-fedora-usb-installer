#!/bin/bash
# lib/usb.sh - USB selection and detection helpers for MediCat installer

TARGET=""
PART_DATA=""
EFI_PART=""
MNT_DIR="/mnt/medicat"

# Friendly message when no removable USB found
no_usb_message() {
  log_error "No removable USB devices detected. Plug in the Medicat-Installation-USB and run the installer again."
}

# Interactive device selection. Does NOT assume partition numbers.
select_usb_device() {
  log_info "Detecting removable USB devices..."

  mapfile -t usb_list < <(lsblk -o NAME,SIZE,MODEL,RM -nr | awk '$4 == 1 {print "/dev/"$1" "$2" "$3}')

  if [ ${#usb_list[@]} -eq 0 ]; then
    no_usb_message
    return 1
  fi

  log_raw ""
  log_raw "Available USB devices:"
  log_raw ""

  local i=1
  for dev in "${usb_list[@]}"; do
    log_raw "  $i) $dev"
    ((i++))
  done

  log_raw ""
  read -rp "Select a USB device (1-${#usb_list[@]}): " choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#usb_list[@]} ]; then
    log_error "Invalid selection."
    return 1
  fi

  TARGET=$(echo "${usb_list[$((choice-1))]}" | awk '{print $1}')

  log_raw ""
  log_raw "You selected: $TARGET"
  read -rp "Proceed with this device? (y/N): " confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    USER_DECLINED_USB=0
    return 0
  else
    USER_DECLINED_USB=1
    return 1
  fi
}

# Primary partition detection wrapper.
# If you have a more advanced detector, implement detect_partitions_impl() and it will be used.
detect_partitions() {
  if declare -F detect_partitions_impl >/dev/null 2>&1; then
    detect_partitions_impl
    return $?
  fi
  fallback_detect_partitions
}

# Fallback inline detector (uses $TARGET). Sets PART_DATA and EFI_PART.
fallback_detect_partitions() {
  if [[ -z "$TARGET" ]]; then
    log_error "No TARGET set for partition detection."
    return 1
  fi

  log_debug "Running fallback partition detection on $TARGET"
  PART_DATA=""
  EFI_PART=""

  mapfile -t parts < <(lsblk -nr -o NAME,FSTYPE,LABEL,PARTTYPE "$TARGET")

  local largest_ntfs_size=0
  local smallest_vfat_size=""

  for line in "${parts[@]}"; do
    read -r name fstype label parttype <<< "$line"
    name="${name:-}"
    fstype="${fstype:-}"
    label="${label:-}"
    parttype="${parttype:-}"
    full="/dev/$name"

    # skip whole-disk line
    [[ -z "$fstype" ]] && continue

    # NTFS: prefer label "Medicat", else choose largest NTFS
    if [[ "$fstype" == "ntfs" ]]; then
      if [[ "$label" == "Medicat" ]]; then
        PART_DATA="$full"
        continue
      fi
      size=$(lsblk -nr -o SIZE "/dev/$name" 2>/dev/null || echo "")
      num="${size//[!0-9]/}"
      if [[ -z "$PART_DATA" || ( -n "$num" && -n "$largest_ntfs_size" && "$num" -gt "$largest_ntfs_size" ) ]]; then
        PART_DATA="$full"
        largest_ntfs_size="$num"
      fi
    fi

    # VFAT: prefer label "VTOYEFI", else choose smallest VFAT
    if [[ "$fstype" == "vfat" ]]; then
      if [[ "$label" == "VTOYEFI" ]]; then
        EFI_PART="$full"
        continue
      fi
      size=$(lsblk -nr -o SIZE "/dev/$name" 2>/dev/null || echo "")
      num="${size//[!0-9]/}"
      if [[ -z "$EFI_PART" || ( -n "$num" && -n "$smallest_vfat_size" && "$num" -lt "$smallest_vfat_size" ) ]]; then
        EFI_PART="$full"
        smallest_vfat_size="$num"
      fi
    fi
  done

  if [[ -z "${PART_DATA:-}" ]]; then
    log_error "Fallback detection could not find an NTFS data partition on $TARGET."
    return 1
  fi

  log_info "Detected partitions: PART_DATA=${PART_DATA}, EFI_PART=${EFI_PART:-NOT FOUND}"
  return 0
}

# Print clear mount instructions (no auto-mounting)
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

# Verify the detected PART_DATA is mounted and writable; never mounts automatically.
# If the partition is mounted anywhere (including /run/media/$USER/...), accept it and set MNT_DIR.
ensure_mounted_manual_only() {
  local part="${PART_DATA:-}"
  local expected_mnt="${MNT_DIR:-/mnt/medicat}"
  local user_mount

  if [[ -z "$part" ]]; then
    log_error "No PART_DATA detected. Cannot verify mount."
    return 1
  fi

  log_info "Verifying Medicat data partition for update-only..."

  # Find the actual mountpoint for the partition, if any
  user_mount=$(findmnt -nr -o TARGET -S "$part" 2>/dev/null || true)

  if [[ -n "$user_mount" ]]; then
    log_debug "Partition $part is mounted at $user_mount (expected $expected_mnt)."

    # Test writability at the actual mountpoint
    if touch "$user_mount/.medicat_write_test" 2>/dev/null; then
      rm -f "$user_mount/.medicat_write_test" 2>/dev/null || true
      log_info "Partition $part is mounted and writable at $user_mount."
      # Use the actual mount for subsequent operations
      MNT_DIR="$user_mount"
      return 0
    fi

    log_error "Partition $part is mounted at $user_mount but not writable by the current user."
    print_mount_instructions "$part" "$user_mount"
    return 1
  fi

  # Not mounted anywhere: print instructions for manual mount
  log_error "Detected Medicat partition: $part (not mounted)"
  print_mount_instructions "$part" "$expected_mnt"
  return 1
}