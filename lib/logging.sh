#!/bin/bash

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

log_raw() {
  echo "$@" | tee -a "$LOG_FILE"
}

log_debug() {
  echo "[$(timestamp)] [DEBUG] $@" | tee -a "$LOG_FILE"
}

log_info() {
  echo "[$(timestamp)] [INFO] $@" | tee -a "$LOG_FILE"
}

log_ok() {
  echo "[$(timestamp)] [OK] $@" | tee -a "$LOG_FILE"
}

log_error() {
  echo "[$(timestamp)] [ERROR] $@" | tee -a "$LOG_FILE" >&2
}
