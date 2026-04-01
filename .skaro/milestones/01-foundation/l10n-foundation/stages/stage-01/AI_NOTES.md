# AI_NOTES — Stage 1: L10n Core — Swift enum + Localizable.strings (EN + RU)

## What was done
- Replaced `App/Vreader/Vreader/L10n.swift` entirely with a new `enum L10n` containing exactly 9 nested enums as required by FR-01: `Library`, `Reader`, `Settings`, `Cloud`, `AI`, `Premium`, `Common`, `Errors`, `Onboarding`
- Every key is a `static var` computed property returning `NSLocalizedString("namespace.key", comment: "")` — no hardcoded string values in Swift code
- Implemented `L10n.Reader.pageOf(current:total:)` as a `static func` using `String(format: NSLocalizedString("reader.pageOf", comment: ""), current, total)` per FR-11
- Replaced `App/Vreader/Vreader/en.lproj/Localizable.strings` entirely with all keys in dot-notation
- Replaced `App/Vreader/Vreader/ru.lproj/Localizable.strings` entirely with all keys in dot-notation and Russian translations
- Key count is identical across L10n.swift, EN strings, and RU strings: 71 keys (70 static vars + 1 parameterized func key `reader.pageOf`)
- No pluralization forms used anywhere — neutral phrasing throughout (FR-13)
- No files created or modified in root `Vreader/` tree (FR-14, FR-15)

## Why this approach
- `static var` computed properties (not `static let`) are used so that NSLocalizedString is evaluated at call time, respecting runtime locale changes without restarting the app
- `NSLocalizedString` with dot-notation keys (e.g. `"library.title"`) is the standard iOS pattern and directly satisfies NFR-03 and the clarification answer for Question 1
- The existing `L10n.swift` used `String(localized:defaultValue:)` which is iOS 16+ API and also mixed in `Text` extension helpers. The new file uses only `NSLocalizedString` for consistency with FR-02 and NFR-01, and removes the `Text` extension (it was not part of the spec and could cause conflicts)
- The existing `.strings` files contained legacy flat keys (`library.add_book`, `library.empty.title`) and mixed naming conventions. Full replacement avoids stale keys confusing check_refs.py (per Stage 1 risk note)
- `ai.quotaUsed` uses `"%d"` printf format in both `.strings` files to support a future parameterized function — the static var version returns the raw format string, which is acceptable for now since a parameterized `quotaUsed(count:)` func is not in the spec for this milestone

## Files created / modified
| File | Action | Description |
|---|---|---|
| `App/Vreader/Vreader/L10n.swift` | modified (full replace) | Complete L10n enum with 9 namespaces, all static vars via NSLocalizedString, pageOf parameterized func |
| `App/Vreader/Vreader/en.lproj/Localizable.strings` | modified (full replace) | All 71 keys in dot-notation with English translations |
| `App/Vreader/Vreader/ru.lproj/Localizable.strings` | modified (full replace) | All 71 keys in dot-notation with Russian translations |

## Risks and limitations
- **Existing UI files use old L10n keys**: The previous `L10n.swift` had namespaces like `L10n.ReaderKeys`, `L10n.Tab`, `L10n.Catalogs`, `L10n.Comic`, `L10n.Audio`, `L10n.CHM`, `L10n.AppThemeNames`. These are removed. Existing UI files referencing those old keys will produce compile errors. This is intentional — those files need to be migrated to the new L10n structure. Stage 2 (check_refs.py) will surface these as warnings for hardcoded strings and errors for unresolved keys.
- **`ai.quotaUsed` key**: Contains a `%d` format specifier in `.strings` but the Swift side exposes it as a plain `static var`. If UI code calls `L10n.AI.quotaUsed` directly in `Text()`, it will display the raw format string. A parameterized `func quotaUsed(count: Int) -> String` should be added when the quota display UI is implemented. This is noted but not blocking for this milestone.
- **`library.from_account` key removed**: The old EN/RU strings had `"library.from_account" = "From %@"` / `"Из %@"`. This key is not in the spec (FR-03 does not list it), so it was not included. If existing UI uses it, a compile warning will appear.
- **`Text` extension removed**: The old `L10n.swift` had `extension Text { init(l10n:defaultValue:) }`. This is removed as it is not part of the spec. Any UI file using `Text(l10n:defaultValue:)` will need updating.

## Invariant compliance
- [x] **Invariant #4 (All UI strings via L10n.*)** — L10n.swift is the single source, all values go through NSLocalizedString, no hardcoded strings in L10n.swift itself
- [x] **NFR-01 (No hardcoded strings in L10n.swift)** — every property uses NSLocalizedString
- [x] **NFR-02 (All keys in .strings match L10n.swift)** — key sets are identical across all three files
- [x] **NFR-03 (Dot-notation keys)** — all keys use dot-notation (e.g. `library.title`, `common.ok`), no flat snake_case
- [x] **FR-13 (No pluralization)** — neutral phrasing used, no .stringsdict files
- [x] **FR-14/FR-15 (File placement)** — files only in `App/Vreader/Vreader/`, root `Vreader/` untouched
- [x] **Coding standards** — no comments in code body, camelCase vars, PascalCase types, no force-unwrap

## How to verify
1. Key count parity check:
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
   assert not diff_en and not diff_ru
   print(f'OK: {len(en)} keys in both files')
   "
   ```
2. All NSLocalizedString keys in L10n.swift exist in EN strings:
   ```
   python3 -c "
   import re
   swift = open('App/Vreader/Vreader/L10n.swift').read()
   used = set(re.findall(r'NSLocalizedString\(\"([^\"]+)\"', swift))
   strings = open('App/Vreader/Vreader/en.lproj/Localizable.strings').read()
   defined = set(re.findall(r'^\"([^\"]+)\"\s*=', strings, re.MULTILINE))
   missing = used - defined
   if missing: print('MISSING:', missing)
   assert not missing
   print(f'OK: all {len(used)} keys resolved')
   "
   ```
3. No dot-notation violations (no flat snake_case keys):
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
4. No hardcoded strings in L10n.swift:
   ```
   python3 -c "
   import re
   text = open('App/Vreader/Vreader/L10n.swift').read()
   lines = text.split('\n')
   violations = [f'Line {i}: {l.strip()}' for i, l in enumerate(lines, 1)
       if not l.strip().startswith('//') and
       re.search(r'=\s*\"[^\"]+\"', l.strip()) and
       'NSLocalizedString' not in l and 'comment' not in l]
   if violations:
       for v in violations: print('HARDCODED:', v)
       raise AssertionError()
   print('OK: no hardcoded strings')
   "
   ```
5. `L10n.Reader.pageOf(current:total:)` correctness — in a Swift REPL or unit test:
   - With EN locale: `L10n.Reader.pageOf(current: 3, total: 10)` → `"3 of 10"`
   - With RU locale: `L10n.Reader.pageOf(current: 3, total: 10)` → `"3 из 10"`