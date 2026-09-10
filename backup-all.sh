#!/usr/bin/env bash
# Sync git repos with GitHub: pull remote updates, commit local changes, then push.
set -euo pipefail

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECTS_DIR/backup-tools}"
LOG_FILE="${LOG_FILE:-$BACKUP_DIR/backup.log}"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"
TODAY="$(date '+%Y-%m-%d')"
export GIT_TERMINAL_PROMPT=0
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-Vivienne}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-yxwvwxy@users.noreply.github.com}"
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-$GIT_AUTHOR_NAME}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-$GIT_AUTHOR_EMAIL}"

log() {
  echo "[$DATE] $*" | tee -a "$LOG_FILE"
}

backup_repo() {
  local dir="$1"
  local name
  name="$(basename "$dir")"

  if [[ ! -d "$dir/.git" ]]; then
    return 0
  fi

  if ! git -C "$dir" remote get-url origin &>/dev/null; then
    log "SKIP $name: no remote"
    return 0
  fi

  local fetched=1
  if ! git -C "$dir" fetch origin --quiet 2>>"$LOG_FILE"; then
    log "WARN $name: fetch failed (offline?)"
    fetched=0
  fi

  local branch
  branch="$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  if [[ -z "$branch" ]]; then
    log "SKIP $name: detached HEAD"
    return 0
  fi

  local dirty=0
  local changed=0
  if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
    dirty=1
  fi

  if [[ "$dirty" -eq 1 ]]; then
    git -C "$dir" add -A
    if git -C "$dir" diff --cached --quiet; then
      log "OK   $name: nothing to commit after add"
    else
      git -C "$dir" commit -m "Daily backup $TODAY"
      log "COMMIT $name"
      changed=1
    fi
  fi

  local upstream="origin/$branch"
  local has_upstream=0
  if git -C "$dir" rev-parse --verify "$upstream" &>/dev/null; then
    has_upstream=1
  fi

  if [[ "$fetched" -eq 1 && "$has_upstream" -eq 1 ]]; then
    local behind
    behind="$(git -C "$dir" rev-list --count "HEAD..$upstream" 2>/dev/null || echo 0)"
    if [[ "$behind" -gt 0 ]]; then
      if git -C "$dir" pull --rebase --autostash origin "$branch" >>"$LOG_FILE" 2>&1; then
        log "PULL $name ($behind commit(s))"
        changed=1
      else
        git -C "$dir" rebase --abort >/dev/null 2>&1 || true
        log "FAIL $name: pull rebase conflict — fix on this machine, then the next sync will retry"
        return 1
      fi
    fi
  fi

  local ahead=0
  if [[ "$has_upstream" -eq 1 ]]; then
    ahead="$(git -C "$dir" rev-list --count "$upstream..HEAD" 2>/dev/null || echo 0)"
  else
    ahead="$(git -C "$dir" rev-list --count HEAD 2>/dev/null || echo 1)"
  fi

  if [[ "$ahead" -eq 0 ]]; then
    if [[ "$changed" -eq 0 ]]; then
      log "OK   $name: no changes"
    else
      log "OK   $name: already up to date"
    fi
    return 0
  fi

  if git -C "$dir" push origin "$branch" >>"$LOG_FILE" 2>&1; then
    log "PUSH $name ($ahead commit(s))"
  else
    log "FAIL $name: push failed"
    return 1
  fi
}

main() {
  mkdir -p "$PROJECTS_DIR"
  log "=== backup start ==="

  local failed=0
  local dir

  while IFS= read -r -d '' dir; do
    if ! backup_repo "$dir"; then
      failed=1
    fi
  done < <(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  if [[ "$failed" -eq 0 ]]; then
    log "=== backup done ==="
  else
    log "=== backup done (with errors) ==="
    exit 1
  fi
}

main "$@"
