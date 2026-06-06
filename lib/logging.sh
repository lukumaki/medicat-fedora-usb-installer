#!/bin/bash
# logging.sh — Unified Logging System (v7.1 PRO)
# Provides clean log file output + colored terminal output + automatic diagnostics.

# =========================================================
#  Terminal Colors (screen only — never written to log)
# =========================================================
color_reset="\033[0m"
color_info="\033[1;33m"     # yellow
color_ok="\033[1;32m"       # green
color_warn="\033[1;35m"     # magenta
color_error="\033[1;31m"    # red bold
color_debug="\033[1;34m"    # blue

# ---------------------------------------------------------
# Raw log writer (NO COLORS)
# ---------------------------------------------------------
log_raw() {
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] $*" >> "$LOG_FILE"
}

# ---------------------------------------------------------
# Screen + Log (colored on screen, plain in log)
# ---------------------------------------------------------
log_info()  { echo -e "${color_info}[INFO]${color_reset} $*";   log_raw "[INFO] $*"; }
log_ok()    { echo -e "${color_ok}[OK]${color_reset} $*";       log_raw "[OK] $*"; }
log_warn()  { echo -e "${color_warn}[WARN]${color_reset} $*";   log_raw "[WARN] $*"; }
log_error() { echo -e "${color_error}[ERROR]${color_reset} $*"; log_raw "[ERROR] $*"; }
log_debug() { echo -e "${color_debug}[DEBUG]${color_reset} $*"; log_raw "[DEBUG] $*"; }

# ---------------------------------------------------------
# Automatic Diagnostics (appended on failures)
# ---------------------------------------------------------
log_diagnostics() {
    log_raw "=== Diagnostics Start ==="

    log_raw "--- MODE / TARGET ---"
    log_raw "MODE=$MODE"
    log_raw "TARGET=$TARGET"
    log_raw "PART_DATA=$PART_DATA"
    log_raw "MNT_DIR=$MNT_DIR"

    log_raw "--- findmnt (partition) ---"
    findmnt -no TARGET,SOURCE,FSTYPE,OPTIONS "$PART_DATA" 2>&1 | sed 's/^/    /' >> "$LOG_FILE"

    log_raw "--- findmnt (mountpoint) ---"
    findmnt -no TARGET,SOURCE,FSTYPE,OPTIONS "$MNT_DIR" 2>&1 | sed 's/^/    /' >> "$LOG_FILE"

    log_raw "--- lsblk ---"
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT 2>&1 | sed 's/^/    /' >> "$LOG_FILE"

    log_raw "--- df -h ---"
    df -h "$MNT_DIR" 2>&1 | sed 's/^/    /' >> "$LOG_FILE"

    log_raw "--- dmesg (last 20 lines) ---"
    dmesg | tail -n 20 | sed 's/^/    /' >> "$LOG_FILE"

    log_raw "--- SELinux ---"
    getenforce 2>&1 | sed 's/^/    /' >> "$LOG_FILE"

    log_raw "=== Diagnostics End ==="
}
