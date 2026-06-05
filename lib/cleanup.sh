#!/bin/bash

cleanup() {
  local code=$?
  log_debug "Running cleanup trap (exit code: $code)"
  sudo umount "$MNT_DIR" 2>/dev/null || true
}
