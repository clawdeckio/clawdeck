#!/usr/bin/env bash
set -euo pipefail

# Fails if stale user-facing branding or stale public domains appear.
# We intentionally do NOT scan config/application.rb (Ruby module name) or logs.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Directories that contain user-facing strings.
SCAN_DIRS=(
  app/views
  app/controllers
  app/helpers
  app/models
  config/locales
  public
  docs
  README.md
  CONTRIBUTING.md
  QUICKSTART.md
  DEPLOYMENT.md
)

# Exclusions for known non-user-facing identifiers.
EXCLUDES=(
  "--exclude-dir=log"
  "--exclude-dir=tmp"
  "--exclude-dir=node_modules"
  "--exclude=*.log"
  # Docs that explicitly discuss internal identifiers may mention "ClawDeck".
  "--exclude=BRANDING_IDENTIFIERS.md"
)

CHECKS=(
  "ClawDeck|user-facing 'ClawDeck' strings"
  "Claw Deck|user-facing 'Claw Deck' strings"
  "PokeDeck|user-facing 'PokeDeck' strings (use PokéDeck)"
  "clawdeck\\.so|stale clawdeck.so domain references"
)

found=0

for check in "${CHECKS[@]}"; do
  pattern="${check%%|*}"
  label="${check#*|}"

  set +e
  matches=$(grep -RInE "${pattern}" "${EXCLUDES[@]}" "${SCAN_DIRS[@]}" 2>/dev/null)
  status=$?
  set -e

  if [[ $status -eq 0 ]]; then
    if [[ $found -eq 0 ]]; then
      echo "FAIL: Found stale user-facing branding/domain references:"
    fi
    echo
    echo "- ${label}:"
    echo "$matches"
    found=1
  elif [[ $status -gt 1 ]]; then
    echo "ERROR: Failed to scan for pattern: ${pattern}"
    exit $status
  fi
done

if [[ $found -eq 1 ]]; then
  exit 1
fi

echo "OK: No stale user-facing branding/domain strings found in scanned paths."
