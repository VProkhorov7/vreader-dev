# Clarifications: project-cleanup

## Question 1
Which version of the project is the canonical source of truth: App/Vreader/Vreader/ or the root Vreader/ directory?

*Context:* Both directories contain overlapping files (Book.swift, ContentSource.swift, etc.) and each has its own .xcodeproj — choosing the wrong one as canonical means discarding potentially newer code.

**Options:**
- A) App/Vreader/Vreader/ is canonical — it has more files (AppTheme, DesignTokens, DiagnosticsService, themes, readers) and is clearly more advanced
- B) Root Vreader/ is canonical — it has ErrorCode.swift and some unique files (StorageView, StoragesView, ReadingSessionView) that App/ lacks
- C) Merge both: take the superset of unique files from each directory into App/Vreader/Vreader/

**Answer:**
App/Vreader/Vreader/ is canonical — it has more files (AppTheme, DesignTokens, DiagnosticsService, themes, readers) and is clearly more advanced

## Question 2
What should happen to the root-level Vreader/ directory and Vreader.xcodeproj after cleanup?

*Context:* If App/Vreader/ is canonical, the root Vreader/ and its .xcodeproj become dead code — leaving them causes confusion and check_refs.py false positives.

**Options:**
- A) Delete root Vreader/ and Vreader.xcodeproj entirely — only App/Vreader/Vreader.xcodeproj remains
- B) Keep root Vreader/ as an archive/reference but add it to .gitignore and .skaroignore
- C) Keep root Vreader.xcodeproj as the primary project file and move all sources under it

**Answer:**
Delete root Vreader/ and Vreader.xcodeproj entirely — only App/Vreader/Vreader.xcodeproj remains

## Question 3
For files that exist only in root Vreader/ and not in App/Vreader/Vreader/ (ErrorCode.swift, StorageView.swift, StoragesView.swift, ReadingSessionView.swift, iCLoudSettingsStore.swift with typo), what is the migration strategy?

*Context:* ErrorCode.swift is required by architectural invariants (every error must be typed via ErrorCode); discarding it without migration would break the invariant.

**Options:**
- A) Copy all unique root Vreader/ files into App/Vreader/Vreader/ before deleting root directory
- B) Copy only ErrorCode.swift (architecturally mandatory); discard StorageView, StoragesView, ReadingSessionView as superseded by App/ equivalents
- C) Discard all root-only files — they are stubs and App/ already has equivalent or better implementations

**Answer:**
Copy only ErrorCode.swift (architecturally mandatory); discard StorageView, StoragesView, ReadingSessionView as superseded by App/ equivalents

## Question 4
Should the Xcode group structure (Models/, Services/, UI/, Cloud/, AI/, Infrastructure/) be created as real filesystem folders or only as virtual Xcode groups?

*Context:* Real folders keep the filesystem and Xcode in sync and are required for check_refs.py path-based validation; virtual groups only reorganize the Xcode navigator without moving files.

**Options:**
- A) Real filesystem folders — move .swift files into subdirectories matching the group names
- B) Virtual Xcode groups only — files stay flat in App/Vreader/Vreader/, groups are navigator-only
- C) Not needed — flat structure is acceptable for this cleanup stage; groups can be added in a later milestone

**Answer:**
Not needed — flat structure is acceptable for this cleanup stage; groups can be added in a later milestone

## Question 5
The root Vreader/VReader.entitlements and App/Vreader/Vreader/VReader.entitlements may differ — which one should be verified and updated for the 4 mandatory entitlements?

*Context:* FR-05 requires all 4 entitlements to be present; if the canonical .entitlements file is missing any of them the app will crash at runtime when accessing iCloud or App Groups.

**Options:**
- A) Only App/Vreader/Vreader/VReader.entitlements — it belongs to the canonical project target
- B) Both files must be checked and made identical before the root copy is deleted
- C) Read both, merge into App/Vreader/Vreader/VReader.entitlements taking the union of all keys, then delete root copy

**Answer:**
Read both, merge into App/Vreader/Vreader/VReader.entitlements taking the union of all keys, then delete root copy

## Question 6
Vreader/Localizable.strings 00-14-05-840.strings is a timestamped duplicate of Localizable.strings in the root directory — how should it be handled?

*Context:* Leaving timestamped duplicate string files causes L10n key conflicts and will fail check_refs.py string validation.

**Options:**
- A) Delete it unconditionally — it is clearly an accidental backup file
- B) Diff it against the canonical Localizable.strings first; if no unique keys, delete; if unique keys exist, merge then delete
- C) Rename it to ARCHIVE_Localizable.strings and exclude from build target only

**Answer:**
Delete it unconditionally — it is clearly an accidental backup file
