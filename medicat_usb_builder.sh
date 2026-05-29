#!/usr/bin/env bash
#
# medicat_usb_builder.sh
# A fully automated Ventoy + MediCat USB installer for Fedora (TUI, MIT licensed)
#

###############################################
#  CONFIGURATION
###############################################
sudo="sudo"
ventoyFS=true
ventoyLauncher="sh ./ventoy/Ventoy2Disk.sh"
LOGFILE="./medicat_builder.log"

###############################################
#  COLOR SUPPORT
###############################################
NumColours=$(tput colors 2>/dev/null || echo 0)

if test -n "$NumColours" && test $NumColours -ge 8; then
    clear="$(tput sgr0)"
    blackN="$(tput setaf 0)"; blackB="$(tput bold setaf 0)"
    redN="$(tput setaf 1)"; redB="$(tput bold setaf 1)"
    greenN="$(tput setaf 2)"; greenB="$(tput bold setaf 2)"
    yellowN="$(tput setaf 3)"; yellowB="$(tput bold setaf 3)"
    blueN="$(tput setaf 4)"; blueB="$(tput bold setaf 4)"
    magentaN="$(tput setaf 5)"; magentaB="$(tput bold setaf 5)"
    cyanN="$(tput setaf 6)"; cyanB="$(tput bold setaf 6)"
    whiteN="$(tput setaf 7)"; whiteB="$(tput bold setaf 7)"
else
    clear=""; redB=""; greenB=""; yellowB=""; blueB=""; cyanB=""; whiteB=""
fi

###############################################
#  HELPERS
###############################################
function colEcho() {
    echo -e "$1$2$clear" | tee -a "$LOGFILE"
}

function die() {
    colEcho "$redB" "ERROR: $1"
    exit 1
}

function UserWait() {
    read -n 1 -s -r -p "Press any key to continue"
    echo -e "\r                         \r"
}

function YesNo() {
    local setCheck=""
    while [[ "$setCheck" != [NnYy]* ]]; do
        read -e -p "$1" setCheck
        if [[ $setCheck == [Yy]* ]]; then
            echo true
        elif [[ $setCheck == [Nn]* ]]; then
            echo false
        else
            colEcho $redB "Invalid input. Please enter 'Y' or 'N'."
        fi
    done
}

###############################################
#  CHECK FEDORA + INSTALL DEPS
###############################################
function checkFedora() {
    grep -qi "fedora" /etc/os-release || die "This installer is only for Fedora."
}

function installDeps() {
    colEcho $cyanB "Installing dependencies..."
    $sudo dnf -y install wget unzip exfatprogs ntfs-3g rsync p7zip p7zip-plugins >>"$LOGFILE" 2>&1
}

###############################################
#  DOWNLOAD VENTOY (LATEST)
###############################################
function downloadVentoy() {
    colEcho $cyanB "\nFetching latest Ventoy version..."
    venver=$(wget -q -O - https://api.github.com/repos/ventoy/Ventoy/releases/latest | grep '"tag_name":' | cut -d'"' -f4)

    [[ -z "$venver" ]] && die "Unable to fetch Ventoy version."

    shortver="${venver: -6}"

    colEcho $cyanB "Downloading Ventoy version: $whiteB $shortver"
    wget -q --show-progress "https://github.com/ventoy/Ventoy/releases/download/v$shortver/ventoy-$shortver-linux.tar.gz" -O ventoy.tar.gz || die "Ventoy download failed."

    colEcho $cyanB "Extracting Ventoy..."
    tar -xf ventoy.tar.gz || die "Failed to extract Ventoy."

    rm -f ventoy.tar.gz

    if [ -d ./ventoy ]; then
        colEcho $cyanB "Removing previous ./ventoy folder..."
        rm -rf ./ventoy/
    fi

    mv ventoy-$shortver ventoy
}

###############################################
#  USB SELECTION
###############################################
function selectUSB() {
    colEcho $yellowB "\nPlease plug your USB now if not already connected..."
    UserWait

    colEcho $yellowB "Available USB devices:"
    lsblk --nodeps --output "NAME,SIZE,VENDOR,MODEL,SERIAL" | grep -v loop | tee -a "$LOGFILE"

    colEcho $yellowB "\nEnter the device name (e.g. sdb, sdc):"
    read letter

    drive="/dev/$letter"
    drive2="$drive""1"

    if $(YesNo "Install Ventoy + MediCat to $drive / $drive2? (Y/N) "); then
        colEcho $cyanB "Installation confirmed. Starting in 5 seconds..."
        sleep 5
    else
        colEcho $yellowB "Installation cancelled."
        exit 0
    fi
}

###############################################
#  INSTALL VENTOY
###############################################
function installVentoy() {
    colEcho $cyanB "Installing Ventoy on $whiteB $drive"

    colEcho $blueB "MBR supports BIOS + UEFI (legacy). GPT supports modern UEFI."
    if $(YesNo "Use GPT instead of MBR? (Y/N) "); then
        colEcho $yellowB "Using GPT"
        $sudo $ventoyLauncher -I -g "$drive" >>"$LOGFILE" 2>&1 || die "Ventoy installation failed."
    else
        colEcho $yellowB "Using MBR"
        $sudo $ventoyLauncher -I "$drive" >>"$LOGFILE" 2>&1 || die "Ventoy installation failed."
    fi
}

###############################################
#  MEDICAT DETECTION
###############################################
function findMedicat() {
    colEcho $cyanB "\nSearching for MediCat package in ~/Downloads..."

    medicatFile=$(find "$HOME/Downloads" -maxdepth 1 -type f -iname "MediCat*.7z" | head -n 1)

    if [[ -n "$medicatFile" ]]; then
        colEcho $greenB "Found MediCat package: $whiteB $medicatFile"
        location="$medicatFile"
        return
    fi

    colEcho $yellowB "No MediCat package found in ~/Downloads."

    if $(YesNo "Open official download page? (Y/N) "); then
        xdg-open "https://medicatusb.com/#downloads"
        colEcho $cyanB "Download the MediCat.USB.vXXXX.7z file and enter its path."
    fi

    read -rp "Enter full path to MediCat.USB.vXXXX.7z: " location
    [[ -f "$location" ]] || die "File not found."
}

###############################################
#  CREATE NTFS PARTITION + EXTRACT MEDICAT
###############################################
function prepareMedicat() {
    colEcho $cyanB "Unmounting $drive..."
    $sudo umount "$drive" >>"$LOGFILE" 2>&1 || true

    colEcho $cyanB "Creating NTFS filesystem on $drive2..."
    $sudo mkntfs --fast --label Medicat "$drive2" >>"$LOGFILE" 2>&1 || die "mkntfs failed."

    mkdir -p MedicatUSB

    colEcho $cyanB "Mounting Medicat NTFS volume..."
    $sudo mount "$drive2" ./MedicatUSB || die "Failed to mount MedicatUSB."

    colEcho $cyanB "Extracting MediCat..."
    7z x -O./MedicatUSB "$location" >>"$LOGFILE" 2>&1 || die "7z extraction failed."

    if $(YesNo "Unmount ./MedicatUSB now? (Y/N) "); then
        colEcho $cyanB "Unmounting..."
        $sudo umount ./MedicatUSB
    else
        colEcho $yellowB "MedicatUSB remains mounted."
    fi

    colEcho $greenB "Medicat USB creation complete."
}

###############################################
#  MAIN
###############################################
checkFedora
installDeps
downloadVentoy
selectUSB
installVentoy
findMedicat
prepareMedicat

colEcho $greenB "\n🎉 All done! Your Ventoy + MediCat USB is ready."
