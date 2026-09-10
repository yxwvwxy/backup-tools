#!/usr/bin/env bash
# Install the Mac backup scheduler (once a day, plus login/wake catch-up).
# Uses backup-scheduler.sh already in this repo.
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$HOME/Projects/backup-tools}"
LABEL="com.yxwvwxy.backup-sync"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
UID_NUM="$(id -u)"

mkdir -p "$HOME/Library/LaunchAgents"

cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${BACKUP_DIR}/backup-scheduler.sh</string>
    <string>daily</string>
  </array>
  <key>WorkingDirectory</key>
  <string>${BACKUP_DIR}</string>
  <key>RunAtLoad</key>
  <true/>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>21</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>${BACKUP_DIR}/scheduler.out.log</string>
  <key>StandardErrorPath</key>
  <string>${BACKUP_DIR}/scheduler.err.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>${HOME}</string>
    <key>PATH</key>
    <string>${HOME}/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>GIT_AUTHOR_NAME</key>
    <string>Vivienne</string>
    <key>GIT_AUTHOR_EMAIL</key>
    <string>yxwvwxy@users.noreply.github.com</string>
    <key>GIT_COMMITTER_NAME</key>
    <string>Vivienne</string>
    <key>GIT_COMMITTER_EMAIL</key>
    <string>yxwvwxy@users.noreply.github.com</string>
  </dict>
</dict>
</plist>
EOF

launchctl bootout "gui/${UID_NUM}" "$PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/${UID_NUM}" "$PLIST"
launchctl enable "gui/${UID_NUM}/${LABEL}"

echo "Installed ${PLIST}"
echo "Runs backup-scheduler.sh once a day at 21:00, and on login if today has not run yet."
echo "Done."
