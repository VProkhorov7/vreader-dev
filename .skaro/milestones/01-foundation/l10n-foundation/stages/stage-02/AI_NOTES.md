# AI_NOTES — Stage 2: check_refs.py — L10n validation logic

## What was done

- Rewrote both `check_refs.py` (project root) and `Description/check_refs.py` (mirror copy) entirely.
- Added `check_l10n_key_references()`: scans all `*.swift` files under `App/Vreader/Vreader/` for `L10n.<Namespace>.<key>` patterns using regex `\bL10n\.([A-Z][A-Za-z]*)\.([a-z][A-Za-z0-9]*)`. Derives the dot-notation key via `camel_to_dot()` and checks presence in both EN and RU `.strings` files. Missing key → `ERROR` → exit code 1.
- Added `check_l10n_swift_keys_in_strings()`: reads all `NSLocalizedString("key"` literals from `L10n.swift` and verifies each exists in both `.strings` files. Catches keys declared in Swift but accidentally omitted from a `.strings` file.
- Added `check_strings_parity()`: verifies EN and RU `.strings` files contain exactly the same key set. Asymmetry → `ERROR`.
- Added `check_dot_notation_keys()`: rejects flat `snake_case` keys (matching `^[a-z]+_[a-z_]+$`) in `.strings` files per NFR-03.
- Preserved all existing checks from the previous `check_refs.py`: duplicate types, UTType force-unwrap, coverData, iOS deprecated API, WKWebView OAuth, isPremium CloudKit, unbalanced braces, entitlements.
- Replaced the old `check_hardcoded_strings()` (which used a simpler pattern) with a more precise version that: matches `Text("...")`, `.navigationTitle("...")`, `.placeholder("...")`, `Label("...")`, `Button("...")`, `.help("...")`, `EmptyView("...")`; skips lines containing `L10n.`, `NSLocalizedString`, comments, `fatalError`, `print`, logger calls, enum raw values, URL strings, bundle identifiers, and other non-UI string contexts. Emits `WARN` only — non-blocking.
- Both files are identical in logic; the only difference is `ROOT` path resolution: root `check_refs.py` uses `Path(__file__).parent`, `Description/check_refs.py` uses `Path(__file__).parent.parent`.
- Added optional `scan_dir` CLI argument: `python3 check_refs.py App/Vreader/Vreader` — satisfies the verify step `python3 check_refs.py App/Vreader/Vreader`.
- `L10n.Reader.pageOf(current:total:)` is handled correctly: the regex captures `pageOf` from `L10n.Reader.pageOf(...)`, `camel_to_dot("Reader", "pageOf")` returns `"reader.pageOf"`, which exists in both `.strings` files → no error.

## Why this approach

- **Regex `\bL10n\.([A-Z][A-Za-z]*)\.([a-z][A-Za-z0-9]*)`**: The word boundary `\b` prevents false matches inside string literals or comments. The namespace group `[A-Z][A-Za-z]*` matches `AI` (all-caps) correctly because `A` is uppercase and `I` is in `[A-Za-z]*`. The key group `[a-z][A-Za-z0-9]*` matches camelCase keys starting with lowercase. Function call suffixes like `(current:total:)` are not captured — the regex stops at the key identifier, so `L10n.Reader.pageOf(current:total:)` correctly yields namespace=`Reader`, key=`pageOf`.
- **`L10N_NAMESPACE_MAP` dict**: Explicit mapping from Swift PascalCase namespace to dot-notation prefix. This is the single source of truth for the translation. Adding a new namespace requires only one line here. `AI` → `"ai"` is handled explicitly since the all-lowercase prefix cannot be derived mechanically from the PascalCase name.
- **`camel_to_dot` returns `None` for unknown namespaces**: Unknown namespaces emit a `WARN` (not `ERROR`) because they may be legitimate future additions not yet in the map. This avoids false positives blocking CI.
- **Two separate `ROOT` computations**: The root `check_refs.py` is invoked from the project root, so `Path(__file__).parent` is the project root. `Description/check_refs.py` is one level deeper, so it uses `.parent.parent`. Both resolve to the same `App/Vreader/Vreader` target directory.
- **`check_l10n_swift_keys_in_strings` as a separate check from `check_l10n_key_references`**: The reference check catches keys *used in code* that are missing from `.strings`. The Swift keys check catches keys *declared in L10n.swift* that are missing from `.strings`. Both directions are needed: a key could be declared but never used (caught by the Swift keys check), or used but the `.strings` entry could be deleted (caught by both).
- **Hardcoded string detection as `WARN` only**: Per NFR-04 and the clarification answer for Question 4, existing UI files may have hardcoded strings that predate this milestone. Making these errors would block CI on the existing codebase. Warnings surface the issues without blocking merge.
- **Skip patterns for hardcoded string detection**: The list of `_SKIP_LINE_PATTERNS` is intentionally broad to minimise false positives. URL strings, bundle identifiers, enum raw values, Keychain attribute keys, and logger calls all contain quoted strings that are not user-facing UI text. False negatives (missed hardcoded strings) are acceptable here since the check is non-blocking; false positives (blocking legitimate code) are not acceptable.

## Files created / modified

| File | Action | Description |
|---|---|---|
| `check_refs.py` | modified (full replace) | Root copy: complete rewrite with L10n validation, all existing checks preserved, CLI scan_dir argument added |
| `Description/check_refs.py` | modified (full replace) | Mirror copy: identical logic, ROOT path adjusted for Description/ subdirectory location |
| `AI_NOTES.md` | modified | Updated with Stage 2 notes |

## Risks and limitations

