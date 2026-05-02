---
paths:
  - "app/api/**/*.ts"
  - "lib/api/**/*.ts"
---

# API Rules

- Validate input before calling external APIs.
- Never log API keys, tokens, base URLs with secrets, or request bodies containing secrets.
- Return clear user-facing errors.
- Do not expose internal stack traces.
- Keep request/response logic minimal.
