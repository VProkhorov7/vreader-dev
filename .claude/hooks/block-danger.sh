#!/usr/bin/env bash
set -euo pipefail
INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")"

if printf '%s' "$CMD" | grep -Eq 'rm[[:space:]]+-rf[[:space:]]+/|git[[:space:]]+push[[:space:]]+(-f|--force)|sudo|chmod[[:space:]]+777|curl.*[|].*sh|wget.*[|].*sh'; then
  echo "BLOCKED: dangerous command: $CMD" >&2
  exit 2
fi
