#!/usr/bin/env bash
set -euo pipefail
mkdir -p .claude/logs
jq -r '[now | todateiso8601, .tool_input.command] | @tsv' 2>/dev/null >> .claude/logs/commands.tsv || true
