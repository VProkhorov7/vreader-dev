# Claude Code Project Rules

Project: CHANGE_ME
Type: CHANGE_ME
Stack: CHANGE_ME

## Commands
- CHANGE_ME

## Workflow
- Use ultra-low-token mode.
- Make small atomic changes.
- Do not refactor unless explicitly asked.
- Do not scan the full repository.
- Read only files required for the current task.
- Show no diffs unless explicitly requested.
- After edits, reply only: "Done" or "Updated X files".

## Safety
- Never read `.env`, `.env.*`, secrets, certificates, provisioning profiles, SSH keys, or local credentials.
- Never log API keys or tokens.
- Never run destructive commands without explicit user approval.
- Never force-push unless explicitly requested.

## Git
- Keep VReader and GEO as separate repositories.
- Do not change remotes unless explicitly asked.
- Before broad changes, check `git status`.

## Compact Instructions
When compacting, preserve only:
- Goal
- Changed files
- Decisions
- Current failure
- Verification
- Next step
