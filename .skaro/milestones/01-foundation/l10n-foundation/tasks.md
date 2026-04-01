# Tasks: l10n-foundation

## Stage 1: L10n Core — Swift enum + Localizable.strings (EN + RU)

- [ ] Replace `App/Vreader/Vreader/L10n.swift` with full `enum L10n` definition containing all 9 namespaces → `App/Vreader/Vreader/L10n.swift`
- [ ] Implement `Library` namespace with all 10 keys (FR-03) as `static var` returning `NSLocalizedString` → `App/Vreader/Vreader/L10n.swift`
- [ ] Implement `Reader` namespace with all 14 keys (FR-04) plus `pageOf(current:total:)` parameterized func → `App/Vreader/Vreader/L10n.swift`
- [ ] Implement `Settings` namespace with all 12 keys (FR-05) → `App/Vreader/Vreader/L10n.swift`
- [ ] Implement `Cloud` namespace with all 18 keys (FR-06) → `App/Vreader/Vreader/L10n.swift`
- [ ] Implement `AI` namespace with all 11 keys (FR-07) → `App/Vreader/Vreader/L10n.swift`
- [ ] Implement `Premium` namespace with all 10 keys (FR-08) → `App/Vreader/Vreader/L10n.swift`
- [ ] Implement `Common` namespace with all 12 keys (FR-09) → `App/Vreader/Vreader/L10n.swift`
- [ ] Implement `Errors` namespace with all 7 keys (FR-10) → `App/Vreader/Vreader/L10n.swift`
- [ ] Implement `Onboarding` namespace (FR-01, placeholder keys) → `App/Vreader/Vreader/L10n.swift`
- [ ] Write `en.lproj/Localizable.strings` with all dot-notation keys and English translations → `App/Vreader/Vreader/en.lproj/Localizable.strings`
- [ ] Write `ru.lproj/Localizable.strings` with all dot-notation keys and Russian translations → `App/Vreader/Vreader/ru.lproj/Localizable.strings`
- [ ] Verify `reader.pageOf` key present in both `.strings` files with printf format `%d of %d` (EN) and `%d из %d` (RU)

## Stage 2: check_refs.py — L10n validation logic

- [ ] Implement regex scanner for `L10n.<Namespace>.<key>` property access patterns in Swift files → `check_refs.py`
- [ ] Implement regex scanner for `L10n.<Namespace>.<func>(` call patterns mapping to keys → `check_refs.py`
- [ ] Implement `.strings` file parser extracting all defined dot-notation keys → `check_refs.py`
- [ ] Implement unresolved key detection: referenced key absent from EN or RU `.strings` → exit code 1 → `check_refs.py`
- [ ] Implement hardcoded string detector for `Text("...")` and similar SwiftUI patterns → WARNING output, non-blocking → `check_refs.py`
- [ ] Ensure exit code 0 when only warnings present, exit code 1 only on unresolved keys → `check_refs.py`
- [ ] Mirror updated script to `Description/check_refs.py` → `Description/check_refs.py`
- [ ] Write `AI_NOTES.md` documenting key mapping logic, regex patterns used, and known limitations → `AI_NOTES.md`