# Fix Log: error-code-system

---

## 2026-03-31 22:07

**User:** ## Test execution context

**Environment**: OS: Darwin 25.4.0; Project root: /Users/pvlad/VReader

**Verify commands** (from verify.yaml):
- `name: Check old ErrorCode.swift deleted (App target)`  (name:)
- `name: Check old ErrorCode.swift deleted (root target)`  (name:)
- `name: Check AppError.swift exists (App target)`  (name:)
- `name: Check AppError.swift exists (root target)`  (name:)
- `name: Check no remaining references to old ErrorCode type`  (name:)
- `name: Check analyticsCode format (no slashes, no spaces, dot-separated only)`  (name:)
- `name: Check TODO L10n comments present`  (name:)
- `name: Check AI_NOTES.md exists`  (name:)
- `name: Check Sendable conformances present`  (name:)
- `name: Build App target`  (name:)
- `name: Run unit tests`  (name:)

## Issues found during automated testing

### Issue 1: Test files present
- **Type**: check
- **Severity**: warning
- **Detail**: No test files found

### Issue 2: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 2
- **Command**: `name: Check old ErrorCode.swift deleted (App target)`
- **Output**:
```
/bin/sh: -c: line 0: syntax error near unexpected token `('
/bin/sh: -c: line 0: `name: Check old ErrorCode.swift deleted (App target)'
```

### Issue 3: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 2
- **Command**: `name: Check old ErrorCode.swift deleted (root target)`
- **Output**:
```
/bin/sh: -c: line 0: syntax error near unexpected token `('
/bin/sh: -c: line 0: `name: Check old ErrorCode.swift deleted (root target)'
```

### Issue 4: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 2
- **Command**: `name: Check AppError.swift exists (App target)`
- **Output**:
```
/bin/sh: -c: line 0: syntax error near unexpected token `('
/bin/sh: -c: line 0: `name: Check AppError.swift exists (App target)'
```

### Issue 5: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 2
- **Command**: `name: Check AppError.swift exists (root target)`
- **Output**:
```
/bin/sh: -c: line 0: syntax error near unexpected token `('
/bin/sh: -c: line 0: `name: Check AppError.swift exists (root target)'
```

### Issue 6: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 127
- **Command**: `name: Check no remaining references to old ErrorCode type`
- **Output**:
```
/bin/sh: name:: command not found
```

### Issue 7: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 2
- **Command**: `name: Check analyticsCode format (no slashes, no spaces, dot-separated only)`
- **Output**:
```
/bin/sh: -c: line 0: syntax error near unexpected token `('
/bin/sh: -c: line 0: `name: Check analyticsCode format (no slashes, no spaces, dot-separated only)'
```

### Issue 8: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 127
- **Command**: `name: Check TODO L10n comments present`
- **Output**:
```
/bin/sh: name:: command not found
```

### Issue 9: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 127
- **Command**: `name: Check AI_NOTES.md exists`
- **Output**:
```
/bin/sh: name:: command not found
```

### Issue 10: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 127
- **Command**: `name: Check Sendable conformances present`
- **Output**:
```
/bin/sh: name:: command not found
```

### Issue 11: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 127
- **Command**: `name: Build App target`
- **Output**:
```
/bin/sh: name:: command not found
```

### Issue 12: name:
- **Type**: command
- **Severity**: error
- **Detail**: Exit code 127
- **Command**: `name: Run unit tests`
- **Output**:
```
/bin/sh: name:: command not found
```

## Instructions

CRITICAL: Diagnose the ROOT CAUSE before doing anything else.

The source files mentioned in errors are provided to you in the "Selected source files" section above. Use ONLY their actual content for diagnosis — do NOT guess or regenerate file content.

Common root causes that do NOT require code changes:
- Wrong execution environment (commands run on host but project runs in Docker)
- Python/Node/etc not on PATH, virtual environment not activated
- Incorrect paths in verify commands (cd to wrong directory)
- Missing dependencies not installed
- Test configuration issues (wrong working directory, missing env vars)

If ANY of the above is the root cause:
→ Do NOT output any source code files
→ Do NOT rewrite, refactor, or 'improve' existing code
→ Explain the root cause and suggest how to fix the verify commands or environment

Only output source code files if the root cause is a genuine bug in the source code itself.

**LLM:** ## Root Cause Analysis

All 11 command errors share the same root cause: **the verify commands were written as YAML key-value pairs but are being executed literally as shell commands**.

The test runner is passing the entire YAML line — including the `name:` key and the human-readable label — directly to `/bin/sh -c`. For example:

```
name: Check old ErrorCode.swift deleted (App target)
```

is being executed as a shell command, which is why the shell reports:
- `syntax error near unexpected to...

**Proposed files:** (no files)