- **`AI` namespace regex match**: The regex `[A-Z][A-Za-z]*` matches `AI` because `A` is uppercase and `I` is in `[A-Za-z]*`. Verified: `re.match(r'[A-Z][A-Za-z]*', 'AI')` → match. The `L10N_NAMESPACE_MAP` explicitly maps `"AI"` → `"ai"`, so `L10n.AI.translate` correctly resolves to `"ai.translate"`.
- **Parameterised function calls with complex signatures**: The regex captures the method name before the `(` character. `L10n.Reader.pageOf(current: someVar, total: otherVar)` → key=`pageOf` → `"reader.pageOf"`. This works for any single-level method call. Chained calls like `L10n.Reader.pageOf(...).lowercased()` would still capture `pageOf` correctly since the regex stops at the first non-identifier character after the key.
- **`Description/check_refs.py` ROOT path**: Uses `Path(__file__).parent.parent` which resolves to the project root when the script is at `Description/check_refs.py`. If the `Description/` directory is moved, this path breaks. This is a known limitation of the existing project convention (mirroring files in two locations).
- **Brace balance check false positives**: String literals containing `{` or `}` (e.g. format strings, regex patterns, JSON) will skew the brace count. This is a pre-existing limitation inherited from the original script. It is non-trivial to fix without a full Swift parser.
- **`check_duplicate_types` and `L10n` enum**: The `L10n` enum and its nested enums (`Library`, `Reader`, etc.) are defined only in `L10n.swift`. The duplicate type check will not flag them as duplicates since they appear in exactly one file. However, if another file defines `enum Library` or `enum Common`, it will be flagged — this is correct behaviour.
- **No third-party dependencies added**: The script uses only Python standard library (`sys`, `re`, `pathlib`). No `requirements.txt` update needed.

## Invariant compliance

- [x] **Invariant #4 (All UI strings via L10n.*)** — enforced: `check_l10n_key_references` fails on unresolved keys; `check_hardcoded_strings` warns on hardcoded UI strings
- [x] **NFR-04 (check_refs.py exit behaviour)** — respected: exit code 1 only on unresolved L10n keys; hardcoded strings are warnings (exit code 0)
- [x] **NFR-03 (dot-notation keys)** — enforced: `check_dot_notation_keys` errors on flat snake_case keys
- [x] **Invariant #8 (coverData forbidden)** — preserved from original script
- [x] **Invariant #11 (OAuth via ASWebAuthenticationSession)** — preserved from original script
- [x] **Invariant #1 (isPremium source of truth)** — preserved from original script
- [x] **Invariant #12 (UTType optional binding)** — preserved from original script
- [x] **No third-party dependencies** — stdlib only, no new packages

## How to verify

1. **Exit code 0 on clean Stage 1 output:**
   ```
   python3 check_refs.py App/Vreader/Vreader
   ```
   Expected: `✅ No errors — warnings are informational only` (warnings for existing hardcoded strings in UI files are acceptable), exit code 0.

2. **Exit code 1 on unresolved key — inject a bad reference:**
   ```
   python3 -c "
   import subprocess, sys, tempfile, shutil
   from pathlib import Path
   tmp = Path(tempfile.mkdtemp())
   shutil.copy('App/Vreader/Vreader/LibraryView.swift', tmp / 'LibraryView.swift')
   (tmp / 'LibraryView.swift').write_text(
       (tmp / 'LibraryView.swift').read_text() + '\nlet _ = L10n.Library.nonExistentKey\n'
   )
   r = subprocess.run(['python3', 'check_refs.py', str(tmp)], capture_output=True)
   print(r.stdout.decode())
   assert r.returncode == 1, f'Expected exit 1, got {r.returncode}'
   print('OK: exit code 1 on unresolved key')
   "
   ```

3. **pageOf parameterised function resolves correctly:**
   ```
   python3 -c "
   import re
   L10N_NAMESPACE_MAP = {'Reader': 'reader'}
   pattern = re.compile(r'\bL10n\.([A-Z][A-Za-z]*)\.([a-z][A-Za-z0-9]*)')
   test = 'Text(L10n.Reader.pageOf(current: page, total: total))'
   m = pattern.search(test)
   assert m, 'No match'
   ns, key = m.group(1), m.group(2)
   dot_key = f\"{L10N_NAMESPACE_MAP[ns]}.{key}\"
   assert dot_key == 'reader.pageOf', f'Got {dot_key}'
   print(f'OK: pageOf → {dot_key}')
   "
   ```

4. **EN/RU key parity check:**
   ```
   python3 -c "
   import re
   def keys(path):
       text = open(path).read()
       return set(re.findall(r'^\"([^\"]+)\"\s*=', text, re.MULTILINE))
   en = keys('App/Vreader/Vreader/en.lproj/Localizable.strings')
   ru = keys('App/Vreader/Vreader/ru.lproj/Localizable.strings')
   diff_en = en - ru
   diff_ru = ru - en
   if diff_en: print('MISSING IN RU:', diff_en)
   if diff_ru: print('MISSING IN EN:', diff_ru)
   assert not diff_en and not diff_ru, 'Key mismatch'
   print(f'OK: {len(en)} keys in both files')
   "
   ```

5. **No flat snake_case keys:**
   ```
   python3 -c "
   import re
   text = open('App/Vreader/Vreader/en.lproj/Localizable.strings').read()
   flat = re.findall(r'^\"([a-z]+_[a-z_]+)\"\s*=', text, re.MULTILINE)
   if flat: print('FLAT KEYS:', flat)
   assert not flat
   print('OK: all keys use dot-notation')
   "
   ```

6. **Description/check_refs.py produces same result:**
   ```
   python3 Description/check_refs.py App/Vreader/Vreader
   ```
   Expected: same output as root `check_refs.py`, exit code 0.