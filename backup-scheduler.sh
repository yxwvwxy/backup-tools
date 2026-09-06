#!/usr/bin/env bash
# Sync with GitHub on a schedule, at load/wake catch-up, and every 30 minutes.
# Pulls remote updates, commits local changes, then pushes.
set -euo pipefail

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECTS_DIR/backup-tools}"
STAMP_FILE="${STAMP_FILE:-$BACKUP_DIR/.backup-last-run}"
LOG_FILE="${LOG_FILE:-$BACKUP_DIR/backup.log}"
BACKUP_SCRIPT="${BACKUP_SCRIPT:-$BACKUP_DIR/backup-all.sh}"

TODAY="$(date '+%Y-%m-%d')"
trigger="${1:-interval}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] RUN  scheduler (trigger=$trigger)" >>"$LOG_FILE"

if "$BACKUP_SCRIPT"; then
  echo "$TODAY" >"$STAMP_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] STAMP $TODAY" >>"$LOG_FILE"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAIL scheduler: backup-all.sh errored" >>"$LOG_FILE"
  exit 1
fi
