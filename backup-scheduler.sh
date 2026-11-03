#!/usr/bin/env bash
# Run daily backup at 2:00 PM, or catch up on next wake/boot if that run was missed.
# A catch-up before 2 PM the next day still counts as the previous day's run,
# so that day's 2 PM run still happens. Pulls remote updates, commits local changes, then pushes.
set -euo pipefail

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECTS_DIR/backup-tools}"
STAMP_FILE="${STAMP_FILE:-$BACKUP_DIR/.backup-last-run}"
LOG_FILE="${LOG_FILE:-$BACKUP_DIR/backup.log}"
BACKUP_SCRIPT="${BACKUP_SCRIPT:-$BACKUP_DIR/backup-all.sh}"

SCHEDULE_HOUR="${SCHEDULE_HOUR:-14}"
SCHEDULE_MINUTE="${SCHEDULE_MINUTE:-0}"

NOW_HOUR="$(date '+%H')"
NOW_MIN="$(date '+%M')"
NOW_MINS=$((10#$NOW_HOUR * 60 + 10#$NOW_MIN))
SCHEDULE_MINS=$((SCHEDULE_HOUR * 60 + SCHEDULE_MINUTE))

# The most recent scheduled run that is due: today's if we're past the
# schedule time, otherwise yesterday's.
if [[ "$NOW_MINS" -ge "$SCHEDULE_MINS" ]]; then
  DUE_DAY="$(date '+%Y-%m-%d')"
else
  DUE_DAY="$(date -v-1d '+%Y-%m-%d')"
fi

log_skip() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP scheduler ($1)" >>"$LOG_FILE"
}

already_ran() {
  # Stamps are YYYY-MM-DD, so string comparison is date order.
  [[ -f "$STAMP_FILE" ]] && [[ ! "$(cat "$STAMP_FILE")" < "$DUE_DAY" ]]
}

mark_ran() {
  echo "$DUE_DAY" >"$STAMP_FILE"
}

trigger="${1:-interval}"

if already_ran; then
  log_skip "run for $DUE_DAY already done"
  exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] RUN  scheduler (trigger=$trigger, for $DUE_DAY)" >>"$LOG_FILE"

if "$BACKUP_SCRIPT"; then
  mark_ran
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] STAMP $DUE_DAY" >>"$LOG_FILE"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAIL scheduler: backup-all.sh errored" >>"$LOG_FILE"
  exit 1
fi
