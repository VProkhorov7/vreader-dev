# Specification: project-structure-cleanup

## Context
The project currently has duplicate files:
- Core/Book.swift, Core/ContentSource.swift, Core/DownloadTask.swift, Core/ErrorCode.swift
- Same files exist in App/Vreader/Vreader/

Also present: Untitled.swift (empty file).

## Decisions

**Canonical files:** Compare modification dates via `git log -1 --format="%ai"` or `stat`. Take the newer version. All canonical files go to App/Vreader/Vreader/. History preserved via `git mv`.

**Reorganization:** No folder reorganization at this stage. Only delete Core/ and Untitled.swift. Layer-based reorganization is deferred.

**Conflicting files:**
- Rename iCLoudSettingsStore.swift → iCloudSettingsStore.swift (fix typo) using `git mv`
- Add TODO comment to AppState.swift about refactoring per ADR-009
- Leave ReadingSession.swift and URLSessionTaskDelegate.swift unchanged

## Entitlements
Add to VReader.entitlements:
- com.apple.developer.ubiquity-kvs-identifier: $(TeamIdentifierPrefix)com.vreader.app
- com.apple.developer.icloud-services: CloudKit, CloudDocuments
- com.apple.developer.icloud-container-identifiers: iCloud.com.vreader.app
- com.apple.security.application-groups: com.vreader.shared

## Step-by-Step Execution Plan

1. **Determine canonical versions**
   - For each duplicate (Book.swift, ContentSource.swift, DownloadTask.swift, ErrorCode.swift):
     - Run `git log -1 --format="%ai"` on both Core/ and App/Vreader/Vreader/ versions
     - If dates differ, the newer file is canonical
     - If dates are identical, diff the files; manually confirm which to keep before proceeding
   - Document the chosen canonical version for each file before any destructive operation

2. **Move canonical files (if Core/ version is newer)**
   - Use `git mv Core/<File>.swift App/Vreader/Vreader/<File>.swift` to overwrite with history preserved
   - If App/Vreader/Vreader/ version is already canonical, no move needed — proceed to deletion

3. **Delete Core/ directory**
   - After all canonical files are confirmed in App/Vreader/Vreader/, run `git rm -r Core/`
   - Verify no remaining references to Core/ paths in .xcodeproj or Swift imports

4. **Delete Untitled.swift**
   - Run `git rm App/Vreader/Vreader/Untitled.swift` (or wherever it resides)
   - Verify file contained no type definitions before deletion

5. **Rename iCLoudSettingsStore.swift**
   - Run `git mv App/Vreader/Vreader/iCLoudSettingsStore.swift App/Vreader/Vreader/iCloudSettingsStore.swift`
   - Update all import references and type usages across the project to match new filename
   - Verify Xcode project file references the corrected filename

6. **Update AppState.swift**
   - Add the following TODO comment at the top of the file (below any copyright header):
     ```swift
     // TODO: Refactor per ADR-009 — decompose into NavigationState, LibraryState,
     // ReaderState, and SyncState (@Observable classes). Remove AppState entirely.
     ```
   - No functional changes to AppState.swift at this stage

7. **Update VReader.entitlements**
   - Add or confirm presence of all four entitlement keys:
     - `com.apple.developer.ubiquity-kvs-identifier` → `$(TeamIdentifierPrefix)com.vreader.app`
     - `com.apple.developer.icloud-services` → `[CloudKit, CloudDocuments]`
     - `com.apple.developer.icloud-container-identifiers` → `[iCloud.com.vreader.app]`
     - `com.apple.security.application-groups` → `[com.vreader.shared]`
   - Do not remove any existing entitlement keys

8. **Verify Xcode project integrity**
   - Confirm .xcodeproj references no deleted files
   - Confirm .xcodeproj references iCloudSettingsStore.swift (corrected name)
   - Build the project; resolve any missing file or missing type errors

9. **Run check_refs.py**
   - Execute `python3 check_refs.py` from project root
   - All checks must pass with zero errors before marking done

## Definition of Done
- Core/ directory deleted from repository and filesystem
- Untitled.swift deleted
- No duplicate type definitions remain anywhere in the project
- iCloudSettingsStore.swift is correctly named (typo fixed, git history preserved)
- AppState.swift contains the ADR-009 TODO comment
- VReader.entitlements contains all four required entitlement keys with correct values
- .xcodeproj contains no references to deleted files
- Project compiles without errors or warnings introduced by this change
- check_refs.py passes with zero errors

## Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-1 | Core/ directory does not exist in the repository | `ls Core/` returns "No such file or directory" |
| AC-2 | Untitled.swift does not exist anywhere in the project | `find . -name "Untitled.swift"` returns empty |
| AC-3 | No type is defined more than once across the project | `check_refs.py` passes; no duplicate type errors |
| AC-4 | iCloudSettingsStore.swift exists with correct casing | `ls App/Vreader/Vreader/iCloudSettingsStore.swift` succeeds |
| AC-5 | iCLoudSettingsStore.swift (old name) does not exist | `find . -name "iCLoudSettingsStore.swift"` returns empty |
| AC-6 | Git history for iCloudSettingsStore.swift is preserved | `git log App/Vreader/Vreader/iCloudSettingsStore.swift` shows prior commits |
| AC-7 | AppState.swift contains ADR-009 TODO comment | `grep "ADR-009" App/Vreader/Vreader/AppState.swift` returns match |
| AC-8 | VReader.entitlements contains ubiquity-kvs-identifier | `grep "ubiquity-kvs-identifier" VReader.entitlements` returns match |
| AC-9 | VReader.entitlements contains iCloud.com.vreader.app | `grep "iCloud.com.vreader.app" VReader.entitlements` returns match |
| AC-10 | Project compiles without errors | `xcodebuild -scheme VReader build` exits with code 0 |
| AC-11 | check_refs.py passes | `python3 check_refs.py` exits with code 0 |
| AC-12 | No references to Core/ remain in .xcodeproj | `grep -r "Core/" App/Vreader/Vreader.xcodeproj` returns empty |