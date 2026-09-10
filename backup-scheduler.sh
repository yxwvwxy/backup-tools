#!/usr/bin/env bash
# Sync with GitHub once a day, plus login/wake catch-up if today has not run yet.
# Pulls remote updates, commits local changes, then pushes.
set -euo pipefail

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECTS_DIR/backup-tools}"
STAMP_FILE="${STAMP_FILE:-$BACKUP_DIR/.backup-last-run}"
LOG_FILE="${LOG_FILE:-$BACKUP_DIR/backup.log}"
BACKUP_SCRIPT="${BACKUP_SCRIPT:-$BACKUP_DIR/backup-all.sh}"

TODAY="$(date '+%Y-%m-%d')"
trigger="${1:-daily}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] RUN  scheduler (trigger=$trigger)" >>"$LOG_FILE"

if [[ "$trigger" != "force" && -f "$STAMP_FILE" && "$(cat "$STAMP_FILE")" == "$TODAY" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP already ran today" >>"$LOG_FILE"
  exit 0
fi

if "$BACKUP_SCRIPT"; then
  echo "$TODAY" >"$STAMP_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] STAMP $TODAY" >>"$LOG_FILE"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAIL scheduler: backup-all.sh errored" >>"$LOG_FILE"
  exit 1
fi
