#!/usr/bin/env bash
set -euo pipefail

LOG_FILE=${LOG_FILE:-}
RSYNC_OPTS=${RSYNC_OPTS:--az --delete}

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  if [ -n "$LOG_FILE" ]; then
    echo "$msg" | tee -a "$LOG_FILE"
  else
    echo "$msg"
  fi
}

usage() {
  echo "Usage: $0 <source_dir> <destination>"
  echo "Destination can be a local path or remote rsync target (user@host:/path)."
  echo "Optional env vars: LOG_FILE=<path>, RSYNC_OPTS='-az --delete'"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  local src=${1:-}
  local dest=${2:-}

  if [ -z "$src" ] || [ -z "$dest" ]; then
    usage
    exit 1
  fi

  if [ ! -d "$src" ]; then
    log "Source directory not found: $src"
    exit 1
  fi

  if ! command -v rsync >/dev/null 2>&1; then
    log "rsync is required but not installed."
    exit 1
  fi

  log "Starting backup from '$src' to '$dest' with options: $RSYNC_OPTS"
  local start_ts end_ts
  start_ts=$(date '+%s')

  if rsync $RSYNC_OPTS "$src"/ "$dest"; then
    end_ts=$(date '+%s')
    log "Backup succeeded in $((end_ts - start_ts))s."
  else
    end_ts=$(date '+%s')
    log "Backup FAILED after $((end_ts - start_ts))s."
    exit 1
  fi
}

main "$@"
