#!/bin/bash

TARGET=""
PART_DATA=""

select_usb_device() {
  log_info "Detecting removable USB devices..."

  mapfile -t usb_list < <(lsblk -o NAME,SIZE,MODEL,RM -nr | awk '$4 == 1 {print "/dev/"$1" "$2" "$3}')

  if [ ${#usb_list[@]} -eq 0 ]; then
    log_error "No removable USB devices detected."
    exit 1
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
    exit 1
  fi

  TARGET=$(echo "${usb_list[$((choice-1))]}" | awk '{print $1}')
  PART_DATA="${TARGET}2"  # Ventoy data partition

  log_raw ""
  log_raw "You selected: $TARGET"
  read -rp "Proceed with this device? (y/N): " confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    USER_DECLINED_USB=0
  else
    USER_DECLINED_USB=1
  fi
}
detect_partitions_simple() {
    log_info "Auto-detecting partitions for update-only mode..."

    local dev="$TARGET"

    # Read partitions: NAME FSTYPE SIZE
    mapfile -t parts < <(lsblk -nr -o NAME,FSTYPE,SIZE "$dev")

    EFI_PART=""
    MEDICAT_PART=""

    for line in "${parts[@]}"; do
        set -- $line
        local name="$1"
        local fstype="$2"
        local size="$3"
        local full="/dev/$name"

        # Detect EFI (FAT32, small size)
        if [[ "$fstype" == "vfat" ]]; then
            EFI_PART="$full"
            continue
        fi

        # Detect Medicat data (NTFS, large size)
        if [[ "$fstype" == "ntfs" ]]; then
            MEDICAT_PART="$full"
            continue
        fi
    done

    log_info "Partition auto-detection results:"
    log_raw "  EFI partition:      ${EFI_PART:-NOT FOUND}"
    log_raw "  Medicat partition:  ${MEDICAT_PART:-NOT FOUND}"

    if [[ -z "$MEDICAT_PART" ]]; then
        log_error "Could not detect NTFS Medicat partition. Update-only cannot continue."
        exit 1
    fi

    # Export result for install_medicat()
    PART_DATA="$MEDICAT_PART"
}

