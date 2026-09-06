#!/usr/bin/env bash
# Install the Mac backup scheduler (login/wake + every 30 minutes).
# Uses backup-scheduler.sh already in this repo — same job as the MacBook.
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
    <string>interval</string>
  </array>
  <key>WorkingDirectory</key>
  <string>${BACKUP_DIR}</string>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>1800</integer>
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
echo "Runs backup-scheduler.sh at login/wake and every 30 minutes."
echo "Kickstarting one sync now..."
launchctl kickstart -k "gui/${UID_NUM}/${LABEL}"
echo "Done."
