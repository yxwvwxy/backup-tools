#!/usr/bin/env bash
set -euo pipefail

USER="${1:-yxwvwxy}"

create_and_push() {
  local dir="$1"
  local repo="$2"
  echo ""
  echo "=== $repo ==="
  cd "$dir"
  if git remote get-url origin &>/dev/null; then
    echo "remote already set, pushing..."
    git push -u origin main
  else
    gh repo create "$USER/$repo" --private --source=. --remote=origin --push
  fi
}

if ! gh auth status &>/dev/null; then
  echo "Not logged in. Run: gh auth login -h github.com -p https -w"
  exit 1
fi

create_and_push "$HOME/Projects/delivery-pivot" "delivery-pivot"
create_and_push "$HOME/Projects/unimap-auto-inbound" "unimap-auto-inbound"
create_and_push "$HOME/Projects/Pickup Database" "pickup-database"
create_and_push "$HOME/Projects/Shaken & Sorted" "shaken-and-sorted"

echo ""
echo "=== KOTC Meta Monitor (existing remote) ==="
cd "$HOME/Projects/KOTC Meta Monitor"
git push

echo ""
echo "Done. Repos:"
echo "  https://github.com/$USER/delivery-pivot"
echo "  https://github.com/$USER/unimap-auto-inbound"
echo "  https://github.com/$USER/pickup-database"
echo "  https://github.com/$USER/shaken-and-sorted"
