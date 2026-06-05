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
