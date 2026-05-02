#!/usr/bin/env bash
set -euo pipefail
FILE="$(jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")"
[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx)
    if [ -f package.json ]; then npx prettier --write "$FILE" >/dev/null 2>&1 || true; fi
    ;;
  *.swift)
    # Add swiftformat here if installed, otherwise do nothing.
    ;;
esac
