# Clarifications: l10n-foundation

## Question 1
How should L10n keys be structured in NSLocalizedString calls — using dot-notation string literals matching the namespace hierarchy, or flat snake_case keys?

*Context:* The key format directly determines how check_refs.py validates L10n usage and how .strings files are structured; inconsistency between L10n.swift and .strings files will break validation.

**Options:**
- A) Dot-notation matching namespace: 'library.title', 'reader.chapter', 'common.ok'
- B) Flat snake_case: 'library_title', 'reader_chapter', 'common_ok'
- C) PascalCase namespace prefix: 'Library.Title', 'Reader.Chapter', 'Common.Ok'

**Answer:**
Dot-notation matching namespace: 'library.title', 'reader.chapter', 'common.ok'

## Question 2
How should pluralization be handled for strings like '1 книга / 2 книги / 5 книг' — which is listed as an open question in the spec?

*Context:* Russian has 3 plural forms (one/few/many) requiring .stringsdict; ignoring this now means rework in milestone 09 when AR (also has 6 forms) is added.

**Options:**
- A) Use .stringsdict files for plural rules now (NSLocalizedString with NSNumber argument), add L10n static funcs for plural keys
- B) Use simple static func with manual Russian plural logic inline in L10n.swift, defer .stringsdict to milestone 09
- C) Skip pluralization entirely in this milestone — use neutral phrasing ('книг: 5') as a workaround

**Answer:**
Skip pluralization entirely in this milestone — use neutral phrasing ('книг: 5') as a workaround

## Question 3
Should L10n.swift be placed in the canonical App/Vreader/Vreader/ path (the active Xcode project) or in the root Vreader/ path (which appears to be a legacy/duplicate tree)?

*Context:* The file tree shows two parallel source trees — App/Vreader/Vreader/ and root Vreader/ — with an existing L10n.swift only in App/Vreader/Vreader/; publishing to the wrong tree means the file is not compiled.

**Options:**
- A) App/Vreader/Vreader/L10n.swift only — the active project target, matching existing L10n.swift location
- B) Both trees must be updated simultaneously to stay in sync
- C) Root Vreader/L10n.swift only — treat root tree as canonical going forward

**Answer:**
App/Vreader/Vreader/L10n.swift only — the active project target, matching existing L10n.swift location

## Question 4
What should check_refs.py do when it finds a hardcoded string in an existing UI file — fail the build, warn with a TODO comment, or silently skip?

*Context:* The spec says existing hardcoded strings should be 'marked TODO' but the acceptance criteria says check_refs.py must find no unresolved L10n keys — these two requirements conflict for the current codebase state.

**Options:**
- A) check_refs.py warns (non-blocking) for hardcoded UI strings in existing files, fails only for unresolved L10n.* key references
- B) check_refs.py fails on any hardcoded string in UI files — all existing files must be migrated as part of this milestone
- C) check_refs.py only validates that every L10n.* call has a matching key in .strings; hardcoded string detection is out of scope for this milestone

**Answer:**
check_refs.py warns (non-blocking) for hardcoded UI strings in existing files, fails only for unresolved L10n.* key references

## Question 5
Should parameterized L10n functions use String(format:) with printf-style format strings in .strings, or String interpolation with named placeholders?

*Context:* The spec defines L10n.Reader.pageOf(current:total:) but does not specify the underlying mechanism; this affects both the .strings file format and Swift 6 concurrency safety of the implementation.

**Options:**
- A) String(format: NSLocalizedString(...), current, total) with printf-style '%d of %d' in .strings — standard iOS pattern, Swift 6 safe
- B) Named placeholders with manual replacement: NSLocalizedString key contains '{current} of {total}', replaced via String.replacingOccurrences — no format string needed
- C) Use Swift string interpolation directly in L10n.swift with hardcoded structure — only the non-parameterized parts go through NSLocalizedString

**Answer:**
String(format: NSLocalizedString(...), current, total) with printf-style '%d of %d' in .strings — standard iOS pattern, Swift 6 safe
