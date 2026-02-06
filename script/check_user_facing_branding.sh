#!/usr/bin/env bash
set -euo pipefail

# Fails if any user-facing "ClawDeck" branding appears in UI text.
# We intentionally do NOT scan config/application.rb (Ruby module name) or logs.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Directories that contain user-facing strings.
SCAN_DIRS=(app/views app/controllers app/helpers app/models config/locales public docs README.md)

# Exclusions for known non-user-facing identifiers.
EXCLUDES=(
  "--exclude-dir=log"
  "--exclude-dir=tmp"
  "--exclude-dir=node_modules"
  "--exclude=*.log"
)

set +e
matches=$(grep -RIn "ClawDeck" "${EXCLUDES[@]}" "${SCAN_DIRS[@]}" 2>/dev/null)
status=$?
set -e

if [[ $status -eq 0 ]]; then
  echo "FAIL: Found user-facing 'ClawDeck' strings:"
  echo "$matches"
  exit 1
fi

echo "OK: No user-facing 'ClawDeck' strings found in scanned paths."
