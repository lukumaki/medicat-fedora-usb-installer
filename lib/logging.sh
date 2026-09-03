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

# Fallback log target so logging works before config.json has been read.
# load_config replaces this with the configured path.
LOG_FILE="${LOG_FILE:-/tmp/medicat_usb_builder.bootstrap.log}"

# Set VERBOSE=1 to see [DEBUG] lines on screen; they always go to the log file.
VERBOSE="${VERBOSE:-0}"

# ---------------------------------------------------------
# Raw log writer (NO COLORS)
# ---------------------------------------------------------
log_raw() {
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    # Never let a logging failure abort the installer.
    echo "[$ts] $*" >> "$LOG_FILE" 2>/dev/null || true
}

# ---------------------------------------------------------
# Point logging at the configured file and start a fresh log
# ---------------------------------------------------------
init_log() {
    local target="$1"
    mkdir -p "$(dirname "$target")" 2>/dev/null || true
    if : > "$target" 2>/dev/null; then
        LOG_FILE="$target"
    else
        log_warn "Cannot write to $target — keeping log at $LOG_FILE"
    fi
}

# ---------------------------------------------------------
# Screen + Log (colored on screen, plain in log)
# ---------------------------------------------------------
log_info()  { echo -e "${color_info}[INFO]${color_reset} $*";   log_raw "[INFO] $*"; }
log_ok()    { echo -e "${color_ok}[OK]${color_reset} $*";       log_raw "[OK] $*"; }
log_warn()  { echo -e "${color_warn}[WARN]${color_reset} $*";   log_raw "[WARN] $*"; }
log_error() { echo -e "${color_error}[ERROR]${color_reset} $*" >&2; log_raw "[ERROR] $*"; }
log_debug() {
    # Plain if/fi rather than a && list: under `set -e` a false && list
    # would abort the script whenever VERBOSE is 0.
    if [ "$VERBOSE" -eq 1 ]; then
        echo -e "${color_debug}[DEBUG]${color_reset} $*"
    fi
    log_raw "[DEBUG] $*"
}

# ---------------------------------------------------------
# Plain message shown on screen AND written to the log
# (for menus and other output that must be visible)
# ---------------------------------------------------------
log_plain() { echo "$*"; log_raw "$*"; }

# ---------------------------------------------------------
# Automatic Diagnostics (appended on failures)
# ---------------------------------------------------------
log_diagnostics() {
    # Every value is optional: diagnostics may run before anything is set.
    local mode="${MODE:-<unset>}"
    local target="${TARGET:-<unset>}"
    local part_data="${PART_DATA:-<unset>}"
    local mnt_dir="${MNT_DIR:-<unset>}"

    log_raw "=== Diagnostics Start ==="

    log_raw "--- MODE / TARGET ---"
    log_raw "MODE=$mode"
    log_raw "TARGET=$target"
    log_raw "PART_DATA=$part_data"
    log_raw "MNT_DIR=$mnt_dir"

    if [ -n "${PART_DATA:-}" ]; then
        log_raw "--- findmnt (partition) ---"
        findmnt -no TARGET,SOURCE,FSTYPE,OPTIONS "$PART_DATA" 2>&1 | sed 's/^/    /' >> "$LOG_FILE" || true
    fi

    if [ -n "${MNT_DIR:-}" ]; then
        log_raw "--- findmnt (mountpoint) ---"
        findmnt -no TARGET,SOURCE,FSTYPE,OPTIONS "$MNT_DIR" 2>&1 | sed 's/^/    /' >> "$LOG_FILE" || true

        log_raw "--- df -h ---"
        df -h "$MNT_DIR" 2>&1 | sed 's/^/    /' >> "$LOG_FILE" || true
    fi

    log_raw "--- lsblk ---"
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT 2>&1 | sed 's/^/    /' >> "$LOG_FILE" || true

    log_raw "--- dmesg (last 20 lines) ---"
    dmesg 2>&1 | tail -n 20 | sed 's/^/    /' >> "$LOG_FILE" || true

    log_raw "--- SELinux ---"
    getenforce 2>&1 | sed 's/^/    /' >> "$LOG_FILE" || true

    log_raw "=== Diagnostics End ==="
}

# ---------------------------------------------------------
# Interactive prompt guard
# ---------------------------------------------------------
# Destructive steps must never proceed unattended. If stdin is not a
# terminal there is nobody to confirm, so callers should abort rather than
# read EOF and fall through to a default.
is_interactive() { [ -t 0 ]; }

require_interactive() {
  if ! is_interactive; then
    log_error "$1 requires an interactive terminal (stdin is not a TTY)."
    return 1
  fi
  return 0
}
