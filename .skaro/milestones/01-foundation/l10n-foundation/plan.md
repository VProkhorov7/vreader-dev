## plan.md

## Stage 1: L10n Core — Swift enum + Localizable.strings (EN + RU)

**Goal:** Implement the complete `L10n` enum with all namespaces and parameterized functions, plus both `.strings` files with all keys in dot-notation. This is the entire functional deliverable of the spec.

**Depends on:** none

**Inputs:**
- Spec: FR-01 through FR-15
- Existing `App/Vreader/Vreader/L10n.swift` (to be replaced)
- Existing `App/Vreader/Vreader/en.lproj/Localizable.strings` (to be replaced)
- Existing `App/Vreader/Vreader/ru.lproj/Localizable.strings` (to be replaced)

**Outputs:**
- `App/Vreader/Vreader/L10n.swift`
- `App/Vreader/Vreader/en.lproj/Localizable.strings`
- `App/Vreader/Vreader/ru.lproj/Localizable.strings`

**DoD:**
- [ ] `enum L10n` defined with 9 nested enums: `Library`, `Reader`, `Settings`, `Cloud`, `AI`, `Premium`, `Common`, `Errors`, `Onboarding`
- [ ] Every key is a `static var` returning `NSLocalizedString("namespace.key", comment: "")`
- [ ] `L10n.Reader.pageOf(current:total:)` implemented via `String(format: NSLocalizedString("reader.pageOf", comment: ""), current, total)`
- [ ] All keys from FR-03 through FR-10 present in L10n.swift
- [ ] `en.lproj/Localizable.strings` contains every key used in L10n.swift with dot-notation
- [ ] `ru.lproj/Localizable.strings` contains every key used in L10n.swift with dot-notation
- [ ] No hardcoded strings in L10n.swift — only `NSLocalizedString` calls
- [ ] No pluralization forms — neutral phrasing used throughout
- [ ] No keys created in root `Vreader/` tree
- [ ] Key count in EN `.strings` == key count in RU `.strings` == key count in L10n.swift

**Risks:**
- Existing `L10n.swift` may define types that conflict — must fully replace, not append
- `.strings` files may have legacy flat keys — must replace entirely to avoid stale keys confusing check_refs.py

---

## Stage 2: check_refs.py — L10n validation logic

**Goal:** Update `check_refs.py` to implement NFR-04: warn (non-blocking) on hardcoded UI strings in existing Swift files, fail with exit code 1 only on unresolved `L10n.*` key references (keys used in code but absent from `.strings` files).

**Depends on:** Stage 1 (needs the canonical set of keys in `.strings` files to validate against)

**Inputs:**
- `Description/check_refs.py` (existing script, to be updated)
- `App/Vreader/Vreader/L10n.swift` (Stage 1 output — source of truth for defined keys)
- `App/Vreader/Vreader/en.lproj/Localizable.strings` (Stage 1 output)
- `App/Vreader/Vreader/ru.lproj/Localizable.strings` (Stage 1 output)
- All `*.swift` files under `App/Vreader/Vreader/` (scanned for L10n usage and hardcoded strings)

**Outputs:**
- `Description/check_refs.py` (updated)
- `check_refs.py` (root copy, updated — mirrors Description/ copy per existing project convention)
- `AI_NOTES.md` (updated)

**DoD:**
- [ ] Script parses all `*.swift` files under `App/Vreader/Vreader/` for `L10n.<Namespace>.<key>` patterns
- [ ] Script extracts the string key each reference resolves to (e.g. `L10n.Library.title` → `"library.title"`)
- [ ] Script reads all keys from both `en.lproj/Localizable.strings` and `ru.lproj/Localizable.strings`
- [ ] If a referenced key is missing from either `.strings` file → print `ERROR: unresolved key` and exit with code 1
- [ ] Script scans SwiftUI view files for hardcoded string literals in `Text("...")` and similar patterns → prints `WARNING:` (non-blocking)
- [ ] Script exits with code 0 when only warnings are present (no unresolved keys)
- [ ] Script exits with code 1 when any unresolved L10n key is found
- [ ] Running against the Stage 1 output produces exit code 0 (all keys resolve)
- [ ] Script handles `L10n.Reader.pageOf(current:total:)` — parameterized func maps to key `"reader.pageOf"` correctly

**Risks:**
- Regex for `L10n.<Namespace>.<key>` must handle both property access (`L10n.Common.ok`) and function calls (`L10n.Reader.pageOf(current:total:)`) — two distinct patterns needed
- Existing `check_refs.py` may have unrelated validation logic that must be preserved

---

## Verify

```yaml
- name: "Check EN strings key count matches RU strings key count"
  command: "python3 -c \"
import re
def keys(path):
    text = open(path).read()
    return set(re.findall(r'^\\\"([^\\\"]+)\\\"\\s*=', text, re.MULTILINE))
en = keys('App/Vreader/Vreader/en.lproj/Localizable.strings')
ru = keys('App/Vreader/Vreader/ru.lproj/Localizable.strings')
diff_en = en - ru
diff_ru = ru - en
if diff_en: print('MISSING IN RU:', diff_en)
if diff_ru: print('MISSING IN EN:', diff_ru)
assert not diff_en and not diff_ru, 'Key mismatch between EN and RU'
print(f'OK: {len(en)} keys in both files')
\""

- name: "Check all L10n NSLocalizedString keys exist in EN strings"
  command: "python3 -c \"
import re
swift = open('App/Vreader/Vreader/L10n.swift').read()
used_keys = set(re.findall(r'NSLocalizedString\\(\\\"([^\\\"]+)\\\",', swift))
strings = open('App/Vreader/Vreader/en.lproj/Localizable.strings').read()
defined_keys = set(re.findall(r'^\\\"([^\\\"]+)\\\"\\s*=', strings, re.MULTILINE))
missing = used_keys - defined_keys
if missing: print('MISSING KEYS:', missing)
assert not missing, 'Unresolved keys in EN strings'
print(f'OK: all {len(used_keys)} keys resolved')
\""

- name: "check_refs.py exits 0 on clean codebase"
  command: "python3 check_refs.py App/Vreader/Vreader"

- name: "No dot-notation violations — all keys use dots not underscores"
  command: "python3 -c \"
import re
text = open('App/Vreader/Vreader/en.lproj/Localizable.strings').read()
flat_keys = re.findall(r'^\\\"([a-z]+_[a-z_]+)\\\"\\s*=', text, re.MULTILINE)
if flat_keys: print('FLAT KEYS FOUND:', flat_keys)
assert not flat_keys, 'Flat snake_case keys found — must use dot-notation'
print('OK: all keys use dot-notation')
\""

- name: "No hardcoded strings in L10n.swift itself"
  command: "python3 -c \"
import re
text = open('App/Vreader/Vreader/L10n.swift').read()
lines = text.split('\n')
violations = []
for i, line in enumerate(lines, 1):
    stripped = line.strip()
    if stripped.startswith('//'):
        continue
    if re.search(r'=\s*\\\"[^\\\"]+\\\"', stripped) and 'NSLocalizedString' not in stripped and 'comment' not in stripped:
        violations.append(f'Line {i}: {stripped}')
if violations:
    for v in violations: print('HARDCODED:', v)
    raise AssertionError('Hardcoded strings found in L10n.swift')
print('OK: no hardcoded strings in L10n.swift')
\""
```