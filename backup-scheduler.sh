#!/usr/bin/env bash
# Run daily backup at 2:30 PM ET, or catch up on next wake/boot if that time was missed.
# Pulls remote updates, commits local changes, then pushes. Does not poll every 30 minutes.
set -euo pipefail

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECTS_DIR/backup-tools}"
STAMP_FILE="${STAMP_FILE:-$BACKUP_DIR/.backup-last-run}"
LOG_FILE="${LOG_FILE:-$BACKUP_DIR/backup.log}"
BACKUP_SCRIPT="${BACKUP_SCRIPT:-$BACKUP_DIR/backup-all.sh}"

SCHEDULE_HOUR="${SCHEDULE_HOUR:-14}"
SCHEDULE_MINUTE="${SCHEDULE_MINUTE:-30}"

TODAY="$(date '+%Y-%m-%d')"
NOW_HOUR="$(date '+%H')"
NOW_MIN="$(date '+%M')"
NOW_MINS=$((10#$NOW_HOUR * 60 + 10#$NOW_MIN))
SCHEDULE_MINS=$((SCHEDULE_HOUR * 60 + SCHEDULE_MINUTE))

log_skip() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP scheduler ($1)" >>"$LOG_FILE"
}

already_ran_today() {
  [[ -f "$STAMP_FILE" ]] && [[ "$(cat "$STAMP_FILE")" == "$TODAY" ]]
}

mark_ran_today() {
  echo "$TODAY" >"$STAMP_FILE"
}

trigger="${1:-interval}"

if already_ran_today; then
  log_skip "already ran today"
  exit 0
fi

# Calendar jobs (scheduled / daily) always run. Catchup waits until 2:30.
if [[ "$trigger" != "scheduled" && "$trigger" != "daily" && "$NOW_MINS" -lt "$SCHEDULE_MINS" ]]; then
  log_skip "before ${SCHEDULE_HOUR}:$(printf '%02d' "$SCHEDULE_MINUTE"), waiting"
  exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] RUN  scheduler (trigger=$trigger)" >>"$LOG_FILE"

if "$BACKUP_SCRIPT"; then
  mark_ran_today
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] STAMP $TODAY" >>"$LOG_FILE"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAIL scheduler: backup-all.sh errored" >>"$LOG_FILE"
  exit 1
fi
